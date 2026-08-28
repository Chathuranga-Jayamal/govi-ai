from pydantic import BaseModel

from app.schemas.product import ProductResponse


class AddCartItemRequest(BaseModel):
    product_id: int
    quantity: int


class UpdateCartItemRequest(BaseModel):
    quantity: int


class CartItemResponse(BaseModel):
    id: int
    quantity: int
    product: ProductResponse
