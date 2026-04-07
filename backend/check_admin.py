import asyncio
import asyncpg

async def check():
    try:
        conn = await asyncpg.connect('postgresql://pbn_user:pbn_secret_password@localhost:5432/pbn_db')
        row = await conn.fetchrow("SELECT email, role, is_active FROM users WHERE email = 'admin@pbn.lk'")
        if row:
            print(f"Found admin user: {row['email']}")
            print(f"Role: {row['role']}")
            print(f"Is Active: {row['is_active']}")
        else:
            print("Admin user 'admin@pbn.lk' not found in database.")
        
        # Check all users
        all_users = await conn.fetch("SELECT email, role FROM users")
        print("\nAll users in DB:")
        for u in all_users:
            print(f"- {u['email']} ({u['role']})")
            
        await conn.close()
    except Exception as e:
        print(f"Connection error: {e}")

if __name__ == "__main__":
    asyncio.run(check())
