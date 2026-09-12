-- AI-2 Medical RAG: pgvector + ingest gate + document/chunk tables
-- REQUIRES a Postgres image that ships/supports the vector extension
-- (e.g. pgvector/pgvector:pg16). Stock postgres:16-alpine does NOT.

CREATE EXTENSION IF NOT EXISTS vector;

-- AlterTable
ALTER TABLE "materials" ADD COLUMN "ai_ingest_allowed" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "materials_ai_ingest_allowed_is_published_idx" ON "materials"("ai_ingest_allowed", "is_published");

-- CreateEnum
CREATE TYPE "AiDocumentStatus" AS ENUM ('PENDING', 'PROCESSING', 'ACTIVE', 'STALE', 'FAILED', 'OCR_REQUIRED');

-- CreateTable
CREATE TABLE "ai_documents" (
    "id" TEXT NOT NULL,
    "material_id" TEXT NOT NULL,
    "content_hash" TEXT NOT NULL,
    "status" "AiDocumentStatus" NOT NULL DEFAULT 'PENDING',
    "embedding_model" TEXT NOT NULL,
    "embedding_dimensions" INTEGER NOT NULL,
    "chunk_count" INTEGER NOT NULL DEFAULT 0,
    "error_code" TEXT,
    "error_message" TEXT,
    "indexed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ai_documents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
-- Default embedding width: 768 (gemini-embedding-001 with outputDimensionality=768).
-- Changing AI_EMBEDDING_DIMENSIONS requires a new migration + full reindex.
CREATE TABLE "ai_document_chunks" (
    "id" TEXT NOT NULL,
    "document_id" TEXT NOT NULL,
    "material_id" TEXT NOT NULL,
    "chunk_index" INTEGER NOT NULL,
    "text" TEXT NOT NULL,
    "page_start" INTEGER,
    "page_end" INTEGER,
    "char_count" INTEGER NOT NULL DEFAULT 0,
    "content_hash" TEXT NOT NULL,
    "embedding" vector(768),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_document_chunks_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ai_documents_material_id_status_idx" ON "ai_documents"("material_id", "status");

-- CreateIndex
CREATE INDEX "ai_documents_status_material_id_idx" ON "ai_documents"("status", "material_id");

-- CreateIndex
CREATE INDEX "ai_documents_content_hash_idx" ON "ai_documents"("content_hash");

-- At most one ACTIVE indexed version per material (versioning safety net)
CREATE UNIQUE INDEX "ai_documents_one_active_per_material_idx"
  ON "ai_documents"("material_id")
  WHERE "status" = 'ACTIVE';

-- CreateIndex
CREATE INDEX "ai_document_chunks_material_id_idx" ON "ai_document_chunks"("material_id");

-- CreateIndex
CREATE INDEX "ai_document_chunks_document_id_idx" ON "ai_document_chunks"("document_id");

-- CreateIndex
CREATE UNIQUE INDEX "ai_document_chunks_document_id_chunk_index_key" ON "ai_document_chunks"("document_id", "chunk_index");

-- AddForeignKey
ALTER TABLE "ai_documents" ADD CONSTRAINT "ai_documents_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "materials"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_document_chunks" ADD CONSTRAINT "ai_document_chunks_document_id_fkey" FOREIGN KEY ("document_id") REFERENCES "ai_documents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
