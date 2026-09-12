-- CreateTable
CREATE TABLE "ai_usage_events" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "endpoint" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "success" BOOLEAN NOT NULL DEFAULT false,
    "latency_ms" INTEGER NOT NULL DEFAULT 0,
    "input_tokens" INTEGER,
    "output_tokens" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_usage_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ai_usage_events_user_id_endpoint_created_at_idx" ON "ai_usage_events"("user_id", "endpoint", "created_at");

-- CreateIndex
CREATE INDEX "ai_usage_events_endpoint_created_at_idx" ON "ai_usage_events"("endpoint", "created_at");

-- AddForeignKey
ALTER TABLE "ai_usage_events" ADD CONSTRAINT "ai_usage_events_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
