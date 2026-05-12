"""Profile audit service powered by GPT-4o vision.

Takes a set of dating-profile photo URLs and produces a structured
ProfileAuditResult — per-photo scores, missing archetypes, and concrete
top fixes. This is the core of the V2 "diagnose-first" flow.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

from openai import AsyncOpenAI

from app.config import get_settings
from app.models.schemas import (
    DatingPlatform,
    GenerationStyle,
    PhotoArchetype,
    PhotoCritique,
    ProfileAuditResult,
    ProfileFix,
)

logger = logging.getLogger(__name__)

# We pin to a vision-capable model. gpt-4o handles images natively and returns
# structured JSON when asked.
VISION_MODEL = "gpt-4o"

AUDIT_SYSTEM_PROMPT = """You are a senior dating-profile photographer who has reviewed
50,000+ Hinge, Tinder, and Bumble profiles. You give honest, actionable, specific
feedback — never generic horoscope text. You speak like a friend, not a corporate AI.

Score each photo on six dimensions (0-10):
- clarity: face sharpness, focus, resolution
- lighting: natural and flattering vs harsh/dim/orange
- expression: genuine warmth, eye contact, real (not posed) smile
- crop: well-framed, head not cut off, not too tight or wide
- authenticity: looks like a real person — NOT over-edited, NOT AI-looking, NOT heavily filtered
- platform_fit: suitable for dating apps (no group photos as first photo, no sunglasses-only, etc.)

Identify each photo's archetype from this list:
- first_photo: strong solo headshot, clear face
- casual_candid: relaxed, in-the-moment, not posed
- dressed_up: formal/styled outfit
- hobby_activity: doing something they love
- travel_lifestyle: out in the world, places
- social_proof: with friends (NEVER as first photo)
- full_body: shows physique/style head-to-toe

Then at the SET level identify:
- best_photo_index: strongest first photo (highest combined clarity + expression + authenticity)
- weakest_photo_index: which to drop or remix
- missing_archetypes: any from the archetype list NOT represented
- top_fixes: 3 concrete next-action recommendations
- overall_score: 0-100 — be honest. Most amateur profiles are 40-65.

Top fixes should be specific. Bad: "improve lighting." Good: "Photo 3's harsh
overhead lighting flattens your face — replace with the candid in Photo 1's
golden-hour light." Map each fix to a target_archetype and suggested_style
when generation can solve it.

Return ONLY valid JSON matching the schema. No prose, no markdown, no comments.
"""


class AuditService:
    """Run a vision audit over a user's photo set."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)

    async def audit_photo_set(
        self,
        photo_urls: list[str],
        target_platforms: list[DatingPlatform] | None = None,
    ) -> ProfileAuditResult:
        """Audit a set of dating-profile photos and return a structured result."""
        if not photo_urls:
            raise ValueError("audit_photo_set requires at least one photo URL")

        target_platforms = target_platforms or []
        platform_str = (
            ", ".join(p.value for p in target_platforms) if target_platforms else "Hinge, Tinder, Bumble"
        )

        # Build user message with all images plus the schema reminder.
        content: list[dict] = [
            {
                "type": "text",
                "text": (
                    f"Audit these {len(photo_urls)} dating photos for {platform_str}.\n"
                    "Return a JSON object with this exact shape:\n"
                    "{\n"
                    '  "overall_score": int (0-100),\n'
                    '  "summary": "1-2 sentence honest read",\n'
                    '  "best_photo_index": int (0-based),\n'
                    '  "weakest_photo_index": int (0-based),\n'
                    '  "missing_archetypes": ["casual_candid", ...],\n'
                    '  "top_fixes": [\n'
                    '    {"title": "...", "detail": "...", '
                    '"target_archetype": "casual_candid|dressed_up|...", '
                    '"suggested_style": "outfit_swap|hairstyle_swap|professional|casual|..."}\n'
                    "  ],\n"
                    '  "per_photo": [\n'
                    "    {\n"
                    '      "photo_index": 0,\n'
                    '      "clarity": 7, "lighting": 6, "expression": 8,\n'
                    '      "crop": 7, "authenticity": 9, "platform_fit": 8,\n'
                    '      "overall": 8,\n'
                    '      "archetype": "first_photo",\n'
                    '      "issues": ["short bullets"],\n'
                    '      "strengths": ["short bullets"]\n'
                    "    }\n"
                    "  ]\n"
                    "}"
                ),
            },
        ]
        for url in photo_urls:
            content.append(
                {"type": "image_url", "image_url": {"url": url, "detail": "low"}}
            )

        try:
            response = await self.client.chat.completions.create(
                model=VISION_MODEL,
                messages=[
                    {"role": "system", "content": AUDIT_SYSTEM_PROMPT},
                    {"role": "user", "content": content},
                ],
                response_format={"type": "json_object"},
                temperature=0.4,
                max_tokens=2500,
            )
        except Exception:
            logger.exception("Audit vision call failed")
            raise

        raw = response.choices[0].message.content or "{}"
        try:
            data = json.loads(raw)
        except json.JSONDecodeError:
            logger.error("Audit returned non-JSON: %s", raw[:300])
            raise ValueError("Audit response was not valid JSON")

        return _hydrate_audit_result(data, photo_urls, target_platforms)

    async def close(self):
        await self.client.close()


def _hydrate_audit_result(
    data: dict,
    photo_urls: list[str],
    target_platforms: list[DatingPlatform],
) -> ProfileAuditResult:
    """Convert the raw GPT JSON into a strongly-typed ProfileAuditResult."""
    n = len(photo_urls)

    per_photo: list[PhotoCritique] = []
    for entry in data.get("per_photo", []):
        idx = int(entry.get("photo_index", 0))
        if idx < 0 or idx >= n:
            continue
        per_photo.append(
            PhotoCritique(
                photo_url=photo_urls[idx],
                photo_index=idx,
                clarity=_clamp(entry.get("clarity", 5), 0, 10),
                lighting=_clamp(entry.get("lighting", 5), 0, 10),
                expression=_clamp(entry.get("expression", 5), 0, 10),
                crop=_clamp(entry.get("crop", 5), 0, 10),
                authenticity=_clamp(entry.get("authenticity", 5), 0, 10),
                platform_fit=_clamp(entry.get("platform_fit", 5), 0, 10),
                overall=_clamp(entry.get("overall", 5), 0, 10),
                archetype=_safe_archetype(entry.get("archetype")),
                issues=list(entry.get("issues") or [])[:5],
                strengths=list(entry.get("strengths") or [])[:5],
            )
        )

    fixes: list[ProfileFix] = []
    for f in data.get("top_fixes", [])[:3]:
        fixes.append(
            ProfileFix(
                title=str(f.get("title", "Fix"))[:100],
                detail=str(f.get("detail", ""))[:400],
                target_archetype=_safe_archetype(f.get("target_archetype")),
                suggested_style=_safe_style(f.get("suggested_style")),
            )
        )

    missing = [a for a in (_safe_archetype(x) for x in data.get("missing_archetypes", [])) if a]

    best_idx = _clamp(int(data.get("best_photo_index", 0)), 0, n - 1)
    weakest_idx = _clamp(int(data.get("weakest_photo_index", 0)), 0, n - 1)

    return ProfileAuditResult(
        overall_score=_clamp(int(data.get("overall_score", 50)), 0, 100),
        summary=str(data.get("summary", ""))[:500],
        best_photo_index=best_idx,
        weakest_photo_index=weakest_idx,
        missing_archetypes=missing,
        top_fixes=fixes,
        per_photo=per_photo,
        target_platforms=target_platforms,
        created_at=datetime.now(timezone.utc),
    )


def _clamp(v, lo: int, hi: int) -> int:
    try:
        n = int(v)
    except (TypeError, ValueError):
        return lo
    return max(lo, min(hi, n))


def _safe_archetype(raw) -> PhotoArchetype | None:
    if not raw:
        return None
    try:
        return PhotoArchetype(str(raw).lower().strip())
    except ValueError:
        return None


def _safe_style(raw) -> GenerationStyle | None:
    if not raw:
        return None
    try:
        return GenerationStyle(str(raw).lower().strip())
    except ValueError:
        return None
