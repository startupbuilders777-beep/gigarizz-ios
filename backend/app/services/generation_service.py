"""Photo generation service — multi-model engine supporting Replicate, fal.ai, and OpenAI."""

from __future__ import annotations

import base64
import logging
from datetime import datetime, timezone
from enum import Enum

import httpx
from nanoid import generate as nanoid

from app.config import get_settings
from app.services.storage_service import StorageService

logger = logging.getLogger(__name__)


# ── Supported Models ────────────────────────────────────────────────────────


class AIModel(str, Enum):
    """All generation models the backend can route to."""

    # Replicate — Black Forest Labs Flux family
    FLUX_SCHNELL = "flux_schnell"           # Fast, good quality (default)
    FLUX_DEV = "flux_dev"                   # Higher quality, slower
    FLUX_1_1_PRO = "flux_1_1_pro"           # Best quality Flux
    FLUX_1_1_PRO_ULTRA = "flux_1_1_pro_ultra"  # Ultra-high-res Flux

    # Replicate — Stability AI
    SDXL = "sdxl"                           # Stable Diffusion XL
    SD3_MEDIUM = "sd3_medium"               # Stable Diffusion 3

    # Replicate — Photorealistic specialists
    REALVIS_XL = "realvis_xl"               # RealVisXL — hyper-photorealistic
    PLAYGROUND_V3 = "playground_v3"         # Playground v3 — artistic + real
    IDEOGRAM_3 = "ideogram_3"              # Ideogram 3 — text + photorealism

    # Replicate — Identity-preserving
    INSTANT_ID = "instant_id"               # InstantID — single-image identity lock with style control

    # Replicate — Face restoration (Facetune-grade enhancement)
    FACE_RESTORE = "face_restore"           # CodeFormer — texture-preserving face restoration + upscale

    # fal.ai — fast inference (NanoBanana-compatible)
    FAL_FLUX_SCHNELL = "fal_flux_schnell"   # Flux Schnell via fal.ai (fastest)
    FAL_FLUX_DEV = "fal_flux_dev"           # Flux Dev via fal.ai
    FAL_FLUX_PRO = "fal_flux_pro"           # Flux Pro via fal.ai
    FAL_SDXL_LIGHTNING = "fal_sdxl_lightning"  # SDXL Lightning — 4-step ultra-fast
    FAL_RECRAFT_V3 = "fal_recraft_v3"       # Recraft V3 — design-quality photos

    # fal.ai — Google Gemini (Nano Banana 2)
    NANO_BANANA_2 = "nano_banana_2"         # Gemini 3.1 Flash Image — locks 5 identities, native 4K

    # OpenAI
    DALL_E_3 = "dall_e_3"                   # DALL-E 3
    GPT_IMAGE_1 = "gpt_image_1"            # GPT Image 1
    GPT_IMAGE_2 = "gpt_image_2"            # GPT Image 2 — agentic edits, premium tier


# Replicate model identifiers
REPLICATE_MODELS: dict[str, str] = {
    AIModel.FLUX_SCHNELL: "black-forest-labs/flux-schnell",
    AIModel.FLUX_DEV: "black-forest-labs/flux-dev",
    AIModel.FLUX_1_1_PRO: "black-forest-labs/flux-1.1-pro",
    AIModel.FLUX_1_1_PRO_ULTRA: "black-forest-labs/flux-1.1-pro-ultra",
    AIModel.SDXL: "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
    AIModel.SD3_MEDIUM: "stability-ai/stable-diffusion-3-medium",
    AIModel.REALVIS_XL: "adirik/realvisxl-v3.0-turbo:1577d0dac4482a46b48c5d3befc6ec1e",
    AIModel.PLAYGROUND_V3: "playgroundai/playground-v2.5-1024px-aesthetic:a45f82a1382bed5c7aeb861dac7c7d191b0fdf74d8d57c4a0e6ed7d4d0bf7d24",
    AIModel.IDEOGRAM_3: "ideogram-ai/ideogram-v2-turbo",
    AIModel.INSTANT_ID: "zsxkib/instant-id-ipadapter-plus-face",
    AIModel.FACE_RESTORE: "sczhou/codeformer:cc4956dd26fa5a7185d5660cc9100fab1b76b4ab8b14e2ed9c89c19b06ad0c20",
}

# fal.ai model identifiers
FAL_MODELS: dict[str, str] = {
    AIModel.FAL_FLUX_SCHNELL: "fal-ai/flux/schnell",
    AIModel.FAL_FLUX_DEV: "fal-ai/flux/dev",
    AIModel.FAL_FLUX_PRO: "fal-ai/flux-pro",
    AIModel.FAL_SDXL_LIGHTNING: "fal-ai/fast-sdxl",
    AIModel.FAL_RECRAFT_V3: "fal-ai/recraft-v3",
    AIModel.NANO_BANANA_2: "fal-ai/gemini-3.1-flash-image-preview",
}

# OpenAI model identifiers
OPENAI_MODELS: dict[str, str] = {
    AIModel.DALL_E_3: "dall-e-3",
    AIModel.GPT_IMAGE_1: "gpt-image-1",
    AIModel.GPT_IMAGE_2: "gpt-image-2",
}

# Human-readable info for the iOS model picker — grouped by category
MODEL_CATALOG: list[dict] = [
    # --- Free tier ---
    {"id": "flux_schnell", "name": "Flux Schnell", "provider": "replicate", "speed": "fast", "quality": "good", "tier": "free", "category": "fast"},
    {"id": "sdxl", "name": "SDXL", "provider": "replicate", "speed": "medium", "quality": "good", "tier": "free", "category": "classic"},
    {"id": "fal_flux_schnell", "name": "Flux Schnell (fal)", "provider": "fal", "speed": "fastest", "quality": "good", "tier": "free", "category": "fast"},
    {"id": "fal_sdxl_lightning", "name": "SDXL Lightning", "provider": "fal", "speed": "fastest", "quality": "good", "tier": "free", "category": "fast"},
    # --- Plus tier ---
    {"id": "flux_dev", "name": "Flux Dev", "provider": "replicate", "speed": "medium", "quality": "high", "tier": "plus", "category": "balanced"},
    {"id": "sd3_medium", "name": "SD3 Medium", "provider": "replicate", "speed": "medium", "quality": "high", "tier": "plus", "category": "classic"},
    {"id": "fal_flux_dev", "name": "Flux Dev (fal)", "provider": "fal", "speed": "fast", "quality": "high", "tier": "plus", "category": "balanced"},
    {"id": "fal_recraft_v3", "name": "Recraft V3", "provider": "fal", "speed": "fast", "quality": "high", "tier": "plus", "category": "artistic"},
    {"id": "dall_e_3", "name": "DALL-E 3", "provider": "openai", "speed": "medium", "quality": "high", "tier": "plus", "category": "classic"},
    {"id": "playground_v3", "name": "Playground v3", "provider": "replicate", "speed": "medium", "quality": "high", "tier": "plus", "category": "artistic"},
    {"id": "instant_id", "name": "InstantID", "provider": "replicate", "speed": "medium", "quality": "high", "tier": "plus", "category": "photorealistic"},
    {"id": "face_restore", "name": "Face Restore", "provider": "replicate", "speed": "fast", "quality": "high", "tier": "plus", "category": "photorealistic"},
    # --- Gold tier ---
    {"id": "flux_1_1_pro", "name": "Flux 1.1 Pro", "provider": "replicate", "speed": "medium", "quality": "best", "tier": "gold", "category": "premium"},
    {"id": "flux_1_1_pro_ultra", "name": "Flux Pro Ultra", "provider": "replicate", "speed": "slow", "quality": "ultra", "tier": "gold", "category": "premium"},
    {"id": "fal_flux_pro", "name": "Flux Pro (fal)", "provider": "fal", "speed": "fast", "quality": "best", "tier": "gold", "category": "premium"},
    {"id": "realvis_xl", "name": "RealVisXL", "provider": "replicate", "speed": "medium", "quality": "best", "tier": "gold", "category": "photorealistic"},
    {"id": "ideogram_3", "name": "Ideogram 3", "provider": "replicate", "speed": "medium", "quality": "best", "tier": "gold", "category": "photorealistic"},
    {"id": "gpt_image_1", "name": "GPT Image 1", "provider": "openai", "speed": "medium", "quality": "best", "tier": "gold", "category": "premium"},
    {"id": "nano_banana_2", "name": "Nano Banana 2", "provider": "fal", "speed": "fast", "quality": "ultra", "tier": "gold", "category": "premium"},
    {"id": "gpt_image_2", "name": "GPT Image 2", "provider": "openai", "speed": "medium", "quality": "ultra", "tier": "gold", "category": "premium"},
]

# Wrapper applied when keep_me_natural=True (the V2 trust default).
# Prefixes/suffixes the existing style prompt with strong identity-preservation
# language so providers (Nano Banana 2, InstantID, Flux) keep facial features,
# skin texture, age, and ethnicity from the source photo instead of drifting.
_NATURAL_PREFIX = (
    "Photorealistic, true-to-life portrait. Preserve the person's exact facial "
    "features, skin texture, age, ethnicity, and natural body proportions from "
    "the source photo. No plastic skin, no over-smoothing, no fashion-model drift. "
)
_NATURAL_SUFFIX = (
    " The result must read as the same real person, not an idealized version."
)


def _wrap_natural(prompt: str) -> str:
    """Apply identity-preservation wrapping to a style prompt.

    Idempotent — calling twice doesn't double-wrap. Pure function so unit tests
    can verify the wrap survives both string templates and the {subject} swap.
    """
    if _NATURAL_PREFIX in prompt:
        return prompt
    return _NATURAL_PREFIX + prompt + _NATURAL_SUFFIX


# Style prompt templates for dating photos
STYLE_PROMPTS: dict[str, str] = {
    "professional": (
        "Professional headshot photo of {subject}, wearing business casual clothing, "
        "modern office or studio background, perfect studio lighting, sharp focus, "
        "confident natural smile, Canon EOS R5, 85mm f/1.4 lens, 8k, photorealistic"
    ),
    "casual": (
        "Casual lifestyle photo of {subject}, relaxed and natural pose, outdoor "
        "golden hour lighting, urban park or café background, warm color grading, "
        "genuine smile, Sony A7IV, 50mm f/1.8, shallow depth of field, photorealistic"
    ),
    "adventure": (
        "Adventure travel photo of {subject}, outdoor hiking or exploring, "
        "dramatic natural landscape, golden hour, wind in hair, confident expression, "
        "GoPro Hero 12, wide angle, vibrant colors, photorealistic"
    ),
    "fitness": (
        "Athletic lifestyle photo of {subject}, fit and healthy appearance, "
        "gym or outdoor workout setting, dynamic lighting, confident pose, "
        "Nike/athletic wear, iPhone 16 Pro, natural light, photorealistic"
    ),
    "night_out": (
        "Night out photo of {subject}, stylish evening attire, upscale bar or "
        "restaurant, warm ambient lighting, charismatic smile, "
        "bokeh background lights, Fujifilm X-T5, 35mm f/1.4, photorealistic"
    ),
    "creative": (
        "Creative artistic portrait of {subject}, studio or gallery setting, "
        "dramatic lighting, artistic composition, expressive pose, "
        "Hasselblad X2D, 90mm lens, editorial style, photorealistic"
    ),
    "luxury": (
        "Luxury lifestyle photo of {subject}, designer clothing, high-end setting "
        "like yacht, rooftop, or luxury hotel, confident expression, "
        "professional photography, Phase One IQ4, cinematic color grading, photorealistic"
    ),

    # Hinge-mode prompt-overlay templates — best paired with gpt_image_2 (its strength is
    # rendering crisp legible typography on top of photo composition).
    "hinge_prompt": (
        "Editorial portrait of {subject}, warm cinematic lighting, soft bokeh background, "
        "with the Hinge-style prompt text 'I'll fall for you if...' rendered in clean "
        "white sans-serif overlay in the lower-left third, photorealistic, vertical 3:4"
    ),
    "hinge_caption": (
        "Magazine-style portrait of {subject}, golden hour, candid expression, "
        "with the caption 'My ideal Sunday in 3 emojis' rendered in elegant white serif "
        "centered below the subject, photorealistic, vertical 3:4"
    ),
    "hinge_chemistry": (
        "Confident portrait of {subject}, modern minimal setting, natural smile, "
        "with the prompt 'Two truths and a lie' rendered as a small white tag in the "
        "upper-right corner, photorealistic, vertical 3:4"
    ),

    # Identity-preserving wardrobe / hair swaps — pair with nano_banana_2.
    # The iOS client appends a specific outfit description; this template is the
    # fallback when the client doesn't override custom_prompt.
    "outfit_swap": (
        "Same person as the reference photo, same face, same pose, same background. "
        "Change ONLY the clothing to a clean, photogenic dating-profile outfit. "
        "Photorealistic, vertical 3:4."
    ),
    "hairstyle_swap": (
        "Same person as the reference photo, same face, same expression, same background. "
        "Change ONLY the hairstyle to a clean, photogenic dating-profile look. "
        "Photorealistic, vertical 3:4."
    ),
    "age_modify": (
        "Same person as the reference photo, same identity. Adjust the apparent age "
        "while preserving facial bone structure, eye color, and natural expression. "
        "Realistic skin texture, no over-smoothing. Photorealistic, vertical 3:4."
    ),
}


class GenerationService:
    """Multi-model photo generation engine.

    Routes requests to Replicate, fal.ai, or OpenAI based on the selected model.
    """

    def __init__(self):
        self.settings = get_settings()
        self.storage = StorageService()

        # Replicate client
        self.replicate = httpx.AsyncClient(
            base_url="https://api.replicate.com/v1",
            headers={
                "Authorization": f"Bearer {self.settings.replicate_api_token}",
                "Content-Type": "application/json",
                "Prefer": "respond-async",
            },
            timeout=60.0,
        )

        # fal.ai client
        self.fal = httpx.AsyncClient(
            base_url="https://queue.fal.run",
            headers={
                "Authorization": f"Key {self.settings.fal_key}",
                "Content-Type": "application/json",
            },
            timeout=60.0,
        )

        # OpenAI client
        self.openai = httpx.AsyncClient(
            base_url="https://api.openai.com/v1",
            headers={
                "Authorization": f"Bearer {self.settings.openai_api_key}",
            },
            timeout=120.0,
        )

    # ── Public API ──────────────────────────────────────────────────────

    async def create_prediction(
        self,
        job_id: str,
        style: str,
        source_image_urls: list[str],
        photo_count: int = 4,
        custom_prompt: str | None = None,
        webhook_url: str | None = None,
        model: str | None = None,
        pose_image_url: str | None = None,
        keep_me_natural: bool = True,
    ) -> str:
        """Create a prediction using the requested model (or default).

        Returns a provider-specific prediction/request ID.
        """
        model_key = model or AIModel.FLUX_SCHNELL
        prompt = custom_prompt or STYLE_PROMPTS.get(style, STYLE_PROMPTS["professional"])
        prompt = prompt.replace("{subject}", "a person")
        if keep_me_natural:
            prompt = _wrap_natural(prompt)

        # Route to the correct provider
        if model_key in FAL_MODELS:
            return await self._create_fal(job_id, model_key, prompt, source_image_urls, photo_count)
        elif model_key in OPENAI_MODELS:
            return await self._create_openai(job_id, model_key, prompt, source_image_urls, photo_count)
        else:
            # Default: Replicate
            return await self._create_replicate(
                job_id, model_key, prompt, source_image_urls, photo_count, webhook_url,
                pose_image_url=pose_image_url,
            )

    async def check_prediction(self, prediction_id: str, model: str | None = None) -> dict:
        """Poll a prediction for status. Routes to correct provider."""
        model_key = model or AIModel.FLUX_SCHNELL

        if model_key in FAL_MODELS:
            return await self._check_fal(prediction_id, model_key)
        elif model_key in OPENAI_MODELS:
            # OpenAI is synchronous — we stored results at creation time
            return {"status": "succeeded", "id": prediction_id}
        else:
            return await self._check_replicate(prediction_id)

    async def cancel_prediction(self, prediction_id: str, model: str | None = None) -> None:
        """Cancel an in-progress prediction."""
        model_key = model or AIModel.FLUX_SCHNELL

        if model_key in FAL_MODELS:
            try:
                fal_model = FAL_MODELS[model_key]
                await self.fal.put(f"/{fal_model}/requests/{prediction_id}/cancel")
            except httpx.HTTPError:
                logger.warning("Failed to cancel fal.ai request %s", prediction_id)
        elif model_key not in OPENAI_MODELS:
            try:
                await self.replicate.post(f"/predictions/{prediction_id}/cancel")
            except httpx.HTTPError:
                logger.warning("Failed to cancel Replicate prediction %s", prediction_id)

    def generate_job_id(self) -> str:
        """Generate a URL-safe nanoid for job identification."""
        return nanoid(size=21)

    # ── Replicate Provider ──────────────────────────────────────────────

    async def _create_replicate(
        self, job_id: str, model_key: str, prompt: str,
        source_image_urls: list[str], photo_count: int,
        webhook_url: str | None,
        pose_image_url: str | None = None,
    ) -> str:
        replicate_model = REPLICATE_MODELS.get(model_key, REPLICATE_MODELS[AIModel.FLUX_SCHNELL])

        # InstantID requires a face reference image and uses a different param schema.
        if model_key == AIModel.INSTANT_ID:
            if not source_image_urls:
                raise ValueError("InstantID requires at least one source face image")
            payload: dict = {
                "input": {
                    "image": source_image_urls[0],
                    "prompt": prompt,
                    "negative_prompt": "low quality, blurry, deformed, plastic skin",
                    "num_outputs": min(photo_count, 4),
                    "guidance_scale": 5.0,
                    "ip_adapter_scale": 0.8,
                    "controlnet_conditioning_scale": 0.8,
                    "output_format": "webp",
                    "output_quality": 90,
                },
            }
            # Optional pose reference — locks the user's face from `image` onto the
            # pose/composition of this second photo. Closes the "put me in this
            # exact photo" use case.
            if pose_image_url:
                payload["input"]["pose_image"] = pose_image_url
        elif model_key == AIModel.FACE_RESTORE:
            if not source_image_urls:
                raise ValueError("Face Restore requires at least one source image")
            # CodeFormer: codeformer_fidelity 0.0 = max enhancement, 1.0 = identity-locked.
            # 0.7 is the Facetune-comparable sweet spot — clean skin without losing identity.
            payload = {
                "input": {
                    "image": source_image_urls[0],
                    "codeformer_fidelity": 0.7,
                    "background_enhance": True,
                    "face_upsample": True,
                    "upscale": 2,
                },
            }
        else:
            payload = {
                "input": {
                    "prompt": prompt,
                    "num_outputs": min(photo_count, 4),
                    "aspect_ratio": "3:4",
                    "output_format": "webp",
                    "output_quality": 90,
                    "go_fast": True,
                },
            }
            if source_image_urls:
                payload["input"]["image"] = source_image_urls[0]

        if webhook_url:
            payload["webhook"] = webhook_url
            payload["webhook_events_filter"] = ["completed"]

        response = await self.replicate.post(f"/models/{replicate_model}/predictions", json=payload)
        response.raise_for_status()
        data = response.json()
        prediction_id = data.get("id", "")
        logger.info("Replicate prediction %s for job %s (model=%s)", prediction_id, job_id, model_key)
        return prediction_id

    async def _check_replicate(self, prediction_id: str) -> dict:
        response = await self.replicate.get(f"/predictions/{prediction_id}")
        response.raise_for_status()
        return response.json()

    # ── fal.ai Provider ─────────────────────────────────────────────────

    async def _create_fal(
        self, job_id: str, model_key: str, prompt: str,
        source_image_urls: list[str], photo_count: int,
    ) -> str:
        fal_model = FAL_MODELS[model_key]

        # Nano Banana 2 (Gemini 3.1 Flash Image) takes image_urls (list, up to 5 identities)
        # and emits 4K output; payload shape differs from the Flux/SDXL family.
        if model_key == AIModel.NANO_BANANA_2:
            payload: dict = {
                "prompt": prompt,
                "num_images": min(photo_count, 4),
                "output_format": "jpeg",
                "aspect_ratio": "3:4",
            }
            if source_image_urls:
                payload["image_urls"] = source_image_urls[:5]
        else:
            payload = {
                "prompt": prompt,
                "num_images": min(photo_count, 4),
                "image_size": {"width": 768, "height": 1024},  # 3:4 portrait
                "output_format": "jpeg",
                "enable_safety_checker": True,
            }
            if source_image_urls:
                payload["image_url"] = source_image_urls[0]

        response = await self.fal.post(f"/{fal_model}", json=payload)
        response.raise_for_status()
        data = response.json()
        request_id = data.get("request_id", "")
        logger.info("fal.ai request %s for job %s (model=%s)", request_id, job_id, model_key)
        return request_id

    async def _check_fal(self, request_id: str, model_key: str) -> dict:
        fal_model = FAL_MODELS[model_key]
        response = await self.fal.get(f"/{fal_model}/requests/{request_id}/status")
        response.raise_for_status()
        data = response.json()

        fal_status = data.get("status", "")

        if fal_status == "COMPLETED":
            # Fetch the actual result
            result_resp = await self.fal.get(f"/{fal_model}/requests/{request_id}")
            result_resp.raise_for_status()
            result = result_resp.json()
            images = result.get("images", [])
            urls = [img.get("url", "") for img in images if img.get("url")]
            return {"status": "succeeded", "output": urls, "id": request_id}
        elif fal_status == "FAILED":
            return {"status": "failed", "error": data.get("error", "fal.ai generation failed"), "id": request_id}
        elif fal_status == "IN_QUEUE":
            queue_pos = data.get("queue_position", 0)
            return {"status": "processing", "logs": f"Queue position: {queue_pos}", "id": request_id}
        else:
            return {"status": "processing", "id": request_id}

    # ── OpenAI Provider ─────────────────────────────────────────────────

    async def _create_openai(
        self, job_id: str, model_key: str, prompt: str,
        source_image_urls: list[str], photo_count: int,
    ) -> str:
        """OpenAI image generation is synchronous — returns results immediately."""
        openai_model = OPENAI_MODELS[model_key]

        if openai_model.startswith("gpt-image"):
            common = {
                "model": openai_model,
                "prompt": prompt,
                "n": str(min(photo_count, 4)),
                "size": "1024x1536",
                "quality": "high",
                "output_format": "jpeg",
                "output_compression": "90",
            }
            source_files = await self._openai_source_files(source_image_urls)
            if source_files:
                response = await self.openai.post("/images/edits", data=common, files=source_files)
            else:
                payload = {**common, "n": int(common["n"]), "output_compression": 90}
                response = await self.openai.post("/images/generations", json=payload)
        else:
            # DALL-E 3
            payload = {
                "model": "dall-e-3",
                "prompt": prompt,
                "n": 1,  # DALL-E 3 only supports n=1
                "size": "1024x1792",  # Portrait
                "quality": "hd",
                "style": "natural",
            }
            response = await self.openai.post("/images/generations", json=payload)

        response.raise_for_status()
        data = response.json()

        urls = self._store_openai_images(job_id, data)

        # For OpenAI we return a synthetic ID — the results are already available
        synthetic_id = f"openai_{nanoid(size=12)}"
        # We'll store results via the caller since OpenAI is synchronous
        logger.info("OpenAI generation %s for job %s (model=%s), got %d images",
                     synthetic_id, job_id, model_key, len(urls))
        # Stash URLs on the instance so the router can grab them
        self._openai_results[synthetic_id] = urls
        return synthetic_id

    async def _openai_source_files(self, source_image_urls: list[str]) -> list[tuple[str, tuple[str, bytes, str]]]:
        """Load source images as multipart files for GPT Image edit requests."""
        loaded: list[tuple[str, bytes, str]] = []
        for index, url in enumerate(source_image_urls[:4]):
            local = self.storage.local_bytes_for_url(url)
            if local:
                data, content_type = local
            else:
                async with httpx.AsyncClient(timeout=30.0) as client:
                    response = await client.get(url)
                    response.raise_for_status()
                    data = response.content
                    content_type = response.headers.get("content-type", "image/jpeg").split(";", 1)[0]
            ext = {
                "image/png": "png",
                "image/webp": "webp",
                "image/heic": "heic",
            }.get(content_type, "jpg")
            loaded.append((f"source_{index}.{ext}", data, content_type))

        return [("image[]", file_tuple) for file_tuple in loaded]

    def _store_openai_images(self, job_id: str, data: dict) -> list[str]:
        """Persist GPT image base64 outputs and return URLs the iOS app can load."""
        urls: list[str] = []
        output_format = (data.get("output_format") or "jpeg").lower()
        content_type = f"image/{'jpeg' if output_format in ('jpg', 'jpeg') else output_format}"
        ext = "jpg" if content_type == "image/jpeg" else output_format

        for index, img in enumerate(data.get("data", [])):
            if img.get("b64_json"):
                raw = base64.b64decode(img["b64_json"])
                key = f"result/openai/{job_id}/{index}_{nanoid(size=10)}.{ext}"
                urls.append(self.storage.upload_bytes(key, raw, content_type=content_type))
            elif img.get("url"):
                urls.append(img["url"])
        return urls

    _openai_results: dict[str, list[str]] = {}

    def pop_openai_results(self, prediction_id: str) -> list[str] | None:
        """Retrieve and remove stored OpenAI results."""
        return self._openai_results.pop(prediction_id, None)

    # ── Cleanup ─────────────────────────────────────────────────────────

    async def close(self):
        await self.replicate.aclose()
        await self.fal.aclose()
        await self.openai.aclose()
