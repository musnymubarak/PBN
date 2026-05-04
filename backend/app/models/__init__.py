# Prime Business Network - Models Package
# All models must be imported here for Alembic autogenerate to detect them.

from app.models.base import Base  # noqa: F401
from app.models.user import User  # noqa: F401
from app.models.chapters import Chapter  # noqa: F401
from app.models.industry_categories import IndustryCategory  # noqa: F401
from app.models.businesses import Business  # noqa: F401
from app.models.applications import Application, ApplicationStatusHistory  # noqa: F401
from app.models.memberships import ChapterMembership, FeeSchedule  # noqa: F401
from app.models.horizontal_clubs import HorizontalClub, HorizontalClubMembership  # noqa: F401
from app.models.designations import UserDesignation  # noqa: F401
from app.models.referrals import Referral, ReferralStatusHistory  # noqa: F401
from app.models.events import Event, EventRSVP, EventAttendance  # noqa: F401
from app.models.privilege_cards import PrivilegeCard, Partner, Offer, OfferRedemption, RedemptionToken, CouponCode  # noqa: F401
from app.models.payments import Payment  # noqa: F401
from app.models.notifications import Notification  # noqa: F401
from app.models.audit_logs import AuditLog  # noqa: F401
from app.models.community import CommunityPost, PostLike, PostComment  # noqa: F401
from app.models.marketplace import MarketplaceListing, MarketplaceInterest  # noqa: F401
from app.models.matchmaking import MatchingProfile, IndustryRelationship, MatchSuggestion  # noqa: F401

__all__ = [
    "Base",
    "User",
    "Chapter",
    "IndustryCategory",
    "Business",
    "Application", "ApplicationStatusHistory",
    "ChapterMembership", "FeeSchedule",
    "HorizontalClub", "HorizontalClubMembership",
    "UserDesignation",
    "Referral", "ReferralStatusHistory",
    "Event", "EventRSVP", "EventAttendance",
    "PrivilegeCard", "Partner", "Offer", "OfferRedemption", "RedemptionToken", "CouponCode",
    "Payment",
    "Notification",
    "AuditLog",
    "CommunityPost", "PostLike", "PostComment",
    "MarketplaceListing", "MarketplaceInterest",
    "MatchingProfile", "IndustryRelationship", "MatchSuggestion",
]

