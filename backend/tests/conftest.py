"""Shared test fixtures for GigaRizz backend E2E tests."""

from __future__ import annotations

import asyncio
from typing import AsyncGenerator
from unittest.mock import AsyncMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from datetime import datetime, timezone

from app.deps import get_audit_service, get_moderation_service
from app.main import create_app
from app.models.database import Base, get_db
from app.models.schemas import (
    DatingPlatform,
    GenerationStyle,
    PhotoArchetype,
    PhotoCritique,
    ProfileAuditResult,
    ProfileFix,
)
from app.services.moderation_service import ModerationService

# In-memory SQLite for tests
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    """Create a single event loop for the entire test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


class FakeModerationService:
    """Stub that always returns safe (no OpenAI call)."""
    async def check_text(self, text: str) -> dict:
        return {"flagged": False, "categories": {}}

    async def check_image_url(self, image_url: str) -> dict:
        return {"flagged": False, "reason": None}


class FakeAuditService:
    """Stub that returns a deterministic audit (no OpenAI vision call)."""
    async def audit_photo_set(self, photo_urls, target_platforms=None, roast_mode=False):
        n = len(photo_urls)
        per_photo = [
            PhotoCritique(
                photo_url=u,
                photo_index=i,
                clarity=7, lighting=6, expression=8,
                crop=7, authenticity=9, platform_fit=8, overall=7,
                archetype=PhotoArchetype.first_photo if i == 0 else PhotoArchetype.casual_candid,
                issues=["test issue"],
                strengths=["test strength"],
            )
            for i, u in enumerate(photo_urls)
        ]
        return ProfileAuditResult(
            overall_score=68,
            summary="Solid base — main lift is variety and a stronger first photo.",
            best_photo_index=0,
            weakest_photo_index=max(0, n - 1),
            missing_archetypes=[PhotoArchetype.travel_lifestyle, PhotoArchetype.hobby_activity],
            top_fixes=[
                ProfileFix(
                    title="Add a hobby photo",
                    detail="Profile lacks an activity shot — generate one in your sport.",
                    target_archetype=PhotoArchetype.hobby_activity,
                    suggested_style=GenerationStyle.adventure,
                ),
            ],
            per_photo=per_photo,
            target_platforms=target_platforms or [],
            created_at=datetime.now(timezone.utc),
        )

    async def close(self):
        return None


@pytest_asyncio.fixture
async def app():
    """Create a fresh FastAPI app with in-memory DB for each test."""
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    fastapi_app = create_app()

    # Override DB dependency
    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with async_session() as session:
            yield session

    fastapi_app.dependency_overrides[get_db] = override_get_db
    fastapi_app.dependency_overrides[get_moderation_service] = lambda: FakeModerationService()
    fastapi_app.dependency_overrides[get_audit_service] = lambda: FakeAuditService()

    yield fastapi_app

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture
async def client(app) -> AsyncGenerator[AsyncClient, None]:
    """Async HTTP client for testing against the FastAPI app."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
