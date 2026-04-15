from rest_framework import serializers

from apps.content.models import HintStory, HintStorySlide


class HintStorySlideSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    def get_image_url(self, obj):
        request = self.context.get("request")
        if not obj.image:
            return ""
        return request.build_absolute_uri(obj.image.url) if request else obj.image.url

    class Meta:
        model = HintStorySlide
        fields = ("id", "image_url", "sort_order")


class HintStorySerializer(serializers.ModelSerializer):
    cover_image_url = serializers.SerializerMethodField()
    slides = serializers.SerializerMethodField()

    def get_cover_image_url(self, obj):
        request = self.context.get("request")
        if not obj.image:
            return ""
        return request.build_absolute_uri(obj.image.url) if request else obj.image.url

    def get_slides(self, obj):
        slides = obj.slides.all()
        if not slides and obj.image:
            return [{"id": obj.id, "image_url": self.get_cover_image_url(obj), "sort_order": 0}]
        return HintStorySlideSerializer(slides, many=True, context=self.context).data

    class Meta:
        model = HintStory
        fields = ("id", "title", "cover_image_url", "slides", "sort_order", "created_at")
