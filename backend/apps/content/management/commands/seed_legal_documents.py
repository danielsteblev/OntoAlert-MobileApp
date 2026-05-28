from django.core.management.base import BaseCommand

from apps.content.models import LegalDocument


class Command(BaseCommand):
    help = "Create placeholder legal document records (upload PDF files via admin)."

    def handle(self, *args, **options):
        placeholders = [
            {
                "title": "Конституция Российской Федерации",
                "slug": "constitution-rf",
                "description": "Основной закон Российской Федерации.",
                "sort_order": 1,
            },
            {
                "title": "Кодекс об административных правонарушениях (фрагмент гл. 20)",
                "slug": "koap-chapter-20",
                "description": "Учебный фрагмент главы 20 КоАП РФ для приложения Fast Learning.",
                "sort_order": 2,
            },
            {
                "title": "Трудовой кодекс (справочный фрагмент)",
                "slug": "tk-rf-fragment",
                "description": "Справочные материалы по трудовому праву.",
                "sort_order": 3,
            },
        ]

        created = 0
        for payload in placeholders:
            _, was_created = LegalDocument.objects.get_or_create(
                slug=payload["slug"],
                defaults={
                    "title": payload["title"],
                    "description": payload["description"],
                    "sort_order": payload["sort_order"],
                    "is_active": True,
                },
            )
            if was_created:
                created += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Legal documents: {created} created, {len(placeholders) - created} already existed. "
                "Upload PDF files in Django admin for records without a file."
            )
        )
