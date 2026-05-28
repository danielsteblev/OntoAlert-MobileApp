import mimetypes

from django.db import models


def legal_document_upload_to(instance, filename: str) -> str:
    return f"documents/{instance.slug}/{filename}"


class LegalDocument(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True)
    description = models.TextField(blank=True)
    file = models.FileField(upload_to=legal_document_upload_to, blank=True)
    file_size = models.PositiveIntegerField(default=0)
    mime_type = models.CharField(max_length=120, default="application/pdf")
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("sort_order", "title")

    def __str__(self) -> str:
        return self.title

    def save(self, *args, **kwargs):
        if self.file:
            self.file_size = self.file.size
            guessed_type, _ = mimetypes.guess_type(self.file.name)
            if guessed_type:
                self.mime_type = guessed_type
        super().save(*args, **kwargs)


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
