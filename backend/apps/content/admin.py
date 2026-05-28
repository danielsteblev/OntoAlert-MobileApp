from django.contrib import admin

from apps.content.models import HintStory, HintStorySlide, LegalDocument


class HintStorySlideInline(admin.TabularInline):
    model = HintStorySlide
    extra = 1
    ordering = ("sort_order", "id")


@admin.register(LegalDocument)
class LegalDocumentAdmin(admin.ModelAdmin):
    list_display = ("title", "slug", "file_size", "mime_type", "sort_order", "is_active", "updated_at")
    list_filter = ("is_active", "mime_type")
    search_fields = ("title", "slug", "description")
    prepopulated_fields = {"slug": ("title",)}
    ordering = ("sort_order", "title")


@admin.register(HintStory)
class HintStoryAdmin(admin.ModelAdmin):
    list_display = ("title", "sort_order", "is_active", "created_at")
    list_filter = ("is_active",)
    search_fields = ("title", "subtitle", "body")
    ordering = ("sort_order", "-created_at")
    inlines = [HintStorySlideInline]
