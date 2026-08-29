from fastapi import APIRouter, Depends, Form, status
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.payment import InitiatePaymentRequest, PayHereCheckoutData
from app.services import payment_service

router = APIRouter()


@router.post("/initiate", response_model=PayHereCheckoutData)
def initiate_payment(
    body: InitiatePaymentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PayHereCheckoutData:
    return payment_service.initiate_payment(db, body.order_id, current_user)


@router.get("/checkout-form", response_class=HTMLResponse)
def payhere_checkout_form(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> str:
    # The WebView loads this page directly (rather than the app building the
    # form HTML locally) so the request PayHere receives at checkout comes
    # from a real https://govi-ai.fly.dev page, not a document with no
    # network origin at all.
    checkout = payment_service.initiate_payment(db, order_id, current_user)
    return payment_service.render_checkout_form_html(checkout)


@router.post("/notify", status_code=status.HTTP_200_OK)
def payhere_notify(
    merchant_id: str = Form(...),
    order_id: str = Form(...),
    payhere_amount: str = Form(...),
    payhere_currency: str = Form(...),
    status_code: str = Form(...),
    md5sig: str = Form(...),
    payment_id: str = Form(...),
    db: Session = Depends(get_db),
) -> dict:
    # No get_current_user here — PayHere calls this server-to-server with no
    # JWT. The md5sig verification inside process_notification is the real
    # authentication; always ACK 200 regardless of outcome (PayHere retries
    # otherwise), never leaking whether verification passed.
    payment_service.process_notification(
        db,
        merchant_id=merchant_id,
        order_id=order_id,
        payhere_amount=payhere_amount,
        payhere_currency=payhere_currency,
        status_code=status_code,
        md5sig=md5sig,
        payhere_payment_id=payment_id,
    )
    return {"status": "ok"}


@router.get("/return", response_class=HTMLResponse)
def payment_return() -> str:
    return "<html><body>Payment complete. You can return to the Govi-AI app.</body></html>"


@router.get("/cancel", response_class=HTMLResponse)
def payment_cancel() -> str:
    return "<html><body>Payment cancelled. You can return to the Govi-AI app.</body></html>"
