import asyncio
import uuid
import datetime
from app.core.database import async_session_factory
from app.features.auth.service import hash_password
from app.models.user import User, UserRole
from app.models.chapters import Chapter
from app.models.industry_categories import IndustryCategory
from app.models.memberships import ChapterMembership, MembershipType
from sqlalchemy import select

async def main():
    try:
        async with async_session_factory() as session:
            # Get chapter
            chapter = (await session.execute(select(Chapter).limit(1))).scalar_one_or_none()
            if not chapter:
                chapter = Chapter(name="Flagship Mixed Chapter — 30 Founding Seats", is_active=True)
                session.add(chapter)
                await session.flush()
            
            # Create completely unique industries
            inds = []
            for i in range(2):
                h = uuid.uuid4().hex[:6]
                ind = IndustryCategory(name=f"Industry {h}", slug=f"industry-{h}")
                session.add(ind)
                await session.flush()
                inds.append(ind)
            
            # Check if Alice exists
            existing_user = (await session.execute(select(User).where(User.phone_number == "+94770000010"))).scalar_one_or_none()
            if existing_user is None:
                user1 = User(
                    phone_number="+94770000010",
                    email="alice@pbn.lk",
                    full_name="Alice Smith",
                    role=UserRole.MEMBER,
                    is_active=True,
                    password_hash=hash_password("pbn123")
                )
                session.add(user1)
                
                user2 = User(
                    phone_number="+94770000011",
                    email="bob@pbn.lk",
                    full_name="Bob Jones",
                    role=UserRole.MEMBER,
                    is_active=True,
                    password_hash=hash_password("pbn123")
                )
                session.add(user2)
                await session.flush()
                
                # Add memberships
                mem1 = ChapterMembership(
                    user_id=user1.id,
                    chapter_id=chapter.id,
                    industry_category_id=inds[0].id,
                    membership_type=MembershipType.STANDARD,
                    start_date=datetime.date.today(),
                    is_active=True
                )
                mem2 = ChapterMembership(
                    user_id=user2.id,
                    chapter_id=chapter.id,
                    industry_category_id=inds[1].id,
                    membership_type=MembershipType.STANDARD,
                    start_date=datetime.date.today(),
                    is_active=True
                )
                session.add(mem1)
                session.add(mem2)
                
                await session.commit()
                print("Members created successfully.")
            else:
                print("Members already exist.")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
