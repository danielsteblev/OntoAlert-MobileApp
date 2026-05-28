from rest_framework import serializers

from apps.content.file_urls import build_media_file_url
from apps.content.models import HintStory, HintStorySlide, LegalDocument


class HintStorySlideSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    def get_image_url(self, obj):
        request = self.context.get("request")
        return build_media_file_url(obj.image, request=request)

    class Meta:
        model = HintStorySlide
        fields = ("id", "image_url", "sort_order")


class HintStorySerializer(serializers.ModelSerializer):
    cover_image_url = serializers.SerializerMethodField()
    slides = serializers.SerializerMethodField()

    def get_cover_image_url(self, obj):
        request = self.context.get("request")
        return build_media_file_url(obj.image, request=request)

    def get_slides(self, obj):
        slides = obj.slides.all()
        if not slides and obj.image:
            return [{"id": obj.id, "image_url": self.get_cover_image_url(obj), "sort_order": 0}]
        return HintStorySlideSerializer(slides, many=True, context=self.context).data

    class Meta:
        model = HintStory
        fields = ("id", "title", "cover_image_url", "slides", "sort_order", "created_at")


class LegalDocumentSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    storage_backend = serializers.SerializerMethodField()

    class Meta:
        model = LegalDocument
        fields = (
            "id",
            "title",
            "slug",
            "description",
            "file_url",
            "file_size",
            "mime_type",
            "sort_order",
            "updated_at",
            "storage_backend",
        )

    def get_file_url(self, obj):
        request = self.context.get("request")
        return build_media_file_url(obj.file, request=request)

    def get_storage_backend(self, obj):
        from django.conf import settings

        return "s3" if settings.USE_OBJECT_STORAGE else "local"
