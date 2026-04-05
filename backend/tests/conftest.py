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

from app.deps import get_moderation_service
from app.main import create_app
from app.models.database import Base, get_db
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
