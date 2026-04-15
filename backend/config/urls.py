from django.contrib import admin
from django.urls import include, path
from rest_framework.response import Response
from rest_framework.views import APIView


class HealthView(APIView):
    permission_classes = []

    def get(self, request):
        return Response({"status": "ok", "service": "fast-learning-api"})


urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthView.as_view(), name="health"),
    path("api/auth/", include("apps.accounts.urls")),
    path("api/", include("apps.accounts.profile_urls")),
    path("api/", include("apps.lessons.urls")),
    path("api/search/", include("apps.search.urls")),
    path("api/recommendations/", include("apps.recommendations.urls")),
    path("api/hints/", include("apps.content.urls")),
]
