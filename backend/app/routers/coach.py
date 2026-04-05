"""AI dating coach endpoints."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.deps import get_coach_service, get_moderation_service
from app.middleware.auth import verify_firebase_token
from app.models.schemas import (
    BioRequest,
    BioResponse,
    OpenersRequest,
    OpenersResponse,
    PromptsResponse,
    ReplyRequest,
    ReplyResponse,
)
from app.services.coach_service import CoachService
from app.services.moderation_service import ModerationService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/coach", tags=["coach"])


@router.post("/bio", response_model=BioResponse)
async def generate_bio(
    req: BioRequest,
    user: dict = Depends(verify_firebase_token),
    coach: CoachService = Depends(get_coach_service),
    mod_svc: ModerationService = Depends(get_moderation_service),
):
    """Generate an optimized dating profile bio."""
    # Moderate input
    combined_text = " ".join(req.interests)
    if combined_text.strip():
        mod_result = await mod_svc.check_text(combined_text)
        if mod_result.get("flagged"):
            raise HTTPException(status_code=400, detail="Content policy violation")

    try:
        result = await coach.generate_bio(
            interests=req.interests,
            tone=req.tone.value if req.tone else "witty",
            platform=req.platform.value if req.platform else "hinge",
            age=req.age,
            gender=req.gender,
        )
        return BioResponse(
            bio=result["bio"],
            alternatives=result.get("alternatives", []),
        )
    except Exception as e:
        logger.error("Bio generation failed: %s", e)
        raise HTTPException(status_code=500, detail="Failed to generate bio")


@router.post("/openers", response_model=OpenersResponse)
async def generate_openers(
    req: OpenersRequest,
    user: dict = Depends(verify_firebase_token),
    coach: CoachService = Depends(get_coach_service),
    mod_svc: ModerationService = Depends(get_moderation_service),
):
    """Generate conversation starters based on a profile."""
    if req.profile_context:
        mod_result = await mod_svc.check_text(req.profile_context)
        if mod_result.get("flagged"):
            raise HTTPException(status_code=400, detail="Content policy violation")

    try:
        openers = await coach.generate_openers(
            match_name="match",
            platform="generic",
            context=req.profile_context,
            count=req.count or 5,
        )
        return OpenersResponse(openers=openers)
    except Exception as e:
        logger.error("Opener generation failed: %s", e)
        raise HTTPException(status_code=500, detail="Failed to generate openers")


@router.post("/prompts", response_model=PromptsResponse)
async def generate_prompts(
    user: dict = Depends(verify_firebase_token),
    coach: CoachService = Depends(get_coach_service),
):
    """Generate Hinge-style prompt + answer pairs."""
    try:
        prompts = await coach.generate_hinge_prompts()
        return PromptsResponse(prompts=prompts)
    except Exception as e:
        logger.error("Prompt generation failed: %s", e)
        raise HTTPException(status_code=500, detail="Failed to generate prompts")


@router.post("/reply", response_model=ReplyResponse)
async def suggest_reply(
    req: ReplyRequest,
    user: dict = Depends(verify_firebase_token),
    coach: CoachService = Depends(get_coach_service),
    mod_svc: ModerationService = Depends(get_moderation_service),
):
    """Suggest replies to a conversation."""
    combined = " ".join(req.conversation_context)
    if combined.strip():
        mod_result = await mod_svc.check_text(combined)
        if mod_result.get("flagged"):
            raise HTTPException(status_code=400, detail="Content policy violation")

    try:
        replies = await coach.suggest_replies(
            message=req.their_message,
            match_name="match",
            conversation_context=" | ".join(req.conversation_context) if req.conversation_context else None,
        )
        return ReplyResponse(replies=replies)
    except Exception as e:
        logger.error("Reply suggestion failed: %s", e)
        raise HTTPException(status_code=500, detail="Failed to suggest replies")
