from uuid import UUID
from typing import List, Dict, Any
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.memberships import ChapterMembership
from app.core.exceptions import BadRequestException
from sqlalchemy.orm import selectinload
from app.models.horizontal_clubs import HorizontalClub, HorizontalClubMembership, HorizontalClubIndustry

async def list_clubs(user_id: UUID, db: AsyncSession) -> List[Dict[str, Any]]:
    # Get user's industry IDs from their chapter memberships
    industry_stmt = (
        select(ChapterMembership.industry_category_id)
        .where(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True)
    )
    user_industry_ids = (await db.execute(industry_stmt)).scalars().all()

    # Get all active clubs with their allowed industries
    stmt = select(HorizontalClub).where(HorizontalClub.is_active == True).options(selectinload(HorizontalClub.industries))
    result = await db.execute(stmt)
    clubs = result.scalars().all()
    
    # Get user's memberships
    mem_stmt = select(HorizontalClubMembership.club_id).where(HorizontalClubMembership.user_id == user_id)
    mem_result = await db.execute(mem_stmt)
    my_club_ids = set(mem_result.scalars().all())
    
    output = []
    for club in clubs:
        allowed_industry_ids = [i.id for i in club.industries]
        is_eligible = any(uid in allowed_industry_ids for uid in user_industry_ids)
        
        output.append({
            "id": str(club.id),
            "name": club.name,
            "description": club.description,
            "industries": [i.name for i in club.industries],
            "industry_ids": [str(i.id) for i in club.industries],
            "min_members": club.min_members,
            "is_active": club.is_active,
            "is_member": club.id in my_club_ids,
            "is_eligible": is_eligible
        })
    return output

async def join_club(user_id: UUID, club_id: UUID, db: AsyncSession):
    # 1. Fetch Club Info
    club_stmt = select(HorizontalClub).where(HorizontalClub.id == club_id).options(selectinload(HorizontalClub.industries))
    club = (await db.execute(club_stmt)).scalar_one_or_none()
    if not club:
        raise BadRequestException("Club not found")

    # 2. Check if already a member
    stmt = select(HorizontalClubMembership).where(
        and_(HorizontalClubMembership.user_id == user_id, HorizontalClubMembership.club_id == club_id)
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        return

    # 3. Validate Industry Vertical (Bylaws Art. 6.1)
    industry_stmt = (
        select(ChapterMembership.industry_category_id)
        .where(ChapterMembership.user_id == user_id, ChapterMembership.is_active == True)
    )
    user_industry_ids = (await db.execute(industry_stmt)).scalars().all()
    
    allowed_industry_ids = [i.id for i in club.industries]
    match_found = any(uid in allowed_industry_ids for uid in user_industry_ids)
    
    if not match_found:
        raise BadRequestException(
            f"You cannot join this club. Your business category does not match any of the allowed industries for this club."
        )
        
    membership = HorizontalClubMembership(user_id=user_id, club_id=club_id)
    db.add(membership)
    await db.commit()

async def leave_club(user_id: UUID, club_id: UUID, db: AsyncSession):
    stmt = select(HorizontalClubMembership).where(
        and_(HorizontalClubMembership.user_id == user_id, HorizontalClubMembership.club_id == club_id)
    )
    existing = (await db.execute(stmt)).scalar_one_or_none()
    if existing:
        await db.delete(existing)
        await db.commit()
