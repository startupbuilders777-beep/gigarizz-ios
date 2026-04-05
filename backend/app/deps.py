"""Dependency injection for FastAPI routes."""

from __future__ import annotations

from functools import lru_cache

from fastapi import Depends

from app.config import Settings, get_settings
from app.middleware.auth import verify_firebase_token
from app.services.coach_service import CoachService
from app.services.generation_service import GenerationService
from app.services.moderation_service import ModerationService
from app.services.storage_service import StorageService


# --- Service singletons ---


@lru_cache()
def get_generation_service() -> GenerationService:
    return GenerationService()


@lru_cache()
def get_coach_service() -> CoachService:
    return CoachService()


@lru_cache()
def get_storage_service() -> StorageService:
    return StorageService()


@lru_cache()
def get_moderation_service() -> ModerationService:
    return ModerationService()


# --- Auth shortcut ---

CurrentUser = Depends(verify_firebase_token)
