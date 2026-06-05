"""
Prime Business Network – Admin Community & Leads service.

Network-wide (cross-chapter) read/aggregation helpers for the admin panel's
Community & Leads dashboard. Unlike the member-facing community service
(app/features/community/service.py) these functions are NOT scoped to the
caller's own chapter; an optional ``chapter_id`` filter is provided so that a
CHAPTER_ADMIN can be transparently scoped to their own chapter by the router.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from sqlalchemy import desc, func, select, or_, cast, Date
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.community import (
    CommunityPost,
    PostLike,
    PostComment,
    PostType,
    LeadStatus,
)
from app.models.chapters import Chapter
from app.models.user import User


# ── Serialization ────────────────────────────────────────────────────────────

def _serialize_admin_post(post: CommunityPost, chapter_name: Optional[str] = None) -> Dict[str, Any]:
    """Lightweight serializer for admin tables. Eager-load author/targets.

    ``CommunityPost`` has no ``chapter`` relationship (only ``chapter_id``), so the
    chapter name is resolved by the caller and passed in.
    """
    return {
        "id": str(post.id),
        "content": post.content,
        "image_url": post.image_url,
        "is_pinned": post.is_pinned,
        "created_at": post.created_at.isoformat(),
        "chapter_id": str(post.chapter_id),
        "chapter_name": chapter_name,
        "author": {
            "id": str(post.author.id),
            "full_name": post.author.full_name,
            "profile_photo": post.author.profile_photo,
            "role": post.author.role.value,
        } if post.author else None,
        "post_type": post.post_type.value,
        "visibility": post.visibility.value,
        "lead_status": post.lead_status.value if post.lead_status else None,
        "budget_range": post.budget_range,
        "deadline": post.deadline.isoformat() if post.deadline else None,
        "business_value": float(post.business_value) if post.business_value else None,
        "target_industry_name": post.target_industry.name if post.target_industry else None,
        "target_club_name": post.target_club.name if post.target_club else None,
    }


# ── Stats / KPIs ─────────────────────────────────────────────────────────────

async def get_community_stats(
    db: AsyncSession,
    chapter_id: Optional[uuid.UUID] = None,
    days: int = 30,
) -> Dict[str, Any]:
    """Network-wide KPIs plus a daily TYFB timeseries for the given window."""
    since = datetime.now(timezone.utc) - timedelta(days=days)

    def _scope(stmt):
        if chapter_id is not None:
            stmt = stmt.where(CommunityPost.chapter_id == chapter_id)
        return stmt

    # Post-type counts (all-time)
    type_counts_stmt = _scope(
        select(CommunityPost.post_type, func.count(CommunityPost.id))
        .where(CommunityPost.is_active == True)
        .group_by(CommunityPost.post_type)
    )
    type_rows = (await db.execute(type_counts_stmt)).all()
    counts_by_type = {pt.value: n for pt, n in type_rows}
    total_posts = sum(counts_by_type.values())
    total_leads = counts_by_type.get(PostType.LEAD.value, 0)
    total_rfps = counts_by_type.get(PostType.RFP.value, 0)

    # Lead-status counts (LEAD + RFP only)
    status_counts_stmt = _scope(
        select(CommunityPost.lead_status, func.count(CommunityPost.id))
        .where(CommunityPost.lead_status.is_not(None))
        .group_by(CommunityPost.lead_status)
    )
    status_rows = (await db.execute(status_counts_stmt)).all()
    counts_by_status = {ls.value: n for ls, n in status_rows}
    open_leads = counts_by_status.get(LeadStatus.OPEN.value, 0)
    in_progress = counts_by_status.get(LeadStatus.IN_PROGRESS.value, 0)
    closed_won = counts_by_status.get(LeadStatus.CLOSED_WON.value, 0)
    closed_lost = counts_by_status.get(LeadStatus.CLOSED_LOST.value, 0)
    decided = closed_won + closed_lost
    win_rate = round((closed_won / decided) * 100, 1) if decided else 0.0

    # TYFB value (all-time, closed-won deals)
    tyfb_stmt = _scope(
        select(
            func.coalesce(func.sum(CommunityPost.business_value), 0),
            func.count(CommunityPost.id),
        ).where(CommunityPost.business_value.is_not(None))
    )
    total_tyfb_value, deals_with_value = (await db.execute(tyfb_stmt)).one()
    total_tyfb_value = float(total_tyfb_value or 0)
    avg_deal_size = round(total_tyfb_value / deals_with_value, 2) if deals_with_value else 0.0

    # Engagement counts (all-time)
    likes_stmt = select(func.count(PostLike.id))
    comments_stmt = select(func.count(PostComment.id))
    if chapter_id is not None:
        likes_stmt = likes_stmt.join(CommunityPost, PostLike.post_id == CommunityPost.id).where(
            CommunityPost.chapter_id == chapter_id
        )
        comments_stmt = comments_stmt.join(CommunityPost, PostComment.post_id == CommunityPost.id).where(
            CommunityPost.chapter_id == chapter_id
        )
    total_likes = (await db.execute(likes_stmt)).scalar_one()
    total_comments = (await db.execute(comments_stmt)).scalar_one()

    # TYFB timeseries: daily sum of business_value within the window
    ts_stmt = _scope(
        select(
            cast(CommunityPost.created_at, Date).label("day"),
            func.coalesce(func.sum(CommunityPost.business_value), 0),
        )
        .where(
            CommunityPost.business_value.is_not(None),
            CommunityPost.created_at >= since,
        )
        .group_by("day")
        .order_by("day")
    )
    ts_rows = (await db.execute(ts_stmt)).all()
    tyfb_timeseries = [{"date": day.isoformat(), "value": float(val)} for day, val in ts_rows]

    return {
        "total_posts": total_posts,
        "total_leads": total_leads,
        "total_rfps": total_rfps,
        "open_leads": open_leads,
        "in_progress_leads": in_progress,
        "closed_won": closed_won,
        "closed_lost": closed_lost,
        "win_rate": win_rate,
        "total_tyfb_value": total_tyfb_value,
        "avg_deal_size": avg_deal_size,
        "total_likes": total_likes,
        "total_comments": total_comments,
        "tyfb_timeseries": tyfb_timeseries,
        "window_days": days,
    }


# ── Listings ─────────────────────────────────────────────────────────────────

def _base_post_query():
    return select(CommunityPost).options(
        joinedload(CommunityPost.author),
        joinedload(CommunityPost.target_industry),
        joinedload(CommunityPost.target_club),
    )


async def _chapter_name_map(db: AsyncSession, posts: List[CommunityPost]) -> Dict[uuid.UUID, str]:
    """Resolve chapter names for a set of posts in a single query."""
    chapter_ids = {p.chapter_id for p in posts if p.chapter_id}
    if not chapter_ids:
        return {}
    rows = (await db.execute(
        select(Chapter.id, Chapter.name).where(Chapter.id.in_(chapter_ids))
    )).all()
    return {cid: name for cid, name in rows}


async def _paginate(db: AsyncSession, stmt, count_stmt, page: int, page_size: int) -> Dict[str, Any]:
    total = (await db.execute(count_stmt)).scalar_one()
    stmt = stmt.order_by(desc(CommunityPost.created_at)).limit(page_size).offset((page - 1) * page_size)
    posts = (await db.execute(stmt)).scalars().all()
    chapter_names = await _chapter_name_map(db, posts)
    return {
        "items": [_serialize_admin_post(p, chapter_names.get(p.chapter_id)) for p in posts],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


async def list_leads(
    db: AsyncSession,
    chapter_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    post_type: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
) -> Dict[str, Any]:
    """Cross-chapter LEAD/RFP pipeline."""
    stmt = _base_post_query().join(CommunityPost.author).where(
        CommunityPost.post_type.in_([PostType.LEAD, PostType.RFP])
    )

    if chapter_id is not None:
        stmt = stmt.where(CommunityPost.chapter_id == chapter_id)
    if status:
        stmt = stmt.where(CommunityPost.lead_status == LeadStatus(status))
    if post_type:
        stmt = stmt.where(CommunityPost.post_type == PostType(post_type))
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(or_(CommunityPost.content.ilike(pattern), User.full_name.ilike(pattern)))

    count_stmt = select(func.count()).select_from(stmt.order_by(None).subquery())
    result = await _paginate(db, stmt, count_stmt, page, page_size)
    return {"leads": result["items"], "total": result["total"], "page": page, "page_size": page_size}


async def list_all_posts(
    db: AsyncSession,
    chapter_id: Optional[uuid.UUID] = None,
    post_type: Optional[str] = None,
    search: Optional[str] = None,
    page: int = 1,
    page_size: int = 20,
) -> Dict[str, Any]:
    """Cross-chapter full feed for moderation (all post types, active only)."""
    stmt = _base_post_query().join(CommunityPost.author).where(CommunityPost.is_active == True)

    if chapter_id is not None:
        stmt = stmt.where(CommunityPost.chapter_id == chapter_id)
    if post_type:
        stmt = stmt.where(CommunityPost.post_type == PostType(post_type))
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(or_(CommunityPost.content.ilike(pattern), User.full_name.ilike(pattern)))

    count_stmt = select(func.count()).select_from(stmt.order_by(None).subquery())
    result = await _paginate(db, stmt, count_stmt, page, page_size)
    return {"posts": result["items"], "total": result["total"], "page": page, "page_size": page_size}


async def get_post_detail(db: AsyncSession, post_id: uuid.UUID) -> Optional[Dict[str, Any]]:
    """Single post with its comments, for the moderation detail modal."""
    stmt = _base_post_query().where(CommunityPost.id == post_id)
    post = (await db.execute(stmt)).scalar_one_or_none()
    if not post:
        return None

    chapter_names = await _chapter_name_map(db, [post])
    data = _serialize_admin_post(post, chapter_names.get(post.chapter_id))

    comments_stmt = (
        select(PostComment)
        .where(PostComment.post_id == post_id)
        .order_by(PostComment.created_at.asc())
        .options(joinedload(PostComment.author))
    )
    comments = (await db.execute(comments_stmt)).scalars().all()
    data["comments"] = [
        {
            "id": str(c.id),
            "content": c.content,
            "created_at": c.created_at.isoformat(),
            "author": {
                "id": str(c.author.id),
                "full_name": c.author.full_name,
                "profile_photo": c.author.profile_photo,
                "role": c.author.role.value,
            } if c.author else None,
        }
        for c in comments
    ]
    return data
