import hashlib
import logging
from datetime import datetime, timezone
from decimal import Decimal
from html import escape

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models.order import Order, OrderItem
from app.models.payment import Payment
from app.models.product import Product
from app.models.user import User
from app.schemas.payment import PayHereCheckoutData

logger = logging.getLogger(__name__)

_CURRENCY = "LKR"

# PayHere's documented status_code values (server-to-server notify payload).
_STATUS_SUCCESS = "2"
_STATUS_FAILURE_CODES = {"-1", "-2", "-3"}  # cancelled, failed, chargedback

_NOTIFY_PATH = "/api/v1/payments/notify"
_RETURN_PATH = "/api/v1/payments/return"
_CANCEL_PATH = "/api/v1/payments/cancel"

_CHECKOUT_URLS = {
    "sandbox": "https://sandbox.payhere.lk/pay/checkout",
    "live": "https://www.payhere.lk/pay/checkout",
}


def _format_amount(amount: Decimal) -> str:
    return f"{amount:.2f}"


def _hashed_secret(merchant_secret: str) -> str:
    return hashlib.md5(merchant_secret.encode()).hexdigest().upper()


def _generate_hash(
    merchant_id: str, order_id: str, amount: str, currency: str, merchant_secret: str
) -> str:
    hashed_secret = _hashed_secret(merchant_secret)
    raw = f"{merchant_id}{order_id}{amount}{currency}{hashed_secret}"
    result = hashlib.md5(raw.encode()).hexdigest().upper()
    # Debug-only: the secret itself is never logged, only its md5 hash and
    # the final pre-hash string, so this is safe to leave on temporarily
    # while debugging a hash mismatch — remove once PayHere accepts it.
    logger.debug(
        "PayHere hash inputs: merchant_id=%r order_id=%r amount=%r currency=%r "
        "hashed_secret=%r raw=%r result=%r",
        merchant_id,
        order_id,
        amount,
        currency,
        hashed_secret,
        raw,
        result,
    )
    return result


def _split_name(full_name: str) -> tuple[str, str]:
    parts = full_name.strip().split(maxsplit=1)
    if len(parts) == 2:
        return parts[0], parts[1]
    return parts[0], parts[0]


def initiate_payment(db: Session, order_id: int, current_user: User) -> PayHereCheckoutData:
    order = (
        db.query(Order)
        .filter(Order.order_id == order_id, Order.user_id == current_user.user_id)
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Order not found."
        )

    existing_payment = (
        db.query(Payment).filter(Payment.order_id == order.order_id).first()
    )
    if existing_payment is not None and existing_payment.status == "success":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This order has already been paid for.",
        )

    order_items = db.query(OrderItem).filter(OrderItem.order_id == order.order_id).all()
    product_ids = [item.product_id for item in order_items]
    products_by_id = {
        product.product_id: product
        for product in db.query(Product).filter(Product.product_id.in_(product_ids)).all()
    }
    items_summary = ", ".join(
        products_by_id[item.product_id].name
        for item in order_items
        if item.product_id in products_by_id
    ) or order.order_number

    settings = get_settings()
    amount = _format_amount(order.total_amount)
    first_name, last_name = _split_name(current_user.full_name)

    payment_hash = _generate_hash(
        merchant_id=settings.payhere_merchant_id,
        order_id=order.order_number,
        amount=amount,
        currency=_CURRENCY,
        merchant_secret=settings.payhere_merchant_secret,
    )

    if existing_payment is not None:
        # Re-initiating a retry/back-out — reuse the row rather than
        # accumulating duplicate payment records for the same order.
        existing_payment.status = "pending"
        existing_payment.amount = order.total_amount
        existing_payment.payhere_transaction_id = None
        existing_payment.processed_at = None
    else:
        db.add(
            Payment(
                order_id=order.order_id,
                amount=order.total_amount,
                status="pending",
            )
        )
    db.commit()

    return PayHereCheckoutData(
        checkoutUrl=_CHECKOUT_URLS.get(settings.payhere_mode, _CHECKOUT_URLS["sandbox"]),
        merchantId=settings.payhere_merchant_id,
        returnUrl=f"{settings.public_base_url}{_RETURN_PATH}",
        cancelUrl=f"{settings.public_base_url}{_CANCEL_PATH}",
        notifyUrl=f"{settings.public_base_url}{_NOTIFY_PATH}",
        orderId=order.order_number,
        items=items_summary,
        currency=_CURRENCY,
        amount=amount,
        firstName=first_name,
        lastName=last_name,
        email=current_user.email,
        # delivery_address is a single free-form TEXT column (no structured
        # city field exists to pull from) — passed through as-is for
        # PayHere's address field; city is left blank rather than guessed.
        phone=current_user.phone_number or "",
        address=order.delivery_address,
        city="",
        country="Sri Lanka",
        hash=payment_hash,
    )


def render_checkout_form_html(checkout: PayHereCheckoutData) -> str:
    """Renders a hidden auto-submitting form POSTing to PayHere's checkout URL.

    Served from a real backend page (rather than built client-side in the
    WebView) so the request PayHere receives comes from a genuine
    https://govi-ai.fly.dev origin instead of no origin at all.
    """
    fields = checkout.model_dump(exclude={"checkout_url"})
    hidden_inputs = "".join(
        f'<input type="hidden" name="{escape(name)}" value="{escape(str(value))}">'
        for name, value in fields.items()
    )
    return f"""<!DOCTYPE html>
<html>
  <body onload="document.forms[0].submit()">
    <form method="POST" action="{escape(checkout.checkout_url)}">
      {hidden_inputs}
    </form>
  </body>
</html>
"""


def process_notification(
    db: Session,
    *,
    merchant_id: str,
    order_id: str,
    payhere_amount: str,
    payhere_currency: str,
    status_code: str,
    md5sig: str,
    payhere_payment_id: str,
) -> None:
    settings = get_settings()

    expected_sig = hashlib.md5(
        (
            f"{merchant_id}{order_id}{payhere_amount}{payhere_currency}"
            f"{status_code}{_hashed_secret(settings.payhere_merchant_secret)}"
        ).encode()
    ).hexdigest().upper()

    # The hash IS the authentication for this endpoint (no JWT — PayHere
    # calls it server-to-server). A mismatch could mean a forged request,
    # so nothing gets written to the database without this passing.
    if md5sig.upper() != expected_sig:
        return

    order = db.query(Order).filter(Order.order_number == order_id).first()
    if order is None:
        return

    payment = db.query(Payment).filter(Payment.order_id == order.order_id).first()
    if payment is None:
        return

    if status_code == _STATUS_SUCCESS:
        payment.status = "success"
    elif status_code in _STATUS_FAILURE_CODES:
        payment.status = "failed"
    else:
        # Pending/unrecognized status_code — leave payment status as-is.
        return

    payment.payhere_transaction_id = payhere_payment_id
    payment.processed_at = datetime.now(timezone.utc)

    if payment.status == "failed":
        # orders.status only allows 'processing'/'delivered'/'cancelled' —
        # there's no "payment_failed" state, so a failed/cancelled/charged-
        # back payment cancels the order outright. A successful payment
        # leaves the order's existing 'processing' status untouched.
        order.status = "cancelled"

    db.commit()
