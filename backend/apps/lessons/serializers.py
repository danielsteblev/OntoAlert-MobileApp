from rest_framework import serializers

from apps.lessons.models import AnswerOption, Bookmark, Lesson, Question, Topic


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

    class Meta:
        model = Lesson
        fields = (
            "id",
            "title",
            "slug",
            "short_description",
            "difficulty",
            "estimated_minutes",
            "topic",
            "is_bookmarked",
        )

    def get_is_bookmarked(self, obj):
        user = self.context["request"].user
        if not user.is_authenticated:
            return False
        return Bookmark.objects.filter(user=user, lesson=obj).exists()


class LessonDetailSerializer(LessonListSerializer):
    questions = QuestionSerializer(many=True, read_only=True)

    class Meta(LessonListSerializer.Meta):
        fields = LessonListSerializer.Meta.fields + ("theory", "article_excerpt", "questions")


class BookmarkSerializer(serializers.ModelSerializer):
    lesson = LessonListSerializer(read_only=True)

    class Meta:
        model = Bookmark
        fields = ("id", "lesson", "created_at")
