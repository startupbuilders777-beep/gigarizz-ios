"""SQLAlchemy async database models and engine setup."""

from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Float, Integer, String, Text, JSON
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings


class Base(DeclarativeBase):
    pass


class GenerationJob(Base):
    __tablename__ = "generation_jobs"

    id = Column(String(21), primary_key=True)  # nanoid
    user_id = Column(String(128), nullable=False, index=True)
    style = Column(String(50), nullable=False)
    model = Column(String(50), default="flux_schnell")
    custom_prompt = Column(Text, nullable=True)
    photo_count = Column(Integer, default=4)
    source_image_urls = Column(JSON, default=list)
    status = Column(String(20), default="queued", index=True)
    progress = Column(Float, default=0.0)
    result_urls = Column(JSON, default=list)
    error_message = Column(Text, nullable=True)
    platform = Column(String(20), default="tinder")
    replicate_prediction_id = Column(String(100), nullable=True)
    batch_id = Column(String(50), nullable=True, index=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)


class User(Base):
    __tablename__ = "users"

    id = Column(String(128), primary_key=True)  # Firebase UID
    email = Column(String(255), nullable=True)
    display_name = Column(String(255), nullable=True)
    tier = Column(String(20), default="free")  # free, plus, gold
    generation_count = Column(Integer, default=0)
    daily_generations_used = Column(Integer, default=0)
    daily_reset_date = Column(String(10), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class UserAnalytics(Base):
    __tablename__ = "user_analytics"

    user_id = Column(String(128), primary_key=True)
    total_generations = Column(Integer, default=0)
    total_matches = Column(Integer, default=0)
    match_rate = Column(Float, default=0.0)
    top_style = Column(String(50), default="professional")
    streak_days = Column(Integer, default=0)
    weekly_generations = Column(JSON, default=lambda: [0] * 7)
    platform_breakdown = Column(JSON, default=dict)


# ── Engine & Session ────────────────────────────────────────────────────────

_engine = None
_session_factory = None


def get_engine():
    global _engine
    if _engine is None:
        settings = get_settings()
        _engine = create_async_engine(
            settings.database_url,
            echo=settings.debug,
            future=True,
        )
    return _engine


def get_session_factory():
    global _session_factory
    if _session_factory is None:
        _session_factory = async_sessionmaker(
            get_engine(),
            class_=AsyncSession,
            expire_on_commit=False,
        )
    return _session_factory


async def get_db() -> AsyncSession:  # type: ignore[misc]
    factory = get_session_factory()
    async with factory() as session:
        yield session


async def init_db():
    """Create all tables (dev only; use Alembic for production)."""
    engine = get_engine()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
