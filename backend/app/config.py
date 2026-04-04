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

    # Firebase
    firebase_project_id: str = "gigarizz-app"
    google_application_credentials: str = ""

    # Moderation
    moderation_enabled: bool = True

    # Feature Flags
    flag_enable_generation: bool = True
    flag_enable_coach: bool = True
    flag_enable_face_swap: bool = False
    flag_enable_background_replacer: bool = True
    flag_enable_expression_coach: bool = True
    flag_enable_photo_ranking: bool = True
    flag_enable_color_grade: bool = True
    flag_enable_pose_library: bool = True
    flag_enable_intro_offer: bool = True
    flag_max_free_generations: int = 3
    flag_max_plus_generations: int = 30
    flag_max_gold_generations: int = 999
    flag_show_promo_banner: bool = False
    flag_min_app_version: str = "1.0.0"

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
