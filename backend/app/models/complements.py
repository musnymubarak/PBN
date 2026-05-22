"""
Prime Business Network – Complements Models.

Complements are tangible/intangible perks issued to approved members
(founder's T-shirt, lapel pin, certificate, …). The catalogue lives in
`complement_types`; per-member fulfilment lives in `member_complements`.
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class FulfilmentStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class ComplementType(Base, TimestampMixin):
    """Catalogue entry for a complement (e.g. founder's T-shirt)."""
    __tablename__ = "complement_types"

    code: Mapped[str] = mapped_column(String(50), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    variants: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    def __repr__(self) -> str:
        return f"<ComplementType {self.code}>"


class MemberComplement(Base, TimestampMixin):
    """Per-member fulfilment record for a complement type."""
    __tablename__ = "member_complements"
    __table_args__ = (
        UniqueConstraint("user_id", "complement_type_id", name="uq_member_complements_user_type"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    complement_type_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("complement_types.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    variant: Mapped[str | None] = mapped_column(String(50), nullable=True)
    fulfilment_status: Mapped[FulfilmentStatus] = mapped_column(
        Enum(
            FulfilmentStatus,
            name="complement_fulfilment_status",
            create_type=False,
            values_callable=lambda x: [e.value for e in x],
        ),
        nullable=False,
        default=FulfilmentStatus.PENDING,
    )
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    fulfilled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    fulfilled_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    complement_type = relationship("ComplementType", lazy="joined")

    def __repr__(self) -> str:
        return f"<MemberComplement user={self.user_id} type={self.complement_type_id} {self.fulfilment_status.value}>"
