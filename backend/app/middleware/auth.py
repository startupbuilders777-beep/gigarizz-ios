"""Firebase Auth token verification middleware."""

from __future__ import annotations

import logging

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=False)

# Firebase public keys cache
_firebase_initialized = False


def _init_firebase():
    """Initialize Firebase Admin SDK (lazy, once)."""
    global _firebase_initialized
    if _firebase_initialized:
        return
    try:
        import firebase_admin
        from firebase_admin import credentials

        settings = get_settings()
        if settings.google_application_credentials:
            cred = credentials.Certificate(settings.google_application_credentials)
            firebase_admin.initialize_app(cred)
        else:
            # Use Application Default Credentials
            firebase_admin.initialize_app()
        _firebase_initialized = True
    except Exception as e:
        logger.warning("Firebase init failed (auth will use dev mode): %s", e)
        _firebase_initialized = True  # Don't retry


async def verify_firebase_token(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
) -> dict:
    """Verify Firebase ID token from Authorization header.

    In development mode (no Firebase configured), returns a dev user.
    """
    settings = get_settings()

    # Dev mode: no auth required
    if settings.environment == "development" and not credentials:
        return {"uid": "dev-user-001", "email": "dev@gigarizz.app", "name": "Dev User"}

    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization token",
        )

    token = credentials.credentials

    try:
        _init_firebase()
        from firebase_admin import auth

        decoded = auth.verify_id_token(token)
        return {
            "uid": decoded["uid"],
            "email": decoded.get("email"),
            "name": decoded.get("name"),
        }
    except ImportError:
        # firebase_admin not available; use dev mode
        if settings.environment == "development":
            return {"uid": "dev-user-001", "email": "dev@gigarizz.app", "name": "Dev User"}
        raise HTTPException(status_code=500, detail="Firebase SDK not configured")
    except Exception as e:
        logger.error("Token verification failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
