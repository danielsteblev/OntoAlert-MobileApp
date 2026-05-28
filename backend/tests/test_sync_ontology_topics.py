from django.core.management import call_command
from django.test import TestCase

from apps.lessons.models import Lesson, Topic
from apps.lessons.seed import sync_ontology_topics


class SyncOntologyTopicsTests(TestCase):
    def test_sync_creates_missing_topics(self):
        stats = sync_ontology_topics()
        self.assertGreaterEqual(Topic.objects.count(), 7)
        self.assertGreaterEqual(Lesson.objects.count(), 7)
        self.assertGreater(Topic.objects.filter(article_code="20.3").count(), 0)
        self.assertGreater(stats["topics_created"] + stats["topics_updated"], 0)

    def test_sync_is_idempotent(self):
        sync_ontology_topics()
        topic_count = Topic.objects.count()
        lesson_count = Lesson.objects.count()

        second = sync_ontology_topics()
        self.assertEqual(second["topics_created"], 0)
        self.assertEqual(second["lessons_created"], 0)
        self.assertEqual(Topic.objects.count(), topic_count)
        self.assertEqual(Lesson.objects.count(), lesson_count)

    def test_management_command_runs(self):
        call_command("sync_ontology_topics")
        self.assertTrue(Topic.objects.filter(article_code="20.6").exists())
