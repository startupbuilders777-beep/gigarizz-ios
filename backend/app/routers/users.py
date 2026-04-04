"""User management endpoints."""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.middleware.auth import verify_firebase_token
from app.models.database import GenerationJob, User, UserAnalytics as UserAnalyticsDB, get_db
from app.models.schemas import UserAnalytics, UserProfile

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/users", tags=["users"])


@router.get("/me", response_model=UserProfile)
async def get_current_user(
    user: dict = Depends(verify_firebase_token),
    db: AsyncSession = Depends(get_db),
):
    """Get current user profile. Creates user record if first login."""
    result = await db.execute(select(User).where(User.id == user["uid"]))
    db_user = result.scalar_one_or_none()

    if not db_user:
        # First time — create user record
        db_user = User(
            id=user["uid"],
            email=user.get("email"),
            display_name=user.get("name"),
        )
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)

    return UserProfile(
        uid=db_user.id,
        email=db_user.email,
        display_name=db_user.display_name,
        tier=db_user.tier,
        total_generations=db_user.total_generations,
        created_at=db_user.created_at,
    )


@router.get("/me/analytics", response_model=UserAnalytics)
async def get_user_analytics(
    user: dict = Depends(verify_firebase_token),
    db: AsyncSession = Depends(get_db),
):
    """Get user analytics summary."""
    # Count generations by status
    result = await db.execute(
        select(GenerationJob).where(GenerationJob.user_id == user["uid"])
    )
    jobs = result.scalars().all()

    total = len(jobs)
    completed = sum(1 for j in jobs if j.status == "completed")
    today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0)
    today_count = sum(1 for j in jobs if j.created_at and j.created_at >= today)

    # Favorite style
    style_counts: dict[str, int] = {}
    for j in jobs:
        if j.style:
            style_counts[j.style] = style_counts.get(j.style, 0) + 1
    favorite_style = max(style_counts, key=style_counts.get) if style_counts else None

    return UserAnalytics(
        total_generations=total,
        successful_generations=completed,
        generations_today=today_count,
        favorite_style=favorite_style,
    )


@router.delete("/me", status_code=204)
async def delete_user_data(
    user: dict = Depends(verify_firebase_token),
    db: AsyncSession = Depends(get_db),
):
    """GDPR: Delete all user data."""
    uid = user["uid"]

    # Delete generation jobs
    result = await db.execute(select(GenerationJob).where(GenerationJob.user_id == uid))
    for job in result.scalars().all():
        await db.delete(job)

    # Delete analytics
    result = await db.execute(select(UserAnalyticsDB).where(UserAnalyticsDB.user_id == uid))
    for a in result.scalars().all():
        await db.delete(a)

    # Delete user
    result = await db.execute(select(User).where(User.id == uid))
    db_user = result.scalar_one_or_none()
    if db_user:
        await db.delete(db_user)

    await db.commit()
    logger.info("Deleted all data for user %s (GDPR)", uid)
