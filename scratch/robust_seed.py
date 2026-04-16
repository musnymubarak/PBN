import asyncio
import sys
import os
import random
from datetime import date, timedelta
from uuid import UUID

# Add backend to path
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app.core.database import async_session_factory
from app.models.chapters import Chapter
from app.models.user import User, UserRole
from app.models.industry_categories import IndustryCategory
from app.models.memberships import ChapterMembership, MembershipType
from sqlalchemy import select, delete

async def seed():
    async with async_session_factory() as session:
        # 1. CLEANUP: Delete ALL existing Chapters and Memberships to ensure a fresh state
        print("Cleaning up old chapters and memberships...")
        await session.execute(delete(ChapterMembership))
        await session.execute(delete(Chapter))
        await session.flush()

        # 2. Setup Chapters
        chapter_names = ["Colombo Chapter", "Jaffna Chapter", "Trinco Chapter"]
        chapters = []
        for name in chapter_names:
            stmt = select(Chapter).where(Chapter.name == name)
            res = (await session.execute(stmt)).scalar_one_or_none()
            if not res:
                res = Chapter(name=name, description=f"The primary business networking hub for {name.split()[0]}.")
                session.add(res)
                await session.flush()
            chapters.append(res)

        # 2. Get Industries
        industries = (await session.execute(select(IndustryCategory))).scalars().all()
        if len(industries) < 30:
            print(f"Error: Only {len(industries)} industries found. Need 30.")
            return

        # 3. Get/Create Users (Target: 90)
        # First, grab existing members
        existing_members = (await session.execute(select(User).where(User.role == UserRole.MEMBER))).scalars().all()
        
        # Deduplicate by email
        unique_pool = {}
        for u in existing_members:
            if u.email and u.email not in unique_pool:
                unique_pool[u.email] = u
        
        members = list(unique_pool.values())
        print(f"Start with {len(members)} unique members.")

        # Create more if needed
        while len(members) < 90:
            idx = len(members) + 1
            email = f"member{idx}@example.com"
            phone = f"+9477000{idx:03d}"
            new_user = User(
                phone_number=phone,
                email=email,
                full_name=f"Member Name {idx}",
                role=UserRole.MEMBER,
                is_active=True
            )
            session.add(new_user)
            await session.flush()
            members.append(new_user)
            
        # Truncate to exactly 90 if more exist
        members = members[:90]
        random.shuffle(members)

        # 4. Clear old memberships for these chapters to avoid conflicts
        chapter_ids = [c.id for c in chapters]
        await session.execute(delete(ChapterMembership).where(ChapterMembership.chapter_id.in_(chapter_ids)))

        # 5. Assign Members
        # Each chapter gets 30 members, each member gets 1 industry
        count = 0
        for chapter in chapters:
            chapter_members = members[count:count + 30]
            random.shuffle(industries) # Randomize industries for this chapter
            
            for i, member in enumerate(chapter_members):
                industry = industries[i]
                membership = ChapterMembership(
                    user_id=member.id,
                    chapter_id=chapter.id,
                    industry_category_id=industry.id,
                    membership_type=MembershipType.STANDARD,
                    start_date=date.today() - timedelta(days=random.randint(0, 365)),
                    is_active=True
                )
                session.add(membership)
            count += 30

        await session.commit()
        print("Successfully seeded 90 members across 3 chapters!")

if __name__ == "__main__":
    asyncio.run(seed())
