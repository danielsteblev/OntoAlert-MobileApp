from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from apps.accounts.models import Profile


class Command(BaseCommand):
    help = "Create or update a superuser for Django admin."

    def add_arguments(self, parser):
        parser.add_argument("--username", default="admin")
        parser.add_argument("--email", default="admin@fast-learning.local")
        parser.add_argument("--password", default="admin12345")
        parser.add_argument("--full-name", default="Администратор")

    def handle(self, *args, **options):
        user_model = get_user_model()
        user, created = user_model.objects.get_or_create(
            username=options["username"],
            defaults={
                "email": options["email"],
                "is_staff": True,
                "is_superuser": True,
            },
        )

        user.email = options["email"]
        user.is_staff = True
        user.is_superuser = True
        user.set_password(options["password"])
        user.save()

        profile, _ = Profile.objects.get_or_create(user=user)
        profile.full_name = options["full_name"]
        profile.save()

        action = "Created" if created else "Updated"
        self.stdout.write(
            self.style.SUCCESS(f"{action} admin user '{options['username']}' with password '{options['password']}'.")
        )
