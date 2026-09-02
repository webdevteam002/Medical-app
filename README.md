# MedStudy — Medical Education Platform

Subscription-based medical education app for MBBS (Year 1–5) and FCPS (Part 1 & 2): study materials, past papers, timed MCQ exams with auto-grading and explanations.

## Locked Stack

| Layer | Technology | Hosting |
|-------|------------|---------|
| **Mobile** | Flutter (Android + iOS) | App Store + Play Store |
| **Admin** | Next.js 15 (TypeScript) | Oracle VM or Vercel |
| **API** | NestJS (TypeScript) | Oracle free VM |
| **Database** | PostgreSQL | Oracle free VM |
| **Cache** | Redis (optional at MVP) | Oracle free VM |
| **File storage** | Cloudflare R2 | Cloudflare (10 GB free) |

## Repository Structure

```
Medical app/
├── mobile/          # Flutter student app
├── admin/           # Next.js admin panel
├── backend/         # NestJS API
├── docs/            # Roadmap, API spec, schema
└── README.md
```

## Documentation

### Team handoff (start here)
- **[Person 1 — Platform & API](docs/PERSON_1_PLATFORM.md)** · [Daily Day 1–80](docs/PERSON_1_DAILY.md)
- **[Person 2 — Apps](docs/PERSON_2_APPS.md)** · [Daily Day 1–80](docs/PERSON_2_DAILY.md)
- **[Person 3 — Content & Design](docs/PERSON_3_CONTENT_DESIGN.md)** · [Daily Day 1–80](docs/PERSON_3_DAILY.md)
- **[3-Team Overview](docs/TEAM_SPLIT.md)** — how all three work together

### Reference
- **[Final Locked Roadmap](docs/ROADMAP.md)** — phases, costs, security matrix
- **[Content Guide](docs/CONTENT_GUIDE.md)** — QBank, PDF, image standards
- **[Database Schema](docs/DATABASE.md)** — PostgreSQL tables
- **[API Overview](docs/API.md)** — endpoints and auth flow

## Quick Start (after scaffold)

```bash
# Backend
cd backend && npm install && npm run start:dev

# Admin
cd admin && npm install && npm run dev

# Mobile
cd mobile && flutter pub get && flutter run
```

See [docs/ROADMAP.md](docs/ROADMAP.md) for full implementation phases.
