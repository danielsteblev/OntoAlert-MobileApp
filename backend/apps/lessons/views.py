from django.db.models import Avg, Count, Q
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.lessons.models import Bookmark, Lesson, LessonAttempt
from apps.lessons.seed import ensure_demo_content
from apps.lessons.serializers import BookmarkSerializer, LessonAttemptSerializer, LessonDetailSerializer, LessonListSerializer


def _lesson_queryset():
    return (
        Lesson.objects.select_related("topic")
        .prefetch_related("questions")
        .annotate(
            learners_count_live=Count("attempts", distinct=True),
            rating_live=Avg("attempts__rating", filter=Q(attempts__rating__isnull=False)),
        )
    )


class LessonListView(generics.ListAPIView):
    serializer_class = LessonListSerializer

    def get_queryset(self):
        ensure_demo_content()
        queryset = _lesson_queryset().order_by("sort_order", "topic__article_code", "title")
        topic_slug = self.request.query_params.get("topic")
        if topic_slug:
            queryset = queryset.filter(topic__slug=topic_slug)
        return queryset


class LessonDetailView(generics.RetrieveAPIView):
    serializer_class = LessonDetailSerializer
    lookup_field = "id"

    def get_queryset(self):
        ensure_demo_content()
        return _lesson_queryset().prefetch_related("questions__options")


class BookmarkListView(generics.ListAPIView):
    serializer_class = BookmarkSerializer

    def get_queryset(self):
        ensure_demo_content()
        return (
            Bookmark.objects.filter(user=self.request.user)
            .select_related("lesson__topic")
            .prefetch_related("lesson__questions", "lesson__attempts")
            .order_by("-created_at")
        )


class BookmarkToggleView(APIView):
    def post(self, request, lesson_id: int):
        ensure_demo_content()
        bookmark, created = Bookmark.objects.get_or_create(user=request.user, lesson_id=lesson_id)
        return Response({"bookmarked": True, "created": created, "id": bookmark.id}, status=status.HTTP_200_OK)

    def delete(self, request, lesson_id: int):
        Bookmark.objects.filter(user=request.user, lesson_id=lesson_id).delete()
        return Response({"bookmarked": False}, status=status.HTTP_200_OK)


class LessonCompleteView(APIView):
    def post(self, request, lesson_id: int):
        ensure_demo_content()
        serializer = LessonAttemptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        attempt, _ = LessonAttempt.objects.update_or_create(
            user=request.user,
            lesson_id=lesson_id,
            defaults=serializer.validated_data,
        )
        lesson = _lesson_queryset().get(id=lesson_id)
        return Response(
            {
                "attempt_id": attempt.id,
                "lesson": LessonDetailSerializer(
                    lesson,
                    context={"request": request},
                ).data,
            },
            status=status.HTTP_200_OK,
        )
