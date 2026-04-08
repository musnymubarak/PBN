import asyncio
from app.core.database import engine
from sqlalchemy import text

async def main():
    try:
        async with engine.begin() as conn:
            await conn.execute(text('ALTER TABLE users ADD COLUMN profile_photo VARCHAR(500)'))
        print('Database updated successfully.')
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    asyncio.run(main())
