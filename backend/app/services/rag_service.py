from functools import lru_cache

from openai import OpenAI
from sentence_transformers import SentenceTransformer
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.config import get_settings

# Must match the model used to seed advisory_docs (database/seed/seed_advisory_docs.py)
# — a different model would produce embeddings in a different vector space, making
# cosine-distance comparisons against the stored 384-dim embeddings meaningless.
_EMBEDDING_MODEL_NAME = "all-MiniLM-L6-v2"

_TOP_K = 3

# Cosine distance (0 = identical, 2 = opposite) above which a retrieved chunk is
# treated as not actually relevant. A starting point, not empirically tuned yet
# against the real 45-doc corpus — revisit once there's real query traffic to check
# against.
_MAX_DISTANCE = 0.6

_LANGUAGE_NAMES = {"si": "Sinhala", "ta": "Tamil", "en": "English"}

# The client sends its own recent-history slice (e.g. last 6-10 turns), but this
# is a defensive server-side cap in case that slicing logic ever sends more —
# keeps prompt size/cost bounded regardless of what the client does.
_MAX_HISTORY_TURNS = 10

_SYSTEM_PROMPT_TEMPLATE = (
    "You are Govi Advisor, a warm and knowledgeable agricultural assistant for "
    "Sri Lankan smallholder farmers, speaking through a chat app. The user's name "
    "is {user_name} — use their first name naturally for greetings, not their "
    "full name, and not in every message.\n\n"
    "Be genuinely conversational, not a template or a document:\n"
    "- If the user greets you or makes small talk, warmly acknowledge it by name "
    "and naturally ask how you can help — don't jump straight into farming "
    "advice unprompted.\n"
    "- If the question is clearly unrelated to farming (e.g. math, general "
    "trivia, unrelated topics), politely decline and steer the conversation "
    "back to agriculture — friendly, never curt or preachy.\n"
    "- If relevant knowledge base context is provided below, ground your answer "
    "in it primarily and don't add facts or figures it doesn't support.\n"
    "- If no knowledge base context is provided but the question is still "
    "agriculture-related, you may answer from your general knowledge — but "
    "stay appropriately cautious about specific dosages or treatments you're "
    "not certain of, and suggest the user consult their local agricultural "
    "extension officer for anything requiring precision.\n\n"
    "Respond entirely in {language_name}, translating as needed.\n\n"
    "Length and structure matter for how natural this feels in a chat app:\n"
    "- Casual exchanges (greetings, small talk, off-topic redirects, simple "
    "follow-ups) should be short — roughly 40-60 words.\n"
    "- Substantive agricultural answers can run longer, but stay under about "
    "100 words. Don't write a wall of text.\n"
    "- Default to ONE paragraph, ONE message. Only use a blank line to split "
    "into a second (or third) message when you have a genuinely distinct, "
    "substantial idea to add — not for ordinary sentence-to-sentence flow "
    "within a single thought. Multi-part replies should be the exception, "
    "not the norm.\n\n"
    'For example: "What\'s a good time to harvest tea?" deserves one short '
    'paragraph, not two. But "my tomato has late blight" legitimately '
    "warrants two parts — one for the immediate treatment, a separate one "
    "for prevention next season — because those are two distinct, "
    "substantial ideas, not just two sentences about the same point. "
    "General information plus a specific supporting detail on the same "
    "topic (e.g. general harvest timing plus the specific stage indicator "
    "to look for) is still ONE idea — keep those together, even if the "
    "combined answer runs a bit over the word guideline.\n\n"
    "Write in plain text only — no markdown (no **bold**, headers, or bullet "
    "symbols like - or *). Replies are shown as plain chat bubbles that don't "
    "render formatting, so any markdown would show up as literal stray "
    "characters. If you need to list a few items, write them as a normal "
    "sentence or put each on its own short line instead."
)


class AdvisoryGenerationError(Exception):
    """Raised when the LLM response has no usable completion — e.g. a
    free-tier provider hiccup returning HTTP 200 with empty/null choices
    instead of a raised error."""


class RAGService:
    def __init__(self) -> None:
        settings = get_settings()
        self._embedder = SentenceTransformer(_EMBEDDING_MODEL_NAME)
        self._client = OpenAI(api_key=settings.llm_api_key, base_url=settings.llm_base_url)
        self._model = settings.llm_model

    def _embed_query(self, message: str) -> list[float]:
        return self._embedder.encode(message).tolist()

    def _retrieve(self, db: Session, embedding: list[float]) -> list[dict]:
        # pgvector accepts its textual input format ("[v1,v2,...]") for a vector
        # cast, so this works without the pgvector Python package/adapter — the
        # same approach the seed script's raw psycopg2 inserts rely on.
        embedding_literal = "[" + ",".join(str(value) for value in embedding) + "]"
        rows = db.execute(
            text(
                "SELECT content, source, "
                "embedding <=> CAST(:embedding AS vector) AS distance "
                "FROM advisory_docs "
                "WHERE embedding <=> CAST(:embedding AS vector) <= :max_distance "
                "ORDER BY embedding <=> CAST(:embedding AS vector) "
                f"LIMIT {_TOP_K}"
            ),
            {"embedding": embedding_literal, "max_distance": _MAX_DISTANCE},
        ).mappings().all()
        return list(rows)

    def _build_messages(
        self,
        *,
        message: str,
        crop: str | None,
        disease: str | None,
        language: str,
        conversation_history: list[dict],
        chunks: list[dict],
        user_name: str,
    ) -> list[dict]:
        messages = [
            {
                "role": "system",
                "content": _SYSTEM_PROMPT_TEMPLATE.format(
                    user_name=user_name, language_name=_LANGUAGE_NAMES[language]
                ),
            }
        ]

        if crop and disease:
            messages.append(
                {
                    "role": "system",
                    "content": f"Context: this conversation is about {crop} — {disease}.",
                }
            )

        for turn in conversation_history[-_MAX_HISTORY_TURNS:]:
            role = "assistant" if turn["role"] == "bot" else "user"
            messages.append({"role": role, "content": turn["content"]})

        if chunks:
            context = "\n\n".join(f"- {chunk['content']}" for chunk in chunks)
            messages.append(
                {
                    "role": "system",
                    "content": (
                        "Relevant knowledge base context for the user's latest "
                        f"message:\n{context}"
                    ),
                }
            )

        messages.append({"role": "user", "content": message})
        return messages

    def get_reply(
        self,
        db: Session,
        *,
        message: str,
        crop: str | None,
        disease: str | None,
        language: str,
        conversation_history: list[dict],
        user_name: str,
    ) -> tuple[str, list[str]]:
        embedding = self._embed_query(message)
        chunks = self._retrieve(db, embedding)

        messages = self._build_messages(
            message=message,
            crop=crop,
            disease=disease,
            language=language,
            conversation_history=conversation_history,
            chunks=chunks,
            user_name=user_name,
        )

        response = self._client.chat.completions.create(
            model=self._model, messages=messages
        )
        # The free-tier provider occasionally returns HTTP 200 with no usable
        # completion (a hiccup, not a raised OpenAIError) — treat that as a
        # service failure rather than crash on `response.choices[0]`.
        if not response.choices:
            raise AdvisoryGenerationError("LLM response contained no choices.")

        reply = (response.choices[0].message.content or "").strip()
        sources = [chunk["source"] for chunk in chunks] if chunks else []
        return reply, sources


@lru_cache
def get_rag_service() -> RAGService:
    return RAGService()
