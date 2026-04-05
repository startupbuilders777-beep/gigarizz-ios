"""Pydantic schemas for request/response models."""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


# ── Generation ──────────────────────────────────────────────────────────────


class GenerationStyle(str, Enum):
    professional = "professional"
    casual = "casual"
    adventure = "adventure"
    fitness = "fitness"
    night_out = "night_out"
    creative = "creative"
    luxury = "luxury"
    custom = "custom"


class JobStatus(str, Enum):
    queued = "queued"
    processing = "processing"
    completed = "completed"
    failed = "failed"
    cancelled = "cancelled"


class AIModelChoice(str, Enum):
    """All AI models available for photo generation."""
    flux_schnell = "flux_schnell"
    flux_dev = "flux_dev"
    flux_1_1_pro = "flux_1_1_pro"
    sdxl = "sdxl"
    sd3_medium = "sd3_medium"
    fal_flux_schnell = "fal_flux_schnell"
    fal_flux_dev = "fal_flux_dev"
    fal_flux_pro = "fal_flux_pro"
    dall_e_3 = "dall_e_3"
    gpt_image_1 = "gpt_image_1"


class GenerateRequest(BaseModel):
    style: GenerationStyle = GenerationStyle.professional
    prompt: str | None = None
    model: AIModelChoice | None = AIModelChoice.flux_schnell
    source_image_url: str | None = None
    photo_count: int = Field(default=4, ge=1, le=8)
    platform: str = "tinder"


class ModelInfo(BaseModel):
    """AI model metadata for the model picker."""
    id: str
    name: str
    provider: str
    speed: str
    quality: str
    tier: str


class GenerationJobResponse(BaseModel):
    job_id: str
    status: JobStatus
    style: str | None = None
    model: str | None = None
    progress: float = 0.0
    created_at: datetime | None = None
    completed_at: datetime | None = None
    result_urls: list[str] = []
    error: str | None = None


# ── Coach ───────────────────────────────────────────────────────────────────


class BioTone(str, Enum):
    witty = "witty"
    sincere = "sincere"
    bold = "bold"


class DatingPlatform(str, Enum):
    tinder = "tinder"
    hinge = "hinge"
    bumble = "bumble"
    raya = "raya"
    generic = "generic"


class BioRequest(BaseModel):
    interests: list[str] = Field(min_length=1, max_length=10)
    tone: BioTone = BioTone.witty
    platform: DatingPlatform = DatingPlatform.tinder
    age: int | None = None
    gender: str | None = None


class BioResponse(BaseModel):
    bio: str
    alternatives: list[str] = []
    character_count: int = 0


class OpenersRequest(BaseModel):
    profile_context: str = ""
    count: int = Field(default=5, ge=1, le=10)


class OpenersResponse(BaseModel):
    openers: list[str]


class PromptsResponse(BaseModel):
    prompts: list[PromptAnswer]


class PromptAnswer(BaseModel):
    prompt: str
    answer: str


class ReplyRequest(BaseModel):
    their_message: str
    conversation_context: list[str] = []


class ReplyResponse(BaseModel):
    replies: list[str]


# ── Feature Flags ───────────────────────────────────────────────────────────


class FeatureFlags(BaseModel):
    enable_generation: bool = True
    enable_coach: bool = True
    enable_face_swap: bool = False
    enable_background_replacer: bool = True
    enable_expression_coach: bool = True
    enable_photo_ranking: bool = True
    enable_color_grade: bool = True
    enable_pose_library: bool = True
    enable_intro_offer: bool = True
    max_free_generations: int = 3
    max_plus_generations: int = 30
    max_gold_generations: int = 999
    show_promo_banner: bool = False
    min_app_version: str = "1.0.0"


# ── Users ───────────────────────────────────────────────────────────────────


class UserProfile(BaseModel):
    uid: str
    email: str | None = None
    display_name: str | None = None
    tier: str = "free"
    total_generations: int = 0
    created_at: datetime | None = None


class UserAnalytics(BaseModel):
    total_generations: int = 0
    successful_generations: int = 0
    generations_today: int = 0
    favorite_style: str | None = None
    total_matches: int = 0
    match_rate: float = 0.0
    top_style: str = "professional"
    streak_days: int = 0
    weekly_generations: list[int] = [0, 0, 0, 0, 0, 0, 0]
    platform_breakdown: dict[str, int] = {}


# ── Health ──────────────────────────────────────────────────────────────────


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    environment: str = "development"
