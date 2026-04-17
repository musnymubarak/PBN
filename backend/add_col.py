import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import get_settings

async def migrate():
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL)
    
    print(f"Connecting to database...")
    async with engine.connect() as conn:
        print("Adding 'must_change_password' column to 'users' table...")
        try:
            await conn.execute(text("ALTER TABLE users ADD COLUMN must_change_password BOOLEAN DEFAULT FALSE NOT NULL"))
            await conn.commit()
            print("✅ Column added successfully!")
        except Exception as e:
            if "already exists" in str(e):
                print("⚠️ Column already exists, skipping.")
            else:
                print(f"❌ Error: {e}")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(migrate())
