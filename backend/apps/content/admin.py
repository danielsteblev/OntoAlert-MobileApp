from django.contrib import admin

from apps.content.models import HintStory, HintStorySlide


class HintStorySlideInline(admin.TabularInline):
    model = HintStorySlide
    extra = 1
    ordering = ("sort_order", "id")


@admin.register(HintStory)
class HintStoryAdmin(admin.ModelAdmin):
    list_display = ("title", "sort_order", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("title", "subtitle", "body")
    ordering = ("sort_order", "-created_at")
    inlines = [HintStorySlideInline]
