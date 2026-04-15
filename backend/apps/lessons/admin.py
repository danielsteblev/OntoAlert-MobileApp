from django.contrib import admin

from apps.lessons.models import AnswerOption, Lesson, Question, Topic


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
    list_display = ("title", "topic", "sort_order", "rating", "learners_count")
    list_filter = ("topic", "difficulty")
    search_fields = ("title", "slug", "short_description")
    ordering = ("sort_order", "title")
    inlines = [QuestionInline]


@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ("prompt", "lesson")
    search_fields = ("prompt",)
    inlines = [AnswerOptionInline]
