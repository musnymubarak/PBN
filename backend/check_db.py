import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect("postgresql://pbn_user:pbn_secret_password@localhost:5432/pbn_db")
    
    # Check enum types
    types = await conn.fetch("""
        SELECT t.typname, e.enumlabel 
        FROM pg_type t 
        JOIN pg_enum e ON t.oid = e.enumtypid 
        ORDER BY t.typname, e.enumsortorder
    """)
    print("Enum types and values:")
    for r in types:
        print(f"  {r['typname']}: {r['enumlabel']}")
    
    # Check table owner
    owners = await conn.fetch("""
        SELECT tablename, tableowner FROM pg_tables WHERE schemaname='public'
    """)
    print("\nTable owners:")
    for r in owners:
        print(f"  {r['tablename']}: {r['tableowner']}")
    
    # Try direct query
    try:
        rows = await conn.fetch("SELECT id, email, role FROM users LIMIT 1")
        print("\nDirect query works:", rows)
    except Exception as e:
        print(f"\nDirect query error: {e}")
    
    # Check type owner/schema
    type_info = await conn.fetch("""
        SELECT n.nspname as schema, t.typname 
        FROM pg_type t 
        JOIN pg_namespace n ON t.typnamespace = n.oid 
        WHERE t.typname LIKE '%role%' OR t.typname LIKE '%status%'
    """)
    print("\nType schemas:")
    for r in type_info:
        print(f"  {r['schema']}.{r['typname']}")
    
    await conn.close()

asyncio.run(main())
