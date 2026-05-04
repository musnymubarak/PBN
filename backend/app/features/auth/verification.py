"""
Prime Business Network – Member Verification & Leveling Logic.
"""

from __future__ import annotations
import logging
from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User, VerificationLevel
from app.features.notifications.service import send_push_notification

logger = logging.getLogger(__name__)

async def update_member_verification(user: User, delta_value: Decimal, db: AsyncSession):
    """Update user's cumulative value and potentially promote to next verification tier."""
    user.cumulative_value_generated += delta_value
    
    val = user.cumulative_value_generated
    new_level = VerificationLevel.NONE
    
    # Tier thresholds in LKR (approximate based on bylaws goals)
    if val >= 5000000:
        new_level = VerificationLevel.PLATINUM
    elif val >= 2500000:
        new_level = VerificationLevel.GOLD
    elif val >= 1000000:
        new_level = VerificationLevel.SILVER
    elif val >= 25000:
        new_level = VerificationLevel.VERIFIED
        
    if new_level != user.verification_level:
        old_level = user.verification_level
        user.verification_level = new_level
        user.verification_updated_at = datetime.now()
        
        logger.info(f"User {user.id} promoted from {old_level} to {new_level}")
        
        # Send Celebration Notification
        try:
            await send_push_notification(
                user_id=user.id,
                title="Level Up! 🏆",
                body=f"Congratulations! You've reached {new_level.value.upper()} verification level for your contributions to the network.",
                notification_type="VERIFICATION_UPGRADE",
                data={"level": new_level.value, "route": "/profile"}
            )
        except Exception as e:
            logger.error(f"Failed to send verification notification: {e}")
