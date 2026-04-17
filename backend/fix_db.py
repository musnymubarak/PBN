import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from sqlalchemy import text
from app.core.config import get_settings

async def migrate():
    settings = get_settings()
    engine = create_async_engine(settings.DATABASE_URL)
    
    print(f"Connecting to database...")
    async with engine.connect() as conn:
        print("1. Adding 'must_change_password' column to 'users' table...")
        try:
            await conn.execute(text("ALTER TABLE users ADD COLUMN must_change_password BOOLEAN DEFAULT FALSE NOT NULL"))
            await conn.commit()
            print("[OK] 'must_change_password' column added successfully!")
        except Exception as e:
            if "already exists" in str(e):
                print("[WARN] Column 'must_change_password' already exists, skipping.")
            else:
                print(f"[ERR] Error adding column: {e}")

    async with engine.connect() as conn:
        print("2. Fixing empty emails in the applications table...")
        try:
            await conn.execute(text("UPDATE applications SET email = 'missing@email.com' WHERE email IS NULL OR email = ''"))
            await conn.commit()
            print("[OK] Application emails fixed successfully!")
        except Exception as e:
            print(f"[ERR] Error updating emails: {e}")

    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(migrate())
