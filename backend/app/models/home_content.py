"""
Prime Business Network – Home Slide (dynamic home carousel) Model.

Drives the home dashboard carousel from the database so admins can change
content, order, scheduling and audience targeting without shipping a new
mobile build.  See docs/dynamic-home-content-plan.md.

`slide_type` keeps today's behaviour:
  custom               -> fully admin-authored panel
  next_virtual_event   -> auto-filled with the next upcoming virtual event
  next_physical_event  -> auto-filled with the next upcoming physical event
"""

from __future__ import annotations

import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin


class SlideType(str, enum.Enum):
    CUSTOM = "custom"
    NEXT_VIRTUAL_EVENT = "next_virtual_event"
    NEXT_PHYSICAL_EVENT = "next_physical_event"


class CtaActionType(str, enum.Enum):
    NONE = "none"
    ROUTE = "route"
    URL = "url"
    EVENT = "event"
    MAPS = "maps"


# ``values_callable`` makes Postgres store the lowercase ``.value`` of each
# member (e.g. "custom") rather than the member NAME ("CUSTOM").  This keeps the
# DB labels, the seed data, the JSON API and the mobile/admin clients perfectly
# consistent and avoids the classic SQLAlchemy name-vs-value mismatch.
_slide_type_enum = Enum(
    SlideType,
    name="home_slide_type",
    values_callable=lambda e: [m.value for m in e],
    create_type=True,
)
_cta_action_enum = Enum(
    CtaActionType,
    name="home_slide_cta_action",
    values_callable=lambda e: [m.value for m in e],
    create_type=True,
)


class HomeSlide(Base, TimestampMixin):
    __tablename__ = "home_slides"

    slide_type: Mapped[SlideType] = mapped_column(
        _slide_type_enum, nullable=False, default=SlideType.CUSTOM
    )

    # ── Content ──────────────────────────────────────────────────────────────
    badge_label: Mapped[str | None] = mapped_column(String(60), nullable=True)
    title: Mapped[str | None] = mapped_column(String(160), nullable=True)
    subtitle: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ── Call-to-action (data-driven; see docs action vocabulary) ─────────────
    cta_label: Mapped[str | None] = mapped_column(String(60), nullable=True)
    cta_action_type: Mapped[CtaActionType] = mapped_column(
        _cta_action_enum, nullable=False, default=CtaActionType.NONE
    )
    cta_action_value: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # ── Ordering & visibility ────────────────────────────────────────────────
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    # ── Scheduling window (null = open-ended) ────────────────────────────────
    starts_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ends_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # ── Audience targeting (null = everyone / all chapters) ──────────────────
    audience_roles: Mapped[list | None] = mapped_column(JSONB, nullable=True)
    audience_chapter_ids: Mapped[list | None] = mapped_column(JSONB, nullable=True)

    def __repr__(self) -> str:
        return f"<HomeSlide {self.slide_type.value} order={self.sort_order}>"
