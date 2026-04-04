"""AI dating coach service powered by OpenAI GPT."""

from __future__ import annotations

import logging

from openai import AsyncOpenAI

from app.config import get_settings

logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """You are GigaRizz Coach, an expert AI dating coach that helps people create 
amazing dating profiles and have better conversations on dating apps. You are:

- Supportive and encouraging, never judgmental
- Practical with actionable advice backed by dating app data
- Aware of platform differences (Tinder, Hinge, Bumble, Raya)
- Skilled at writing bios, openers, and conversation replies
- Focused on authenticity — help users be their BEST selves, not fake

Rules:
- Keep bios under 500 characters unless specified
- Opening lines should be unique, not generic copy-paste
- Never be creepy, pushy, or disrespectful
- Adapt tone to what the user asks for (witty/sincere/bold)
- Reference specific details when context is provided
"""


class CoachService:
    """Handles AI dating coach interactions via OpenAI."""

    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model

    async def generate_bio(
        self,
        interests: list[str],
        tone: str,
        platform: str,
        age: int | None = None,
        gender: str | None = None,
    ) -> dict:
        """Generate a dating bio with alternatives."""
        user_context = f"Interests: {', '.join(interests)}"
        if age:
            user_context += f"\nAge: {age}"
        if gender:
            user_context += f"\nGender: {gender}"

        prompt = f"""Write a {tone} dating bio for {platform}. 

{user_context}

Requirements:
- Under 500 characters for the main bio
- Authentic and specific to their interests
- Optimized for {platform}'s format and audience
- Include a hook, personality reveal, and soft CTA

Return exactly 3 bio options, separated by ---"""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.9,
            max_tokens=1000,
        )

        content = response.choices[0].message.content or ""
        bios = [b.strip() for b in content.split("---") if b.strip()]

        return {
            "bio": bios[0] if bios else content,
            "alternatives": bios[1:] if len(bios) > 1 else [],
            "character_count": len(bios[0]) if bios else len(content),
        }

    async def generate_openers(
        self,
        match_name: str,
        platform: str,
        context: str | None = None,
        count: int = 3,
    ) -> list[str]:
        """Generate conversation opening lines."""
        context_str = f"About them: {context}" if context else "No specific context provided."

        prompt = f"""Write {count} unique opening messages for {match_name} on {platform}.

{context_str}

Requirements:
- Each opener should have a different approach (funny, curious, direct)
- Reference their profile details if context is provided
- Keep each under 200 characters
- Be engaging, not generic
- No pickup lines or anything cringe

Return each opener on a new line, numbered 1-{count}."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.95,
            max_tokens=600,
        )

        content = response.choices[0].message.content or ""
        # Parse numbered lines
        lines = []
        for line in content.strip().split("\n"):
            cleaned = line.strip()
            # Remove numbering like "1. " or "1) "
            if cleaned and cleaned[0].isdigit():
                cleaned = cleaned.lstrip("0123456789.)- ").strip()
            if cleaned:
                lines.append(cleaned)
        return lines[:count]

    async def generate_hinge_prompts(self) -> list[dict]:
        """Generate Hinge prompt + answer pairs."""
        prompt = """Write 3 Hinge prompt answers. Use real Hinge prompts.

Format each as:
PROMPT: [the hinge prompt]
ANSWER: [a great answer]

Requirements:
- Answers should be witty, specific, and conversation-starting
- Mix humor with genuine personality
- Keep answers under 150 characters each
- Use prompts that actually exist on Hinge"""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.9,
            max_tokens=600,
        )

        content = response.choices[0].message.content or ""
        results = []
        current_prompt = ""
        for line in content.strip().split("\n"):
            line = line.strip()
            if line.upper().startswith("PROMPT:"):
                current_prompt = line[7:].strip()
            elif line.upper().startswith("ANSWER:") and current_prompt:
                results.append({"prompt": current_prompt, "answer": line[7:].strip()})
                current_prompt = ""

        return results or [
            {"prompt": "The way to win me over is", "answer": "Show up with curiosity and good restaurant picks"},
            {"prompt": "I'm looking for", "answer": "Someone who matches my energy at concerts AND on lazy Sundays"},
            {"prompt": "A life goal of mine", "answer": "Visit every continent with a local friend on each one"},
        ]

    async def suggest_replies(
        self,
        message: str,
        match_name: str,
        conversation_context: str | None = None,
        count: int = 3,
    ) -> list[str]:
        """Suggest conversation replies."""
        context_str = f"Conversation so far: {conversation_context}" if conversation_context else ""

        prompt = f"""Suggest {count} reply options to this message from {match_name}:

"{message}"

{context_str}

Requirements:
- Each reply should have a different energy (playful, interested, flirty)
- Keep each under 200 characters
- Move the conversation forward
- Be authentic, not try-hard

Return each reply on a new line, numbered 1-{count}."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            temperature=0.9,
            max_tokens=500,
        )

        content = response.choices[0].message.content or ""
        lines = []
        for line in content.strip().split("\n"):
            cleaned = line.strip()
            if cleaned and cleaned[0].isdigit():
                cleaned = cleaned.lstrip("0123456789.)- ").strip()
            if cleaned:
                lines.append(cleaned)
        return lines[:count]

    async def close(self):
        await self.client.close()
