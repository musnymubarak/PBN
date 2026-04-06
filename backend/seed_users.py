"""Add password_hash column to users table and seed test users."""
import asyncio
import uuid
import bcrypt

# ── Fix for passlib/bcrypt 4.0 conflict ──────────────────────
if not hasattr(bcrypt, "__about__"):
    bcrypt.__about__ = type("about", (object,), {"__version__": bcrypt.__version__})

from datetime import datetime, timezone

from passlib.context import CryptContext
import asyncpg

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")

DB_URL = "postgresql://pbn_user:pbn_secret_password@localhost:5432/pbn_db"

TEST_USERS = [
    {
        "full_name": "Super Admin",
        "email": "admin@pbn.lk",
        "phone_number": "+94770000001",
        "role": "SUPER_ADMIN",
        "password": "Admin@123",
    },
    {
        "full_name": "Chapter Admin",
        "email": "chapteradmin@pbn.lk",
        "phone_number": "+94770000002",
        "role": "CHAPTER_ADMIN",
        "password": "Chapter@123",
    },
    {
        "full_name": "John Member",
        "email": "member@pbn.lk",
        "phone_number": "+94770000003",
        "role": "MEMBER",
        "password": "Member@123",
    },
    {
        "full_name": "Jane Prospect",
        "email": "prospect@pbn.lk",
        "phone_number": "+94770000004",
        "role": "PROSPECT",
        "password": "Prospect@123",
    },
]


async def seed():
    conn = await asyncpg.connect(DB_URL)

    # ── Step 1: Add password_hash column if missing ─────────────────────
    col_exists = await conn.fetchval("""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'users' AND column_name = 'password_hash'
        )
    """)
    if not col_exists:
        print("🔧 Adding missing 'password_hash' column to users table...")
        await conn.execute("ALTER TABLE users ADD COLUMN password_hash VARCHAR(255) DEFAULT NULL")
        print("   ✅ Column added.\n")
    else:
        print("✅ 'password_hash' column already exists.\n")

    # ── Step 2: Seed test users ─────────────────────────────────────────
    print("🌱 Seeding test users...\n")

    for data in TEST_USERS:
        existing = await conn.fetchrow(
            "SELECT id FROM users WHERE email = $1 OR phone_number = $2",
            data["email"],
            data["phone_number"],
        )

        if existing:
            print(f"  🔄 {data['role']:15s} | {data['email']:25s} | Updating password hash...")
            await conn.execute(
                "UPDATE users SET password_hash = $1 WHERE id = $2",
                pwd_ctx.hash(data["password"]),
                existing["id"]
            )
            continue

        now = datetime.now(timezone.utc)
        await conn.execute(
            """
            INSERT INTO users (id, full_name, email, phone_number, role, is_active, password_hash, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5::user_role, $6, $7, $8, $9)
            """,
            uuid.uuid4(),
            data["full_name"],
            data["email"],
            data["phone_number"],
            data["role"],
            True,
            pwd_ctx.hash(data["password"]),
            now,
            now,
        )
        print(f"  ✅ {data['role']:15s} | {data['email']:25s} | Password: {data['password']}")

    await conn.close()

    print("\n✨ Done! Test accounts:\n")
    print(f"  {'Role':<15s} | {'Email / Phone':<25s} | Password")
    print(f"  {'-'*15} | {'-'*25} | {'-'*15}")
    for data in TEST_USERS:
        print(f"  {data['role']:<15s} | {data['email']:<25s} | {data['password']}")
        print(f"  {'':<15s} | {data['phone_number']:<25s} |")
    print()


if __name__ == "__main__":
    asyncio.run(seed())
