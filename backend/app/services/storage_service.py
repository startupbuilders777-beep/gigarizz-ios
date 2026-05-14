"""S3/R2 storage service for generated photos."""

from __future__ import annotations

import base64
import logging
import mimetypes
from pathlib import Path
from urllib.parse import unquote, urlparse

import boto3
from botocore.config import Config

from app.config import get_settings

logger = logging.getLogger(__name__)

PLACEHOLDER_VALUES = {"", "REPLACE", "REPLACE_WITH_YOUR_AWS_ACCESS_KEY", "REPLACE_WITH_YOUR_AWS_SECRET_KEY"}


def _clean_endpoint(raw: str) -> str:
    """Strip inline-comment garbage from S3_ENDPOINT_URL env values."""
    if not raw:
        return ""
    # pydantic-settings doesn't strip inline comments — guard against `URL  # comment`
    cleaned = raw.split("#", 1)[0].strip()
    if not cleaned.startswith(("http://", "https://")):
        return ""
    return cleaned


class StorageService:
    """Handles photo upload/download to S3 or Cloudflare R2.

    The boto3 client is constructed lazily so an unconfigured dev env
    can still import + serve the upload router (the route falls back to
    a placeholder URL when storage is unavailable).
    """

    def __init__(self):
        settings = get_settings()
        self.bucket = settings.s3_bucket_name
        self._s3_client = None

    @property
    def uses_local_storage(self) -> bool:
        settings = get_settings()
        return settings.environment == "development" and not self._has_usable_s3_credentials()

    def _has_usable_s3_credentials(self) -> bool:
        settings = get_settings()
        return (
            settings.aws_access_key_id.strip() not in PLACEHOLDER_VALUES
            and settings.aws_secret_access_key.strip() not in PLACEHOLDER_VALUES
        )

    @property
    def local_root(self) -> Path:
        root = Path(get_settings().local_storage_dir).expanduser().resolve()
        root.mkdir(parents=True, exist_ok=True)
        return root

    def _safe_local_path(self, key: str) -> Path:
        clean_key = unquote(key).lstrip("/")
        path = (self.local_root / clean_key).resolve()
        if self.local_root != path and self.local_root not in path.parents:
            raise ValueError("Invalid storage key")
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    @property
    def s3(self):
        if self._s3_client is None:
            settings = get_settings()
            kwargs = {
                "region_name": settings.aws_region,
                "aws_access_key_id": settings.aws_access_key_id,
                "aws_secret_access_key": settings.aws_secret_access_key,
                "config": Config(signature_version="s3v4"),
            }
            endpoint = _clean_endpoint(settings.s3_endpoint_url)
            if endpoint:
                kwargs["endpoint_url"] = endpoint
            self._s3_client = boto3.client("s3", **kwargs)
        return self._s3_client

    def upload_bytes(self, key: str, data: bytes, content_type: str = "image/webp") -> str:
        """Upload bytes to S3 and return the public URL."""
        if self.uses_local_storage:
            path = self._safe_local_path(key)
            path.write_bytes(data)
            return self.get_url(key)

        self.s3.put_object(
            Bucket=self.bucket,
            Key=key,
            Body=data,
            ContentType=content_type,
        )
        return self.get_url(key)

    def get_url(self, key: str) -> str:
        """Get the public URL for a key."""
        settings = get_settings()
        if self.uses_local_storage:
            base = settings.local_public_base_url.rstrip("/")
            return f"{base}/media/{key}"
        endpoint = _clean_endpoint(settings.s3_endpoint_url)
        if endpoint:
            return f"{endpoint}/{self.bucket}/{key}"
        return f"https://{self.bucket}.s3.{settings.aws_region}.amazonaws.com/{key}"

    def generate_presigned_upload(self, key: str, content_type: str = "image/jpeg", expires: int = 3600) -> dict:
        """Generate a presigned URL for client-side upload."""
        if self.uses_local_storage:
            base = get_settings().local_public_base_url.rstrip("/")
            return {
                "upload_url": f"{base}/api/v1/uploads/local/{key}",
                "key": key,
                "expires_in": expires,
            }

        url = self.s3.generate_presigned_url(
            "put_object",
            Params={"Bucket": self.bucket, "Key": key, "ContentType": content_type},
            ExpiresIn=expires,
        )
        return {"upload_url": url, "key": key, "expires_in": expires}

    def generate_presigned_download(self, key: str, expires: int = 3600) -> str:
        """Generate a presigned URL for downloading."""
        return self.s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": self.bucket, "Key": key},
            ExpiresIn=expires,
        )

    def delete(self, key: str) -> None:
        """Delete an object from S3."""
        if self.uses_local_storage:
            try:
                self._safe_local_path(key).unlink()
            except FileNotFoundError:
                pass
            return
        self.s3.delete_object(Bucket=self.bucket, Key=key)

    def write_local_upload(self, key: str, data: bytes, content_type: str = "image/jpeg") -> str:
        """Persist a local-development upload and return its public URL."""
        if not self.uses_local_storage:
            raise RuntimeError("Local upload endpoint is only available in development storage mode")
        return self.upload_bytes(key, data, content_type)

    def local_bytes_for_url(self, url: str) -> tuple[bytes, str] | None:
        """Return bytes + content-type for URLs served from the local /media mount."""
        settings = get_settings()
        parsed = urlparse(url)
        base = urlparse(settings.local_public_base_url)
        same_host = parsed.scheme == base.scheme and parsed.netloc == base.netloc
        if not same_host or not parsed.path.startswith("/media/"):
            return None

        key = parsed.path.removeprefix("/media/")
        path = self._safe_local_path(key)
        if not path.exists() or not path.is_file():
            return None
        content_type = mimetypes.guess_type(path.name)[0] or "image/jpeg"
        return path.read_bytes(), content_type

    def data_url_for_local_url(self, url: str) -> str | None:
        """Convert a local media URL to a data URL for OpenAI vision calls."""
        local = self.local_bytes_for_url(url)
        if not local:
            return None
        data, content_type = local
        encoded = base64.b64encode(data).decode("ascii")
        return f"data:{content_type};base64,{encoded}"
