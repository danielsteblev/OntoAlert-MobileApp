#!/bin/sh
set -e

python /app/ontology/scripts/build_chapter20_ontology.py

python manage.py migrate
python manage.py migrate --run-syncdb
python manage.py collectstatic --noinput
python manage.py seed_demo_content
python manage.py sync_ontology_topics
python manage.py seed_legal_documents
python manage.py ensure_admin_user

exec gunicorn config.wsgi:application --bind 0.0.0.0:8000 --workers 3 --timeout 120
