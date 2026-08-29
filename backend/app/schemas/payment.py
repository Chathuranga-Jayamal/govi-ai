from pydantic import BaseModel, ConfigDict, Field


class InitiatePaymentRequest(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    order_id: int = Field(alias="orderId")


class PayHereCheckoutData(BaseModel):
    """Everything Flutter needs to POST PayHere's Checkout API form.

    The MD5 hash is computed here, server-side, from PAYHERE_MERCHANT_SECRET —
    per PayHere's own security requirement, the secret and the hash
    generation logic must never reach the client.
    """

    model_config = ConfigDict(populate_by_name=True)

    checkout_url: str = Field(alias="checkoutUrl")
    merchant_id: str = Field(alias="merchantId")
    return_url: str = Field(alias="returnUrl")
    cancel_url: str = Field(alias="cancelUrl")
    notify_url: str = Field(alias="notifyUrl")
    order_id: str = Field(alias="orderId")
    items: str
    currency: str
    amount: str
    first_name: str = Field(alias="firstName")
    last_name: str = Field(alias="lastName")
    email: str
    phone: str
    address: str
    city: str
    country: str
    hash: str
