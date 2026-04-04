"""Feature flag endpoints."""

from fastapi import APIRouter

from app.config import get_settings
from app.models.schemas import FeatureFlags

router = APIRouter(prefix="/api/v1/flags", tags=["feature-flags"])


@router.get("", response_model=FeatureFlags)
async def get_feature_flags():
    """Return current feature flag configuration.

    Feature flags are server-driven so we can gate features
    without pushing app updates.
    """
    settings = get_settings()
    return FeatureFlags(
        enable_generation=settings.flag_enable_generation,
        enable_coach=settings.flag_enable_coach,
        enable_face_swap=settings.flag_enable_face_swap,
        enable_background_replacer=settings.flag_enable_background_replacer,
        enable_expression_coach=settings.flag_enable_expression_coach,
        enable_photo_ranking=settings.flag_enable_photo_ranking,
        enable_color_grade=settings.flag_enable_color_grade,
        enable_pose_library=settings.flag_enable_pose_library,
        max_free_generations=settings.flag_max_free_generations,
        max_plus_generations=settings.flag_max_plus_generations,
        max_gold_generations=settings.flag_max_gold_generations,
        show_promo_banner=settings.flag_show_promo_banner,
        min_app_version=settings.flag_min_app_version,
    )
