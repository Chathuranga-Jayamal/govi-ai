from sqlalchemy import Column, DateTime, Integer, Numeric, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class Payment(Base):
    """Maps to the existing `payments` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "payments"

    payment_id = Column(Integer, primary_key=True)
    order_id = Column(Integer, nullable=False)
    payhere_transaction_id = Column(String, nullable=True)
    amount = Column(Numeric(10, 2), nullable=False)
    status = Column(String, nullable=False)
    processed_at = Column(DateTime, nullable=True)
