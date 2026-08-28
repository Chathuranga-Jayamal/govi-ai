from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.product import Product
from app.schemas.product import ProductCategory, ProductResponse

router = APIRouter()


@router.get("", response_model=list[ProductResponse])
def list_products(
    request: Request,
    category: ProductCategory | None = Query(default=None),
    best_seller: bool | None = Query(default=None),
    db: Session = Depends(get_db),
) -> list[ProductResponse]:
    query = db.query(Product)
    if category is not None:
        query = query.filter(Product.category == category)
    if best_seller is not None:
        query = query.filter(Product.is_best_seller == best_seller)

    products = query.order_by(Product.product_id).all()
    return [ProductResponse.from_model(product, request) for product in products]


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int, request: Request, db: Session = Depends(get_db)
) -> ProductResponse:
    product = db.query(Product).filter(Product.product_id == product_id).first()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found."
        )
    return ProductResponse.from_model(product, request)
