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
    # Hinge-mode prompt-overlay templates — leverage GPT Image 2's text rendering.
    hinge_prompt = "hinge_prompt"
    hinge_caption = "hinge_caption"
    hinge_chemistry = "hinge_chemistry"
    # Identity-preserving wardrobe / hair / age swaps — pair with Nano Banana 2.
    outfit_swap = "outfit_swap"
    hairstyle_swap = "hairstyle_swap"
    age_modify = "age_modify"
    # V3 Sprint 1 — Face Refine Studio. Each routes to GPT Image 2 / Nano Banana 2
    # with identity-preserving wrappers. The naturalness slider gates intensity;
    # FaceCheck Pre-Flight on the client rejects outputs that fail drift checks.
    smile_enhance = "smile_enhance"
    add_smile = "add_smile"
    jaw_refine = "jaw_refine"
    nose_refine = "nose_refine"
    lip_enhance = "lip_enhance"
    eye_color_swap = "eye_color_swap"
    ai_portrait = "ai_portrait"
    # V3 Sprint 2 — Scene catalog. High-impact dating environments designed to
    # outclass ReGen's preset library. Each preserves identity exactly; only the
    # environment, outfit, and lighting change. Routed via Nano Banana 2 / GPT
    # Image 2 for identity lock + scene fidelity.
    scene_helicopter = "scene_helicopter"
    scene_movie_theatre = "scene_movie_theatre"
    scene_rooftop_bar = "scene_rooftop_bar"
    scene_art_gallery = "scene_art_gallery"
    scene_coffee_shop = "scene_coffee_shop"
    scene_concert = "scene_concert"
    scene_yacht_deck = "scene_yacht_deck"
    scene_ski_lift = "scene_ski_lift"
    scene_tokyo_street = "scene_tokyo_street"
    scene_italian_cafe = "scene_italian_cafe"
    scene_recording_studio = "scene_recording_studio"
    scene_motorcycle = "scene_motorcycle"
    scene_private_jet = "scene_private_jet"
    # V3 Sprint 4 — additional environments. All use the same identity-lock
    # contract; intent is to widen the catalog ReGen has to compete against.
    scene_gym = "scene_gym"
    scene_sailing_race = "scene_sailing_race"
    scene_sushi_bar = "scene_sushi_bar"
    scene_vineyard = "scene_vineyard"
    scene_observation_deck = "scene_observation_deck"
    scene_dog_park = "scene_dog_park"
    scene_golf_course = "scene_golf_course"
    scene_dance_studio = "scene_dance_studio"
    # V3 Sprint 7 — additional environments. Push catalog past 25 to make
    # ReGen's preset library look thin.
    scene_rooftop_pool = "scene_rooftop_pool"
    scene_ramen_shop = "scene_ramen_shop"
    scene_library = "scene_library"
    scene_museum = "scene_museum"
    scene_beach_sunset = "scene_beach_sunset"
    scene_boxing_gym = "scene_boxing_gym"
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
    flux_1_1_pro_ultra = "flux_1_1_pro_ultra"
    sdxl = "sdxl"
    sd3_medium = "sd3_medium"
    realvis_xl = "realvis_xl"
    playground_v3 = "playground_v3"
    ideogram_3 = "ideogram_3"
    instant_id = "instant_id"
    face_restore = "face_restore"
    fal_flux_schnell = "fal_flux_schnell"
    fal_flux_dev = "fal_flux_dev"
    fal_flux_pro = "fal_flux_pro"
    fal_sdxl_lightning = "fal_sdxl_lightning"
    fal_recraft_v3 = "fal_recraft_v3"
    nano_banana_2 = "nano_banana_2"
    dall_e_3 = "dall_e_3"
    gpt_image_1 = "gpt_image_1"
    gpt_image_2 = "gpt_image_2"


class GenerateRequest(BaseModel):
    style: GenerationStyle = GenerationStyle.professional
    prompt: str | None = None
    model: AIModelChoice | None = AIModelChoice.gpt_image_2
    source_image_url: str | None = None
    source_image_urls: list[str] = Field(default_factory=list, max_length=8)
    # Optional pose-reference image for InstantID. When set, the model
    # locks the user's face from `source_image_url` onto the pose/composition
    # of `pose_image_url`. Enables "put me in this exact photo" flows.
    pose_image_url: str | None = None
    photo_count: int = Field(default=4, ge=1, le=8)
    platform: str = "tinder"
    # Trust toggle. When true, every generation prompt is wrapped with strong
    # identity-preservation language so the result still looks like the user,
    # not a fashion-model-pretending-to-be-them. Default true so new users get
    # the safer behavior; advanced users can flip off in iOS Settings.
    keep_me_natural: bool = True
    # V3 naturalness intensity (0–100). When present, swaps the prompt wrapper
    # to a Conservative (<=40) / Standard (41–70) / Bold (71+) variant.
    # When None, the legacy default wrapper is used.
    naturalness_intensity: int | None = Field(default=None, ge=0, le=100)


class ModelInfo(BaseModel):
    """AI model metadata for the model picker."""
    id: str
    name: str
    provider: str
    speed: str
    quality: str
    tier: str
    category: str = "classic"


class BatchGenerateRequest(BaseModel):
    """Generate photos across multiple models simultaneously."""
    style: GenerationStyle = GenerationStyle.professional
    prompt: str | None = None
    models: list[AIModelChoice] = Field(min_length=1, max_length=6)
    source_image_url: str | None = None
    source_image_urls: list[str] = Field(default_factory=list, max_length=8)
    photo_count: int = Field(default=2, ge=1, le=4)
    platform: str = "tinder"


class BatchGenerationResponse(BaseModel):
    """Response containing all jobs from a batch generation."""
    batch_id: str
    jobs: list[GenerationJobResponse]
    total_models: int


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
    # ── Core surfaces ─────────────────────────────────────────────────────
    enable_generation: bool = True
    enable_coach: bool = True
    enable_face_swap: bool = False
    enable_background_replacer: bool = True
    enable_expression_coach: bool = True
    enable_photo_ranking: bool = True
    enable_color_grade: bool = True
    enable_pose_library: bool = True
    enable_intro_offer: bool = True
    enable_batch_generation: bool = True
    enable_premium_models: bool = True
    enable_photorealistic_models: bool = True
    enable_artistic_models: bool = True

    # ── New SOTA features (iter 1-9) ───────────────────────────────────────
    enable_face_enhance: bool = True       # Anti-plastic CodeFormer
    enable_outfit_studio: bool = True      # Nano Banana 2 outfit swap
    enable_hairstyle: bool = True          # Nano Banana 2 hairstyle try-on
    enable_age_studio: bool = True         # Nano Banana 2 age slider
    enable_pose_studio: bool = True        # InstantID any-pose generator
    enable_hinge_overlay: bool = True      # GPT Image 2 prompt-overlay presets
    enable_nano_banana_2: bool = True      # Surface model in picker
    enable_gpt_image_2: bool = True        # Surface model in picker
    enable_instant_id: bool = True         # Surface model in picker

    # ── Paywall strategy ───────────────────────────────────────────────────
    # "none" = no paywall (everything free)
    # "soft" = paywall after N free uses, dismissible
    # "hard" = paywall on first launch after onboarding, not dismissible
    paywall_mode: str = "soft"
    soft_paywall_after_uses: int = 3       # Trigger soft paywall on Nth use

    # ── Onboarding ─────────────────────────────────────────────────────────
    onboarding_enabled: bool = True
    onboarding_quiz_enabled: bool = True   # Personality / style quiz
    onboarding_skip_enabled: bool = True   # Show "Skip" button
    onboarding_max_steps: int = 30         # Cap the 30-step luxury flow
    onboarding_show_social_proof: bool = True
    onboarding_show_testimonials: bool = True
    onboarding_show_video_demo: bool = True

    # ── Quotas ─────────────────────────────────────────────────────────────
    max_free_generations: int = 3
    max_plus_generations: int = 30
    max_gold_generations: int = 999
    max_batch_models: int = 4

    # ── V2 Profile Upgrade flow ─────────────────────────────────────────────
    # When ON, iOS shows the new Upgrade tab (audit-first flow) and hides V1 tools-hub.
    # When OFF, iOS keeps the existing tab structure. Lets us A/B real users.
    enable_v2_upgrade_flow: bool = False
    enable_audit_endpoint: bool = True
    # Screenshot Coach (V2 Sprint 5) — paste a profile/chat screenshot and get
    # OCR-driven openers + reply suggestions. iOS-only Vision OCR, no new
    # backend endpoint, just toggles the surface.
    enable_screenshot_coach: bool = True

    # ── Misc ───────────────────────────────────────────────────────────────
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


# ── Uploads ─────────────────────────────────────────────────────────────────


class UploadPurpose(str, Enum):
    """Why the iOS client is uploading a photo."""
    source = "source"      # source selfie that the AI provider should pull from
    result = "result"      # finished photo the user wants to back up
    avatar = "avatar"      # profile avatar


class UploadPresignRequest(BaseModel):
    """Request a presigned upload URL for a user photo."""
    content_type: str = "image/jpeg"
    purpose: UploadPurpose = UploadPurpose.source


class UploadPresignResponse(BaseModel):
    """Presigned upload URL + the public URL the backend will pass to AI providers."""
    upload_url: str
    public_url: str
    key: str
    expires_in: int = 3600


# ── Profile Audit + ProfileKit (V2) ─────────────────────────────────────────


class PhotoArchetype(str, Enum):
    """The slot a dating photo fills in a complete profile."""
    first_photo = "first_photo"
    casual_candid = "casual_candid"
    dressed_up = "dressed_up"
    hobby_activity = "hobby_activity"
    travel_lifestyle = "travel_lifestyle"
    social_proof = "social_proof"
    full_body = "full_body"


class PhotoCritique(BaseModel):
    """Per-photo audit scores + qualitative notes."""
    photo_url: str
    photo_index: int
    clarity: int = Field(ge=0, le=10)
    lighting: int = Field(ge=0, le=10)
    expression: int = Field(ge=0, le=10)
    crop: int = Field(ge=0, le=10)
    authenticity: int = Field(ge=0, le=10)
    platform_fit: int = Field(ge=0, le=10)
    overall: int = Field(ge=0, le=10)
    archetype: PhotoArchetype | None = None
    issues: list[str] = []      # short bullets describing what's hurting this photo
    strengths: list[str] = []   # what's working


class ProfileFix(BaseModel):
    """A concrete recommendation for the user to act on."""
    title: str
    detail: str
    target_archetype: PhotoArchetype | None = None
    suggested_style: GenerationStyle | None = None


class ProfileAuditResult(BaseModel):
    """Set-level audit produced by the audit service."""
    overall_score: int = Field(ge=0, le=100)
    summary: str
    best_photo_index: int
    weakest_photo_index: int
    missing_archetypes: list[PhotoArchetype] = []
    top_fixes: list[ProfileFix] = []
    per_photo: list[PhotoCritique] = []
    target_platforms: list[DatingPlatform] = []
    created_at: datetime | None = None


class AuditRequest(BaseModel):
    """Run a profile audit on a set of uploaded photos."""
    photo_urls: list[str] = Field(min_length=1, max_length=12)
    target_platforms: list[DatingPlatform] = []
    # V3 Sprint 8 — Roast Mode toggle. When true, swaps the audit voice from
    # the supportive coach default to a brutally honest mentor. Counter to
    # Roast.dating's "roasted by humans" hook; same engine, attitude swap.
    roast_mode: bool = False


class MissingPhotoSlot(BaseModel):
    """A profile slot that needs to be generated."""
    archetype: PhotoArchetype
    title: str
    why_it_matters: str
    suggested_style: GenerationStyle


class PromptKitItem(BaseModel):
    """A platform-specific prompt or bio entry inside a ProfileKit."""
    platform: DatingPlatform
    label: str           # e.g. "Bio", "Hinge Prompt: A life goal of mine"
    content: str


class ProfileKit(BaseModel):
    """The hero artifact of the V2 flow — a complete, exportable dating profile."""
    id: str
    user_id: str
    # The user's stated reason for using GigaRizz. Codex's V2 plan calls this
    # out as the literal first question (Step 0 of the upgrade flow). Free-form
    # string so iOS can extend the option set without backend redeploys.
    primary_goal: str | None = None
    target_platforms: list[DatingPlatform] = []
    audit: ProfileAuditResult | None = None
    current_photo_urls: list[str] = []
    generated_photo_urls: list[str] = []
    recommended_order_hinge: list[int] = []      # indices into current+generated
    recommended_order_tinder: list[int] = []
    recommended_order_bumble: list[int] = []
    bio: str | None = None
    prompts: list[PromptKitItem] = []
    openers: list[str] = []
    created_at: datetime | None = None
    updated_at: datetime | None = None


# ── Health ──────────────────────────────────────────────────────────────────


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    environment: str = "development"
