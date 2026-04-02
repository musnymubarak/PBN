"""
Prime Business Network – Chapters & Memberships API Service.
"""

from __future__ import annotations

from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.core.exceptions import NotFoundException, BadRequestException
from app.models.businesses import Business
from app.models.chapters import Chapter
from app.models.industry_categories import IndustryCategory
from app.models.memberships import ChapterMembership
from app.models.audit_logs import AuditLog
from app.models.user import User


async def list_active_chapters(db: AsyncSession) -> List[Chapter]:
    stmt = select(Chapter).where(Chapter.is_active.is_(True)).order_by(Chapter.name)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_chapter_members(chapter_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    # Check if chapter exists
    chap_stmt = select(Chapter).where(Chapter.id == chapter_id)
    chap = (await db.execute(chap_stmt)).scalar_one_or_none()
    if not chap:
        raise NotFoundException("Chapter not found")

    # Select Membership, User, Industry, and optionally Business
    stmt = (
        select(ChapterMembership, User, IndustryCategory, Business)
        .join(User, ChapterMembership.user_id == User.id)
        .join(IndustryCategory, ChapterMembership.industry_category_id == IndustryCategory.id)
        .outerjoin(Business, Business.owner_user_id == User.id)
        .where(
            ChapterMembership.chapter_id == chapter_id,
            ChapterMembership.is_active.is_(True)
        )
        .order_by(User.full_name)
    )
    result = await db.execute(stmt)
    rows = result.all()

    members = []
    for mem, user, ind, biz in rows:
        member_data = {
            "user_id": user.id,
            "full_name": user.full_name,
            "email": user.email,
            "phone_number": user.phone_number,
            "membership_type": mem.membership_type,
            "start_date": mem.start_date,
            "end_date": mem.end_date,
            "industry_category": {
                "id": ind.id,
                "name": ind.name,
                "slug": ind.slug,
            },
            "business": {
                "id": biz.id,
                "business_name": biz.business_name,
                "district": biz.district,
                "website": biz.website,
            } if biz else None,
        }
        members.append(member_data)

    return members


async def get_my_memberships(user_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    stmt = (
        select(ChapterMembership, Chapter, IndustryCategory)
        .join(Chapter, ChapterMembership.chapter_id == Chapter.id)
        .join(IndustryCategory, ChapterMembership.industry_category_id == IndustryCategory.id)
        .where(ChapterMembership.user_id == user_id)
        .order_by(ChapterMembership.start_date.desc())
    )
    result = await db.execute(stmt)
    rows = result.all()

    memberships = []
    for mem, chap, ind in rows:
        memberships.append({
            "id": mem.id,
            "membership_type": mem.membership_type.value,
            "start_date": mem.start_date,
            "end_date": mem.end_date,
            "is_active": mem.is_active,
            "chapter": {
                "id": chap.id,
                "name": chap.name,
                "description": chap.description,
                "meeting_schedule": chap.meeting_schedule,
                "is_active": chap.is_active,
            },
            "industry_category": {
                "id": ind.id,
                "name": ind.name,
                "slug": ind.slug,
            },
        })
        
    return memberships


async def remove_member(chapter_id: UUID, user_id: UUID, actor_id: UUID, db: AsyncSession) -> None:
    stmt = select(ChapterMembership).where(
        ChapterMembership.chapter_id == chapter_id,
        ChapterMembership.user_id == user_id
    )
    mem = (await db.execute(stmt)).scalar_one_or_none()
    if not mem:
        raise NotFoundException("Membership not found in this chapter")

    # Hard delete to physically free the slot in the unique constraint
    await db.delete(mem)
    
    audit = AuditLog(
        actor_id=actor_id,
        entity_type="chapter_membership",
        entity_id=mem.id,
        action="delete",
        old_value={"user_id": str(user_id), "chapter_id": str(chapter_id), "industry": str(mem.industry_category_id)},
    )
    db.add(audit)
    
    await db.flush()
