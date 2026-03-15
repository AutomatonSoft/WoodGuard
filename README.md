# Woodguard

Woodguard is a timber due diligence workspace built around invoice dossiers.

- `FastAPI` imports invoice rows from Warehub and stores internal compliance data.
- `Next.js` is the browser UI for operators and reviewers.
- `Streamlit` is a faster internal console for QA and manual testing.
- `JWT auth + roles` protect business endpoints.
- `Refresh tokens + audit trail` support longer-lived operator sessions and traceability.
- `Alembic + Postgres-ready config + S3-compatible storage` prepare the project for a more production-like environment.

## What the backend stores

- Raw Warehub invoice payload
- User accounts and roles: `admin`, `analyst`, `reviewer`, `viewer`
- Refresh sessions and token revocation
- Supplier card and contact details
- Evidence uploads: certificate, location photos, notice, transport papers, geolocation screenshots, other files
- Wood specification: species, material type, quantity, origin, delivery date
- Human review inputs: child labor, human rights, personal risk, rationale
- Calculated risk summary with breakdown and blockers
- Audit events for login, sync, upload, dossier changes and user administration

## Run the API

```bash
venv\Scripts\python.exe -m pip install -r requirements.txt
venv\Scripts\alembic.exe upgrade head
venv\Scripts\uvicorn.exe main:app --reload
```

API base: `http://127.0.0.1:8000/api/v1`

Default local bootstrap admin:

- Username: `admin`
- Password: `woodguard123`

Change `JWT_SECRET_KEY` and bootstrap credentials in `.env` before using this outside local development.

New auth flow:

- `POST /api/v1/auth/login` returns access token + refresh token
- `POST /api/v1/auth/refresh` rotates refresh tokens
- `POST /api/v1/auth/logout` revokes the current refresh token
- Next automatically refreshes expired access tokens
- Streamlit also refreshes expired access tokens during API calls

Important assumption:

- The current public Warehub endpoint only exposes financial invoice facts such as invoice number, status, paid amount and remaining amount.
- Supplier profile, wood origin, geolocation evidence and compliance data are completed inside Woodguard after sync.
- If seller address / seller geolocation label / seller name are filled, Woodguard can auto-resolve coordinates during save using the configured geocoding provider.

Geolocation auto-fill settings:

```bash
GEOCODING_ENABLED=true
GEOCODING_BASE_URL=https://nominatim.openstreetmap.org
GEOCODING_TIMEOUT_SECONDS=8
GEOCODING_USER_AGENT=woodguard/1.0 (local-development)
GEOCODING_CONTACT_EMAIL=
```

## Postgres and migrations

Local Postgres + MinIO containers:

```bash
docker compose up -d
```

Full Docker stack with API + Next frontend + Postgres + MinIO:

```bash
docker compose up --build
```

Services:

- Frontend: `http://127.0.0.1:3000`
- API: `http://127.0.0.1:8000/api/v1`
- MinIO API: `http://127.0.0.1:9000`
- MinIO Console: `http://127.0.0.1:9001`

Docker compose overrides the app config for container use:

- API uses Postgres at `postgres:5432`
- Upload storage switches to MinIO/S3
- Next frontend is built with `NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1`

Example Postgres connection string:

```bash
DATABASE_URL=postgresql+psycopg://woodguard:woodguard@localhost:5432/woodguard
AUTO_CREATE_SCHEMA=false
```

Apply migrations:

```bash
venv\Scripts\alembic.exe upgrade head
```

S3-compatible local storage with MinIO:

```bash
STORAGE_BACKEND=s3
S3_ENDPOINT_URL=http://127.0.0.1:9000
S3_BUCKET_NAME=woodguard
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin
S3_REGION_NAME=us-east-1
S3_KEY_PREFIX=woodguard
S3_PUBLIC_BASE_URL=
```

Notes:

- With `STORAGE_BACKEND=local`, uploads stay under `storage/uploads`
- With `STORAGE_BACKEND=s3`, uploads go to MinIO or any S3-compatible bucket
- If `S3_PUBLIC_BASE_URL` is empty, the API returns presigned GET URLs

Create a new migration after schema changes:

```bash
venv\Scripts\alembic.exe revision --autogenerate -m "describe change"
```

## Run the Next frontend

```bash
cd frontend
npm install
npm run dev
```

Frontend URL: `http://127.0.0.1:3000`

Optional `frontend/.env.local`:

```bash
NEXT_PUBLIC_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

The Next app now requires login, stores access + refresh tokens in local storage, auto-refreshes sessions, and shows invoice audit history.

Production image build only:

```bash
docker compose build frontend api
```

## Run the Streamlit console

```bash
venv\Scripts\streamlit.exe run streamlit_app.py
```

Console URL: `http://127.0.0.1:8501`

The Streamlit console also requires login with the same API credentials, supports refresh tokens, uploads evidence into the invoice context, and shows audit events.

## Main endpoints

- `GET /api/v1/health`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/me`
- `GET /api/v1/users`
- `POST /api/v1/users`
- `PATCH /api/v1/users/{id}`
- `POST /api/v1/invoices/sync/warehub`
- `GET /api/v1/invoices`
- `POST /api/v1/invoices`
- `GET /api/v1/invoices/{id}`
- `GET /api/v1/invoices/{id}/audit-logs`
- `PUT /api/v1/invoices/{id}`
- `PUT /api/v1/invoices/{id}/assessment`
- `POST /api/v1/uploads`
- `GET /api/v1/audit-logs`
- `GET /api/v1/dashboard/metrics`
- `GET /api/v1/reference/options`
