"""
Prime Business Network – Analytics API Schemas.
"""

from __future__ import annotations

from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel


class DashboardReferralsStats(BaseModel):
    sent_total: int
    sent_this_month: int
    received_total: int
    received_this_month: int
    pending_followup: int
    conversion_rate: float


class DashboardROIStats(BaseModel):
    total_value_generated: Decimal
    this_month_value: Decimal
    avg_deal_value: Decimal


class DashboardEventsStats(BaseModel):
    next_event: Optional[dict] = None
    attended_this_year: int


class DashboardMembershipStats(BaseModel):
    status: str
    type: str
    expires_at: Optional[str] = None
    days_until_expiry: Optional[int] = None


class DashboardResponse(BaseModel):
    referrals: DashboardReferralsStats
    roi: DashboardROIStats
    events: DashboardEventsStats
    membership: DashboardMembershipStats
    leaderboard_position: Optional[int]


class LeaderboardEntry(BaseModel):
    user_id: str
    full_name: str
    business_name: Optional[str]
    converted_count: int
    sent_count: int
    actual_value: Decimal
    rank: int


class LeaderboardResponse(BaseModel):
    entries: List[LeaderboardEntry]
    current_user_entry: Optional[LeaderboardEntry]


class ROIMonthlyNode(BaseModel):
    month: str
    sent: int
    received: int
    converted: int
    value: Decimal


class AdminAnalyticsOverview(BaseModel):
    total_members: int
    total_referrals: int
    total_value: Decimal
    conversion_rate: float
    members_by_chapter: List[dict]
    referrals_by_month: List[dict]
    top_performing_chapters: List[dict]
