import asyncio
from app.core.database import async_session_factory
from sqlalchemy import select
from app.models.referrals import Referral

async def check():
    async with async_session_factory() as db:
        res = await db.execute(select(Referral)) # Get all to be sure
        refs = res.scalars().all()
        for r in refs:
            if r.client_name == "Web Development":
                print(f"Found: {r.client_name}, Phone: {r.client_phone}, Email: {r.client_email}, Desc: {r.description}")

if __name__ == "__main__":
    asyncio.run(check())
