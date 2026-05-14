"""Source-image upload endpoints.

iOS uploads source selfies via presigned PUT. Backend hands AI providers (Replicate,
fal.ai, OpenAI) the resulting public URL — that is the unlock for identity-preserving
generation across InstantID, Nano Banana 2, GPT Image 2, etc.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, Response
from nanoid import generate as nanoid

from app.config import get_settings
from app.deps import get_storage_service
from app.middleware.auth import verify_firebase_token
from app.models.schemas import UploadPresignRequest, UploadPresignResponse
from app.services.storage_service import StorageService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/uploads", tags=["uploads"])

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/heic", "image/webp"}
EXTENSION_FOR_TYPE = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/heic": "heic",
    "image/webp": "webp",
}


@router.post("/presign", response_model=UploadPresignResponse)
async def request_presigned_upload(
    req: UploadPresignRequest,
    user: dict = Depends(verify_firebase_token),
    storage: StorageService = Depends(get_storage_service),
):
    """Mint a presigned PUT URL the iOS client can upload bytes to.

    The returned `public_url` is what gets passed to /api/v1/generate's
    `source_image_url` field so AI providers can fetch the source.
    """
    if req.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported content_type {req.content_type!r}. "
                   f"Use one of: {sorted(ALLOWED_CONTENT_TYPES)}",
        )

    settings = get_settings()
    if not storage.uses_local_storage and not storage._has_usable_s3_credentials() and settings.environment != "development":
        raise HTTPException(
            status_code=503,
            detail="Photo upload temporarily unavailable (storage not configured).",
        )

    ext = EXTENSION_FOR_TYPE[req.content_type]
    timestamp = int(datetime.now(timezone.utc).timestamp())
    key = f"{req.purpose.value}/{user['uid']}/{timestamp}_{nanoid(size=10)}.{ext}"

    try:
        presigned = storage.generate_presigned_upload(
            key=key, content_type=req.content_type, expires=3600
        )
        public_url = storage.get_url(key)
    except Exception as e:
        # Dev mode without S3 creds: surface a deterministic placeholder so iOS can
        # still exercise the round-trip and we get coverage in tests.
        if settings.environment == "development":
            logger.info("Storage not available in dev — returning placeholder for %s", key)
            placeholder_host = "https://uploads-dev.gigarizz.local"
            return UploadPresignResponse(
                upload_url=f"{placeholder_host}/{key}",
                public_url=f"{placeholder_host}/{key}",
                key=key,
                expires_in=3600,
            )
        logger.error("Failed to mint presigned upload URL: %s", e)
        raise HTTPException(status_code=500, detail="Failed to prepare upload")

    return UploadPresignResponse(
        upload_url=presigned["upload_url"],
        public_url=public_url,
        key=key,
        expires_in=presigned.get("expires_in", 3600),
    )


@router.put("/local/{key:path}", status_code=204)
async def upload_local_media(
    key: str,
    request: Request,
    storage: StorageService = Depends(get_storage_service),
):
    """Development-only PUT target that mimics a presigned S3 upload.

    This keeps Simulator QA fully local when AWS/R2 credentials are absent.
    Production still uses real presigned S3/R2 URLs.
    """
    if not storage.uses_local_storage:
        raise HTTPException(status_code=404, detail="Local upload endpoint disabled")

    content_type = request.headers.get("content-type", "image/jpeg").split(";", 1)[0].strip()
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=400, detail=f"Unsupported content_type {content_type!r}")

    storage.write_local_upload(key, await request.body(), content_type=content_type)
    return Response(status_code=204)
