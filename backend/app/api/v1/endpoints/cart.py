from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.cart_item import CartItem
from app.models.product import Product
from app.models.user import User
from app.schemas.cart import AddCartItemRequest, CartItemResponse, UpdateCartItemRequest
from app.schemas.product import ProductResponse

router = APIRouter()


def _to_response(
    cart_item: CartItem, product: Product, request: Request
) -> CartItemResponse:
    return CartItemResponse(
        id=cart_item.cart_item_id,
        quantity=cart_item.quantity,
        product=ProductResponse.from_model(product, request),
    )


@router.get("", response_model=list[CartItemResponse])
def get_cart(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CartItemResponse]:
    cart_items = (
        db.query(CartItem).filter(CartItem.user_id == current_user.user_id).all()
    )
    if not cart_items:
        return []

    product_ids = [item.product_id for item in cart_items]
    products = db.query(Product).filter(Product.product_id.in_(product_ids)).all()
    products_by_id = {product.product_id: product for product in products}

    return [
        _to_response(item, products_by_id[item.product_id], request)
        for item in cart_items
        if item.product_id in products_by_id
    ]


@router.post("/add", response_model=CartItemResponse, status_code=status.HTTP_201_CREATED)
def add_to_cart(
    body: AddCartItemRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CartItemResponse:
    product = db.query(Product).filter(Product.product_id == body.product_id).first()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found."
        )

    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.user_id == current_user.user_id,
            CartItem.product_id == body.product_id,
        )
        .first()
    )

    if cart_item is not None:
        # UNIQUE(user_id, product_id) — increment instead of inserting a duplicate.
        cart_item.quantity += body.quantity
    else:
        cart_item = CartItem(
            user_id=current_user.user_id,
            product_id=body.product_id,
            quantity=body.quantity,
            # See orders.py's Order.placed_at for why this must be set
            # explicitly rather than relying on the table's DB default.
            added_at=datetime.now(timezone.utc),
        )
        db.add(cart_item)

    db.commit()
    db.refresh(cart_item)
    return _to_response(cart_item, product, request)


@router.patch("/{cart_item_id}", response_model=CartItemResponse)
def update_cart_item(
    cart_item_id: int,
    body: UpdateCartItemRequest,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CartItemResponse:
    if body.quantity < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quantity must be at least 1.",
        )

    # Scoped to the current user too, not just cart_item_id — otherwise one
    # user could edit another user's cart row by guessing an id.
    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.cart_item_id == cart_item_id,
            CartItem.user_id == current_user.user_id,
        )
        .first()
    )
    if cart_item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found."
        )

    cart_item.quantity = body.quantity
    db.commit()
    db.refresh(cart_item)

    product = db.query(Product).filter(Product.product_id == cart_item.product_id).first()
    return _to_response(cart_item, product, request)


@router.delete("/{cart_item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cart_item(
    cart_item_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    cart_item = (
        db.query(CartItem)
        .filter(
            CartItem.cart_item_id == cart_item_id,
            CartItem.user_id == current_user.user_id,
        )
        .first()
    )
    if cart_item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cart item not found."
        )

    db.delete(cart_item)
    db.commit()
