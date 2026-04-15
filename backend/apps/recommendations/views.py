from rest_framework.response import Response
from rest_framework.views import APIView

from apps.lessons.seed import ensure_demo_content
from apps.lessons.serializers import LessonListSerializer
from apps.recommendations.services import build_recommendations_for_user


class RecommendationListView(APIView):
    def get(self, request):
        ensure_demo_content()
        recommendations = build_recommendations_for_user(request.user)
        payload = [
            {
                "lesson": LessonListSerializer(item["lesson"], context={"request": request}).data,
                "reason": item["reason"],
                "score": item["score"],
            }
            for item in recommendations
        ]
        return Response(payload)
