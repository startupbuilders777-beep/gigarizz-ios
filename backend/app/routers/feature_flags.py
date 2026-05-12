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
        enable_intro_offer=settings.flag_enable_intro_offer,
        enable_batch_generation=settings.flag_enable_batch_generation,
        enable_premium_models=settings.flag_enable_premium_models,
        enable_photorealistic_models=settings.flag_enable_photorealistic_models,
        enable_artistic_models=settings.flag_enable_artistic_models,
        enable_face_enhance=settings.flag_enable_face_enhance,
        enable_outfit_studio=settings.flag_enable_outfit_studio,
        enable_hairstyle=settings.flag_enable_hairstyle,
        enable_age_studio=settings.flag_enable_age_studio,
        enable_pose_studio=settings.flag_enable_pose_studio,
        enable_hinge_overlay=settings.flag_enable_hinge_overlay,
        enable_nano_banana_2=settings.flag_enable_nano_banana_2,
        enable_gpt_image_2=settings.flag_enable_gpt_image_2,
        enable_instant_id=settings.flag_enable_instant_id,
        paywall_mode=settings.flag_paywall_mode,
        soft_paywall_after_uses=settings.flag_soft_paywall_after_uses,
        onboarding_enabled=settings.flag_onboarding_enabled,
        onboarding_quiz_enabled=settings.flag_onboarding_quiz_enabled,
        onboarding_skip_enabled=settings.flag_onboarding_skip_enabled,
        onboarding_max_steps=settings.flag_onboarding_max_steps,
        onboarding_show_social_proof=settings.flag_onboarding_show_social_proof,
        onboarding_show_testimonials=settings.flag_onboarding_show_testimonials,
        onboarding_show_video_demo=settings.flag_onboarding_show_video_demo,
        max_free_generations=settings.flag_max_free_generations,
        max_plus_generations=settings.flag_max_plus_generations,
        max_gold_generations=settings.flag_max_gold_generations,
        max_batch_models=settings.flag_max_batch_models,
        show_promo_banner=settings.flag_show_promo_banner,
        min_app_version=settings.flag_min_app_version,
        enable_v2_upgrade_flow=settings.flag_enable_v2_upgrade_flow,
        enable_audit_endpoint=settings.flag_enable_audit_endpoint,
        enable_screenshot_coach=settings.flag_enable_screenshot_coach,
    )
