import asyncio
from app.core.database import async_session_factory
from sqlalchemy import select
from app.models.user import User, VerificationLevel
from app.models.verification_requests import VerificationRequest
from app.models.businesses import Business
from app.models.industry_categories import IndustryCategory
from datetime import datetime

async def main():
    print("Starting End-to-End Database Flow Verification...")
    async with async_session_factory() as db:
        # Retrieve first industry category
        cat_stmt = select(IndustryCategory).limit(1)
        category = (await db.execute(cat_stmt)).scalars().first()
        if not category:
            raise Exception("No industry category found in the database. Run seed script first.")

        # 1. Retrieve a test user (e.g., Target User)
        user_stmt = select(User).where(User.full_name == 'Target User').limit(1)
        user = (await db.execute(user_stmt)).scalars().first()
        if not user:
            print("Target User not found. Selecting first user.")
            user = (await db.execute(select(User).limit(1))).scalars().first()

        print(f"\nUsing test user: {user.full_name} (Current verification level: {user.verification_level})")

        # 2. Get or create their business portfolio
        biz_stmt = select(Business).where(Business.owner_user_id == user.id)
        business = (await db.execute(biz_stmt)).scalar_one_or_none()
        if not business:
            print("Business profile not found, creating one...")
            business = Business(
                owner_user_id=user.id,
                business_name="Test Enterprise Ltd",
                description="E2E Testing Company",
                industry_category_id=category.id
            )
            db.add(business)
            await db.flush()

        # Update all portfolio fields
        business.logo_url = "/uploads/logos/test_logo.png"
        business.website = "https://testenterprise.com"
        business.address = "123 Innovation Way, Tech Park"
        business.established_year = "2020"
        business.br_number = "BR998877"
        business.brochure_url = "/uploads/brochures/test_profile.pdf"
        business.google_maps_url = "https://maps.app.goo.gl/test"
        business.linkedin_url = "https://linkedin.com/company/test"
        business.facebook_url = "https://facebook.com/test"
        business.instagram_url = "https://instagram.com/test"

        # Update their cumulative generated value to LKR 30,000 (qualifies them for verification)
        user.cumulative_value_generated = 30000.0
        
        # Save updates to DB
        await db.commit()
        print("Updated user value generated and filled all required portfolio fields.")

    # 3. Simulate client checking status and requesting verification
    async with async_session_factory() as db:
        # Reload user
        user = (await db.execute(select(User).where(User.id == user.id))).scalar_one()
        business = (await db.execute(select(Business).where(Business.owner_user_id == user.id))).scalar_one()
        
        # Verify eligibility metrics
        business_value = float(user.cumulative_value_generated)
        value_met = business_value >= 25000.0
        
        portfolio_complete = all([
            bool(business.logo_url),
            bool(business.website),
            bool(business.address),
            bool(business.established_year),
            bool(business.br_number),
            bool(business.brochure_url),
            bool(business.linkedin_url or business.facebook_url or business.instagram_url)
        ])
        
        print(f"Value generated: LKR {business_value:,.2f} (Met: {value_met})")
        print(f"Portfolio completeness: {portfolio_complete}")
        
        assert value_met, "Value generated threshold should be met"
        assert portfolio_complete, "Portfolio completeness check should pass"

        # Submit verification request
        new_req = VerificationRequest(
            user_id=user.id,
            status="pending"
        )
        db.add(new_req)
        await db.commit()
        print(f"Submitted pending verification request: {new_req.id}")

    # 4. Simulate admin reviewing and approving request
    async with async_session_factory() as db:
        # Query the pending request
        req_stmt = select(VerificationRequest).where(VerificationRequest.user_id == user.id).order_by(VerificationRequest.created_at.desc())
        req = (await db.execute(req_stmt)).scalars().first()
        print(f"Admin retrieved request {req.id} - Status: {req.status}")
        assert req.status == "pending", "Request should be pending"

        # Admin approves the request
        req.status = "approved"
        
        # Load user and upgrade level to VERIFIED
        user_to_verify = (await db.execute(select(User).where(User.id == req.user_id))).scalar_one()
        user_to_verify.verification_level = VerificationLevel.VERIFIED
        user_to_verify.verification_updated_at = datetime.now()
        
        # Perform auto-leveling checks in case they qualify for higher tiers
        val = user_to_verify.cumulative_value_generated
        if val >= 5000000:
            user_to_verify.verification_level = VerificationLevel.PLATINUM
        elif val >= 2500000:
            user_to_verify.verification_level = VerificationLevel.GOLD
        elif val >= 1000000:
            user_to_verify.verification_level = VerificationLevel.SILVER

        await db.commit()
        print(f"Request approved! User's new verification level: {user_to_verify.verification_level}")
        assert user_to_verify.verification_level == VerificationLevel.VERIFIED, "User should be VERIFIED"

    # 5. Clean up test data
    async with async_session_factory() as db:
        # Delete test requests
        await db.execute(select(VerificationRequest).where(VerificationRequest.user_id == user.id))
        del_req_stmt = f"DELETE FROM verification_requests WHERE user_id = '{user.id}'"
        from sqlalchemy import text
        await db.execute(text(del_req_stmt))
        
        # Reset user
        user_reset = (await db.execute(select(User).where(User.id == user.id))).scalar_one()
        user_reset.verification_level = VerificationLevel.NONE
        user_reset.cumulative_value_generated = 0.0
        
        # Reset business portfolio
        biz_reset = (await db.execute(select(Business).where(Business.owner_user_id == user.id))).scalar_one()
        biz_reset.logo_url = None
        biz_reset.website = None
        biz_reset.address = None
        biz_reset.established_year = None
        biz_reset.br_number = None
        biz_reset.brochure_url = None
        biz_reset.google_maps_url = None
        biz_reset.linkedin_url = None
        biz_reset.facebook_url = None
        biz_reset.instagram_url = None
        
        await db.commit()
        print("\nCleaned up all test modifications. Database is clean!")
        print("End-to-End Database Flow Verification completed successfully!")

if __name__ == "__main__":
    asyncio.run(main())
