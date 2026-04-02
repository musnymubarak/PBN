"""
Prime Business Network – Chapter Model.
"""

from __future__ import annotations

from sqlalchemy import Boolean, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class Chapter(Base, TimestampMixin):
    __tablename__ = "chapters"

    name: Mapped[str] = mapped_column(String(150), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    meeting_schedule: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    def __repr__(self) -> str:
        return f"<Chapter {self.name}>"
