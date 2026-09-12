-- AlterTable
ALTER TABLE "exam_attempt_details" ADD COLUMN IF NOT EXISTS "ai_correct_option_id" TEXT;
ALTER TABLE "exam_attempt_details" ADD COLUMN IF NOT EXISTS "ai_explanation" TEXT;
ALTER TABLE "exam_attempt_details" ADD COLUMN IF NOT EXISTS "graded_by" TEXT NOT NULL DEFAULT 'key';
