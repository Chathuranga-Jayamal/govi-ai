from sqlalchemy import Boolean, Column, DateTime, Integer, Numeric, String, Text
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Product(Base):
    """Maps to the existing `products` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "products"

    product_id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    category = Column(String, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    description = Column(Text, nullable=True)
    usage_instructions = Column(Text, nullable=True)
    warning_text = Column(Text, nullable=True)
    rating = Column(Numeric(2, 1), nullable=True)
    is_best_seller = Column(Boolean, nullable=True)
    stock_quantity = Column(Integer, nullable=True)
    image_filename = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=True)
