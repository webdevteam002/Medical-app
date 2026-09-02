# Person 2 — Apps (Mobile + Admin)

**Role:** Flutter + Next.js developer  
**You own:** `mobile/` · `admin/`  
**Works with:** Person 1 (API) · Person 3 (content upload + design polish on your UI)

> **Daily schedule (Day 1–80):** [PERSON_2_DAILY.md](./PERSON_2_DAILY.md) — every working day, Mon–Fri, 16 weeks

---

## Your job in one sentence

Build everything **students and admins see and touch** — the Flutter study/exam app and the Next.js admin panel — wired to Person 1’s API.

---

## What you own

| Area | Your responsibility |
|------|---------------------|
| **Flutter app** | Full student experience |
| **Next.js admin** | Content upload, users, questions, exams |
| Auth UI | Login, register, session handling |
| Study flow | Browse years/subjects, PDF viewer, bookmarks |
| Security (client) | Secure storage, device ID, FLAG_SECURE (Android), watermarks |
| Offline | Encrypted in-app PDF downloads |
| Exams UI | Timer, questions, submit, results, review |
| Payments | RevenueCat SDK, paywall |
| Admin | Users, materials, QBank import, exam builder |

---

## What you do NOT own

- NestJS API, database, R2 server config → **Person 1**
- Writing MCQs, compressing PDFs → **Person 3**
- Final visual design / Figma polish → **Person 3** (you implement their specs)
- Oracle server setup → **Person 1**

---

## Folder ownership

```text
mobile/                  ← YOU
admin/                   ← YOU
```

---

## Week-by-week summary

> Full day-by-day tasks: **[PERSON_2_DAILY.md](./PERSON_2_DAILY.md)**

## Week-by-week checklist

### Weeks 1–2 — Scaffold + auth
- [ ] Flutter project: routing (`go_router`), theme, folder structure
- [ ] Next.js admin: login page, dashboard shell, sidebar
- [ ] Wire login/register to Person 1’s `/auth/*` endpoints
- [ ] Store tokens in `flutter_secure_storage`
- [ ] Send `X-Device-Id` header on every request (`device_info_plus` + UUID)
- [ ] Admin: store JWT in httpOnly cookie or localStorage
- [ ] `.env.example` with `API_BASE_URL`

**Exit:** Both apps log in successfully.

---

### Weeks 3–4 — Sessions + admin users
- [ ] Flutter: auto-logout on 401 / `SESSION_REVOKED`
- [ ] Flutter: show “Logged in elsewhere” message
- [ ] Admin: user list table (`GET /admin/users`)
- [ ] Admin: ban user, reset device buttons
- [ ] Flutter: basic home shell (tabs or drawer)

**Exit:** Single-device login works in app.

---

### Weeks 5–6 — Study + PDF viewer
- [ ] Flutter: year → subject → material list
- [ ] Flutter: call `GET /materials/:id/access`, open PDF viewer (`pdfx`)
- [ ] Watermark overlay (user email + ID)
- [ ] Android: `FLAG_SECURE` on PDF screens (`flutter_windowmanager`)
- [ ] iOS: screenshot detection + blur on background
- [ ] Admin: year/subject/topic CRUD pages
- [ ] Admin: PDF upload with progress bar

**Exit:** Student can read a watermarked PDF; admin can upload.

---

### Weeks 7–8 — Offline + search
- [ ] Flutter: download encrypted PDF to app sandbox
- [ ] Offline materials list (read without network)
- [ ] Search/filter materials
- [ ] Bookmarks add/remove/list
- [ ] Admin: material publish/unpublish toggle

**Exit:** Offline study works in-app only.

---

### Weeks 9–11 — Exam UI
- [ ] Flutter: exam list by subject/year
- [ ] Start exam → show questions one-by-one or paginated
- [ ] Countdown timer
- [ ] Question palette (answered / flagged / skipped)
- [ ] Submit → results screen (score, %, time)
- [ ] Review mode: each Q with explanation
- [ ] Exam history list
- [ ] Admin: question editor (create/edit)
- [ ] Admin: CSV import UI for QBank
- [ ] Admin: exam builder + publish

**Exit:** Full exam flow works with Person 1’s grading API.

---

### Week 12 — Payments
- [ ] Integrate `purchases_flutter` (RevenueCat)
- [ ] Paywall screen with plans from Person 1’s `/subscriptions/me`
- [ ] Lock content when no active plan
- [ ] Admin: view/grant subscriptions manually

**Exit:** Purchase unlocks content.

---

### Weeks 13–14 — Beta builds
- [ ] Android APK / AAB for internal testing
- [ ] iOS TestFlight build (needs Apple Developer account)
- [ ] Fix bugs from Person 3 beta testing
- [ ] Share build links with Person 3

**Exit:** Person 3 can test with real content.

---

### Weeks 15–16 — Design polish + launch
- [ ] Implement Person 3’s Figma v2 / change list
- [ ] Loading skeletons, empty states, error messages
- [ ] App Store + Play Store listing (screenshots from Person 3)
- [ ] Submit apps for review
- [ ] Production API URL in release builds

**Exit:** Apps live in stores.

---

## Integration gates (your part)

| Gate | You must deliver |
|------|------------------|
| **Gate 1 — Auth** | Login works; device kick works |
| **Gate 2 — Content** | PDF viewer + admin upload |
| **Gate 3 — Exams** | Full exam UI end-to-end |
| **Gate 4 — Payments** | Paywall + unlock |
| **Gate 5 — Beta** | TestFlight/APK to Person 3 |
| **Gate 6 — Polish** | Person 3 design changes implemented |
| **Gate 7 — Launch** | Store submission done |

---

## What you need from others

| From Person 1 | When |
|---------------|------|
| API endpoints per milestone | Same week (use mocks max 3 days) |
| Updated `docs/API.md` | Before each gate |
| Staging + prod API URLs | Week 11 |
| Cert pinning config | Week 13 |

| From Person 3 | When |
|---------------|------|
| Test content (PDF + CSV) | Week 6+ |
| Design change list / Figma v2 | Week 14 |
| Store screenshots | Week 15 |
| Beta feedback (prioritized) | Week 13+ |

---

## Key Flutter packages

| Package | Use |
|---------|-----|
| `go_router` | Navigation |
| `flutter_secure_storage` | Tokens |
| `device_info_plus` | Device fingerprint |
| `pdfx` | PDF viewer |
| `flutter_windowmanager` | Android FLAG_SECURE |
| `purchases_flutter` | RevenueCat |
| `dio` or `http` | API client |

---

## Key admin pages to build

| Route | Purpose |
|-------|---------|
| `/login` | Admin auth |
| `/dashboard` | Stats overview |
| `/users` | List, ban, reset device |
| `/content/years` | Year CRUD |
| `/content/subjects` | Subject CRUD |
| `/content/materials` | Upload PDFs |
| `/questions` | QBank editor + CSV import |
| `/exams` | Exam builder |
| `/subscriptions` | View/grant plans |

---

## Security checklist (your code)

- [ ] Never store PDFs in public device folders
- [ ] Watermark on every PDF page
- [ ] FLAG_SECURE on Android study screens
- [ ] Auto-logout on session revoke
- [ ] No API keys in Flutter source (use env/build config)
- [ ] Admin behind auth only

---

## Weekly sync — your agenda items

1. Which screens shipped?
2. Blocked on which API endpoints?
3. Ready for Person 3 to test/upload?
4. Design polish items backlog size?

---

## Related docs

- [API.md](./API.md) — endpoints you call
- [PERSON_1_PLATFORM.md](./PERSON_1_PLATFORM.md) — backend owner
- [PERSON_3_CONTENT_DESIGN.md](./PERSON_3_CONTENT_DESIGN.md) — content + design owner
- [ROADMAP.md](./ROADMAP.md) — security matrix (Android vs iOS)

---

**Tip:** When Person 1’s API is late, mock JSON locally — but swap to real API before each gate.
