from typing import TYPE_CHECKING, Literal

from pydantic import BaseModel, ConfigDict, Field

if TYPE_CHECKING:
    from fastapi import Request

    from app.models.product import Product

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

    @classmethod
    def from_model(cls, product: "Product", request: "Request") -> "ProductResponse":
        image_url = None
        if product.image_filename:
            image_url = f"{request.base_url}static/products/{product.image_filename}"

        return cls(
            id=product.product_id,
            name=product.name,
            category=product.category,
            price=float(product.price),
            description=product.description,
            usage_instructions=product.usage_instructions,
            warning_text=product.warning_text,
            rating=float(product.rating) if product.rating is not None else 0.0,
            is_best_seller=bool(product.is_best_seller),
            image_url=image_url,
        )
