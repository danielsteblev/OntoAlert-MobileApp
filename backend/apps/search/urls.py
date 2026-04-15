from django.urls import path

from apps.search.views import SearchHistoryView, SemanticSearchView


urlpatterns = [
    path("semantic", SemanticSearchView.as_view(), name="semantic-search"),
    path("history", SearchHistoryView.as_view(), name="search-history"),
]
