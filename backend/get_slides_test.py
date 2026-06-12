import asyncio
import os
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select
from app.models.user import User
from app.features.home_content.service import list_public_slides

async def main():
    engine = create_async_engine("postgresql+asyncpg://pbn_user:pbn_secret_password@postgres:5432/pbn_db")
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as db:
        user = (await db.execute(select(User).where(User.full_name.ilike('%Musni%')))).scalar_one()
        slides = await list_public_slides(user, db)
        print("SLIDES FOR MUSNI:", [s['title'] for s in slides])
        
if __name__ == "__main__":
    asyncio.run(main())
