"""
Prime Business Network – Events API Schemas.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.models.events import EventType, RSVPStatus


class UserSimple(BaseModel):
    id: UUID
    full_name: str
    phone_number: str


class EventCreate(BaseModel):
    chapter_id: UUID
    title: str
    description: Optional[str] = None
    event_type: EventType
    location: Optional[str] = None
    meeting_link: Optional[str] = None
    start_at: datetime
    end_at: datetime
    fee: Decimal = Decimal(0)
    max_attendees: Optional[int] = None
    is_published: bool = True
    image_url: Optional[str] = None


class EventRSVPRequest(BaseModel):
    status: RSVPStatus


class EventRSVPApproval(BaseModel):
    user_id: UUID
    status: RSVPStatus


class EventAttendanceRequest(BaseModel):
    user_id: UUID


class EventRSVPResponse(BaseModel):
    user: UserSimple
    status: str
    created_at: datetime


class EventAttendanceResponse(BaseModel):
    user: UserSimple
    marked_at: datetime
    marked_by_user: Optional[UserSimple]


class EventResponse(BaseModel):
    id: str
    chapter_id: str
    title: str
    description: Optional[str]
    event_type: str
    location: Optional[str]
    meeting_link: Optional[str]
    start_at: str
    end_at: str
    fee: Decimal
    max_attendees: Optional[int]
    is_published: bool
    is_active: bool
    image_url: Optional[str]
    created_at: str
    
    rsvps: Optional[List[EventRSVPResponse]] = []
    attendances: Optional[List[EventAttendanceResponse]] = []


class EventUpdate(BaseModel):
    chapter_id: Optional[UUID] = None
    title: Optional[str] = None
    description: Optional[str] = None
    event_type: Optional[EventType] = None
    location: Optional[str] = None
    meeting_link: Optional[str] = None
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    fee: Optional[Decimal] = None
    max_attendees: Optional[int] = None
    is_published: Optional[bool] = None
    image_url: Optional[str] = None
