"""
Prime Business Network – Notifications Schemas.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any, Dict, Literal, Optional

from pydantic import BaseModel, Field


# Alias so router can import either name
class FCMTokenUpdate(BaseModel):
    fcm_token: str = Field(..., min_length=1, max_length=500)
    platform: Literal["ios", "android"] = "android"


# Keep both names available
RegisterDeviceRequest = FCMTokenUpdate


class NotificationResponse(BaseModel):
    id: uuid.UUID
    title: str
    body: str
    notification_type: str
    data: Optional[Dict[str, Any]] = None
    is_read: bool
    sent_at: datetime
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class NotificationsListResponse(BaseModel):
    notifications: list[NotificationResponse]
    total_unread: int


class UnreadCountResponse(BaseModel):
    count: int
