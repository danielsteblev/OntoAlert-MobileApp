from django.conf import settings
from django.db import models

from apps.lessons.models import Lesson


class RecommendationLog(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="recommendations")
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="recommendation_logs")
    reason = models.CharField(max_length=255)
    score = models.FloatField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"{self.user} -> {self.lesson}"
