"""End-to-end tests for GigaRizz backend API.

Tests all endpoints through the HTTP layer using httpx + ASGITransport.
Dev mode auth is used (no Firebase token required).
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from httpx import AsyncClient

from app.models.schemas import GenerateRequest


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
        # V2 flags
        "enable_v2_upgrade_flow",
        "enable_audit_endpoint",
        "enable_screenshot_coach",
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
    assert len(models) == 20  # 11 Replicate + 6 fal + 3 OpenAI
    # Verify shape
    for m in models:
        assert "id" in m
        assert "name" in m
        assert "provider" in m
        assert "speed" in m
        assert "quality" in m
        assert "tier" in m
        assert "category" in m
        assert m["provider"] in ("replicate", "fal", "openai")
        assert m["tier"] in ("free", "plus", "gold")
    # flux_schnell should be first and free
    assert models[0]["id"] == "flux_schnell"
    assert models[0]["tier"] == "free"
    # Verify new models exist
    model_ids = {m["id"] for m in models}
    assert "realvis_xl" in model_ids
    assert "ideogram_3" in model_ids
    assert "fal_recraft_v3" in model_ids
    assert "fal_sdxl_lightning" in model_ids
    assert "flux_1_1_pro_ultra" in model_ids
    assert "playground_v3" in model_ids
    # SOTA additions (May 2026)
    assert "nano_banana_2" in model_ids
    assert "gpt_image_2" in model_ids
    assert "instant_id" in model_ids
    assert "face_restore" in model_ids


@pytest.mark.asyncio
async def test_batch_generation_endpoint(client: AsyncClient):
    """POST /api/v1/generate/batch creates multiple jobs."""
    resp = await client.post(
        "/api/v1/generate/batch",
        json={
            "style": "professional",
            "models": ["flux_schnell", "sdxl"],
            "photo_count": 2,
        },
    )
    # 202 if providers are configured, 500 if not (expected in CI)
    assert resp.status_code in (202, 500)
    if resp.status_code == 202:
        data = resp.json()
        assert "batch_id" in data
        assert "jobs" in data
        assert data["total_models"] == 2
        assert len(data["jobs"]) == 2


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


def test_generate_request_accepts_multiple_source_urls():
    """V2 clients can send a full source set for GPT Image edits."""
    req = GenerateRequest(
        style="professional",
        model="gpt_image_2",
        source_image_url="https://cdn.example.com/lead.jpg",
        source_image_urls=[
            "https://cdn.example.com/lead.jpg",
            "https://cdn.example.com/candid.jpg",
            "https://cdn.example.com/full-body.jpg",
        ],
    )

    assert req.source_image_url == "https://cdn.example.com/lead.jpg"
    assert req.source_image_urls == [
        "https://cdn.example.com/lead.jpg",
        "https://cdn.example.com/candid.jpg",
        "https://cdn.example.com/full-body.jpg",
    ]


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


# ────────────────────────────────────────────────────────────────────────────
# Uploads — /api/v1/uploads
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_upload_presign_returns_urls(client: AsyncClient):
    """POST /api/v1/uploads/presign returns upload_url + public_url + key."""
    resp = await client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/jpeg", "purpose": "source"},
    )
    assert resp.status_code == 200
    data = resp.json()
    for required in ("upload_url", "public_url", "key", "expires_in"):
        assert required in data, f"Missing {required} in {data}"
    assert data["key"].startswith("source/dev-user-001/")
    assert data["key"].endswith(".jpg")
    assert isinstance(data["expires_in"], int)
    assert data["expires_in"] > 0


@pytest.mark.asyncio
async def test_local_upload_put_and_media_get(client: AsyncClient):
    """Dev storage returns a PUT target that persists bytes under /media."""
    presign = await client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/jpeg", "purpose": "source"},
    )
    assert presign.status_code == 200
    data = presign.json()
    upload_path = "/" + data["upload_url"].split("/", 3)[3]
    media_path = "/" + data["public_url"].split("/", 3)[3]

    put_resp = await client.put(
        upload_path,
        content=b"fake-jpeg",
        headers={"content-type": "image/jpeg"},
    )
    assert put_resp.status_code == 204

    get_resp = await client.get(media_path)
    assert get_resp.status_code == 200
    assert get_resp.content == b"fake-jpeg"


@pytest.mark.asyncio
async def test_openai_edit_source_files_use_image_array_field(client: AsyncClient):
    """GPT Image edit requests send source files as image[] multipart fields."""
    from app.services.generation_service import GenerationService

    presign = await client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/jpeg", "purpose": "source"},
    )
    assert presign.status_code == 200
    data = presign.json()
    upload_path = "/" + data["upload_url"].split("/", 3)[3]

    put_resp = await client.put(
        upload_path,
        content=b"fake-jpeg",
        headers={"content-type": "image/jpeg"},
    )
    assert put_resp.status_code == 204

    service = GenerationService()
    try:
        files = await service._openai_source_files([data["public_url"]])
    finally:
        await service.close()

    assert len(files) == 1
    field, file_tuple = files[0]
    filename, body, content_type = file_tuple
    assert field == "image[]"
    assert filename.endswith(".jpg")
    assert body == b"fake-jpeg"
    assert content_type == "image/jpeg"


@pytest.mark.asyncio
async def test_upload_presign_rejects_unsupported_type(client: AsyncClient):
    """Unsupported content-types get a clean 400."""
    resp = await client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/gif", "purpose": "source"},
    )
    assert resp.status_code == 400
    detail = resp.json().get("detail", "")
    assert "image/gif" in detail or "Unsupported" in detail


@pytest.mark.asyncio
async def test_upload_presign_default_content_type(client: AsyncClient):
    """Empty body falls back to image/jpeg defaults."""
    resp = await client.post("/api/v1/uploads/presign", json={})
    assert resp.status_code == 200
    data = resp.json()
    assert data["key"].endswith(".jpg")


@pytest.mark.asyncio
async def test_upload_presign_rejects_invalid_purpose(client: AsyncClient):
    """Unknown purpose values get a 422 validation error from pydantic."""
    resp = await client.post(
        "/api/v1/uploads/presign",
        json={"content_type": "image/jpeg", "purpose": "malicious_path/../../etc/passwd"},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_upload_presign_accepts_all_known_purposes(client: AsyncClient):
    """source / result / avatar all map cleanly into the key prefix."""
    for purpose in ("source", "result", "avatar"):
        resp = await client.post(
            "/api/v1/uploads/presign",
            json={"content_type": "image/jpeg", "purpose": purpose},
        )
        assert resp.status_code == 200, f"{purpose}: {resp.text}"
        assert resp.json()["key"].startswith(f"{purpose}/dev-user-001/")


@pytest.mark.asyncio
async def test_generation_accepts_new_style_enums(client: AsyncClient):
    """Iter 5+7 added new GenerationStyle values for Hinge overlays + outfit/hair swaps.
    The /generate endpoint must accept all of them (returns 202 if providers configured,
    500 if not — both prove the schema validated)."""
    new_styles = ["hinge_prompt", "hinge_caption", "hinge_chemistry", "outfit_swap", "hairstyle_swap", "age_modify"]
    for style in new_styles:
        resp = await client.post(
            "/api/v1/generate",
            json={"style": style, "prompt": "test prompt", "photo_count": 1, "model": "nano_banana_2"},
        )
        # 202 = job queued; 500 = provider not configured (fal_key empty in CI). Both mean
        # the request shape passed schema validation. 422 would mean the enum rejected.
        assert resp.status_code in (202, 500), f"{style} got {resp.status_code}: {resp.text}"


# ────────────────────────────────────────────────────────────────────────────
# Naturalness wrap (V2 trust default)
# ────────────────────────────────────────────────────────────────────────────


def test_natural_wrap_prepends_identity_clause():
    """Importable: naturalness wrapper prefixes identity-preservation language."""
    from app.services.generation_service import _wrap_natural, _NATURAL_PREFIX, _NATURAL_SUFFIX

    base = "Professional headshot of a person in a navy suit."
    wrapped = _wrap_natural(base)
    assert wrapped.startswith(_NATURAL_PREFIX)
    assert wrapped.endswith(_NATURAL_SUFFIX)
    assert base in wrapped


def test_natural_wrap_is_idempotent():
    """Wrapping twice doesn't double-wrap."""
    from app.services.generation_service import _wrap_natural

    base = "casual outdoor photo"
    once = _wrap_natural(base)
    twice = _wrap_natural(once)
    assert once == twice


# ────────────────────────────────────────────────────────────────────────────
# Audit — /api/v1/audit (V2)
# ────────────────────────────────────────────────────────────────────────────


@pytest.mark.asyncio
async def test_audit_returns_structured_result(client: AsyncClient):
    """POST /api/v1/audit returns ProfileAuditResult with per-photo critiques."""
    resp = await client.post(
        "/api/v1/audit",
        json={
            "photo_urls": [
                "https://example.com/p1.jpg",
                "https://example.com/p2.jpg",
                "https://example.com/p3.jpg",
            ],
            "target_platforms": ["hinge", "tinder"],
        },
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert 0 <= data["overall_score"] <= 100
    assert isinstance(data["summary"], str) and data["summary"]
    assert 0 <= data["best_photo_index"] < 3
    assert 0 <= data["weakest_photo_index"] < 3
    assert isinstance(data["missing_archetypes"], list)
    assert isinstance(data["top_fixes"], list)
    assert len(data["per_photo"]) == 3
    # First photo should map back to first url
    assert data["per_photo"][0]["photo_url"] == "https://example.com/p1.jpg"
    # Each per_photo critique has all six dimensions
    for crit in data["per_photo"]:
        for k in ("clarity", "lighting", "expression", "crop", "authenticity", "platform_fit", "overall"):
            assert 0 <= crit[k] <= 10
    # target_platforms round-trips
    assert "hinge" in data["target_platforms"]
    assert "tinder" in data["target_platforms"]


@pytest.mark.asyncio
async def test_audit_rejects_empty_photo_list(client: AsyncClient):
    """POST /api/v1/audit with no photos returns 422 (pydantic min_length)."""
    resp = await client.post("/api/v1/audit", json={"photo_urls": []})
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_audit_caps_photo_count(client: AsyncClient):
    """POST /api/v1/audit rejects more than 12 photos."""
    resp = await client.post(
        "/api/v1/audit",
        json={"photo_urls": [f"https://example.com/p{i}.jpg" for i in range(13)]},
    )
    assert resp.status_code == 422


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
