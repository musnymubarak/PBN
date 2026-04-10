import asyncio
from decimal import Decimal
from sqlalchemy import select
from app.core.database import async_session_factory
from app.models.user import User
from app.models.payments import Payment, PaymentType, PaymentStatus

async def add_payments_to_all():
    async with async_session_factory() as db:
        users = (await db.execute(select(User))).scalars().all()
        count = 0
        for user in users:
            p = Payment(
                user_id=user.id,
                amount=Decimal('15000.00'),
                payment_type=PaymentType.MEMBERSHIP,
                status=PaymentStatus.COMPLETED,
                currency="LKR",
                reference_id="TEST-PAYMENT-123"
            )
            db.add(p)
            count += 1
            
        await db.commit()
        print(f"Successfully added 15000 LKR payment to all {count} users in the database!")

if __name__ == "__main__":
    asyncio.run(add_payments_to_all())
