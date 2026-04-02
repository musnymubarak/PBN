"""
Prime Business Network – Business Model.
"""

from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class Business(Base, TimestampMixin):
    __tablename__ = "businesses"

    owner_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    business_name: Mapped[str] = mapped_column(String(255), nullable=False)
    industry_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id"), nullable=False
    )
    district: Mapped[str | None] = mapped_column(String(100), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    website: Mapped[str | None] = mapped_column(String(500), nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    def __repr__(self) -> str:
        return f"<Business {self.business_name}>"
