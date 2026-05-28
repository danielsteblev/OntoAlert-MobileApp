from __future__ import annotations

from django.conf import settings


def build_media_file_url(file_field, request=None) -> str:
    """Return an absolute URL for a stored file (local nginx or S3 presigned URL)."""
    if not file_field:
        return ""

    url = file_field.url
    if url.startswith(("http://", "https://")):
        return url

    if request is not None:
        return request.build_absolute_uri(url)

    public_base = getattr(settings, "PUBLIC_MEDIA_BASE_URL", "").rstrip("/")
    if public_base:
        return f"{public_base}/{url.lstrip('/')}"

    return url
