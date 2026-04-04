"""Photo generation service using Replicate (SDXL/Flux) with webhook callbacks."""

from __future__ import annotations

import logging
from datetime import datetime, timezone

import httpx
from nanoid import generate as nanoid

from app.config import get_settings

logger = logging.getLogger(__name__)

# Replicate model versions for different quality tiers
MODELS = {
    "flux_schnell": "black-forest-labs/flux-schnell",  # Fast, good quality
    "flux_dev": "black-forest-labs/flux-dev",  # Higher quality, slower
    "sdxl": "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
}

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
}


class GenerationService:
    """Handles AI photo generation via Replicate API."""

    def __init__(self):
        self.settings = get_settings()
        self.client = httpx.AsyncClient(
            base_url="https://api.replicate.com/v1",
            headers={
                "Authorization": f"Bearer {self.settings.replicate_api_token}",
                "Content-Type": "application/json",
                "Prefer": "respond-async",
            },
            timeout=60.0,
        )

    async def create_prediction(
        self,
        job_id: str,
        style: str,
        source_image_urls: list[str],
        photo_count: int = 4,
        custom_prompt: str | None = None,
        webhook_url: str | None = None,
    ) -> str:
        """Create a Replicate prediction for photo generation.

        Returns the Replicate prediction ID.
        """
        # Build prompt
        prompt = custom_prompt or STYLE_PROMPTS.get(style, STYLE_PROMPTS["professional"])
        prompt = prompt.replace("{subject}", "a person")

        # Use Flux Schnell for fast generation
        model = MODELS["flux_schnell"]

        payload = {
            "input": {
                "prompt": prompt,
                "num_outputs": min(photo_count, 4),
                "aspect_ratio": "3:4",  # Portrait orientation for dating apps
                "output_format": "webp",
                "output_quality": 90,
                "go_fast": True,
            },
        }

        if webhook_url:
            payload["webhook"] = webhook_url
            payload["webhook_events_filter"] = ["completed"]

        # If we have source images, use img2img with face reference
        if source_image_urls:
            payload["input"]["image"] = source_image_urls[0]

        response = await self.client.post(
            f"/models/{model}/predictions",
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

        prediction_id = data.get("id", "")
        logger.info("Created prediction %s for job %s", prediction_id, job_id)
        return prediction_id

    async def check_prediction(self, prediction_id: str) -> dict:
        """Poll a Replicate prediction for status."""
        response = await self.client.get(f"/predictions/{prediction_id}")
        response.raise_for_status()
        return response.json()

    async def cancel_prediction(self, prediction_id: str) -> None:
        """Cancel an in-progress prediction."""
        try:
            await self.client.post(f"/predictions/{prediction_id}/cancel")
        except httpx.HTTPError:
            logger.warning("Failed to cancel prediction %s", prediction_id)

    async def wait_for_prediction(self, prediction_id: str, max_polls: int = 60) -> dict:
        """Poll until prediction completes (up to ~5 minutes)."""
        import asyncio

        for _ in range(max_polls):
            result = await self.check_prediction(prediction_id)
            status = result.get("status")

            if status == "succeeded":
                return result
            elif status in ("failed", "canceled"):
                raise Exception(f"Prediction {status}: {result.get('error', 'Unknown')}")

            await asyncio.sleep(5)

        raise TimeoutError(f"Prediction {prediction_id} timed out")

    def generate_job_id(self) -> str:
        """Generate a URL-safe nanoid for job identification."""
        return nanoid(size=21)

    async def close(self):
        await self.client.aclose()
