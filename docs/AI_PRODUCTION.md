# MedStudy AI — Production Hardening Checklist (AI-7/8)

This document covers deploying the Student/Admin AI stack (AI-0 through AI-6).
It does **not** claim these steps were executed against your live production database.

## Prerequisites

1. PostgreSQL with **pgvector** support (image: `pgvector/pgvector:pg16`).
2. Confirm extension after migrate: `CREATE EXTENSION IF NOT EXISTS vector;`
3. Apply all Prisma migrations including:
   - `20260912110000_ai_usage_events`
   - `20260912120000_ai_rag_pgvector` (vector **768**)
   - `20260912130000_ai_assistant_conversations`
   - `20260912140000_ai_admin_verification`
4. Server-side Gemini keys only (never Flutter / Next.js client).
   - `GEMINI_API_KEY` — single key (still supported)
   - `GEMINI_API_KEYS` — comma-separated pool for automatic failover when one key hits quota/rate-limit/auth failure
   - Prefer a small number of legitimate Google AI Studio / Cloud projects over many personal free accounts (ToS risk)
   - Check `/v1/ai/health` → `apiKeyPool` for masked status (never returns raw keys)

## Environment (safe defaults)

Keep AI off until ready:

```env
AI_ENABLED=false
AI_RAG_ENABLED=false
GEMINI_API_KEY=
GEMINI_API_KEYS=
GEMINI_KEY_COOLDOWN_MS=300000
GEMINI_MODEL=gemini-flash-latest
AI_TIMEOUT_MS=18000
AI_MAX_OUTPUT_TOKENS=1200
AI_DAILY_EXPLANATION_LIMIT=20
AI_DAILY_CHAT_LIMIT=40
AI_DAILY_ADMIN_VERIFY_LIMIT=40
AI_CHAT_HISTORY_LIMIT=8
AI_CHAT_MAX_MESSAGE_CHARS=2000
AI_EMBEDDING_MODEL=gemini-embedding-001
AI_EMBEDDING_DIMENSIONS=768
AI_RAG_TOP_K=6
```

When enabling in production:

- Set `AI_ENABLED=true` and at least one of `GEMINI_API_KEY` / `GEMINI_API_KEYS`.
- Optional: set `GEMINI_API_KEYS=key1,key2,key3` so quota exhaustion on one key fails over to the next (cooldown default 5 minutes).
- Set `AI_RAG_ENABLED=true` only after pgvector is confirmed.
- Keep `AI_EMBEDDING_DIMENSIONS=768` unless you migrate the vector column **and** reindex everything.

Production bootstrap **refuses to start** if AI is enabled without a key, or RAG dims ≠ 768.

## Material ingestion

- `aiIngestAllowed` defaults to **false**.
- Only admin can enable ingest on published PDFs.
- Reindex: `POST /v1/admin/ai/materials/:id/reindex` (ADMIN/SUPER_ADMIN).
- Scanned/no-text PDFs → `OCR_REQUIRED` (OCR is **not** implemented).
- Failed ingest must not destroy a prior ACTIVE document.

## Post-deploy verification

```bash
curl -H "Authorization: Bearer $TOKEN" -H "X-Device-Id: $DEVICE" \
  https://api.example.com/v1/ai/health
```

Expect JSON with `enabled`, `apiKeyConfigured` (boolean only), quotas, rag flags — **no secrets**.

Smoke:

1. Student MCQ explain (authorized question).
2. Student chat (bounded).
3. Admin verify-question (advisory only — does not change `Question.correctOptionId`).
4. Confirm citations appear only when RAG hits exist.

## Backups / retention

- `scripts/backup-db.sh` uses `pg_dump` of the full database (includes AI tables).
- Production cron/backup path: **NOT VERIFIED — REQUIRES OPS/PRODUCTION CONFIRMATION**
- Chat retention policy is not auto-enforced; treat as an OPS decision.

## Known limitations

- Synchronous RAG reindex (no Redis/BullMQ).
- No OCR.
- No web grounding.
- Production-scale latency: not measured in CI — **NOT VERIFIED**.
- Live `CREATE EXTENSION vector` on managed production DB: **NOT VERIFIED — REQUIRES OPS CONFIRMATION**.
