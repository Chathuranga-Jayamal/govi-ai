from sqlalchemy import Column, DateTime, Integer, String
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class User(Base):
    """Maps to the existing `users` table. Schema is owned by database/ — do not migrate from here."""

    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    phone_number = Column(String, nullable=True)
    password_hash = Column(String, nullable=False)
    preferred_language = Column(String, nullable=True)
    created_at = Column(DateTime, nullable=False)
