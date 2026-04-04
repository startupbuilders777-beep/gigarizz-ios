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
    settings = get_settings()
    return GenerationService(replicate_api_token=settings.replicate_api_token)


@lru_cache()
def get_coach_service() -> CoachService:
    settings = get_settings()
    return CoachService(openai_api_key=settings.openai_api_key)


@lru_cache()
def get_storage_service() -> StorageService:
    settings = get_settings()
    return StorageService(
        bucket_name=settings.s3_bucket_name,
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        endpoint_url=settings.s3_endpoint_url,
        region_name=settings.aws_region,
    )


@lru_cache()
def get_moderation_service() -> ModerationService:
    settings = get_settings()
    return ModerationService(
        openai_api_key=settings.openai_api_key,
        enabled=settings.moderation_enabled,
    )


# --- Auth shortcut ---

CurrentUser = Depends(verify_firebase_token)
