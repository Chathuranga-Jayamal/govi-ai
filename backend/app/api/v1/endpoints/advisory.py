from fastapi import APIRouter, Depends, HTTPException, status
from openai import OpenAIError
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.advisory import AdvisoryRequest, AdvisoryResponse
from app.services.rag_service import (
    AdvisoryGenerationError,
    RAGService,
    get_rag_service,
)

router = APIRouter()


@router.post("", response_model=AdvisoryResponse)
async def get_advisory(
    request: AdvisoryRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    rag_service: RAGService = Depends(get_rag_service),
) -> AdvisoryResponse:
    conversation_history = [
        {"role": turn.role, "content": turn.content}
        for turn in request.conversation_history
    ]

    try:
        reply, sources = rag_service.get_reply(
            db,
            message=request.message,
            crop=request.crop,
            disease=request.disease,
            language=request.language,
            conversation_history=conversation_history,
            user_name=current_user.full_name,
        )
    except (OpenAIError, AdvisoryGenerationError):
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Advisory service is temporarily unavailable. Please try again.",
        )

    return AdvisoryResponse(reply=reply, sources=sources)
