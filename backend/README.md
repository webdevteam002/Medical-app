# MedStudy API (Person 1 — Backend)

NestJS API with PostgreSQL, Prisma, JWT auth, and single-device sessions.

## Quick start

### 1. Prerequisites
- Node.js 20+
- Docker Desktop (for local PostgreSQL) **or** PostgreSQL installed locally

### 2. Install & configure

```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` — set strong `JWT_SECRET` and `JWT_REFRESH_SECRET` (min 32 chars).

### 3. Start database

```bash
docker compose up -d
```

### 4. Migrate & seed

```bash
npx prisma migrate dev --name init
npm run prisma:seed
```

### 5. Run API

```bash
npm run start:dev
```

- API: http://localhost:3000/v1
- Swagger: http://localhost:3000/api/docs
- Health: http://localhost:3000/v1/health

## Default admin (after seed)

| Field | Value |
|-------|-------|
| Email | `admin@medstudy.local` |
| Password | `Admin123!` |

Change this password before production.

## Auth endpoints (Day 1–10 complete)

| Method | Path | Auth |
|--------|------|------|
| POST | `/v1/auth/register` | Public |
| POST | `/v1/auth/login` | Public |
| POST | `/v1/auth/refresh` | Public |
| POST | `/v1/auth/logout` | Bearer + `X-Device-Id` |
| GET | `/v1/auth/me` | Bearer + `X-Device-Id` |

## Admin endpoints (Day 16–20)

| Method | Path | Role |
|--------|------|------|
| GET | `/v1/admin/users` | ADMIN |
| PATCH | `/v1/admin/users/:id/ban` | ADMIN |
| POST | `/v1/admin/users/:id/reset-device` | ADMIN |

All authenticated routes require header: `X-Device-Id: <device-fingerprint>`

## Test login (curl)

```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"admin@medstudy.local\",\"password\":\"Admin123!\",\"deviceId\":\"test-device-001\",\"deviceName\":\"Dev Machine\"}"
```

## Person 1 progress

- [x] Day 1–5: NestJS scaffold, Prisma, auth endpoints
- [x] Day 6–10: Seeds, Swagger, `/auth/me`, health check
- [x] Day 11–15: Single-device sessions, device guard
- [x] Day 16–20: Admin user list, ban, reset device
- [x] Day 21–25: Storage (R2 + local fallback), material upload
- [x] Day 26–30: Content API (years, subjects, materials, access URLs)
- [x] Day 31–45: Exam engine (questions, CSV import, start/submit/grade/review)
- [x] Day 46–50: JazzCash manual payments (`/payments/plans`, `/payments/instructions`, admin grant/list/revoke)
- [x] Day 51–55: Production deploy files (Dockerfile, docker-compose.prod, nginx, PM2, DEPLOY.md)
- [x] Day 56–60: Rate limiting on login, bookmarks API, backup script
- [x] Day 61–65: CSV import hardening (dry-run, BOM), DB indexes, SSL pins endpoint, batch upload script
- [ ] Day 66+: Production deploy on Oracle VM (you run DEPLOY.md)

## Content endpoints (Day 21–30)

### Student (requires auth + subscription + X-Device-Id)

| Method | Path |
|--------|------|
| GET | `/v1/years` |
| GET | `/v1/years/:yearSlug/subjects` |
| GET | `/v1/subjects/:subjectId/materials` |
| GET | `/v1/materials/:id/access` |
| GET | `/v1/materials/:id/stream` (local dev storage) |

### Admin

| Method | Path |
|--------|------|
| GET/POST | `/v1/admin/years` |
| GET/POST | `/v1/admin/subjects` |
| GET/POST | `/v1/admin/topics` |
| GET | `/v1/admin/subjects/:id/topics` |
| GET/POST/PATCH/DELETE | `/v1/admin/materials` |
| POST | `/v1/admin/materials/upload` (multipart) |
| POST | `/v1/admin/subscriptions/users/:userId/grant` |
| GET | `/v1/admin/subscriptions` |
| POST | `/v1/admin/subscriptions/:id/revoke` |

## JazzCash payments (no Google/Apple fee)

| Method | Path | Auth |
|--------|------|------|
| GET | `/v1/payments/plans` | Public |
| GET | `/v1/payments/instructions` | Public |

Set `PAYMENT_JAZZCASH_NUMBER`, etc. in `.env`.

## Bookmarks

| POST | `/v1/bookmarks/:materialId` |
| DELETE | `/v1/bookmarks/:materialId` |
| GET | `/v1/bookmarks` |

## Security (Flutter pinning)

| GET | `/v1/security/ssl-pins` | Public |

## Storage modes

- **R2:** Set `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` in `.env`
- **Local (dev):** If R2 vars empty, files save to `backend/uploads/`

## Test accounts (after seed)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@medstudy.local | Admin123! |
| Student (Year 1 sub) | student@test.com | Student123! |
