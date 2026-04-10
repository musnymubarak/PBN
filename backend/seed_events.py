import asyncio
import datetime
from sqlalchemy import select
from app.core.database import async_session_factory
from app.models.chapters import Chapter
from app.models.events import Event, EventType

async def main():
    async with async_session_factory() as session:
        # Get the chapter (assuming we have at least one)
        chapter = (await session.execute(select(Chapter).limit(1))).scalar_one_or_none()
        if not chapter:
            chapter = Chapter(name="Main Chapter", is_active=True)
            session.add(chapter)
            await session.flush()
        
        now = datetime.datetime.now(datetime.timezone.utc)
        current_year = now.year
        current_month = now.month
        
        # 1 Physical (FLAGSHIP) Event
        physical_event = Event(
            chapter_id=chapter.id,
            title="Monthly Premium Networking Dinner",
            description="Our primary physical meetup for the month. Connect with executives over closed-door dinner.",
            event_type=EventType.FLAGSHIP,
            location="The Grand Hotel, Colombo",
            start_at=datetime.datetime(current_year, current_month, 25, 18, 0, tzinfo=datetime.timezone.utc),
            end_at=datetime.datetime(current_year, current_month, 25, 21, 0, tzinfo=datetime.timezone.utc),
            fee=2500,
            is_published=True,
            is_active=True
        )
        session.add(physical_event)
        
        # 3 Virtual Events
        for i in range(1, 4):
            day = 5 + (i * 5) # e.g. 10th, 15th, 20th
            if day > 28: day = 20
            virtual_event = Event(
                chapter_id=chapter.id,
                title=f"Weekly Virtual Mastermind #{i}",
                description="Online mastermind session to evaluate referrals and discuss business tactics.",
                event_type=EventType.VIRTUAL,
                meeting_link="https://zoom.us/j/123456789",
                start_at=datetime.datetime(current_year, current_month, day, 10, 0, tzinfo=datetime.timezone.utc),
                end_at=datetime.datetime(current_year, current_month, day, 11, 0, tzinfo=datetime.timezone.utc),
                fee=0,
                is_published=True,
                is_active=True
            )
            session.add(virtual_event)
            
        await session.commit()
        print("Events seeded successfully.")

if __name__ == "__main__":
    asyncio.run(main())
