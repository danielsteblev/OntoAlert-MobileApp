from django.contrib import admin
from django.db.models import Avg, Count

from apps.lessons.models import AnswerOption, Lesson, LessonAttempt, Question, Topic


class AnswerOptionInline(admin.TabularInline):
    model = AnswerOption
    extra = 1


class QuestionInline(admin.StackedInline):
    model = Question
    extra = 1


@admin.register(Topic)
class TopicAdmin(admin.ModelAdmin):
    list_display = ("title", "article_code", "slug")
    search_fields = ("title", "article_code", "slug")


@admin.register(Lesson)
class LessonAdmin(admin.ModelAdmin):
    list_display = ("title", "topic", "sort_order", "display_rating", "display_learners_count")
    list_filter = ("topic", "difficulty")
    search_fields = ("title", "slug")
    ordering = ("sort_order", "title")
    inlines = [QuestionInline]
    exclude = ("short_description",)

    def get_queryset(self, request):
        return super().get_queryset(request).annotate(
            live_rating=Avg("attempts__rating"),
            live_learners_count=Count("attempts", distinct=True),
        )

    @admin.display(description="Rating")
    def display_rating(self, obj):
        return round(float(obj.live_rating or 0), 1)

    @admin.display(description="Learners")
    def display_learners_count(self, obj):
        return int(obj.live_learners_count or 0)


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ("prompt", "lesson")
    search_fields = ("prompt",)
    inlines = [AnswerOptionInline]


@admin.register(LessonAttempt)
class LessonAttemptAdmin(admin.ModelAdmin):
    list_display = ("lesson", "user", "score_percent", "rating", "completed_at")
    list_filter = ("lesson", "rating")
    search_fields = ("lesson__title", "user__username", "user__email")
    ordering = ("-completed_at",)
