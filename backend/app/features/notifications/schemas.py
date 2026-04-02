"""
Prime Business Network – Notifications API Schemas.
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class FCMTokenUpdate(BaseModel):
    fcm_token: str


class NotificationBase(BaseModel):
    id: UUID
    title: str
    body: str
    notification_type: str
    data: Optional[dict] = None
    is_read: bool
    sent_at: datetime
    read_at: Optional[datetime] = None


class NotificationsListResponse(BaseModel):
    notifications: list[NotificationBase]
    total_unread: int


class UnreadCountResponse(BaseModel):
    count: int
