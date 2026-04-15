from rest_framework import generics

from apps.content.models import HintStory
from apps.content.serializers import HintStorySerializer
from apps.lessons.seed import ensure_demo_content


class HintStoryListView(generics.ListAPIView):
    serializer_class = HintStorySerializer

    def get_queryset(self):
        ensure_demo_content()
        return HintStory.objects.filter(is_active=True).order_by("sort_order", "-created_at")
