# Person 1 — Daily Work Schedule (Day 1–80)

**Parent doc:** [PERSON_1_PLATFORM.md](./PERSON_1_PLATFORM.md)  
**Format:** 16 weeks · Mon–Fri · 5 days/week = 80 working days

---

## Week 1 — Project setup & auth foundation

| Day | Tasks |
|-----|-------|
| **Day 1** | Clone repo; scaffold NestJS in `backend/`; install Prisma; connect local PostgreSQL; create `.env` and `.env.example` |
| **Day 2** | Copy schema from `DATABASE.md` into `prisma/schema.prisma`; create `users` + `device_sessions` models; run first migration |
| **Day 3** | Create `auth` module; implement password hashing (bcrypt); `POST /auth/register` with validation |
| **Day 4** | Implement JWT access + refresh token generation; `POST /auth/login`; `POST /auth/refresh` |
| **Day 5** | `POST /auth/logout`; auth guards; test all auth endpoints in Postman; share API URL with Person 2 |

---

## Week 2 — Seeds & API docs

| Day | Tasks |
|-----|-------|
| **Day 6** | Seed script: years (1–5, FCPS 1/2), subjects per year, subscription_plans |
| **Day 7** | Run seeds; fix migration issues; add `GET /auth/me` for current user profile |
| **Day 8** | Set up Swagger/OpenAPI at `/api/docs`; document auth endpoints |
| **Day 9** | Global exception filters; validation pipes; CORS config for Person 2 local dev |
| **Day 10** | **Gate 1 prep:** full auth flow test; demo login to Person 2; fix blockers |

---

## Week 3 — 2-Device Limit (Mobile + Desktop)

| Day | Tasks |
|-----|-------|
| **Day 11** | On login: save `device_id`, `device_name`, `device_type` (mobile/desktop) in `device_sessions` |
| **Day 12** | Enforce 2-device limit (e.g. 1 mobile, 1 desktop max); revoke oldest if limit exceeded |
| **Day 13** | Middleware: validate `X-Device-Id` matches active session on every request |
| **Day 14** | Return `SESSION_REVOKED` / `DEVICE_MISMATCH` errors; test 3-device scenario |
| **Day 15** | Role enum + `@Roles()` decorator; STUDENT vs ADMIN guards |

---

## Week 4 — Admin user endpoints

| Day | Tasks |
|-----|-------|
| **Day 16** | `GET /admin/users` with pagination, search, subscription summary |
| **Day 17** | `PATCH /admin/users/:id/ban` and unban |
| **Day 18** | `POST /admin/users/:id/reset-device` — clear sessions |
| **Day 19** | Subscription guard skeleton: `SubscriptionGuard` checks active plan (stub true for now) |
| **Day 20** | **Gate 1 complete:** integration test with Person 2; document breaking changes in API.md |

---

## Week 5 — Cloudflare R2 setup

| Day | Tasks |
|-----|-------|
| **Day 21** | Create Cloudflare R2 bucket; API tokens; add R2 env vars; test S3 SDK connection |
| **Day 22** | `StorageService`: upload file, delete file, generate presigned URL (15 min expiry) |
| **Day 23** | `materials` table migration if not done; link `file_key` to R2 path |
| **Day 24** | `POST /admin/materials/upload` multipart endpoint; save metadata to DB |
| **Day 25** | Test upload with sample PDF from Person 3 (or dummy file) |

---

## Week 6 — Content API

| Day | Tasks |
|-----|-------|
| **Day 26** | CRUD `years`, `subjects`, `topics` admin endpoints |
| **Day 27** | `GET /years` student endpoint — filter by user subscription |
| **Day 28** | `GET /subjects/:id/materials` with search, pagination, past_paper filter |
| **Day 29** | `GET /materials/:id/access` — subscription check + presigned URL + watermark text |
| **Day 30** | **Gate 2 prep:** Person 2 can list and open PDF; fix bugs; update API.md |

---

## Week 7 — Questions module

| Day | Tasks |
|-----|-------|
| **Day 31** | `questions` CRUD admin endpoints; options as JSONB; validation (4–5 options, one correct) |
| **Day 32** | `POST /admin/questions/import` — parse CSV from Person 3 template |
| **Day 33** | Import error reporting (row number, reason); dry-run mode |
| **Day 34** | Test import with Person 3 sample CSV (10–20 questions) |
| **Day 35** | `GET /admin/questions` filter by subject, difficulty, tags |

---

## Week 8 — Exams module (part 1)

| Day | Tasks |
|-----|-------|
| **Day 36** | `exams` CRUD; `exam_questions` join table; attach questions to exam |
| **Day 37** | `POST /exams/:id/start` — create attempt; return questions **without** correct answers |
| **Day 38** | Shuffle questions if `shuffle_questions` true; shuffle option order if configured |
| **Day 39** | Timer validation: reject submit after `duration_minutes` exceeded |
| **Day 40** | `exam_attempts` + `exam_attempt_details` tables; save in-progress answers (optional) |

---

## Week 9 — Exams module (part 2)

| Day | Tasks |
|-----|-------|
| **Day 41** | `POST /exams/attempts/:id/submit` — grade all answers server-side |
| **Day 42** | Return score, percentage, per-question: selected, correct, explanation |
| **Day 43** | `GET /exams/attempts` history; `GET /exams/attempts/:id` review mode |
| **Day 44** | Prevent double submit; one active attempt per user per exam |
| **Day 45** | **Gate 3 prep:** full exam with Person 2; fix grading edge cases |

---

## Week 10 — Subscriptions & RevenueCat

| Day | Tasks |
|-----|-------|
| **Day 46** | `subscriptions` service: check `hasAccess(userId, yearSlug)` |
| **Day 47** | Wire SubscriptionGuard to content + exam routes |
| **Day 48** | RevenueCat webhook endpoint; verify signature |
| **Day 49** | Handle events: INITIAL_PURCHASE, RENEWAL, EXPIRATION, CANCELLATION |
| **Day 50** | `GET /subscriptions/me`; admin `POST /admin/subscriptions` manual grant |

---

## Week 11 — Oracle VM & deploy prep

| Day | Tasks |
|-----|-------|
| **Day 51** | Provision Oracle Always Free VM; Ubuntu 22.04; SSH access; firewall ports 80/443 |
| **Day 52** | Install PostgreSQL on VM; create DB user; run migrations remotely |
| **Day 53** | Install Node.js; clone repo; deploy NestJS with PM2 or systemd |
| **Day 54** | Nginx reverse proxy; Certbot SSL; staging domain pointed to VM |
| **Day 55** | **Gate 4 prep:** Person 2 tests paywall against staging API |

---

## Week 12 — Production hardening

| Day | Tasks |
|-----|-------|
| **Day 56** | Rate limiting on `/auth/login` (e.g. 5 attempts / 15 min) |
| **Day 57** | Daily PostgreSQL backup script → upload dump to R2; test restore |
| **Day 58** | Sentry or logging setup; health check `GET /health` |
| **Day 59** | Load test exam submit (k6 or artillery) — target 100 concurrent |
| **Day 60** | **Gate 5 prep:** staging stable for Person 3 beta |

---

## Week 13 — Integration fixes

| Day | Tasks |
|-----|-------|
| **Day 61** | Triage bugs from Person 2 (API issues); fix priority P0 |
| **Day 62** | Triage Person 3 content import errors; fix CSV parser edge cases |
| **Day 63** | Optimize slow queries; add DB indexes on foreign keys |
| **Day 64** | Certificate pinning hash for Person 2 Flutter release build |
| **Day 65** | Batch upload script for Person 3 (optional CLI: upload folder to R2) |

---

## Week 14 — Pre-launch

| Day | Tasks |
|-----|-------|
| **Day 66** | Production env vars; production deploy; smoke test all gates |
| **Day 67** | Monitor R2 storage usage; document scaling plan for Person 3 |
| **Day 68** | Security review: no secrets in logs; HTTPS only; admin routes protected |
| **Day 69** | Fix P1 bugs from beta students |
| **Day 70** | **Gate 6:** production API ready; uptime check |

---

## Week 15 — Launch week

| Day | Tasks |
|-----|-------|
| **Day 71** | On-call for Person 2 store submission issues |
| **Day 72** | Monitor error rates; fix hotfixes |
| **Day 73** | Verify webhooks in production RevenueCat |
| **Day 74** | Backup verification; document runbook for restarts |
| **Day 75** | Performance check under real beta traffic |

---

## Week 16 — Post-launch & handoff

| Day | Tasks |
|-----|-------|
| **Day 76** | **Gate 7 — Launch:** confirm live; monitor DB + R2 |
| **Day 77** | Address launch-day bugs |
| **Day 78** | Document API changelog for v1.0 |
| **Day 79** | Plan v1.1 (FCPS content APIs if any gaps) |
| **Day 80** | Retrospective with team; archive staging notes |

---

## Daily routine (every day)

- [ ] Push code at end of day
- [ ] Update Person 2 if any API contract changed
- [ ] Check weekly sync agenda for blockers
