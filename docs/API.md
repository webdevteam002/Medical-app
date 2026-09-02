# MedStudy — API Overview

Base URL: `https://api.yourdomain.com/v1`  
Auth: Bearer JWT in `Authorization` header  
Device: `X-Device-Id` header required on all authenticated requests

---

## Auth

### POST /auth/register

```json
{
  "email": "student@example.com",
  "password": "securePassword123",
  "fullName": "Ali Khan",
  "deviceId": "uuid-device-fingerprint",
  "deviceName": "Samsung Galaxy A54"
}
```

### POST /auth/login

```json
{
  "email": "student@example.com",
  "password": "securePassword123",
  "deviceId": "uuid-device-fingerprint",
  "deviceName": "Samsung Galaxy A54"
}
```

**Response**

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 900,
  "user": { "id": "...", "email": "...", "fullName": "..." }
}
```

### POST /auth/refresh

```json
{
  "refreshToken": "eyJ...",
  "deviceId": "uuid-device-fingerprint"
}
```

### POST /auth/logout

Requires auth. Invalidates current device session.

---

## Content (Student)

All routes require auth + active subscription for the relevant year.

### GET /years

List years user has access to.

### GET /years/:yearSlug/subjects

List subjects for a year.

### GET /subjects/:subjectId/materials

Query: `?topicId=&search=&pastPapersOnly=true`

### GET /materials/:id/access

Returns presigned R2 URL (15 min expiry).

```json
{
  "url": "https://...r2.cloudflarestorage.com/...",
  "expiresAt": "2026-03-12T15:30:00Z",
  "watermark": "ali@example.com · ID:4821"
}
```

### GET /materials/:id/download

Returns encrypted file blob metadata for offline storage.

### POST /bookmarks/:materialId

### DELETE /bookmarks/:materialId

### GET /bookmarks

---

## Exams (Student)

### GET /exams

Query: `?yearSlug=&subjectId=`

### POST /exams/:id/start

Creates attempt; returns questions **without** correct answers.

```json
{
  "attemptId": "...",
  "durationMinutes": 60,
  "questions": [
    {
      "id": "...",
      "stem": "Which nerve innervates...?",
      "options": [
        { "id": "a", "text": "Median nerve" },
        { "id": "b", "text": "Ulnar nerve" }
      ]
    }
  ]
}
```

### POST /exams/attempts/:attemptId/submit

```json
{
  "answers": [
    { "questionId": "...", "selectedOptionId": "a", "timeSpentSeconds": 45 }
  ]
}
```

**Response**

```json
{
  "score": 38,
  "total": 50,
  "percentage": 76.0,
  "details": [
    {
      "questionId": "...",
      "selectedOptionId": "b",
      "correctOptionId": "a",
      "isCorrect": false,
      "explanation": "The median nerve..."
    }
  ]
}
```

### GET /exams/attempts

Exam history for current user.

### GET /exams/attempts/:attemptId

Review past attempt with full explanations.

---

## Subscriptions

### GET /subscriptions/me

Current user subscriptions and entitlements.

### POST /webhooks/revenuecat

RevenueCat webhook (server-to-server). Verifies signature.

---

## Admin

All admin routes require `ADMIN` or `SUPER_ADMIN` role.

### Users

- `GET /admin/users` — list with subscription + device info
- `PATCH /admin/users/:id/ban` — ban/unban
- `POST /admin/users/:id/reset-device` — clear device binding

### Content

- `CRUD /admin/years`
- `CRUD /admin/subjects`
- `CRUD /admin/topics`
- `POST /admin/materials/upload` — multipart upload to R2
- `PATCH /admin/materials/:id` — publish, metadata
- `DELETE /admin/materials/:id`

### Questions & Exams

- `CRUD /admin/questions`
- `POST /admin/questions/import` — CSV bulk import
- `CRUD /admin/exams`
- `POST /admin/exams/:id/questions` — add questions to exam
- `GET /admin/exams/:id/analytics` — attempt stats

### Subscriptions

- `GET /admin/subscriptions` — filter by status, plan
- `POST /admin/subscriptions` — manually grant plan (JazzCash etc.)

---

## Error Codes

| Code | HTTP | Meaning |
|------|------|---------|
| `INVALID_CREDENTIALS` | 401 | Wrong email/password |
| `DEVICE_MISMATCH` | 401 | Token used from wrong device |
| `SESSION_REVOKED` | 401 | Logged in elsewhere |
| `SUBSCRIPTION_REQUIRED` | 403 | No active plan for content |
| `USER_BANNED` | 403 | Account banned |
| `NOT_FOUND` | 404 | Resource missing |

---

## Security Headers (Mobile)

```
Authorization: Bearer <accessToken>
X-Device-Id: <deviceFingerprint>
```

Certificate pinning recommended in production (Phase 6).
