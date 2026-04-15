from rest_framework import serializers

from apps.lessons.serializers import LessonListSerializer


class RecommendationSerializer(serializers.Serializer):
    lesson = LessonListSerializer()
    reason = serializers.CharField()
    score = serializers.FloatField()
