from django.urls import path

from apps.content.document_views import (
    LegalDocumentDetailView,
    LegalDocumentListView,
    LegalDocumentOfflineManifestView,
)


urlpatterns = [
    path("", LegalDocumentListView.as_view(), name="document-list"),
    path("offline-manifest/", LegalDocumentOfflineManifestView.as_view(), name="document-offline-manifest"),
    path("<slug:slug>/", LegalDocumentDetailView.as_view(), name="document-detail"),
]
