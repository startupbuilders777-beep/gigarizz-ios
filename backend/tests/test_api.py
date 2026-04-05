"""End-to-end tests for GigaRizz backend API.

Tests all endpoints through the HTTP layer using httpx + ASGITransport.
Dev mode auth is used (no Firebase token required).
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from httpx import AsyncClient


# ────────────────────────────────────────────────────────────────────────────
# Health
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    """GET /health returns 200 with correct shape."""
    resp = await client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert "version" in data
    assert "environment" in data


# ────────────────────────────────────────────────────────────────────────────
# Feature Flags
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_feature_flags(client: AsyncClient):
    """GET /api/v1/flags returns all expected flag keys."""
    resp = await client.get("/api/v1/flags")
    assert resp.status_code == 200
    data = resp.json()

    expected_keys = {
        "enable_generation",
        "enable_coach",
        "enable_face_swap",
        "enable_background_replacer",
        "enable_expression_coach",
        "enable_photo_ranking",
        "enable_color_grade",
        "enable_pose_library",
        "enable_intro_offer",
        "max_free_generations",
        "max_plus_generations",
        "max_gold_generations",
        "show_promo_banner",
        "min_app_version",
    }
    assert expected_keys.issubset(set(data.keys())), f"Missing keys: {expected_keys - set(data.keys())}"

    # Default values
    assert data["enable_generation"] is True
    assert data["enable_coach"] is True
    assert data["enable_face_swap"] is False
    assert isinstance(data["max_free_generations"], int)
    assert data["max_free_generations"] > 0


# ────────────────────────────────────────────────────────────────────────────
# Users — /api/v1/users
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_get_current_user_creates_record(client: AsyncClient):
    """GET /api/v1/users/me auto-creates user in dev mode."""
    resp = await client.get("/api/v1/users/me")
    assert resp.status_code == 200
    data = resp.json()
    assert data["uid"] == "dev-user-001"
    assert data["email"] == "dev@gigarizz.app"
    assert data["tier"] == "free"
    assert data["total_generations"] == 0


@pytest.mark.asyncio
async def test_get_current_user_idempotent(client: AsyncClient):
    """Calling GET /users/me twice returns same user (no duplicate create)."""
    resp1 = await client.get("/api/v1/users/me")
    resp2 = await client.get("/api/v1/users/me")
    assert resp1.status_code == resp2.status_code == 200
    assert resp1.json()["uid"] == resp2.json()["uid"]


@pytest.mark.asyncio
async def test_get_user_analytics_empty(client: AsyncClient):
    """GET /api/v1/users/me/analytics returns zero counts for fresh user."""
    # Ensure user exists first
    await client.get("/api/v1/users/me")
    resp = await client.get("/api/v1/users/me/analytics")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_generations"] == 0


@pytest.mark.asyncio
async def test_delete_user_data(client: AsyncClient):
    """DELETE /api/v1/users/me returns 204 and cleans up."""
    # Create user
    await client.get("/api/v1/users/me")
    resp = await client.delete("/api/v1/users/me")
    assert resp.status_code == 204


# ────────────────────────────────────────────────────────────────────────────
# Generation — /api/v1/generate
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_list_models(client: AsyncClient):
    """GET /api/v1/generate/models returns available AI models."""
    resp = await client.get("/api/v1/generate/models")
    assert resp.status_code == 200
    models = resp.json()
    assert isinstance(models, list)
    assert len(models) == 10  # 5 Replicate + 3 fal + 2 OpenAI
    # Verify shape
    for m in models:
        assert "id" in m
        assert "name" in m
        assert "provider" in m
        assert "speed" in m
        assert "quality" in m
        assert "tier" in m
        assert m["provider"] in ("replicate", "fal", "openai")
        assert m["tier"] in ("free", "plus", "gold")
    # flux_schnell should be first and free
    assert models[0]["id"] == "flux_schnell"
    assert models[0]["tier"] == "free"


@pytest.mark.asyncio
async def test_create_generation_returns_job(client: AsyncClient):
    """POST /api/v1/generate creates a job and returns 202.

    Note: This will fail if Replicate API is not configured, which is expected
    in CI. The test verifies the request shape is accepted.
    """
    resp = await client.post(
        "/api/v1/generate",
        json={
            "style": "professional",
            "prompt": "professional headshot, studio lighting",
            "photo_count": 2,
        },
    )
    # 202 if Replicate is configured, 500 if not (expected in CI)
    assert resp.status_code in (202, 500)
    if resp.status_code == 202:
        data = resp.json()
        assert "job_id" in data
        assert data["status"] in ("queued", "processing")


@pytest.mark.asyncio
async def test_get_generation_status_404(client: AsyncClient):
    """GET /api/v1/generate/{nonexistent} returns 404."""
    resp = await client.get("/api/v1/generate/nonexistent-job-id")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_cancel_generation_404(client: AsyncClient):
    """DELETE /api/v1/generate/{nonexistent} returns 404."""
    resp = await client.delete("/api/v1/generate/nonexistent-job-id")
    assert resp.status_code == 404


# ────────────────────────────────────────────────────────────────────────────
# Coach — /api/v1/coach
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_coach_bio_validation(client: AsyncClient):
    """POST /api/v1/coach/bio with missing interests returns 422."""
    resp = await client.post(
        "/api/v1/coach/bio",
        json={"interests": [], "tone": "witty", "platform": "tinder"},
    )
    assert resp.status_code == 422  # Validation error: min_length=1


@pytest.mark.asyncio
async def test_coach_bio_success_or_external_failure(client: AsyncClient):
    """POST /api/v1/coach/bio accepts valid payload.

    Returns 200 if OpenAI is configured, 500 if not (expected in CI).
    """
    resp = await client.post(
        "/api/v1/coach/bio",
        json={
            "interests": ["hiking", "cooking", "photography"],
            "tone": "witty",
            "platform": "tinder",
        },
    )
    # 200 if OpenAI configured, 500 if not
    assert resp.status_code in (200, 500)
    if resp.status_code == 200:
        data = resp.json()
        assert "bio" in data
        assert len(data["bio"]) > 10


@pytest.mark.asyncio
async def test_coach_openers_success_or_external_failure(client: AsyncClient):
    """POST /api/v1/coach/openers accepts valid payload."""
    resp = await client.post(
        "/api/v1/coach/openers",
        json={"profile_context": "Sarah, 28, loves travel and coffee", "count": 3},
    )
    assert resp.status_code in (200, 500)
    if resp.status_code == 200:
        data = resp.json()
        assert "openers" in data
        assert isinstance(data["openers"], list)


@pytest.mark.asyncio
async def test_coach_reply_success_or_external_failure(client: AsyncClient):
    """POST /api/v1/coach/reply accepts valid payload."""
    resp = await client.post(
        "/api/v1/coach/reply",
        json={
            "their_message": "Hey! I love your photos, where was that taken?",
            "conversation_context": ["Hey there!", "Hi! How are you?"],
        },
    )
    assert resp.status_code in (200, 500)
    if resp.status_code == 200:
        data = resp.json()
        assert "replies" in data
        assert isinstance(data["replies"], list)


@pytest.mark.asyncio
async def test_coach_prompts_success_or_external_failure(client: AsyncClient):
    """POST /api/v1/coach/prompts generates Hinge-style prompt answers."""
    resp = await client.post("/api/v1/coach/prompts")
    assert resp.status_code in (200, 500)
    if resp.status_code == 200:
        data = resp.json()
        assert "prompts" in data


# ────────────────────────────────────────────────────────────────────────────
# Auth — verify dev mode fallback
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_protected_route_dev_mode_no_token(client: AsyncClient):
    """Protected routes work without token in dev mode."""
    resp = await client.get("/api/v1/users/me")
    assert resp.status_code == 200  # Dev mode returns mock user


# ────────────────────────────────────────────────────────────────────────────
# CORS
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_cors_headers(client: AsyncClient):
    """CORS preflight returns correct headers."""
    resp = await client.options(
        "/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code == 200
    assert "access-control-allow-origin" in resp.headers


# ────────────────────────────────────────────────────────────────────────────
# Full E2E Flow:  User creation → generation → check analytics
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_full_user_lifecycle(client: AsyncClient):
    """E2E: Create user → check analytics → check flags → clean up."""
    # Step 1: Create user
    resp = await client.get("/api/v1/users/me")
    assert resp.status_code == 200
    user = resp.json()
    assert user["uid"] == "dev-user-001"

    # Step 2: Check analytics (should be empty)
    resp = await client.get("/api/v1/users/me/analytics")
    assert resp.status_code == 200
    analytics = resp.json()
    assert analytics["total_generations"] == 0

    # Step 3: Check feature flags
    resp = await client.get("/api/v1/flags")
    assert resp.status_code == 200
    flags = resp.json()
    assert flags["enable_generation"] is True

    # Step 4: Clean up
    resp = await client.delete("/api/v1/users/me")
    assert resp.status_code == 204
