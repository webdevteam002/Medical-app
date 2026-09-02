# Person 1 — Platform & API

**Role:** Backend developer + DevOps  
**You own:** `backend/` · Oracle VM · PostgreSQL · Cloudflare R2 · API contract  
**Works with:** Person 2 (uses your API) · Person 3 (uploads content through APIs/admin Person 2 builds)

> **Daily schedule (Day 1–80):** [PERSON_1_DAILY.md](./PERSON_1_DAILY.md) — every working day, Mon–Fri, 16 weeks

---

## Your job in one sentence

Build and run the **server brain** — auth, subscriptions, content access, exam grading, file storage — so Person 2’s apps and Person 3’s content have something solid to plug into.

---

## What you own

| Area | Your responsibility |
|------|---------------------|
| NestJS API | All business logic and endpoints |
| PostgreSQL + Prisma | Schema, migrations, seeds |
| Cloudflare R2 | Upload, storage, presigned URLs |
| Oracle VM | Deploy API, DB, Nginx, SSL, backups |
| Auth | Register, login, JWT, refresh, **single-device sessions** |
| Subscriptions | Plans, RevenueCat webhooks, access guards |
| Content API | Years, subjects, materials, topics |
| Exams API | Questions, CSV import, exams, grading |
| Security (server) | Rate limits, signed URLs, ban users |
| API docs | Keep `docs/API.md` + Swagger accurate |

---

## What you do NOT own

- Flutter app → **Person 2**
- Admin panel UI → **Person 2** (you provide API only)
- Writing MCQs, polishing PDFs → **Person 3**
- Final UI/design polish → **Person 3**
- App Store submission → **Person 2** (you support with prod API)

---

## Folder ownership

```text
backend/                 ← YOU
docs/API.md              ← YOU maintain
docs/DATABASE.md         ← YOU maintain
docs/ROADMAP.md          ← shared (don’t change stack alone)
```

---

## Week-by-week summary

> Full day-by-day tasks: **[PERSON_1_DAILY.md](./PERSON_1_DAILY.md)**

## Week-by-week checklist

### Weeks 1–2 — Foundation
- [ ] Scaffold NestJS in `backend/`
- [ ] Prisma schema from `docs/DATABASE.md`
- [ ] Run migrations locally + seed years, subjects, subscription plans
- [ ] `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`
- [ ] JWT access (15 min) + refresh (7 days)
- [ ] `.env.example` with all variables documented
- [ ] Share local API URL with Person 2

**Exit:** Person 2 can log in from app/admin.

---

### Weeks 3–4 — Device binding + users
- [ ] `device_sessions` table — one active session per user
- [ ] New login revokes previous device
- [ ] Validate `X-Device-Id` on every authenticated request
- [ ] Admin: `GET /admin/users`, `PATCH ban`, `POST reset-device`
- [ ] Role guards: STUDENT, ADMIN, SUPER_ADMIN
- [ ] Subscription guard skeleton (check plan before content)

**Exit:** Login on phone B kicks phone A off.

---

### Weeks 5–6 — Content + R2
- [ ] Cloudflare R2 bucket + API keys
- [ ] Admin upload endpoint (multipart → R2)
- [ ] `GET /materials/:id/access` → presigned URL (15 min)
- [ ] CRUD: years, subjects, topics, materials
- [ ] Student list endpoints with subscription filter
- [ ] Optional: batch upload script for Person 3

**Exit:** Person 2 can upload and view a PDF; Person 3 can upload via admin.

---

### Weeks 7–9 — Exam engine
- [ ] Questions CRUD + `POST /admin/questions/import` (CSV)
- [ ] Exams CRUD + attach questions
- [ ] `POST /exams/:id/start` — questions **without** correct answers
- [ ] `POST /exams/attempts/:id/submit` — grade + explanations
- [ ] `GET /exams/attempts` — history + review
- [ ] Shuffle questions/options flags

**Exit:** Person 2 can run a full exam end-to-end.

---

### Week 10 — Payments
- [ ] RevenueCat webhook handler (verify signature)
- [ ] Handle: purchase, renewal, expiration, cancellation
- [ ] `GET /subscriptions/me` — user entitlements
- [ ] Admin: manual grant subscription (JazzCash/manual payments)
- [ ] Block content/exams when subscription expired

**Exit:** Paywall + access gating works with Person 2.

---

### Weeks 11–12 — Production
- [ ] Oracle VM: Ubuntu, Node, PostgreSQL, Nginx, Certbot SSL
- [ ] Deploy API + env vars
- [ ] Daily PostgreSQL backup to R2 (cron script)
- [ ] Staging + production environments (or single prod for MVP)
- [ ] Rate limiting on `/auth/login`
- [ ] Error monitoring (Sentry optional)
- [ ] Load test exam submit (target: 100+ concurrent)

**Exit:** Staging URL live for beta.

---

### Weeks 13–16 — Launch support
- [ ] Fix integration bugs from Person 2 & 3
- [ ] Production deploy for launch
- [ ] Monitor logs, DB size, R2 usage
- [ ] Certificate pinning hash for Person 2’s Flutter app
- [ ] Post-launch hotfixes

---

## Integration gates (your part)

| Gate | You must deliver |
|------|------------------|
| **Gate 1 — Auth** | Login/register/refresh live |
| **Gate 2 — Content** | R2 upload + presigned access |
| **Gate 3 — Exams** | Start/submit/grade/review APIs |
| **Gate 4 — Payments** | RevenueCat webhooks + guards |
| **Gate 5 — Beta** | Staging API stable |
| **Gate 6 — Polish** | Production API ready |
| **Gate 7 — Launch** | Monitoring + backups running |

---

## What you need from others

| From Person 2 | When |
|---------------|------|
| Bug reports with request/response | Ongoing |
| RevenueCat product IDs | Week 10 |
| Final API consumer issues | Week 11+ |

| From Person 3 | When |
|---------------|------|
| Sample CSV for import testing | Week 7 |
| Real PDFs for R2 testing | Week 5 |
| Content volume estimate (GB) | Week 11 |

---

## Environment variables (your `.env`)

```env
DATABASE_URL=postgresql://...
JWT_SECRET=...
JWT_REFRESH_SECRET=...
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=medstudy-pdfs
REVENUECAT_WEBHOOK_SECRET=...
PORT=3000
NODE_ENV=production
```

---

## Tech stack (locked)

- NestJS 10 · TypeScript · Prisma · PostgreSQL 16
- Cloudflare R2 (S3-compatible SDK)
- Oracle Cloud Always Free VM
- Redis optional (use PostgreSQL for sessions at MVP)

See [STACK.md](../STACK.md)

---

## Weekly sync — your agenda items

1. Which endpoints shipped this week?
2. Any breaking API changes? (notify Person 2 immediately)
3. Blockers for next gate?
4. Staging/prod status

---

## Related docs

- [API.md](./API.md) — endpoint contract
- [DATABASE.md](./DATABASE.md) — schema
- [ROADMAP.md](./ROADMAP.md) — full project phases
- [PERSON_2_APPS.md](./PERSON_2_APPS.md) — who consumes your API
- [PERSON_3_CONTENT_DESIGN.md](./PERSON_3_CONTENT_DESIGN.md) — content uploader

---

**Questions?** Check `docs/API.md` first. Stack changes need team agreement.
