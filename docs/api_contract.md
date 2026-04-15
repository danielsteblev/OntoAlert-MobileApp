# API Contract

## Authentication

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/profile/me`
- `PATCH /api/profile/me`

## Learning content

- `GET /api/lessons`
- `GET /api/lessons/{id}`
- `GET /api/bookmarks`
- `POST /api/bookmarks/{lesson_id}`
- `DELETE /api/bookmarks/{lesson_id}`

## Search

- `POST /api/search/semantic`
- `GET /api/search/history`

## Recommendations and hints

- `GET /api/recommendations/`
- `GET /api/hints/`
