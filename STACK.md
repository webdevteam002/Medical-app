# LOCKED — MedStudy Technology Stack

**Do not change without team approval.**

| Layer | Technology | Version target |
|-------|------------|----------------|
| Mobile/Desktop | Flutter | 3.x |
| Admin | Next.js | 15.x |
| API | NestJS | 10.x |
| Language | TypeScript | 5.x (backend + admin) |
| ORM | Prisma | 5.x |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 (optional MVP) |
| Storage | Cloudflare R2 | S3-compatible API |
| Hosting | Oracle Cloud Always Free VM | Ubuntu 22.04 ARM |
| Payments | RevenueCat | Mobile subscriptions |
| Push | Firebase FCM | — |

## Security by Platform

| Feature | Android | iOS | Windows/macOS |
|---------|---------|-----|---------------|
| Screenshot block | YES | NO | YES (via OS plugin) |
| Watermark | YES | YES | YES |
| Encrypted offline | YES | YES | YES |
| 2-Device Limit | YES | YES | YES (HW UUID) |

## Monthly Cost (Startup)

**$0–5/month** (Oracle free + R2 ≤10GB)

Full details: [docs/ROADMAP.md](docs/ROADMAP.md)
