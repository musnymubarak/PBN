"""
Prime Business Network – Marketplace Schemas.
"""

from __future__ import annotations

import uuid
from decimal import Decimal
from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, HttpUrl

from app.models.marketplace import ListingCategory, ListingStatus


class MarketplaceListingBase(BaseModel):
    title: str = Field(..., min_length=3, max_length=255)
    description: str = Field(..., min_length=10)
    category: ListingCategory
    industry_category_id: uuid.UUID
    
    regular_price: Optional[Decimal] = None
    member_price: Optional[Decimal] = None
    currency: str = "LKR"
    price_note: Optional[str] = None
    
    image_urls: List[str] = []
    whatsapp_number: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None


class MarketplaceListingCreate(MarketplaceListingBase):
    pass


class MarketplaceListingUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    category: Optional[ListingCategory] = None
    industry_category_id: Optional[uuid.UUID] = None
    
    regular_price: Optional[Decimal] = None
    member_price: Optional[Decimal] = None
    currency: Optional[str] = None
    price_note: Optional[str] = None
    
    image_urls: Optional[List[str]] = None
    whatsapp_number: Optional[str] = None
    contact_email: Optional[str] = None
    contact_phone: Optional[str] = None
    status: Optional[ListingStatus] = None


class MarketplaceListingRead(MarketplaceListingBase):
    id: uuid.UUID
    seller_id: uuid.UUID
    status: ListingStatus
    is_featured: bool
    view_count: int
    interest_count: int
    created_at: datetime
    updated_at: datetime
    
    seller_name: Optional[str] = None
    industry_name: Optional[str] = None

    class Config:
        from_attributes = True


class MarketplaceInterestCreate(BaseModel):
    message: Optional[str] = None


class MarketplaceInterestUpdate(BaseModel):
    status: Optional[str] = None
    business_value: Optional[Decimal] = None
    is_read: Optional[bool] = None


class MarketplaceInterestRead(BaseModel):
    id: uuid.UUID
    listing_id: uuid.UUID
    interested_user_id: uuid.UUID
    interested_user_name: str
    message: Optional[str] = None
    is_read: bool
    status: str
    business_value: Optional[Decimal] = None
    created_at: datetime

    class Config:
        from_attributes = True
