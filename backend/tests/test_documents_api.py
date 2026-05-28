from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from apps.content.models import LegalDocument


class DocumentsApiTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        LegalDocument.objects.create(
            title="Тестовый документ",
            slug="test-doc",
            description="PDF для теста",
            file=SimpleUploadedFile("test.pdf", b"%PDF-1.4 test", content_type="application/pdf"),
            sort_order=1,
        )

    def authenticate(self):
        response = self.client.post(
            "/api/auth/register",
            {"email": "docs@example.com", "password": "strongpass123"},
            format="json",
        )
        token = response.data["tokens"]["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_documents_list_requires_auth_and_returns_file_url(self):
        self.authenticate()
        response = self.client.get("/api/documents/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["slug"], "test-doc")
        self.assertIn("file_url", response.data[0])
        self.assertIn("updated_at", response.data[0])

    def test_offline_manifest(self):
        self.authenticate()
        response = self.client.get("/api/documents/offline-manifest/")
        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data["documents"]), 1)
