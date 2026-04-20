"""
Prime Business Network – Event, RSVP & Attendance Models.
"""

from __future__ import annotations

import enum
import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
import sqlalchemy.orm

from app.models.base import Base, TimestampMixin

from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from app.models.chapters import Chapter
    from app.models.user import User


class EventType(str, enum.Enum):
    FLAGSHIP = "flagship"
    VIRTUAL = "virtual"
    MICRO_MEETUP = "micro_meetup"


class RSVPStatus(str, enum.Enum):
    GOING = "going"
    NOT_GOING = "not_going"
    MAYBE = "maybe"
    REQUESTED = "requested"


class Event(Base, TimestampMixin):
    __tablename__ = "events"

    chapter_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("chapters.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    event_type: Mapped[EventType] = mapped_column(
        Enum(EventType, name="event_type", create_type=True), nullable=False
    )
    location: Mapped[str | None] = mapped_column(String(500), nullable=True)
    meeting_link: Mapped[str | None] = mapped_column(String(500), nullable=True)
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    fee: Mapped[Decimal] = mapped_column(
        Numeric(precision=10, scale=2), default=0, nullable=False
    )
    max_attendees: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_published: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    chapter: Mapped["Chapter"] = sqlalchemy.orm.relationship("Chapter")
    rsvps: Mapped[list["EventRSVP"]] = sqlalchemy.orm.relationship("EventRSVP", back_populates="event", cascade="all, delete-orphan")
    attendances: Mapped[list["EventAttendance"]] = sqlalchemy.orm.relationship("EventAttendance", back_populates="event", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Event {self.title}>"


class EventRSVP(Base, TimestampMixin):
    __tablename__ = "event_rsvps"

    event_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("events.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    status: Mapped[RSVPStatus] = mapped_column(
        Enum(RSVPStatus, name="rsvp_status", create_type=True), nullable=False
    )

    __table_args__ = (
        UniqueConstraint("event_id", "user_id", name="unique_event_rsvp"),
    )

    event: Mapped["Event"] = sqlalchemy.orm.relationship("Event", back_populates="rsvps")
    user: Mapped["User"] = sqlalchemy.orm.relationship("User")

    def __repr__(self) -> str:
        return f"<RSVP event={self.event_id} user={self.user_id} [{self.status.value}]>"


class EventAttendance(Base, TimestampMixin):
    __tablename__ = "event_attendance"

    event_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("events.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    marked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    marked_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    event: Mapped["Event"] = sqlalchemy.orm.relationship("Event", back_populates="attendances")
    user: Mapped["User"] = sqlalchemy.orm.relationship("User", foreign_keys=[user_id])
    marked_by_user: Mapped["User | None"] = sqlalchemy.orm.relationship("User", foreign_keys=[marked_by])

    def __repr__(self) -> str:
        return f"<Attendance event={self.event_id} user={self.user_id}>"
