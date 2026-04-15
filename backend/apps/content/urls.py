from django.urls import path

from apps.content.views import HintStoryListView


urlpatterns = [
    path("", HintStoryListView.as_view(), name="hint-list"),
]
