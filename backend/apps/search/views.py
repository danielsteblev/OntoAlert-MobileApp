from rest_framework import generics
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.lessons.seed import ensure_demo_content
from apps.lessons.serializers import LessonListSerializer
from apps.search.models import SearchQuery
from apps.search.serializers import SearchHistorySerializer, SemanticSearchInputSerializer
from apps.search.services import semantic_search


class SemanticSearchView(APIView):
    def post(self, request):
        ensure_demo_content()
        serializer = SemanticSearchInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        query = serializer.validated_data["query"]
        result = semantic_search(query)

        SearchQuery.objects.create(
            user=request.user,
            query_text=query,
            normalized_terms=result["normalized_terms"],
            matched_article=result["matched_article"],
        )

        payload = {
            **result,
            "lessons": LessonListSerializer(result["lessons"], many=True, context={"request": request}).data,
        }
        return Response(payload)


class SearchHistoryView(generics.ListAPIView):
    serializer_class = SearchHistorySerializer

    def get_queryset(self):
        return SearchQuery.objects.filter(user=self.request.user).order_by("-created_at")[:20]
