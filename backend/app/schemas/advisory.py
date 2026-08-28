from typing import Literal

from pydantic import BaseModel, Field

AdvisoryLanguage = Literal["si", "ta", "en"]
ChatRole = Literal["user", "bot"]


class ChatTurn(BaseModel):
    role: ChatRole
    content: str


class AdvisoryRequest(BaseModel):
    message: str
    crop: str | None = None
    disease: str | None = None
    language: AdvisoryLanguage
    conversation_history: list[ChatTurn] = Field(default_factory=list)


class AdvisoryResponse(BaseModel):
    reply: str
    sources: list[str]
