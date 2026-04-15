from django.db import models


class HintStory(models.Model):
    title = models.CharField(max_length=255)
    subtitle = models.CharField(max_length=255, blank=True)
    body = models.TextField(blank=True)
    highlight_text = models.CharField(max_length=255, blank=True)
    image = models.ImageField(upload_to="stories/covers/", blank=True, null=True)
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.title


class HintStorySlide(models.Model):
    story = models.ForeignKey(HintStory, on_delete=models.CASCADE, related_name="slides")
    image = models.ImageField(upload_to="stories/slides/")
    sort_order = models.PositiveIntegerField(default=0)

    class Meta:
        ordering = ("sort_order", "id")

    def __str__(self) -> str:
        return f"{self.story.title} #{self.sort_order or self.id}"
