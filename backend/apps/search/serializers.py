from rest_framework import serializers

from apps.lessons.serializers import LessonListSerializer
from apps.search.models import SearchQuery


class SemanticSearchInputSerializer(serializers.Serializer):
    query = serializers.CharField(max_length=500)


class SearchHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchQuery
        fields = ("id", "query_text", "normalized_terms", "matched_article", "created_at")


class SemanticSearchResultSerializer(serializers.Serializer):
    query = serializers.CharField()
    normalized_terms = serializers.ListField(child=serializers.CharField())
    expanded_terms = serializers.ListField(child=serializers.CharField())
    matched_article = serializers.CharField()
    matched_terms = serializers.ListField(child=serializers.CharField())
    confidence = serializers.FloatField()
    explanation = serializers.CharField()
    nlp = serializers.DictField()
    sparql = serializers.DictField()
    ranking = serializers.ListField(child=serializers.DictField())
    lessons = LessonListSerializer(many=True)
