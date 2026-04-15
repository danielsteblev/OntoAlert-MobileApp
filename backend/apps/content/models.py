from django.db import models


class HintStory(models.Model):
    title = models.CharField(max_length=255)
    subtitle = models.CharField(max_length=255)
    body = models.TextField()
    highlight_text = models.CharField(max_length=255, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.title
