"""
Prime Business Network – Marketplace Service.
"""

from __future__ import annotations

import uuid
from typing import Any, Dict, List, Optional
from decimal import Decimal

from sqlalchemy import desc, func, select, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.core.exceptions import NotFoundException, ForbiddenException
from app.models.marketplace import MarketplaceListing, MarketplaceInterest, ListingStatus, ListingCategory
from app.models.industry_categories import IndustryCategory
from app.models.user import User, UserRole
from app.features.marketplace.schemas import MarketplaceListingCreate, MarketplaceListingUpdate


async def create_listing(user_id: uuid.UUID, data: MarketplaceListingCreate, db: AsyncSession) -> MarketplaceListing:
    listing = MarketplaceListing(
        seller_id=user_id,
        title=data.title,
        description=data.description,
        category=data.category,
        industry_category_id=data.industry_category_id,
        regular_price=data.regular_price,
        member_price=data.member_price,
        currency=data.currency,
        price_note=data.price_note,
        image_urls=data.image_urls,
        whatsapp_number=data.whatsapp_number,
        contact_email=data.contact_email,
        contact_phone=data.contact_phone,
        status=ListingStatus.ACTIVE,
        is_approved=False
    )
    db.add(listing)
    await db.commit()
    await db.refresh(listing)
    return listing


async def list_listings(
    db: AsyncSession,
    category: Optional[ListingCategory] = None,
    industry_id: Optional[uuid.UUID] = None,
    search: Optional[str] = None,
    featured_only: bool = False,
    seller_id: Optional[uuid.UUID] = None,
    limit: int = 20,
    offset: int = 0,
    approved_only: bool = True
) -> List[MarketplaceListing]:
    stmt = select(MarketplaceListing).options(
        joinedload(MarketplaceListing.seller),
        joinedload(MarketplaceListing.industry)
    ).where(MarketplaceListing.status == ListingStatus.ACTIVE)
    
    if approved_only:
        stmt = stmt.where(MarketplaceListing.is_approved == True)
    
    if category:
        stmt = stmt.where(MarketplaceListing.category == category)
    if industry_id:
        stmt = stmt.where(MarketplaceListing.industry_category_id == industry_id)
    if seller_id:
        stmt = stmt.where(MarketplaceListing.seller_id == seller_id)
    if featured_only:
        stmt = stmt.where(MarketplaceListing.is_featured == True)
        
    if search:
        pattern = f"%{search}%"
        stmt = stmt.where(or_(
            MarketplaceListing.title.ilike(pattern),
            MarketplaceListing.description.ilike(pattern)
        ))
        
    # Order: Featured first, then newest
    stmt = stmt.order_by(desc(MarketplaceListing.is_featured), desc(MarketplaceListing.created_at))
    stmt = stmt.limit(limit).offset(offset)
    
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_listing(listing_id: uuid.UUID, db: AsyncSession, increment_view: bool = False) -> MarketplaceListing:
    stmt = select(MarketplaceListing).options(
        joinedload(MarketplaceListing.seller),
        joinedload(MarketplaceListing.industry)
    ).where(MarketplaceListing.id == listing_id)
    
    listing = (await db.execute(stmt)).scalar_one_or_none()
    if not listing:
        raise NotFoundException("Listing not found")
        
    if increment_view:
        listing.view_count += 1
        await db.commit()
        
    return listing


async def update_listing(
    user_id: uuid.UUID, 
    listing_id: uuid.UUID, 
    data: MarketplaceListingUpdate, 
    role: UserRole,
    db: AsyncSession
) -> MarketplaceListing:
    listing = await get_listing(listing_id, db)
    
    # Permission check: Owner or Admin
    if listing.seller_id != user_id and role not in [UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]:
        raise ForbiddenException("You cannot edit this listing")
        
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(listing, key, value)
        
    await db.commit()
    await db.refresh(listing)
    return listing


async def toggle_featured(listing_id: uuid.UUID, db: AsyncSession) -> bool:
    listing = await get_listing(listing_id, db)
    listing.is_featured = not listing.is_featured
    await db.commit()
    return listing.is_featured


async def record_interest(user_id: uuid.UUID, listing_id: uuid.UUID, message: Optional[str], db: AsyncSession) -> MarketplaceInterest:
    listing = await get_listing(listing_id, db)
    
    if listing.seller_id == user_id:
        raise ForbiddenException("You cannot express interest in your own listing")
        
    # Check if already expressed interest
    interest_stmt = select(MarketplaceInterest).where(
        MarketplaceInterest.listing_id == listing_id,
        MarketplaceInterest.interested_user_id == user_id
    )
    existing = (await db.execute(interest_stmt)).scalar_one_or_none()
    if existing:
        return existing
        
    interest = MarketplaceInterest(
        listing_id=listing_id,
        interested_user_id=user_id,
        message=message
    )
    db.add(interest)
    
    # Increment listing counter
    listing.interest_count += 1
    
    await db.commit()
    await db.refresh(interest)
    
    # Send Notification to Seller
    from app.features.notifications.service import send_push_notification
    try:
        interested_user_name = (await db.execute(select(User.full_name).where(User.id == user_id))).scalar()
        await send_push_notification(
            user_id=listing.seller_id,
            title="Marketplace Interest! 🏪",
            body=f"{interested_user_name} is interested in your listing: {listing.title}",
            notification_type="MARKETPLACE_INTEREST",
            data={"listing_id": str(listing.id), "route": "/marketplace/my-listings"}
        )
    except Exception:
        pass
        
    return interest


async def update_interest(
    user_id: uuid.UUID,
    interest_id: uuid.UUID,
    data: MarketplaceInterestUpdate,
    db: AsyncSession
) -> MarketplaceInterest:
    from app.models.marketplace import InterestStatus
    
    stmt = select(MarketplaceInterest).options(
        joinedload(MarketplaceInterest.listing)
    ).where(MarketplaceInterest.id == interest_id)
    
    interest = (await db.execute(stmt)).scalar_one_or_none()
    if not interest:
        raise NotFoundException("Interest not found")
        
    # Permission: Only the seller of the listing can update the status/value
    if interest.listing.seller_id != user_id:
        raise ForbiddenException("Only the seller can update interest status")
        
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if key == "status":
            setattr(interest, key, InterestStatus(value))
        else:
            setattr(interest, key, value)
            
    await db.commit()
    await db.refresh(interest)
    return interest


async def get_listing_interests(listing_id: uuid.UUID, user_id: uuid.UUID, db: AsyncSession) -> List[MarketplaceInterest]:
    listing = await get_listing(listing_id, db)
    if listing.seller_id != user_id:
        raise ForbiddenException("Only the seller can view interests")
        
    stmt = select(MarketplaceInterest).options(
        joinedload(MarketplaceInterest.interested_user)
    ).where(MarketplaceInterest.listing_id == listing_id).order_by(desc(MarketplaceInterest.created_at))
    
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def delete_listing(user_id: uuid.UUID, listing_id: uuid.UUID, role: UserRole, db: AsyncSession) -> None:
    listing = await get_listing(listing_id, db)

    # Permission check: Owner or Admin
    if listing.seller_id != user_id and role not in [UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]:
        raise ForbiddenException("You cannot delete this listing")

    await db.delete(listing)
    await db.commit()
