"""
Prime Business Network – Audit Log Model.

Captures every administrative operation:
  - WHO: actor_id (FK to users)
  - WHEN: created_at (from TimestampMixin)
  - WHAT: method + path + entity_type/entity_id + action + description
  - RESULT: status_code, old_value / new_value
  - CONTEXT: ip_address, user_agent, request_id, duration_ms
"""

from __future__ import annotations

import uuid

from sqlalchemy import ForeignKey, Integer, String, Index
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class AuditLog(Base, TimestampMixin):
    __tablename__ = "audit_logs"

    actor_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    entity_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    entity_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    action: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # HTTP request context (filled by AuditMiddleware)
    method: Mapped[str | None] = mapped_column(String(10), nullable=True)
    path: Mapped[str | None] = mapped_column(String(255), nullable=True)
    status_code: Mapped[int | None] = mapped_column(Integer, nullable=True)
    duration_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    request_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(500), nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)

    old_value: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    new_value: Mapped[dict | None] = mapped_column(JSONB, nullable=True)

    __table_args__ = (
        Index("ix_audit_logs_actor_created", "actor_id", "created_at"),
    )

    def __repr__(self) -> str:
        return f"<AuditLog {self.method or ''} {self.path or ''} actor={self.actor_id}>"
