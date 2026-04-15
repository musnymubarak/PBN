import asyncio
from sqlalchemy import select, update
from app.core.database import async_session_factory
from app.models.chapters import Chapter
from app.models.industry_categories import IndustryCategory

CATEGORIES = [
    "Lawyer", "Accountant", "Financial Advisor", "Insurance Agent", 
    "HR Consultant", "Business Coach", "Corporate Trainer", "Company Secretary", 
    "Tax Advisor", "Management Consultant", "IT Company", "Digital Marketer", 
    "Cybersecurity", "Data Analyst", "UI/UX Designer", "Real Estate Agent", 
    "Architect", "Contractor", "Interior Designer", "Quantity Surveyor", 
    "Doctor / GP", "Dentist", "Physiotherapist", "Nutritionist", 
    "Pharmacist", "Photographer", "PR Firm", "Event Organiser", 
    "Branding Designer", "Content Creator"
]

NEW_CHAPTER_NAME = "Flagship Mixed Chapter — 30 Founding Seats"

async def main():
    print("Starting Safe Category Update...")
    try:
        async with async_session_factory() as session:
            # 1. Deactivate ALL current categories
            print("Deactivating all existing industry categories...")
            await session.execute(
                update(IndustryCategory).values(is_active=False)
            )
            
            # 2. Deactivate old Chapters (optional, but requested implicitly by 'only Flagship')
            print("Deactivating all existing chapters...")
            await session.execute(
                update(Chapter).values(is_active=False)
            )
            
            await session.flush()

            # 3. Add/Reactivate the 30 new categories
            print(f"Adding/Reactivating {len(CATEGORIES)} industry categories...")
            for cat_name in CATEGORIES:
                # Check if it already exists (by name)
                stmt = select(IndustryCategory).where(IndustryCategory.name == cat_name)
                existing = (await session.execute(stmt)).scalar_one_or_none()
                
                if existing:
                    existing.is_active = True
                else:
                    slug = cat_name.lower().replace(" / ", "-").replace(" — ", "-").replace(" ", "-").replace("&", "and")
                    session.add(IndustryCategory(name=cat_name, slug=slug, is_active=True))

            # 4. Add/Reactivate the Flagship Chapter
            print(f"Ensuring Flagship Chapter is active: {NEW_CHAPTER_NAME}")
            stmt = select(Chapter).where(Chapter.name == NEW_CHAPTER_NAME)
            existing_chapter = (await session.execute(stmt)).scalar_one_or_none()
            
            if existing_chapter:
                existing_chapter.is_active = True
            else:
                session.add(Chapter(
                    name=NEW_CHAPTER_NAME,
                    description="The premier founding chapter of Prime Business Network.",
                    is_active=True
                ))

            await session.commit()
            print("Safe update completed successfully!")

    except Exception as e:
        print(f"Error during safe update: {e}")

if __name__ == "__main__":
    asyncio.run(main())
