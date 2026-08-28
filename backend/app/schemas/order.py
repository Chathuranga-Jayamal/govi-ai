from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.product import ProductResponse

PaymentMethod = Literal["cod", "card", "payhere"]


class PlaceOrderRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    delivery_address: str = Field(alias="deliveryAddress")
    payment_method: PaymentMethod = Field(alias="paymentMethod")


class OrderItemResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    product: ProductResponse
    quantity: int
    price_at_purchase: float = Field(alias="priceAtPurchase")


class OrderResponse(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    id: int
    order_number: str = Field(alias="orderNumber")
    status: str
    total_amount: float = Field(alias="totalAmount")
    delivery_address: str = Field(alias="deliveryAddress")
    payment_method: str = Field(alias="paymentMethod")
    placed_at: datetime | None = Field(default=None, alias="placedAt")
    items: list[OrderItemResponse]
