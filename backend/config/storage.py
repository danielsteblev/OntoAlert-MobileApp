from __future__ import annotations

import os
from pathlib import Path

from django.conf import settings


def configure_storages() -> dict:
    """Build Django STORAGES dict: local filesystem or S3-compatible object storage."""
    use_object_storage = os.getenv("USE_OBJECT_STORAGE", "false").lower() == "true"

    storages: dict = {
        "staticfiles": {
            "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
        },
    }

    if use_object_storage:
        storages["default"] = {
            "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
            "OPTIONS": {
                "bucket_name": os.getenv("AWS_STORAGE_BUCKET_NAME", ""),
                "access_key": os.getenv("AWS_ACCESS_KEY_ID", ""),
                "secret_key": os.getenv("AWS_SECRET_ACCESS_KEY", ""),
                "endpoint_url": os.getenv(
                    "AWS_S3_ENDPOINT_URL",
                    "https://storage.yandexcloud.net",
                ),
                "region_name": os.getenv("AWS_S3_REGION_NAME", "ru-central1"),
                "default_acl": None,
                "querystring_auth": os.getenv("AWS_QUERYSTRING_AUTH", "true").lower() == "true",
                "file_overwrite": False,
                "location": os.getenv("AWS_LOCATION", "media"),
            },
        }
        custom_domain = os.getenv("AWS_S3_CUSTOM_DOMAIN", "").strip()
        if custom_domain:
            storages["default"]["OPTIONS"]["custom_domain"] = custom_domain
    else:
        media_root = getattr(settings, "MEDIA_ROOT", Path("media"))
        media_url = getattr(settings, "MEDIA_URL", "/media/")
        storages["default"] = {
            "BACKEND": "django.core.files.storage.FileSystemStorage",
            "OPTIONS": {
                "location": str(media_root),
                "base_url": media_url,
            },
        }

    return storages


def use_object_storage() -> bool:
    return os.getenv("USE_OBJECT_STORAGE", "false").lower() == "true"
