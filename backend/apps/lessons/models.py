from django.conf import settings
from django.db import models


class Topic(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    article_code = models.CharField(max_length=50)
    summary = models.TextField()
    semantic_keywords = models.JSONField(default=list, blank=True)

    def __str__(self) -> str:
        return self.title


class Lesson(models.Model):
    topic = models.ForeignKey(Topic, on_delete=models.CASCADE, related_name="lessons")
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    short_description = models.TextField()
    theory = models.TextField()
    article_excerpt = models.TextField()
    difficulty = models.CharField(max_length=30, default="beginner")
    estimated_minutes = models.PositiveIntegerField(default=10)

    def __str__(self) -> str:
        return self.title


class Question(models.Model):
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="questions")
    prompt = models.TextField()
    explanation = models.TextField(blank=True)

    def __str__(self) -> str:
        return self.prompt[:50]


class AnswerOption(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name="options")
    text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)

    def __str__(self) -> str:
        return self.text


class Bookmark(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="bookmarks")
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name="bookmarked_by")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "lesson")

    def __str__(self) -> str:
        return f"{self.user} -> {self.lesson}"
