"""GigaRizz backend configuration loaded from environment variables."""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """App-wide settings pulled from .env file or environment."""

    # Server
    host: str = "0.0.0.0"
    port: int = 8000
    debug: bool = False
    environment: str = "development"

    # Database
    database_url: str = "sqlite+aiosqlite:///./gigarizz.db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # OpenAI
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"

    # Replicate
    replicate_api_token: str = ""

    # fal.ai
    fal_key: str = ""

    # S3 / R2
    s3_bucket_name: str = "gigarizz-photos"
    aws_region: str = "us-east-1"
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    s3_endpoint_url: str = ""
    local_storage_dir: str = "./data/media"
    local_public_base_url: str = "http://localhost:8000"

    # Firebase
    firebase_project_id: str = "gigarizz-app"
    google_application_credentials: str = ""

    # Moderation
    moderation_enabled: bool = True

    # Feature Flags — read from env, served from /api/v1/flags, mirrored on iOS.
    # Edit any of these in the deployed .env (or in CI env vars) and the iOS app
    # picks up the change on next refresh (1h cache TTL or app cold start).
    flag_enable_generation: bool = True
    flag_enable_coach: bool = True
    flag_enable_face_swap: bool = False
    flag_enable_background_replacer: bool = True
    flag_enable_expression_coach: bool = True
    flag_enable_photo_ranking: bool = True
    flag_enable_color_grade: bool = True
    flag_enable_pose_library: bool = True
    flag_enable_intro_offer: bool = True
    flag_enable_batch_generation: bool = True
    flag_enable_premium_models: bool = True
    flag_enable_photorealistic_models: bool = True
    flag_enable_artistic_models: bool = True
    # New SOTA features (iter 1-9)
    flag_enable_face_enhance: bool = True
    flag_enable_outfit_studio: bool = True
    flag_enable_hairstyle: bool = True
    flag_enable_age_studio: bool = True
    flag_enable_pose_studio: bool = True
    flag_enable_hinge_overlay: bool = True
    flag_enable_nano_banana_2: bool = True
    flag_enable_gpt_image_2: bool = True
    flag_enable_instant_id: bool = True
    # Paywall + onboarding strategy (server-driven)
    flag_paywall_mode: str = "soft"  # none | soft | hard
    flag_soft_paywall_after_uses: int = 3
    flag_onboarding_enabled: bool = True
    flag_onboarding_quiz_enabled: bool = True
    flag_onboarding_skip_enabled: bool = True
    flag_onboarding_max_steps: int = 30
    flag_onboarding_show_social_proof: bool = True
    flag_onboarding_show_testimonials: bool = True
    flag_onboarding_show_video_demo: bool = True
    # Quotas
    flag_max_free_generations: int = 3
    flag_max_plus_generations: int = 30
    flag_max_gold_generations: int = 999
    flag_max_batch_models: int = 4
    flag_show_promo_banner: bool = False
    flag_min_app_version: str = "1.0.0"

    # V2 Profile Upgrade flow
    flag_enable_v2_upgrade_flow: bool = True
    flag_enable_audit_endpoint: bool = True
    flag_enable_screenshot_coach: bool = True

    # Rate Limiting
    rate_limit_generation: str = "10/hour"
    rate_limit_coach: str = "30/hour"

    # Webhook
    webhook_secret: str = ""
    webhook_base_url: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
