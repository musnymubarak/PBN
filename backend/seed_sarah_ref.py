import asyncio
from app.core.database import async_session_factory
from sqlalchemy import select
from app.models.user import User
from app.models.referrals import Referral, ReferralStatus

async def seed():
    async with async_session_factory() as db:
        u_sarah = (await db.execute(select(User).where(User.email == 'sarah@pbn.lk'))).scalar_one()
        u_member = (await db.execute(select(User).where(User.email == 'member@pbn.lk'))).scalar_one()
        
        # New lead with full details
        ref = Referral(
            from_member_id=u_member.id,
            to_member_id=u_sarah.id,
            client_name="Luxury Villa Project",
            client_phone="+94 77 999 8888",
            client_email="architect@luxury.lk",
            description="High-end interior design and architectural consultation for a new villa in Galle. Ready to start immediately.",
            status=ReferralStatus.SUBMITTED
        )
        db.add(ref)
        await db.commit()
        print("Seeded Luxury Villa Project lead for Sarah!")

if __name__ == "__main__":
    asyncio.run(seed())
