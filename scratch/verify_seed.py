import asyncio
import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.core.database import async_session_factory
from app.models.chapters import Chapter
from app.models.user import User, UserRole
from app.models.memberships import ChapterMembership
from app.models.industry_categories import IndustryCategory
from sqlalchemy import select, func

async def verify():
    async with async_session_factory() as session:
        # Total counts
        user_count = (await session.execute(select(func.count(User.id)).where(User.role == UserRole.MEMBER))).scalar()
        membership_count = (await session.execute(select(func.count(ChapterMembership.id)))).scalar()
        
        print(f"Stats:\n- Total Member Users: {user_count}\n- Total Memberships: {membership_count}")
        
        # Check by Chapter
        chaps = (await session.execute(select(Chapter))).scalars().all()
        for c in chaps:
            count = (await session.execute(select(func.count(ChapterMembership.id)).where(ChapterMembership.chapter_id == c.id))).scalar()
            
            # Check unique industries
            ind_count = (await session.execute(select(func.count(func.distinct(ChapterMembership.industry_category_id))).where(ChapterMembership.chapter_id == c.id))).scalar()
            
            print(f"Chapter: {c.name}")
            print(f"  - Members: {count}")
            print(f"  - Unique Industries: {ind_count}")

if __name__ == "__main__":
    asyncio.run(verify())
