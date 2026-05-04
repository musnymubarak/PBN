"""
Prime Business Network – Marketplace Models.

Handles member-to-member product and service listings.
"""

from __future__ import annotations

import enum
import uuid
from decimal import Decimal
from typing import List

from sqlalchemy import Boolean, ForeignKey, String, Text, Enum, Numeric, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class ListingCategory(str, enum.Enum):
    PRODUCT = "product"
    SERVICE = "service"
    CONSULTATION = "consultation"


class ListingStatus(str, enum.Enum):
    ACTIVE = "active"
    PAUSED = "paused"
    SOLD_OUT = "sold_out"
    FLAGGED = "flagged"
    REMOVED = "removed"


class MarketplaceListing(Base, TimestampMixin):
    __tablename__ = "marketplace_listings"

    seller_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[ListingCategory] = mapped_column(
        Enum(ListingCategory), default=ListingCategory.PRODUCT, nullable=False, index=True
    )
    industry_category_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("industry_categories.id"), nullable=False, index=True
    )
    
    # Pricing
    regular_price: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    member_price: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    currency: Mapped[str] = mapped_column(String(10), default="LKR")
    price_note: Mapped[str | None] = mapped_column(String(100), nullable=True)
    
    # Media & Display
    image_urls: Mapped[List[str]] = mapped_column(JSONB, default=list, nullable=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[ListingStatus] = mapped_column(
        Enum(ListingStatus), default=ListingStatus.ACTIVE, nullable=False, index=True
    )
    
    # Contact Info
    whatsapp_number: Mapped[str | None] = mapped_column(String(20), nullable=True)
    contact_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(20), nullable=True)

    # Metrics
    view_count: Mapped[int] = mapped_column(default=0, nullable=False)
    interest_count: Mapped[int] = mapped_column(default=0, nullable=False)

    # Relationships
    seller = relationship("User", lazy="joined")
    industry = relationship("IndustryCategory", lazy="joined")
    interests = relationship("MarketplaceInterest", back_populates="listing", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<MarketplaceListing id={self.id} title={self.title}>"


class InterestStatus(str, enum.Enum):
    PENDING = "pending"
    DEAL_CONFIRMED = "deal_confirmed"
    CANCELLED = "cancelled"


class MarketplaceInterest(Base, TimestampMixin):
    __tablename__ = "marketplace_interests"

    listing_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("marketplace_listings.id", ondelete="CASCADE"), nullable=False, index=True
    )
    interested_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[InterestStatus] = mapped_column(
        Enum(InterestStatus), default=InterestStatus.PENDING, nullable=False, index=True
    )
    business_value: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), default=0, nullable=True)

    # Relationships
    listing = relationship("MarketplaceListing", back_populates="interests")
    interested_user = relationship("User", lazy="joined")

    __table_args__ = (
        UniqueConstraint("listing_id", "interested_user_id", name="unique_member_interest"),
    )

    def __repr__(self) -> str:
        return f"<MarketplaceInterest listing={self.listing_id} user={self.interested_user_id}>"
