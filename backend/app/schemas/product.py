from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

ProductCategory = Literal["fertilizer", "pesticide", "tools"]


class ProductResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    name: str
    category: str
    price: float
    description: str | None = None
    usage_instructions: str | None = Field(default=None, alias="usageInstructions")
    warning_text: str | None = Field(default=None, alias="warningText")
    rating: float
    is_best_seller: bool = Field(alias="isBestSeller")
    image_url: str | None = Field(default=None, alias="imageUrl")
