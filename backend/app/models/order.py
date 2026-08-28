from sqlalchemy import Column, DateTime, Integer, Numeric, String, Text
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Order(Base):
    """Maps to the existing `orders` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "orders"

    order_id = Column(Integer, primary_key=True)
    user_id = Column(Integer, nullable=False)
    order_number = Column(String, nullable=False)
    status = Column(String, nullable=False)
    total_amount = Column(Numeric(10, 2), nullable=False)
    delivery_address = Column(Text, nullable=False)
    payment_method = Column(String, nullable=False)
    placed_at = Column(DateTime, nullable=True)


class OrderItem(Base):
    """Maps to the existing `order_items` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "order_items"

    order_item_id = Column(Integer, primary_key=True)
    order_id = Column(Integer, nullable=False)
    product_id = Column(Integer, nullable=False)
    quantity = Column(Integer, nullable=False)
    price_at_purchase = Column(Numeric(10, 2), nullable=False)
