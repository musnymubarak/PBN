"""
Prime Business Network – Home Content (dynamic carousel) Service.

`list_public_slides` is what the mobile app consumes: it applies the schedule
window + audience targeting server-side and resolves the dynamic event slides,
so the app only has to render whatever it receives.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException
from app.models.events import Event, EventType
from app.models.home_content import CtaActionType, HomeSlide, SlideType
from app.models.memberships import ChapterMembership
from app.models.user import User


# ── Serialization ────────────────────────────────────────────────────────────


def _admin_dict(s: HomeSlide) -> Dict[str, Any]:
    """Full record for the admin panel (includes targeting/schedule fields)."""
    return {
        "id": str(s.id),
        "slide_type": s.slide_type.value,
        "badge_label": s.badge_label,
        "title": s.title,
        "subtitle": s.subtitle,
        "image_url": s.image_url,
        "cta_label": s.cta_label,
        "cta_action_type": s.cta_action_type.value,
        "cta_action_value": s.cta_action_value,
        "sort_order": s.sort_order,
        "is_active": s.is_active,
        "starts_at": s.starts_at.isoformat() if s.starts_at else None,
        "ends_at": s.ends_at.isoformat() if s.ends_at else None,
        "audience_roles": s.audience_roles,
        "audience_chapter_ids": s.audience_chapter_ids,
    }


def _public_dict(s: HomeSlide) -> Dict[str, Any]:
    """Lean payload the mobile carousel renders."""
    return {
        "id": str(s.id),
        "slide_type": s.slide_type.value,
        "badge_label": s.badge_label,
        "title": s.title,
        "subtitle": s.subtitle,
        "image_url": s.image_url,
        "cta_label": s.cta_label,
        "cta_action_type": s.cta_action_type.value,
        "cta_action_value": s.cta_action_value,
    }


# ── Admin CRUD ───────────────────────────────────────────────────────────────


async def list_admin_slides(db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = select(HomeSlide).order_by(HomeSlide.sort_order, HomeSlide.created_at)
    slides = (await db.execute(stmt)).scalars().all()
    return [_admin_dict(s) for s in slides]


async def create_slide(data: Any, db: AsyncSession) -> HomeSlide:
    slide = HomeSlide(
        slide_type=SlideType(data.slide_type),
        badge_label=data.badge_label,
        title=data.title,
        subtitle=data.subtitle,
        image_url=data.image_url,
        cta_label=data.cta_label,
        cta_action_type=CtaActionType(data.cta_action_type),
        cta_action_value=data.cta_action_value,
        sort_order=data.sort_order,
        is_active=data.is_active,
        starts_at=data.starts_at,
        ends_at=data.ends_at,
        audience_roles=data.audience_roles,
        audience_chapter_ids=data.audience_chapter_ids,
    )
    db.add(slide)
    await db.commit()
    await db.refresh(slide)
    return slide


async def update_slide(slide_id: UUID, data: Any, db: AsyncSession) -> HomeSlide:
    slide = (await db.execute(select(HomeSlide).where(HomeSlide.id == slide_id))).scalar_one_or_none()
    if not slide:
        raise NotFoundException("Home slide not found")

    if data.slide_type is not None:
        slide.slide_type = SlideType(data.slide_type)
    if data.badge_label is not None:
        slide.badge_label = data.badge_label
    if data.title is not None:
        slide.title = data.title
    if data.subtitle is not None:
        slide.subtitle = data.subtitle
    if data.image_url is not None:
        slide.image_url = data.image_url
    if data.cta_label is not None:
        slide.cta_label = data.cta_label
    if data.cta_action_type is not None:
        slide.cta_action_type = CtaActionType(data.cta_action_type)
    if data.cta_action_value is not None:
        slide.cta_action_value = data.cta_action_value
    if data.sort_order is not None:
        slide.sort_order = data.sort_order
    if data.is_active is not None:
        slide.is_active = data.is_active
    if data.starts_at is not None:
        slide.starts_at = data.starts_at
    if data.ends_at is not None:
        slide.ends_at = data.ends_at
    if data.audience_roles is not None:
        slide.audience_roles = data.audience_roles
    if data.audience_chapter_ids is not None:
        slide.audience_chapter_ids = data.audience_chapter_ids

    await db.commit()
    await db.refresh(slide)
    return slide


async def delete_slide(slide_id: UUID, db: AsyncSession) -> None:
    slide = (await db.execute(select(HomeSlide).where(HomeSlide.id == slide_id))).scalar_one_or_none()
    if not slide:
        raise NotFoundException("Home slide not found")
    await db.delete(slide)
    await db.commit()


async def reorder_slides(ordered_ids: List[UUID], db: AsyncSession) -> None:
    """Persist the given id order as 0..n in ``sort_order``."""
    for index, slide_id in enumerate(ordered_ids):
        slide = (await db.execute(select(HomeSlide).where(HomeSlide.id == slide_id))).scalar_one_or_none()
        if slide:
            slide.sort_order = index
    await db.commit()


# ── Public feed (consumed by the mobile carousel) ────────────────────────────


async def _next_event(db: AsyncSession, *, physical: bool) -> Event | None:
    now = datetime.now(timezone.utc)
    stmt = select(Event).where(
        Event.start_at >= now,
        Event.is_active.is_(True),
        Event.is_published.is_(True),
    )
    if physical:
        stmt = stmt.where(Event.event_type != EventType.VIRTUAL)
    else:
        stmt = stmt.where(Event.event_type == EventType.VIRTUAL)
    stmt = stmt.order_by(Event.start_at.asc()).limit(1)
    return (await db.execute(stmt)).scalars().first()


async def list_public_slides(user: User, db: AsyncSession) -> List[Dict[str, Any]]:
    now = datetime.now(timezone.utc)

    slides = (
        await db.execute(
            select(HomeSlide)
            .where(HomeSlide.is_active.is_(True))
            .order_by(HomeSlide.sort_order, HomeSlide.created_at)
        )
    ).scalars().all()

    # Caller's active chapter ids – used for chapter-level audience targeting.
    membership_rows = (
        await db.execute(
            select(ChapterMembership.chapter_id).where(
                ChapterMembership.user_id == user.id,
                ChapterMembership.is_active.is_(True),
            )
        )
    ).scalars().all()
    my_chapter_ids = {str(c) for c in membership_rows}
    role_value = user.role.value if user.role else None

    out: List[Dict[str, Any]] = []
    for s in slides:
        # ── Schedule window ──────────────────────────────────────────────────
        if s.starts_at and s.starts_at > now:
            continue
        if s.ends_at and s.ends_at < now:
            continue

        # ── Audience targeting ───────────────────────────────────────────────
        if s.audience_roles and role_value not in s.audience_roles:
            continue
        if s.audience_chapter_ids:
            wanted = {str(c) for c in s.audience_chapter_ids}
            if not (my_chapter_ids & wanted):
                continue

        payload = _public_dict(s)

        # ── Resolve dynamic event slides ─────────────────────────────────────
        if s.slide_type in (SlideType.NEXT_VIRTUAL_EVENT, SlideType.NEXT_PHYSICAL_EVENT):
            physical = s.slide_type == SlideType.NEXT_PHYSICAL_EVENT
            event = await _next_event(db, physical=physical)
            if not event:
                # Nothing upcoming – hide the slide rather than show an empty one.
                continue
            payload["title"] = s.title or event.title
            payload["image_url"] = s.image_url or event.image_url
            payload["event_id"] = str(event.id)
            payload["start_at"] = event.start_at.isoformat() if event.start_at else None
            payload["location"] = event.location
            if physical:
                payload["cta_label"] = s.cta_label or "VIEW LOCATION"
                payload["cta_action_type"] = CtaActionType.MAPS.value
                payload["cta_action_value"] = event.location
            else:
                payload["cta_label"] = s.cta_label or "JOIN ZOOM"
                payload["cta_action_type"] = CtaActionType.URL.value
                payload["cta_action_value"] = event.meeting_link

        out.append(payload)

    return out
