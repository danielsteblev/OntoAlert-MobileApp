from rest_framework import serializers

from apps.lessons.models import AnswerOption, Bookmark, Lesson, LessonAttempt, Question, Topic


class AnswerOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = AnswerOption
        fields = ("id", "text", "is_correct")


class QuestionSerializer(serializers.ModelSerializer):
    options = AnswerOptionSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ("id", "prompt", "explanation", "options")


class TopicSerializer(serializers.ModelSerializer):
    class Meta:
        model = Topic
        fields = ("id", "title", "slug", "article_code", "summary", "semantic_keywords")


class LessonListSerializer(serializers.ModelSerializer):
    topic = TopicSerializer(read_only=True)
    is_bookmarked = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    questions_count = serializers.IntegerField(source="questions.count", read_only=True)
    rating = serializers.SerializerMethodField()
    learners_count = serializers.SerializerMethodField()

    class Meta:
        model = Lesson
        fields = (
            "id",
            "title",
            "slug",
            "short_description",
            "difficulty",
            "estimated_minutes",
            "rating",
            "learners_count",
            "questions_count",
            "image_url",
            "topic",
            "is_bookmarked",
        )

    def get_is_bookmarked(self, obj):
        user = self.context["request"].user
        if not user.is_authenticated:
            return False
        return Bookmark.objects.filter(user=user, lesson=obj).exists()

    def get_image_url(self, obj):
        request = self.context.get("request")
        if not obj.cover_image:
            return ""
        return request.build_absolute_uri(obj.cover_image.url) if request else obj.cover_image.url

    def get_rating(self, obj):
        annotated = getattr(obj, "rating_live", None)
        if annotated is not None:
            return round(float(annotated), 1)
        rating = obj.attempts.exclude(rating__isnull=True).values_list("rating", flat=True)
        if not rating:
            return 0.0
        return round(sum(rating) / len(rating), 1)

    def get_learners_count(self, obj):
        annotated = getattr(obj, "learners_count_live", None)
        if annotated is not None:
            return int(annotated)
        return obj.attempts.count()


class LessonDetailSerializer(LessonListSerializer):
    questions = QuestionSerializer(many=True, read_only=True)

    class Meta(LessonListSerializer.Meta):
        fields = LessonListSerializer.Meta.fields + ("theory", "article_excerpt", "questions")


class BookmarkSerializer(serializers.ModelSerializer):
    lesson = LessonListSerializer(read_only=True)

    class Meta:
        model = Bookmark
        fields = ("id", "lesson", "created_at")


class LessonAttemptSerializer(serializers.ModelSerializer):
    rating = serializers.IntegerField(min_value=1, max_value=5)
    score_percent = serializers.IntegerField(min_value=0, max_value=100)

    class Meta:
        model = LessonAttempt
        fields = ("score_percent", "rating")
