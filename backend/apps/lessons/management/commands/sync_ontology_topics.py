from django.core.management.base import BaseCommand

from apps.lessons.seed import sync_ontology_topics


class Command(BaseCommand):
    help = "Upsert chapter 20 topics and lessons from ontology seed without resetting the database."

    def add_arguments(self, parser):
        parser.add_argument(
            "--create-only",
            action="store_true",
            help="Only create missing records; do not update existing topics and lessons.",
        )

    def handle(self, *args, **options):
        stats = sync_ontology_topics(update_existing=not options["create_only"])

        self.stdout.write(
            self.style.SUCCESS(
                "Ontology topics synced: "
                f"topics +{stats['topics_created']} ~{stats['topics_updated']}, "
                f"lessons +{stats['lessons_created']} ~{stats['lessons_updated']}, "
                f"questions +{stats['questions_created']} ~{stats['questions_updated']}, "
                f"options +{stats['options_created']}."
            )
        )
