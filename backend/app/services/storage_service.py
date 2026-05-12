"""S3/R2 storage service for generated photos."""

from __future__ import annotations

import logging

import boto3
from botocore.config import Config

from app.config import get_settings

logger = logging.getLogger(__name__)


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
        if settings.s3_endpoint_url:
            return f"{settings.s3_endpoint_url}/{self.bucket}/{key}"
        return f"https://{self.bucket}.s3.{settings.aws_region}.amazonaws.com/{key}"

    def generate_presigned_upload(self, key: str, content_type: str = "image/jpeg", expires: int = 3600) -> dict:
        """Generate a presigned URL for client-side upload."""
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
        self.s3.delete_object(Bucket=self.bucket, Key=key)
