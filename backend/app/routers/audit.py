"""Profile audit endpoint — V2 'diagnose first' flow."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.config import get_settings
from app.deps import get_audit_service
from app.middleware.auth import verify_firebase_token
from app.models.schemas import AuditRequest, ProfileAuditResult
from app.services.audit_service import AuditService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/audit", tags=["audit"])


@router.post("", response_model=ProfileAuditResult)
async def run_audit(
    req: AuditRequest,
    user: dict = Depends(verify_firebase_token),
    audit_svc: AuditService = Depends(get_audit_service),
):
    """Audit the user's current photo set and return a structured diagnosis.

    The result is the source of truth for the V2 Upgrade flow:
    - per-photo scores (clarity / lighting / expression / crop / authenticity / platform_fit)
    - best + weakest photo indices
    - missing archetypes (slots the user should generate)
    - 3 concrete top fixes mapped to archetypes + suggested styles
    """
    settings = get_settings()
    if not settings.flag_enable_audit_endpoint:
        raise HTTPException(status_code=503, detail="Audit endpoint disabled by feature flag")

    try:
        return await audit_svc.audit_photo_set(
            photo_urls=req.photo_urls,
            target_platforms=req.target_platforms,
            roast_mode=req.roast_mode,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception:
        logger.exception("Audit failed")
        raise HTTPException(status_code=500, detail="Audit failed")
