from sqlalchemy import Column, DateTime, Integer
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class CartItem(Base):
    """Maps to the existing `cart_items` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "cart_items"

    cart_item_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    product_id = Column(Integer, nullable=False)
    quantity = Column(Integer, nullable=False)
    added_at = Column(DateTime, nullable=True)
