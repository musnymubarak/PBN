"""
Prime Business Network – Events API Service.
"""

from __future__ import annotations

from typing import Any, Dict, List
from uuid import UUID
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload, joinedload
from sqlalchemy.exc import IntegrityError

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.features.events.schemas import EventCreate, EventRSVPRequest, EventAttendanceRequest
from app.models.events import Event, EventRSVP, EventAttendance, RSVPStatus
from app.models.chapters import Chapter
from app.models.user import User


async def _serialize_event(ev: Event) -> Dict[str, Any]:
    return {
        "id": str(ev.id),
        "chapter_id": str(ev.chapter_id),
        "title": ev.title,
        "description": ev.description,
        "event_type": ev.event_type.value,
        "location": ev.location,
        "meeting_link": ev.meeting_link,
        "start_at": ev.start_at.isoformat(),
        "end_at": ev.end_at.isoformat(),
        "fee": float(ev.fee),
        "max_attendees": ev.max_attendees,
        "is_published": ev.is_published,
        "is_active": ev.is_active,
        "created_at": ev.created_at.isoformat() if ev.created_at else None,
        "rsvps": [
            {
                "user": {
                    "id": str(r.user.id),
                    "full_name": r.user.full_name,
                    "phone_number": r.user.phone_number,
                },
                "status": r.status.value,
                "created_at": r.created_at.isoformat() if r.created_at else None
            }
            for r in getattr(ev, "rsvps", [])
        ],
        "attendances": [
            {
                "user": {
                    "id": str(a.user.id),
                    "full_name": a.user.full_name,
                    "phone_number": a.user.phone_number,
                },
                "marked_at": a.marked_at.isoformat(),
                "marked_by_user": {
                    "id": str(a.marked_by_user.id),
                    "full_name": a.marked_by_user.full_name,
                    "phone_number": a.marked_by_user.phone_number,
                } if getattr(a, "marked_by_user", None) else None
            }
            for a in getattr(ev, "attendances", [])
        ]
    }


async def create_event(data: EventCreate, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    # Ensure chapter exists
    chap = (await db.execute(select(Chapter).where(Chapter.id == data.chapter_id))).scalar_one_or_none()
    if not chap:
        raise BadRequestException("Chapter does not exist")

    event = Event(
        chapter_id=data.chapter_id,
        title=data.title,
        description=data.description,
        event_type=data.event_type,
        location=data.location,
        meeting_link=data.meeting_link,
        start_at=data.start_at,
        end_at=data.end_at,
        fee=data.fee,
        max_attendees=data.max_attendees,
        is_published=data.is_published,
    )
    db.add(event)
    await db.flush()

    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event.id)
    fresh_event = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_event(fresh_event)


async def list_events(chapter_id: UUID | None, published_only: bool, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).order_by(Event.start_at.desc())
    
    if chapter_id:
        stmt = stmt.where(Event.chapter_id == chapter_id)
    if published_only:
        stmt = stmt.where(Event.is_published.is_(True))
        
    result = await db.execute(stmt)
    events = result.scalars().all()
    
    return [await _serialize_event(e) for e in events]


async def update_rsvp(event_id: UUID, actor_id: UUID, status: RSVPStatus, db: AsyncSession) -> Dict[str, Any]:
    event = (await db.execute(select(Event).where(Event.id == event_id))).scalar_one_or_none()
    if not event:
        raise NotFoundException("Event not found")
        
    stmt = select(EventRSVP).where(EventRSVP.event_id == event_id, EventRSVP.user_id == actor_id)
    rsvp = (await db.execute(stmt)).scalar_one_or_none()
    
    if rsvp:
        rsvp.status = status
    else:
        rsvp = EventRSVP(
            event_id=event_id,
            user_id=actor_id,
            status=status
        )
        db.add(rsvp)

    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        raise BadRequestException("Could not record RSVP")

    # Fetch fresh object with relations
    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event_id)
    fresh_event = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_event(fresh_event)


async def mark_attendance(event_id: UUID, target_user_id: UUID, actor_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    event = (await db.execute(select(Event).where(Event.id == event_id))).scalar_one_or_none()
    if not event:
        raise NotFoundException("Event not found")

    target = (await db.execute(select(User).where(User.id == target_user_id))).scalar_one_or_none()
    if not target:
        raise NotFoundException("User not found")
        
    # Check if already marked
    stmt = select(EventAttendance).where(
        EventAttendance.event_id == event_id, 
        EventAttendance.user_id == target_user_id
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        raise BadRequestException("Attendance already marked for this user")
        
    attendance = EventAttendance(
        event_id=event_id,
        user_id=target_user_id,
        marked_at=datetime.now(timezone.utc),
        marked_by=actor_id
    )
    db.add(attendance)
    await db.flush()
    
    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event_id)
    fresh_event = (await db.execute(fresh_stmt)).scalar_one()

    return await _serialize_event(fresh_event)
