-- AI-5 Admin AI Verification (advisory reviews; never mutates questions)
CREATE TYPE "AiVerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'FAILED');

CREATE TYPE "AiVerificationIssueType" AS ENUM (
  'NONE',
  'AMBIGUOUS',
  'POSSIBLE_KEY_ISSUE',
  'MULTIPLE_PLAUSIBLE_ANSWERS',
  'INSUFFICIENT_INFORMATION',
  'EXPLANATION_ISSUE',
  'OPTION_QUALITY_ISSUE'
);

CREATE TABLE "ai_question_verifications" (
    "id" TEXT NOT NULL,
    "question_id" TEXT NOT NULL,
    "status" "AiVerificationStatus" NOT NULL DEFAULT 'PENDING',
    "official_correct_option_id" TEXT NOT NULL,
    "question_content_hash" TEXT NOT NULL,
    "issue_type" "AiVerificationIssueType",
    "confidence" DOUBLE PRECISION,
    "reasoning" TEXT,
    "recommendation" TEXT,
    "option_analysis_json" JSONB,
    "quality_flags_json" JSONB,
    "source_support_json" JSONB,
    "evidence_json" JSONB,
    "grounding" TEXT,
    "provider" TEXT,
    "model" TEXT,
    "created_by_admin_id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decided_by_admin_id" TEXT,
    "decided_at" TIMESTAMP(3),
    "admin_note" TEXT,
    "error_code" TEXT,
    "error_message" TEXT,

    CONSTRAINT "ai_question_verifications_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "ai_question_verifications_question_id_created_at_idx" ON "ai_question_verifications"("question_id", "created_at");
CREATE INDEX "ai_question_verifications_status_created_at_idx" ON "ai_question_verifications"("status", "created_at");
CREATE INDEX "ai_question_verifications_question_id_question_content_hash_status_idx" ON "ai_question_verifications"("question_id", "question_content_hash", "status");
CREATE INDEX "ai_question_verifications_issue_type_status_idx" ON "ai_question_verifications"("issue_type", "status");

ALTER TABLE "ai_question_verifications" ADD CONSTRAINT "ai_question_verifications_question_id_fkey" FOREIGN KEY ("question_id") REFERENCES "questions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ai_question_verifications" ADD CONSTRAINT "ai_question_verifications_created_by_admin_id_fkey" FOREIGN KEY ("created_by_admin_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ai_question_verifications" ADD CONSTRAINT "ai_question_verifications_decided_by_admin_id_fkey" FOREIGN KEY ("decided_by_admin_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
