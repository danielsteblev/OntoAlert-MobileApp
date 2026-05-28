from rest_framework import generics
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.content.models import LegalDocument
from apps.content.serializers import LegalDocumentSerializer


class LegalDocumentListView(generics.ListAPIView):
    serializer_class = LegalDocumentSerializer

    def get_queryset(self):
        return (
            LegalDocument.objects.filter(is_active=True)
            .exclude(file="")
            .order_by("sort_order", "title")
        )


class LegalDocumentDetailView(generics.RetrieveAPIView):
    serializer_class = LegalDocumentSerializer
    lookup_field = "slug"

    def get_queryset(self):
        return LegalDocument.objects.filter(is_active=True).exclude(file="")


class LegalDocumentOfflineManifestView(APIView):
    """Metadata for mobile offline sync (no file bytes in this response)."""

    def get(self, request):
        documents = (
            LegalDocument.objects.filter(is_active=True)
            .exclude(file="")
            .order_by("sort_order", "title")
        )
        serializer = LegalDocumentSerializer(documents, many=True, context={"request": request})
        return Response(
            {
                "documents": serializer.data,
                "storage": "s3" if documents and serializer.data else "local",
                "hint": "Download each file_url while online, then open from local cache.",
            }
        )
