"""GigaRizz Backend — FastAPI Application."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.models.database import init_db
from app.routers import coach, feature_flags, generation, health, users

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown lifecycle."""
    settings = get_settings()
    logging.basicConfig(
        level=logging.DEBUG if settings.debug else logging.INFO,
        format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    )
    logger.info("Starting GigaRizz API (%s)", settings.environment)

    # Init database tables
    await init_db()
    logger.info("Database initialized")

    yield  # App runs here

    logger.info("Shutting down GigaRizz API")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="GigaRizz API",
        description="AI-powered dating photo generation and coaching backend",
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.environment != "production" else None,
        redoc_url="/redoc" if settings.environment != "production" else None,
    )

    # CORS — allow iOS app and local dev
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:3000",
            "http://localhost:8000",
            "https://gigarizz.app",
            "https://*.gigarizz.app",
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Mount routers
    app.include_router(health.router)
    app.include_router(feature_flags.router)
    app.include_router(generation.router)
    app.include_router(coach.router)
    app.include_router(users.router)

    return app


app = create_app()
