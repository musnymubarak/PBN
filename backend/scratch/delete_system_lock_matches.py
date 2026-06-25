import asyncio
from sqlalchemy import select, delete
from app.core.database import SessionLocal
from app.models.matchmaking import MatchSuggestion
from app.models.user import User

async def run():
    async with SessionLocal() as db:
        # Find all system lock users
        stmt = select(User.id).where(User.full_name.ilike("%system lock%"))
        result = await db.execute(stmt)
        system_lock_ids = result.scalars().all()
        print(f"Found system lock ids: {system_lock_ids}")

        if system_lock_ids:
            # Delete matches where matched_user_id is in system_lock_ids
            del_stmt = delete(MatchSuggestion).where(MatchSuggestion.matched_user_id.in_(system_lock_ids))
            res = await db.execute(del_stmt)
            await db.commit()
            print(f"Deleted {res.rowcount} match suggestions.")
        else:
            print("No system lock users found.")

asyncio.run(run())
