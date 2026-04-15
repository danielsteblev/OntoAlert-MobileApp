# Fast-learning

Fast-learning is an Android-first legal education platform built around chapter 20 of the Russian Administrative Offenses Code. The repository contains a Flutter mobile client, a Django REST backend, and ontology assets for semantic search over administrative offense scenarios.

## Repository layout

- `mobile_app/` Flutter client structure and UI code
- `backend/` Django REST API, business logic, and tests
- `ontology/` OWL builder scripts and chapter 20 source data
- `docs/` architecture and API notes

## Key MVP capabilities

- student registration and login
- profile management
- lesson catalog with bookmarks
- semantic search over chapter 20 topics
- search history and rule-based lesson recommendations
- hint stories on the home screen

## Local setup

### Backend

1. Create a virtual environment in `backend/`
2. Install dependencies from `backend/requirements.txt`
3. Copy `.env.example` values into your environment
4. Run `python manage.py migrate --run-syncdb`
5. Run `python manage.py seed_demo_content`
6. Run `python manage.py runserver`

### Database

`docker-compose.yml` contains a local PostgreSQL service definition for development.

### Ontology

1. Install backend dependencies
2. Run `python ../ontology/scripts/build_chapter20_ontology.py`
3. Run `python ../ontology/scripts/validate_ontology.py`

### Flutter

Flutter SDK is required locally to run the client. The repository already contains the app source under `mobile_app/`, but the SDK was not available in this environment for running `flutter create` or `flutter test`.