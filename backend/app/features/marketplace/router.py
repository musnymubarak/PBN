"""
Prime Business Network – Marketplace API Router.
"""

from __future__ import annotations

import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, Query, status, Request, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_db
from app.features.auth.dependencies import get_current_user, require_role
from app.features.marketplace import service
from app.features.marketplace.schemas import (
    MarketplaceListingCreate,
    MarketplaceListingRead,
    MarketplaceListingUpdate,
    MarketplaceInterestCreate,
    MarketplaceInterestRead,
    MarketplaceInterestUpdate
)
from app.models.user import User, UserRole
from app.models.marketplace import ListingCategory

router = APIRouter(tags=["Marketplace"])


@router.post("/listings", response_model=MarketplaceListingRead, status_code=status.HTTP_201_CREATED)
async def create_listing_endpoint(
    data: MarketplaceListingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    listing = await service.create_listing(current_user.id, data, db)
    # Map additional fields for response
    listing.seller_name = current_user.full_name
    return listing


@router.post("/listings/upload", summary="Upload marketplace listing image")
async def upload_listing_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
) -> ORJSONResponse:
    """Upload a product/service image for a listing."""
    import os
    import shutil
    import uuid
    from app.core.response import success_response
    from app.core.exceptions import BadRequestException

    # Validation
    MAX_SIZE = 5 * 1024 * 1024
    if file.size and file.size > MAX_SIZE:
        raise BadRequestException(message="File too large (max 5MB)", code="FILE_TOO_LARGE")

    ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp"]
    if file.content_type not in ALLOWED_TYPES:
        raise BadRequestException(message="Invalid format. Use JPG, PNG or WebP.", code="INVALID_FORMAT")

    os.makedirs("uploads/marketplace", exist_ok=True)
    ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    filename = f"market_{uuid.uuid4().hex[:12]}.{ext}"
    file_path = f"uploads/marketplace/{filename}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return success_response(data={"image_url": f"/static/marketplace/{filename}"})


@router.get("/listings", response_model=List[MarketplaceListingRead])
async def list_listings_endpoint(
    request: Request,
    category: Optional[ListingCategory] = None,
    industry_id: Optional[uuid.UUID] = None,
    search: Optional[str] = None,
    featured_only: bool = False,
    seller_id: Optional[uuid.UUID] = None,
    my: bool = False,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db)
):
    if my:
        # Require user for 'my' listings
        auth_header = request.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            from app.core.exceptions import UnauthorizedException
            raise UnauthorizedException(message="You must be logged in to see your listings.")
        
        current_user = await get_current_user(request, db)
        seller_id = current_user.id
        
    listings = await service.list_listings(
        db, category, industry_id, search, featured_only, seller_id, limit, offset
    )
    # Map names for response
    for l in listings:
        l.seller_name = l.seller.full_name
        l.industry_name = l.industry.name
    return listings


@router.get("/listings/{listing_id}", response_model=MarketplaceListingRead)
async def get_listing_endpoint(
    listing_id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    listing = await service.get_listing(listing_id, db, increment_view=True)
    listing.seller_name = listing.seller.full_name
    listing.industry_name = listing.industry.name
    return listing


@router.patch("/listings/{listing_id}", response_model=MarketplaceListingRead)
async def update_listing_endpoint(
    listing_id: uuid.UUID,
    data: MarketplaceListingUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    listing = await service.update_listing(current_user.id, listing_id, data, current_user.role, db)
    listing.seller_name = listing.seller.full_name
    listing.industry_name = listing.industry.name
    return listing


@router.post("/listings/{listing_id}/interest", response_model=MarketplaceInterestRead)
async def express_interest_endpoint(
    listing_id: uuid.UUID,
    data: MarketplaceInterestCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    interest = await service.record_interest(current_user.id, listing_id, data.message, db)
    interest.interested_user_name = current_user.full_name
    return interest


@router.get("/listings/{listing_id}/interests", response_model=List[MarketplaceInterestRead])
async def get_interests_endpoint(
    listing_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    interests = await service.get_listing_interests(listing_id, current_user.id, db)
    for i in interests:
        i.interested_user_name = i.interested_user.full_name
    return interests


@router.patch("/interests/{interest_id}", response_model=MarketplaceInterestRead)
async def update_interest_endpoint(
    interest_id: uuid.UUID,
    data: MarketplaceInterestUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    interest = await service.update_interest(current_user.id, interest_id, data, db)
    interest.interested_user_name = interest.interested_user.full_name
    return interest


@router.post("/listings/{listing_id}/feature", response_model=bool, dependencies=[Depends(require_role([UserRole.SUPER_ADMIN, UserRole.CHAPTER_ADMIN]))])
async def toggle_feature_endpoint(
    listing_id: uuid.UUID,
    db: AsyncSession = Depends(get_db)
):
    return await service.toggle_featured(listing_id, db)


@router.delete("/listings/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_listing_endpoint(
    listing_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    await service.delete_listing(current_user.id, listing_id, current_user.role, db)
    return None
