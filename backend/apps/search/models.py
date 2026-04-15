from django.conf import settings
from django.db import models


class SearchQuery(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="search_queries")
    query_text = models.TextField()
    normalized_terms = models.JSONField(default=list, blank=True)
    matched_article = models.CharField(max_length=50, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.query_text
