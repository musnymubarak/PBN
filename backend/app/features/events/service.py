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
import logging

logger = logging.getLogger(__name__)

from app.core.exceptions import BadRequestException, NotFoundException, ForbiddenException
from app.features.notifications.service import send_push_notification, notify_multiple_users
from app.features.events.schemas import EventCreate, EventRSVPRequest, EventAttendanceRequest
from app.models.events import Event, EventRSVP, EventAttendance, RSVPStatus
from app.models.chapters import Chapter
from app.models.memberships import ChapterMembership
from app.models.user import User, UserRole


async def _serialize_event(ev: Event) -> Dict[str, Any]:
    try:
        return {
            "id": str(ev.id),
            "chapter_id": str(ev.chapter_id),
            "title": ev.title,
            "description": ev.description,
            "event_type": ev.event_type.value if ev.event_type else None,
            "location": ev.location,
            "meeting_link": ev.meeting_link,
            "start_at": ev.start_at.isoformat() if ev.start_at else None,
            "end_at": ev.end_at.isoformat() if ev.end_at else None,
            "fee": float(ev.fee) if ev.fee is not None else 0.0,
            "max_attendees": ev.max_attendees,
            "is_published": ev.is_published,
            "is_active": ev.is_active,
            "image_url": ev.image_url,
            "created_at": ev.created_at.isoformat() if ev.created_at else None,
            "rsvps": [
                {
                    "user": {
                        "id": str(r.user.id),
                        "full_name": r.user.full_name,
                        "phone_number": r.user.phone_number,
                    },
                    "status": r.status.value if r.status else None,
                    "created_at": r.created_at.isoformat() if r.created_at else None
                }
                for r in getattr(ev, "rsvps", [])
                if r.user is not None # Critical safety check
            ],
            "attendances": [
                {
                    "user": {
                        "id": str(a.user.id),
                        "full_name": a.user.full_name,
                        "phone_number": a.user.phone_number,
                    },
                    "marked_at": a.marked_at.isoformat() if a.marked_at else None,
                    "marked_by_user": {
                        "id": str(a.marked_by_user.id),
                        "full_name": a.marked_by_user.full_name,
                        "phone_number": a.marked_by_user.phone_number,
                    } if getattr(a, "marked_by_user", None) else None
                }
                for a in getattr(ev, "attendances", [])
                if a.user is not None # Critical safety check
            ]
        }
    except Exception as e:
        logger.error(f"Failed to serialize event {ev.id}: {str(e)}")
        raise


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
        image_url=data.image_url,
    )
    db.add(event)
    await db.flush()

    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event.id)
    fresh_event = (await db.execute(fresh_stmt)).scalar_one()

    # 1. Notify Members if published
    if data.is_published:
        try:
            await _notify_chapter_members(
                data.chapter_id,
                f"📅 New Meeting: {data.title}",
                f"A new meeting has been scheduled for {data.start_at.strftime('%b %d at %I:%M %p')}. Register now!",
                db,
                {"event_id": str(event.id), "route": "/events"}
            )
        except Exception: pass

    return await _serialize_event(fresh_event)


async def _notify_chapter_members(chapter_id: UUID, title: str, body: str, db: AsyncSession, data: Dict[str, str] | None = None):
    """Internal helper to notify all active members of a chapter."""
    stmt = select(User.id).join(ChapterMembership).where(
        ChapterMembership.chapter_id == chapter_id,
        User.is_active == True
    )
    user_ids = (await db.execute(stmt)).scalars().all()
    if user_ids:
        from fastapi import BackgroundTasks
        # We don't have BackgroundTasks here easily, so we just call it. 
        # In a real app, this should be a background task.
        await notify_multiple_users(user_ids, title, body, "CHAPTER_BROADCAST", data)


async def _notify_chapter_admins(chapter_id: UUID, title: str, body: str, db: AsyncSession, data: Dict[str, str] | None = None):
    """Internal helper to notify chapter admins of a specific chapter."""
    stmt = select(User.id).join(ChapterMembership).where(
        ChapterMembership.chapter_id == chapter_id,
        User.role == UserRole.CHAPTER_ADMIN,
        User.is_active == True
    )
    admin_ids = (await db.execute(stmt)).scalars().all()
    if admin_ids:
        await notify_multiple_users(admin_ids, title, body, "ADMIN_ALERT", data)


async def update_event(event_id: UUID, data: Dict[str, Any], db: AsyncSession) -> Dict[str, Any]:
    event = (await db.execute(select(Event).where(Event.id == event_id))).scalar_one_or_none()
    if not event:
        raise NotFoundException("Event not found")

    for key, value in data.items():
        if hasattr(event, key):
            setattr(event, key, value)
    
    await db.flush()

    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event_id)
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
    
    serialized = []
    for e in events:
        try:
            serialized.append(await _serialize_event(e))
        except Exception:
            # Skip corrupted event records so the whole list doesn't fail
            logger.warning(f"Skipping corrupted event record {e.id}")
            continue
            
    return serialized


async def update_rsvp(event_id: UUID, actor_id: UUID, status: RSVPStatus, db: AsyncSession) -> Dict[str, Any]:
    # Fetch actor to check role
    actor = (await db.execute(select(User).where(User.id == actor_id))).scalar_one()
    
    event = (await db.execute(select(Event).where(Event.id == event_id))).scalar_one_or_none()
    if not event:
        raise NotFoundException("Event not found")
        
    # LOGIC: If a MEMBER/PROSPECT selects GOING, set to REQUESTED
    if actor.role in [UserRole.MEMBER, UserRole.PROSPECT] and status == RSVPStatus.GOING:
        status = RSVPStatus.REQUESTED
        
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

    # Notify Admin if requested
    if status == RSVPStatus.REQUESTED:
        try:
            await _notify_chapter_admins(
                event.chapter_id,
                "🔔 New RSVP Request",
                f"{actor.full_name} has requested a spot for '{event.title}'.",
                db,
                {"event_id": str(event.id), "route": "/events"} # Route to admin manage? 
            )
        except Exception: pass

    return await _serialize_event(fresh_event)


async def approve_rsvp(event_id: UUID, target_user_id: UUID, status: RSVPStatus, db: AsyncSession) -> Dict[str, Any]:
    stmt = select(EventRSVP).where(EventRSVP.event_id == event_id, EventRSVP.user_id == target_user_id)
    rsvp = (await db.execute(stmt)).scalar_one_or_none()
    
    if not rsvp:
        raise NotFoundException("RSVP request not found")
        
    rsvp.status = status # Admin can set to GOING or NOT_GOING
    await db.flush()
    
    # Fetch fresh object with relations
    fresh_stmt = select(Event).options(
        selectinload(Event.rsvps).joinedload(EventRSVP.user),
        selectinload(Event.attendances).joinedload(EventAttendance.user),
        selectinload(Event.attendances).joinedload(EventAttendance.marked_by_user),
    ).where(Event.id == event_id)
    fresh_event = (await db.execute(fresh_stmt)).scalar_one()

    # Notify User
    try:
        title = "✅ Registration Confirmed" if status == RSVPStatus.GOING else "❌ Registration Update"
        body = f"Your spot for '{fresh_event.title}' has been confirmed!" if status == RSVPStatus.GOING else f"Your request for '{fresh_event.title}' was updated to {status.value}."
        
        await send_push_notification(
            user_id=target_user_id,
            title=title,
            body=body,
            notification_type="RSVP_UPDATE",
            data={"event_id": str(event_id), "route": "/events"}
        )
    except Exception: pass

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
