import asyncio
import sys
import os

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.core.database import async_session_factory
from app.models.chapters import Chapter
from app.models.user import User, UserRole
from app.models.industry_categories import IndustryCategory
from sqlalchemy import select, func

async def main():
    async with async_session_factory() as session:
        # Total counts
        user_count = (await session.execute(select(func.count(User.id)).where(User.role == UserRole.MEMBER))).scalar()
        chapter_count = (await session.execute(select(func.count(Chapter.id)))).scalar()
        cat_count = (await session.execute(select(func.count(IndustryCategory.id)))).scalar()
        
        print(f"Stats:\n- Member Users: {user_count}\n- Total Chapters: {chapter_count}\n- Total Categories: {cat_count}")
        
        # List chapters
        chaps = (await session.execute(select(Chapter))).scalars().all()
        for c in chaps:
            print(f"Chapter: {c.name} (ID: {c.id})")

if __name__ == "__main__":
    asyncio.run(main())
