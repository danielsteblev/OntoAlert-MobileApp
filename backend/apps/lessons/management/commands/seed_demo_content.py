from django.core.management.base import BaseCommand

from apps.lessons.seed import ensure_demo_content


class Command(BaseCommand):
    help = "Populate the database with demo content for chapter 20."

    def handle(self, *args, **options):
        ensure_demo_content()
        self.stdout.write(self.style.SUCCESS("Demo content has been loaded."))
