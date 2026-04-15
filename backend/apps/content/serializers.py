from rest_framework import serializers

from apps.content.models import HintStory


class HintStorySerializer(serializers.ModelSerializer):
    class Meta:
        model = HintStory
        fields = ("id", "title", "subtitle", "body", "highlight_text", "created_at")
