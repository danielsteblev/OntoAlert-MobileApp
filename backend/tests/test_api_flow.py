from django.urls import reverse
from rest_framework.test import APITestCase


class ApiFlowTests(APITestCase):
    def authenticate(self):
        response = self.client.post(
            "/api/auth/register",
            {
                "username": "student1",
                "email": "student@example.com",
                "password": "strongpass123",
                "full_name": "Иван Студент",
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        access = response.data["tokens"]["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access}")

    def test_student_flow(self):
        self.authenticate()

        profile_response = self.client.get("/api/profile/me")
        self.assertEqual(profile_response.status_code, 200)
        self.assertEqual(profile_response.data["full_name"], "Иван Студент")

        lessons_response = self.client.get("/api/lessons")
        self.assertEqual(lessons_response.status_code, 200)
        self.assertGreaterEqual(len(lessons_response.data), 1)

        first_lesson_id = lessons_response.data[0]["id"]
        bookmark_response = self.client.post(f"/api/bookmarks/{first_lesson_id}")
        self.assertEqual(bookmark_response.status_code, 200)
        self.assertTrue(bookmark_response.data["bookmarked"])

        search_response = self.client.post("/api/search/semantic", {"query": "мелкое хулиганство в парке"}, format="json")
        self.assertEqual(search_response.status_code, 200)
        self.assertIn("matched_article", search_response.data)

        history_response = self.client.get("/api/search/history")
        self.assertEqual(history_response.status_code, 200)
        self.assertGreaterEqual(len(history_response.data), 1)

        recommendation_response = self.client.get("/api/recommendations/")
        self.assertEqual(recommendation_response.status_code, 200)
        self.assertGreaterEqual(len(recommendation_response.data), 1)

        hints_response = self.client.get("/api/hints/")
        self.assertEqual(hints_response.status_code, 200)
        self.assertGreaterEqual(len(hints_response.data), 1)
