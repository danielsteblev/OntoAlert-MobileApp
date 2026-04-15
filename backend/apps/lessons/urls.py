from django.urls import path

from apps.lessons.views import BookmarkListView, BookmarkToggleView, LessonDetailView, LessonListView


urlpatterns = [
    path("lessons", LessonListView.as_view(), name="lesson-list"),
    path("lessons/<int:id>", LessonDetailView.as_view(), name="lesson-detail"),
    path("bookmarks", BookmarkListView.as_view(), name="bookmark-list"),
    path("bookmarks/<int:lesson_id>", BookmarkToggleView.as_view(), name="bookmark-toggle"),
]
