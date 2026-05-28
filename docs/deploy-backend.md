# Backend Deployment

## 1. Prepare server

Install Docker and Docker Compose plugin on the VPS.

## 2. Copy project

Clone the repository onto the server:

```bash
git clone <your-repo-url>
cd OntoAlert-MobileApp
```

## 3. Create `.env`

Create a root `.env` file next to `docker-compose.yml`:

```env
DJANGO_SECRET_KEY=replace-with-a-long-random-secret
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=your-domain-or-server-ip
CORS_ALLOWED_ORIGINS=https://your-admin-domain,https://your-app-domain
CSRF_TRUSTED_ORIGINS=https://your-admin-domain,https://your-app-domain

DATABASE_NAME=fastlearning
DATABASE_USER=postgres
DATABASE_PASSWORD=replace-with-strong-password
DATABASE_HOST=db
DATABASE_PORT=5432

JWT_ACCESS_MINUTES=60
JWT_REFRESH_DAYS=7
```

## 4. Start stack

```bash
docker compose up -d --build
```

This starts 3 containers:

- `db` - PostgreSQL
- `backend` - Django + Gunicorn
- `nginx` - public reverse proxy on port `80`

The backend container entrypoint will automatically:

- apply migrations
- collect static files
- seed demo content
- create/update the admin user
- start Gunicorn on internal port `8000`

## 5. Check status

```bash
docker compose ps
docker compose logs -f backend
docker compose logs -f nginx
```

## 6. Open API

- Healthcheck: `http://your-server/api/health/`
- Admin: `http://your-server/admin/`

Default admin credentials created by `ensure_admin_user`:

- username: `admin`
- password: `admin12345`

Change them immediately in production:

```bash
docker compose exec backend python manage.py ensure_admin_user --username admin --email your@email --password "new-strong-password"
```

## 7. Point Flutter app to server

Run/build the mobile app with:

```bash
flutter run --dart-define=API_BASE_URL=http://your-server
```

For release builds:

```bash
flutter build apk --release --dart-define=API_BASE_URL=http://your-server
```

## Notes

- Only `nginx` is exposed publicly.
- `backend` and `db` stay inside the Docker network.
- Static and media files are served by `nginx`.

## Recommended next step

Add HTTPS with Let's Encrypt or place the stack behind an external reverse proxy.

## CI/CD (GitHub Actions)

This repository includes `.github/workflows/main.yml` with:

- backend CI (`manage.py check`, `manage.py test`)
- mobile CI (`flutter analyze`, `flutter test`)
- backend deploy over SSH on push to `main`

Configure these repository secrets before enabling deploy:

- `SSH_HOST` - server IP or domain
- `SSH_USERNAME` - server user (for example `steblev`)
- `SSH_PRIVATE_KEY` - private SSH key that can access the server
