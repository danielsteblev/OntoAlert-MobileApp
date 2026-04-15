from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.lessons.models import Bookmark, Lesson
from apps.lessons.seed import ensure_demo_content
from apps.lessons.serializers import BookmarkSerializer, LessonDetailSerializer, LessonListSerializer


class LessonListView(generics.ListAPIView):
    serializer_class = LessonListSerializer

    def get_queryset(self):
        ensure_demo_content()
        queryset = Lesson.objects.select_related("topic").all().order_by("topic__article_code", "title")
        topic_slug = self.request.query_params.get("topic")
        if topic_slug:
            queryset = queryset.filter(topic__slug=topic_slug)
        return queryset


class LessonDetailView(generics.RetrieveAPIView):
    serializer_class = LessonDetailSerializer
    lookup_field = "id"

    def get_queryset(self):
        ensure_demo_content()
        return Lesson.objects.select_related("topic").prefetch_related("questions__options")


class BookmarkListView(generics.ListAPIView):
    serializer_class = BookmarkSerializer

    def get_queryset(self):
        ensure_demo_content()
        return Bookmark.objects.filter(user=self.request.user).select_related("lesson__topic").order_by("-created_at")


class BookmarkToggleView(APIView):
    def post(self, request, lesson_id: int):
        ensure_demo_content()
        bookmark, created = Bookmark.objects.get_or_create(user=request.user, lesson_id=lesson_id)
        return Response({"bookmarked": True, "created": created, "id": bookmark.id}, status=status.HTTP_200_OK)

    def delete(self, request, lesson_id: int):
        Bookmark.objects.filter(user=request.user, lesson_id=lesson_id).delete()
        return Response({"bookmarked": False}, status=status.HTTP_200_OK)
