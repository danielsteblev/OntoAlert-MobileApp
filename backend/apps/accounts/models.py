from django.conf import settings
from django.db import models


class Profile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="profile")
    full_name = models.CharField(max_length=255, blank=True)
    bio = models.TextField(blank=True)
    university = models.CharField(max_length=255, blank=True)
    avatar_url = models.URLField(blank=True)

    def __str__(self) -> str:
        return self.full_name or self.user.username
