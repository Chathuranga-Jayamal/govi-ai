import secrets
from collections import defaultdict
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.cart_item import CartItem
from app.models.order import Order, OrderItem
from app.models.product import Product
from app.models.user import User
from app.schemas.order import OrderItemResponse, OrderResponse, PlaceOrderRequest
from app.schemas.product import ProductResponse

router = APIRouter()


def _generate_order_number() -> str:
    return f"GOVI-{secrets.token_hex(4).upper()}"


@router.post("", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
def place_order(
    body: PlaceOrderRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> OrderResponse:
    cart_items = (
        db.query(CartItem).filter(CartItem.user_id == current_user.user_id).all()
    )
    if not cart_items:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Your cart is empty."
        )

    product_ids = [item.product_id for item in cart_items]
    products = db.query(Product).filter(Product.product_id.in_(product_ids)).all()
    products_by_id = {product.product_id: product for product in products}

    missing = [pid for pid in product_ids if pid not in products_by_id]
    if missing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more items in your cart are no longer available.",
        )

    # total_amount is computed here from live product prices — never trust a
    # client-supplied total.
    total_amount = sum(
        products_by_id[item.product_id].price * item.quantity for item in cart_items
    )

    order = Order(
        user_id=current_user.user_id,
        order_number=_generate_order_number(),
        status="processing",
        total_amount=total_amount,
        delivery_address=body.delivery_address,
        payment_method=body.payment_method,
        # SQLAlchemy sends an explicit NULL for any unset mapped column
        # rather than omitting it, which would silently defeat the table's
        # DEFAULT CURRENT_TIMESTAMP — set it here instead (same reasoning
        # as User.created_at in auth_service.py).
        placed_at=datetime.now(timezone.utc),
    )
    db.add(order)
    db.flush()  # assigns order.order_id without committing yet

    order_items = []
    for item in cart_items:
        product = products_by_id[item.product_id]
        order_item = OrderItem(
            order_id=order.order_id,
            product_id=item.product_id,
            quantity=item.quantity,
            price_at_purchase=product.price,
        )
        db.add(order_item)
        order_items.append((order_item, product))

    for item in cart_items:
        db.delete(item)

    # Single commit: the order, its items, and the cart clear all persist
    # together or not at all.
    db.commit()
    db.refresh(order)

    return OrderResponse(
        id=order.order_id,
        order_number=order.order_number,
        status=order.status,
        total_amount=float(order.total_amount),
        delivery_address=order.delivery_address,
        payment_method=order.payment_method,
        placed_at=order.placed_at,
        items=[
            OrderItemResponse(
                product=ProductResponse.from_model(product, request),
                quantity=order_item.quantity,
                price_at_purchase=float(order_item.price_at_purchase),
            )
            for order_item, product in order_items
        ],
    )


@router.get("", response_model=list[OrderResponse])
def get_orders(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[OrderResponse]:
    orders = (
        db.query(Order)
        .filter(Order.user_id == current_user.user_id)
        .order_by(Order.placed_at.desc())
        .all()
    )
    if not orders:
        return []

    order_ids = [order.order_id for order in orders]
    order_items = db.query(OrderItem).filter(OrderItem.order_id.in_(order_ids)).all()

    product_ids = {item.product_id for item in order_items}
    products = db.query(Product).filter(Product.product_id.in_(product_ids)).all()
    products_by_id = {product.product_id: product for product in products}

    items_by_order: dict[int, list[OrderItemResponse]] = defaultdict(list)
    for item in order_items:
        product = products_by_id.get(item.product_id)
        if product is None:
            continue
        items_by_order[item.order_id].append(
            OrderItemResponse(
                product=ProductResponse.from_model(product, request),
                quantity=item.quantity,
                price_at_purchase=float(item.price_at_purchase),
            )
        )

    return [
        OrderResponse(
            id=order.order_id,
            order_number=order.order_number,
            status=order.status,
            total_amount=float(order.total_amount),
            delivery_address=order.delivery_address,
            payment_method=order.payment_method,
            placed_at=order.placed_at,
            items=items_by_order.get(order.order_id, []),
        )
        for order in orders
    ]
