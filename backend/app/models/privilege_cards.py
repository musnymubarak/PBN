"""
Prime Business Network – Privilege Card, Partner, Offer & Redemption Models.
"""

from __future__ import annotations

import enum
import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column
import sqlalchemy.orm

from app.models.base import Base, TimestampMixin


class PrivilegeCard(Base, TimestampMixin):
    __tablename__ = "privilege_cards"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    card_number: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    qr_code_data: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    issued_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped["User"] = sqlalchemy.orm.relationship("User")

    def __repr__(self) -> str:
        return f"<PrivilegeCard {self.card_number}>"


class Partner(Base, TimestampMixin):
    __tablename__ = "partners"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    logo_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    website: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    admin_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )

    admin: Mapped["User | None"] = sqlalchemy.orm.relationship("User")
    offers: Mapped[list["Offer"]] = sqlalchemy.orm.relationship("Offer", back_populates="partner", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Partner {self.name}>"


class OfferType(str, enum.Enum):
    DISCOUNT = "discount"
    FREE_ITEM = "free_item"
    SERVICE = "service"


class TokenStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class CouponStatus(str, enum.Enum):
    ACTIVE = "active"
    USED = "used"
    EXPIRED = "expired"


class Offer(Base, TimestampMixin):
    __tablename__ = "offers"

    partner_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("partners.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    offer_type: Mapped[OfferType] = mapped_column(
        Enum(OfferType, name="offer_type", create_type=True), nullable=False
    )
    discount_percentage: Mapped[int | None] = mapped_column(nullable=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    redemption_instructions: Mapped[str | None] = mapped_column(Text, nullable=True)

    partner: Mapped["Partner"] = sqlalchemy.orm.relationship("Partner", back_populates="offers")
    redemptions: Mapped[list["OfferRedemption"]] = sqlalchemy.orm.relationship("OfferRedemption", back_populates="offer", cascade="all, delete-orphan")
    redemption_tokens: Mapped[list["RedemptionToken"]] = sqlalchemy.orm.relationship("RedemptionToken", back_populates="offer", cascade="all, delete-orphan")
    coupon_codes: Mapped[list["CouponCode"]] = sqlalchemy.orm.relationship("CouponCode", back_populates="offer", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Offer {self.title}>"


class OfferRedemption(Base, TimestampMixin):
    __tablename__ = "offer_redemptions"

    offer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("offers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    redeemed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    redemption_token_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("redemption_tokens.id", ondelete="SET NULL"), nullable=True
    )

    __table_args__ = (
        UniqueConstraint("offer_id", "user_id", name="unique_offer_redemption"),
    )

    offer: Mapped["Offer"] = sqlalchemy.orm.relationship("Offer", back_populates="redemptions")
    user: Mapped["User"] = sqlalchemy.orm.relationship("User")
    redemption_token: Mapped["RedemptionToken | None"] = sqlalchemy.orm.relationship("RedemptionToken")

    def __repr__(self) -> str:
        return f"<Redemption offer={self.offer_id} user={self.user_id}>"


class RedemptionToken(Base, TimestampMixin):
    """Token generated when a user initiates an in-store QR redemption."""
    __tablename__ = "redemption_tokens"

    offer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("offers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    token: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), unique=True, nullable=False, index=True, default=uuid.uuid4
    )
    status: Mapped[TokenStatus] = mapped_column(
        Enum(TokenStatus, name="token_status", create_type=True),
        nullable=False, default=TokenStatus.PENDING
    )
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    signer_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    signature_data: Mapped[str | None] = mapped_column(Text, nullable=True)
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    offer: Mapped["Offer"] = sqlalchemy.orm.relationship("Offer", back_populates="redemption_tokens")
    user: Mapped["User"] = sqlalchemy.orm.relationship("User")

    def __repr__(self) -> str:
        return f"<RedemptionToken offer={self.offer_id} status={self.status.value}>"


class CouponCode(Base, TimestampMixin):
    """One-time coupon code for online purchase redemption."""
    __tablename__ = "coupon_codes"

    offer_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("offers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    code: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    status: Mapped[CouponStatus] = mapped_column(
        Enum(CouponStatus, name="coupon_status", create_type=True),
        nullable=False, default=CouponStatus.ACTIVE
    )
    used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        UniqueConstraint("offer_id", "user_id", name="unique_coupon_per_user_offer"),
    )

    offer: Mapped["Offer"] = sqlalchemy.orm.relationship("Offer", back_populates="coupon_codes")
    user: Mapped["User"] = sqlalchemy.orm.relationship("User")

    def __repr__(self) -> str:
        return f"<CouponCode {self.code} status={self.status.value}>"
