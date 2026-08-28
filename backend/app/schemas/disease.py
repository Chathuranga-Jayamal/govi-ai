from typing import Literal

from pydantic import BaseModel

PredictionStatus = Literal["ok", "low_confidence", "not_a_leaf"]


class PredictResponse(BaseModel):
    status: PredictionStatus
    crop: str | None
    disease: str | None
    confidence: float
    message: str | None
    heatmap_url: str | None = None
