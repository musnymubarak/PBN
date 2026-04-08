"""
Prime Business Network – Analytics & Dashboard Service.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import select, func, case, text, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.exceptions import NotFoundException
from app.core.redis import get_redis_client
from app.models.user import User
from app.models.referrals import Referral, ReferralStatus, ReferralStatusHistory
from app.models.chapters import Chapter
from app.models.memberships import ChapterMembership
from app.models.businesses import Business
from app.models.events import Event, EventAttendance, EventRSVP


def _parse_decimal(obj):
    if hasattr(obj, 'quantize'):
        return float(obj)
    raise TypeError(f"Type {type(obj)} not serializable")


async def get_dashboard(user_id: UUID, db: AsyncSession) -> Dict[str, Any]:
    try:
        redis = get_redis_client()  # sync call, no await
        cache_key = f"dashboard:user:{user_id}"
        
        cached = await redis.get(cache_key)
        if cached:
            return json.loads(cached)

        now = datetime.now(timezone.utc)
        first_day_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        first_day_of_year = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)

        # ── Run queries sequentially (asyncpg forbids concurrent ops on one connection) ──

        ref_stmt = select(
            func.count(1).filter(Referral.from_member_id == user_id).label("sent_total"),
            func.count(1).filter((Referral.from_member_id == user_id) & (Referral.created_at >= first_day_of_month)).label("sent_this_month"),
            func.count(1).filter(Referral.to_member_id == user_id).label("received_total"),
            func.count(1).filter((Referral.to_member_id == user_id) & (Referral.created_at >= first_day_of_month)).label("received_this_month"),
            func.count(1).filter((Referral.to_member_id == user_id) & (Referral.status.in_([
                ReferralStatus.SUBMITTED, ReferralStatus.CONTACTED,
                ReferralStatus.NEGOTIATION, ReferralStatus.IN_PROGRESS,
            ]))).label("pending_followup"),
            func.count(1).filter((Referral.from_member_id == user_id) & (Referral.status == ReferralStatus.SUCCESS)).label("sent_won"),
        )
        ref_stats = (await db.execute(ref_stmt)).one()

        roi_stmt = select(
            func.coalesce(func.sum(Referral.actual_value).filter((Referral.from_member_id == user_id) & (Referral.status == ReferralStatus.SUCCESS)), 0).label("total_value"),
            func.coalesce(func.sum(Referral.actual_value).filter((Referral.from_member_id == user_id) & (Referral.status == ReferralStatus.SUCCESS) & (Referral.closed_at >= first_day_of_month)), 0).label("month_value"),
        )
        roi_stats = (await db.execute(roi_stmt)).one()

        mem = (await db.execute(select(ChapterMembership).where(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True))).scalars().first()

        att_stmt = select(func.count(1)).where(EventAttendance.user_id == user_id, EventAttendance.marked_at >= first_day_of_year)
        attended_this_year = (await db.execute(att_stmt)).scalar_one()

        rank_stmt = select(
            Referral.from_member_id.label("user_id"),
            func.rank().over(
                order_by=(
                    func.count(1).filter(Referral.status == ReferralStatus.SUCCESS).desc(),
                    func.count(1).desc()
                )
            ).label("rank")
        ).group_by(Referral.from_member_id).subquery()

        user_rank_stmt = select(rank_stmt.c.rank).where(rank_stmt.c.user_id == user_id)
        leaderboard_position = (await db.execute(user_rank_stmt)).scalar_one_or_none()

        # ── Derived calculations ─────────────────────────────────────────────

        conversion_rate = 0.0
        if ref_stats.sent_total > 0:
            conversion_rate = (ref_stats.sent_won / ref_stats.sent_total) * 100.0

        total_val = float(roi_stats.total_value)
        month_val = float(roi_stats.month_value)
        avg_deal = total_val / ref_stats.sent_won if ref_stats.sent_won > 0 else 0.0

        # ── Sequential: next_event depends on membership ─────────────────────

        next_event = None
        if mem:
            next_event_obj = (await db.execute(
                select(Event).where(Event.chapter_id == mem.chapter_id, Event.is_published == True, Event.start_at >= now)
                .order_by(Event.start_at.asc())
                .limit(1)
            )).scalar_one_or_none()
            
            if next_event_obj:
                next_event = {
                    "id": str(next_event_obj.id),
                    "title": next_event_obj.title,
                    "start_at": next_event_obj.start_at.isoformat()
                }

        # 4. Membership Stats
        membership_data = {
            "status": "Inactive",
            "type": "None",
            "expires_at": None,
            "days_until_expiry": None
        }
        if mem:
            membership_data = {
                "status": "Active" if mem.is_active else "Expired",
                "type": mem.membership_type.value,
                "expires_at": mem.end_date.isoformat() if mem.end_date else None,
                "days_until_expiry": (mem.end_date - now.date()).days if mem.end_date else None
            }

        payload = {
            "referrals": {
                "sent_total": ref_stats.sent_total,
                "sent_this_month": ref_stats.sent_this_month,
                "received_total": ref_stats.received_total,
                "received_this_month": ref_stats.received_this_month,
                "pending_followup": ref_stats.pending_followup,
                "conversion_rate": round(conversion_rate, 2)
            },
            "roi": {
                "total_value_generated": total_val,
                "this_month_value": month_val,
                "avg_deal_value": round(avg_deal, 2)
            },
            "events": {
                "next_event": next_event,
                "attended_this_year": attended_this_year
            },
            "membership": membership_data,
            "leaderboard_position": int(leaderboard_position) if leaderboard_position is not None else None
        }
        
        await redis.setex(cache_key, 600, json.dumps(payload))
        return payload
    except Exception as e:
        print(f"ERROR IN GET_DASHBOARD: {e}")
        import traceback
        traceback.print_exc()
        raise e


async def get_leaderboard(chapter_id: UUID | None, period: str, db: AsyncSession) -> Dict[str, Any]:
    # period: this_month, this_quarter, this_year, all_time
    now = datetime.now(timezone.utc)
    start_date = datetime(1970, 1, 1, tzinfo=timezone.utc)
    
    if period == "this_month":
        start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    elif period == "this_year":
        start_date = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
    elif period == "this_quarter":
        quarter_month = (now.month - 1) // 3 * 3 + 1
        start_date = now.replace(month=quarter_month, day=1, hour=0, minute=0, second=0, microsecond=0)

    # Base query for stats
    base_ref = select(
        Referral.from_member_id.label("uid"),
        func.count(1).filter(Referral.status == ReferralStatus.SUCCESS).label("won_cnt"),
        func.count(1).label("sent_cnt"),
        func.coalesce(func.sum(Referral.actual_value), 0).label("val")
    ).where(Referral.created_at >= start_date)

    if chapter_id:
        # Join members to filter by chapter
        base_ref = base_ref.join(ChapterMembership, ChapterMembership.user_id == Referral.from_member_id)\
                           .where(ChapterMembership.chapter_id == chapter_id)
                           
    stats_subq = base_ref.group_by(Referral.from_member_id).subquery()
    
    # rank over it
    rank_subq = select(
        stats_subq.c.uid,
        stats_subq.c.won_cnt,
        stats_subq.c.sent_cnt,
        stats_subq.c.val,
        func.rank().over(
            order_by=(
                stats_subq.c.won_cnt.desc(),
                stats_subq.c.sent_cnt.desc(),
                stats_subq.c.val.desc()
            )
        ).label("rank_pos")
    ).subquery()

    # Join with User and Business
    final_stmt = select(
        rank_subq.c.uid,
        rank_subq.c.won_cnt,
        rank_subq.c.sent_cnt,
        rank_subq.c.val,
        rank_subq.c.rank_pos,
        User.full_name,
        Business.business_name
    ).join(User, User.id == rank_subq.c.uid)\
     .outerjoin(Business, Business.owner_user_id == User.id)\
     .order_by(rank_subq.c.rank_pos.asc())\
     .limit(10)

    result = await db.execute(final_stmt)
    rows = result.all()
    
    entries = []
    for r in rows:
        entries.append({
            "user_id": str(r.uid),
            "full_name": r.full_name,
            "business_name": r.business_name,
            "converted_count": r.won_cnt,
            "sent_count": r.sent_cnt,
            "actual_value": float(r.val),
            "rank": int(r.rank_pos)
        })

    return {
        "entries": entries,
        "current_user_entry": None # Caller router will populate if needed
    }


async def get_analytics_roi(user_id: UUID, period: str, db: AsyncSession) -> List[Dict[str, Any]]:
    now = datetime.now(timezone.utc)
    months_go_back = 6
    if period == "last_3_months":
        months_go_back = 3
    elif period == "last_year":
        months_go_back = 12
        
    start_date = now - timedelta(days=30 * months_go_back)

    stmt = select(
        func.date_trunc('month', Referral.created_at).label("mnth"),
        func.count(1).label("sent"),
        func.count(1).filter(Referral.status == ReferralStatus.SUCCESS).label("converted"),
        func.coalesce(func.sum(Referral.actual_value), 0).label("val")
    ).where(Referral.from_member_id == user_id, Referral.created_at >= start_date)\
     .group_by(text("mnth")).order_by(text("mnth"))

    res_sent = (await db.execute(stmt)).all()
    
    recv_stmt = select(
        func.date_trunc('month', Referral.created_at).label("mnth"),
        func.count(1).label("received")
    ).where(Referral.to_member_id == user_id, Referral.created_at >= start_date)\
     .group_by(text("mnth")).order_by(text("mnth"))
     
    res_recv = (await db.execute(recv_stmt)).all()
    
    # Merge dicts
    merged = {}
    for r in res_sent:
        m_str = r.mnth.strftime("%Y-%m")
        merged[m_str] = {
            "month": m_str,
            "sent": r.sent,
            "received": 0,
            "converted": r.converted,
            "value": float(r.val)
        }
        
    for r in res_recv:
        m_str = r.mnth.strftime("%Y-%m")
        if m_str not in merged:
            merged[m_str] = {"month": m_str, "sent": 0, "received": 0, "converted": 0, "value": 0.0}
        merged[m_str]["received"] = r.received

    sorted_list = [merged[k] for k in sorted(merged.keys())]
    return sorted_list


async def get_admin_overview(db: AsyncSession) -> Dict[str, Any]:
    from app.models.user import UserRole
    total_members = (await db.execute(select(func.count(1)).where(User.role == UserRole.MEMBER))).scalar_one()
    
    ref_stmt = select(
        func.count(1).label("total_ref"),
        func.count(1).filter(Referral.status == ReferralStatus.SUCCESS).label("won_ref"),
        func.coalesce(func.sum(Referral.actual_value), 0).label("tot_val")
    )
    ref_stats = (await db.execute(ref_stmt)).one()
    
    conversion_rate = 0.0
    if ref_stats.total_ref > 0:
        conversion_rate = (ref_stats.won_ref / ref_stats.total_ref) * 100.0

    chap_stmt = select(
        Chapter.name,
        func.count(ChapterMembership.id).label("members")
    ).outerjoin(ChapterMembership, ChapterMembership.chapter_id == Chapter.id)\
     .group_by(Chapter.id, Chapter.name)
     
    members_by_chapter = [{"chapter": r.name, "count": r.members} for r in (await db.execute(chap_stmt)).all()]

    return {
        "total_members": total_members,
        "total_referrals": ref_stats.total_ref,
        "total_value": float(ref_stats.tot_val),
        "conversion_rate": round(conversion_rate, 2),
        "members_by_chapter": members_by_chapter,
        "referrals_by_month": [],  # Stub
        "top_performing_chapters": [] # Stub
    }
