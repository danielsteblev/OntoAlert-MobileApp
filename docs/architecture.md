# Fast-learning Architecture

## Overview

Fast-learning is organized as a monorepo with three main modules:

- `mobile_app/` for the Flutter Android client
- `backend/` for the Django REST API
- `ontology/` for chapter 20 ontology source data and OWL generation

## Request flow

1. The student authenticates in the Flutter app.
2. Flutter sends JWT-authenticated requests to Django REST API.
3. Django loads lesson content from PostgreSQL or local demo seed data.
4. Semantic search normalizes the query, matches chapter 20 keywords, and optionally enriches matches with OWL ontology terms.
5. The API stores search history and returns lessons, hints, and recommendations.

## MVP data flow

- `chapter20_seed.json` is used as a single source of truth for lessons, hints, and ontology generation.
- `build_chapter20_ontology.py` converts the seed data into `chapter20.owl`.
- Backend runtime uses the same content model for lessons and recommendations.
