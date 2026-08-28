"""
Script to seed advisory_docs table with content from batch files.
"""

import os
import re
import sys
from pathlib import Path

import psycopg2
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

# ---------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------

SCRIPT_DIR = Path(__file__).resolve().parent
BATCH_FILES = [
    SCRIPT_DIR / "batch1_rice_tomato.txt",
    SCRIPT_DIR / "batch2_chili_potato_corn.txt",
    SCRIPT_DIR / "batch3_tea_banana.txt",
    SCRIPT_DIR / "batch4_coconut.txt",
]

# Load DATABASE_URL from backend/.env
BACKEND_ENV_PATH = SCRIPT_DIR.parent.parent / "backend" / ".env"
load_dotenv(BACKEND_ENV_PATH)
DATABASE_URL = os.environ.get("DATABASE_URL")

if not DATABASE_URL:
    print(f"ERROR: DATABASE_URL not found. Checked: {BACKEND_ENV_PATH}")
    sys.exit(1)

MODEL_NAME = "all-MiniLM-L6-v2"
LANGUAGE = "en"  # all current content is English; si/ta are a follow-up
SOURCE_LABEL = "AI-assisted research, human-reviewed (Govi-AI advisory KB)"

# ---------------------------------------------------------------------
# Step 1 — Parse each batch file into (disease_name, content) entries
# ---------------------------------------------------------------------

def parse_batch_file(path: Path) -> list[tuple[str, str]]:
    """
    Splits a batch file on '## disease___name' headings.
    Returns a list of (disease_name, content_text) tuples.
    """
    if not path.exists():
        print(f"WARNING: file not found, skipping: {path}")
        return []

    text = path.read_text(encoding="utf-8")

    # Split on lines starting with '#' or '##' (markdown H1/H2 headings) —
    # the 4 research batches came out with inconsistent heading levels
    # (batches 1/3 used '##', batches 2/4 used '#'), so accept either.
    # Also strips any parenthetical note after the disease name, e.g.
    # "coconut___cci_caterpillars (Coconut Caterpillar Infestation)"
    # -> "coconut___cci_caterpillars"
    pattern = re.compile(
        r"^#{1,2}\s+(\S+).*?\n(.*?)(?=^#{1,2}\s+\S+|\Z)",
        re.MULTILINE | re.DOTALL,
    )

    entries = []
    for match in pattern.finditer(text):
        disease_name = match.group(1).strip()
        content = match.group(2).strip()
        if content:  # skip empty trailing entries (e.g. an unfinished last heading)
            entries.append((disease_name, content))

    return entries


def parse_all_batches() -> list[tuple[str, str]]:
    all_entries = []
    for batch_path in BATCH_FILES:
        entries = parse_batch_file(batch_path)
        print(f"  {batch_path.name}: {len(entries)} entries parsed")
        all_entries.extend(entries)
    return all_entries


# ---------------------------------------------------------------------
# Step 2 — Generate embeddings
# ---------------------------------------------------------------------

def generate_embeddings(entries: list[tuple[str, str]], model: SentenceTransformer):
    """
    Returns a list of (disease_name, content, embedding_list) tuples.
    """
    texts = [content for _, content in entries]
    print(f"\nGenerating embeddings for {len(texts)} entries using {MODEL_NAME}...")
    embeddings = model.encode(texts, show_progress_bar=True)

    results = []
    for (disease_name, content), embedding in zip(entries, embeddings):
        results.append((disease_name, content, embedding.tolist()))
    return results


# ---------------------------------------------------------------------
# Step 3 — Insert into advisory_docs
# ---------------------------------------------------------------------

def insert_rows(rows: list[tuple[str, str, list]]):
    conn = psycopg2.connect(DATABASE_URL)
    cur = conn.cursor()

    inserted = 0
    skipped = 0

    for disease_name, content, embedding in rows:
        # Prefix the disease name into the content itself so retrieval
        # can match on both the semantic meaning AND find the exact
        # disease name if the query includes it directly.
        full_content = f"[{disease_name}] {content}"

        # Check for an existing entry with the same disease name to avoid
        # duplicate rows if this script is re-run.
        cur.execute(
            "SELECT doc_id FROM advisory_docs WHERE content LIKE %s LIMIT 1",
            (f"[{disease_name}]%",),
        )
        existing = cur.fetchone()
        if existing:
            print(f"  SKIP (already exists): {disease_name}")
            skipped += 1
            continue

        cur.execute(
            """
            INSERT INTO advisory_docs (content, embedding, language, source)
            VALUES (%s, %s, %s, %s)
            """,
            (full_content, embedding, LANGUAGE, SOURCE_LABEL),
        )
        inserted += 1
        print(f"  INSERTED: {disease_name}")

    conn.commit()
    cur.close()
    conn.close()

    print(f"\nDone. Inserted: {inserted}, Skipped (duplicates): {skipped}")


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------

def main():
    print("Parsing batch files...")
    entries = parse_all_batches()
    print(f"\nTotal entries parsed across all batches: {len(entries)}")

    if not entries:
        print("No entries found — check that batch files exist and are formatted correctly.")
        sys.exit(1)

    # Show a preview so you can sanity-check before committing to the DB
    print("\nPreview of first 3 entries:")
    for disease_name, content in entries[:3]:
        print(f"  - {disease_name} ({len(content)} chars): {content[:80]}...")

    confirm = input(f"\nProceed with embedding + inserting {len(entries)} entries into advisory_docs? [y/N] ")
    if confirm.strip().lower() != "y":
        print("Aborted.")
        sys.exit(0)

    print(f"\nLoading model {MODEL_NAME}...")
    model = SentenceTransformer(MODEL_NAME)

    rows = generate_embeddings(entries, model)

    print("\nInserting into advisory_docs...")
    insert_rows(rows)


if __name__ == "__main__":
    main()
