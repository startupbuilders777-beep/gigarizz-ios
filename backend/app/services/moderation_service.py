"""Content moderation service using OpenAI moderation endpoint."""

from __future__ import annotations

import logging

from openai import AsyncOpenAI

from app.config import get_settings

logger = logging.getLogger(__name__)


class ModerationService:
    """Checks uploaded images and text for policy violations."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.enabled = settings.moderation_enabled

    async def check_text(self, text: str) -> dict:
        """Check text content for policy violations."""
        if not self.enabled:
            return {"flagged": False, "categories": {}}

        response = await self.client.moderations.create(input=text)
        result = response.results[0]
        return {
            "flagged": result.flagged,
            "categories": {k: v for k, v in result.categories.model_dump().items() if v},
        }

    async def check_image_url(self, image_url: str) -> dict:
        """Check an image URL for policy violations using GPT-4o vision."""
        if not self.enabled:
            return {"flagged": False, "reason": None}

        try:
            response = await self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are a content moderation system. Analyze the image and respond "
                            "with ONLY 'SAFE' or 'FLAGGED: [reason]'. Flag images containing: "
                            "nudity, violence, hate symbols, minors, weapons, drugs."
                        ),
                    },
                    {
                        "role": "user",
                        "content": [{"type": "image_url", "image_url": {"url": image_url}}],
                    },
                ],
                max_tokens=50,
            )
            content = response.choices[0].message.content or "SAFE"
            if content.strip().upper().startswith("FLAGGED"):
                reason = content.split(":", 1)[1].strip() if ":" in content else "Policy violation"
                return {"flagged": True, "reason": reason}
            return {"flagged": False, "reason": None}
        except Exception as e:
            logger.error("Image moderation failed: %s", e)
            # Fail open for now; in production, fail closed
            return {"flagged": False, "reason": None}

    async def close(self):
        await self.client.close()
