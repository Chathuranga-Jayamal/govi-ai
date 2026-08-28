from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.product import Product
from app.schemas.product import ProductCategory, ProductResponse

router = APIRouter()


def _to_response(product: Product, request: Request) -> ProductResponse:
    image_url = None
    if product.image_filename:
        image_url = f"{request.base_url}static/products/{product.image_filename}"

    return ProductResponse(
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
    return [_to_response(product, request) for product in products]


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int, request: Request, db: Session = Depends(get_db)
) -> ProductResponse:
    product = db.query(Product).filter(Product.product_id == product_id).first()
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Product not found."
        )
    return _to_response(product, request)
