from fastapi import APIRouter, Depends, Form, HTTPException, UploadFile, status

from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.disease import PredictResponse
from app.services.inference_service import (
    InferenceService,
    InvalidCropError,
    get_inference_service,
)

router = APIRouter()


@router.post("/predict", response_model=PredictResponse)
async def predict(
    image: UploadFile,
    crop: str = Form(...),
    current_user: User = Depends(get_current_user),
    inference_service: InferenceService = Depends(get_inference_service),
) -> PredictResponse:
    if not crop.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="crop is required.",
        )

    image_bytes = await image.read()

    try:
        result = inference_service.predict(image_bytes, crop)
    except InvalidCropError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unrecognized crop: {crop!r}.",
        )

    return PredictResponse(
        status=result.status,
        crop=result.crop,
        disease=result.disease,
        confidence=result.confidence,
        message=result.message,
        heatmap_url=result.heatmap_base64,
    )
