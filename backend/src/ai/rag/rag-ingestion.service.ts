import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiDocumentStatus } from '@prisma/client';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import { aiConfigFrom } from '../ai.config';
import { ChunkingService } from './chunking.service';
import { EmbeddingService } from './embedding.service';
import { evaluateMaterialIngestEligibility } from './material-eligibility';
import { PdfExtractionService } from './pdf-extraction.service';
import { sha256Hex } from './text-normalize';

export type ReindexResult = {
  materialId: string;
  documentId: string;
  status: AiDocumentStatus;
  contentHash: string;
  chunkCount: number;
  embeddingModel: string;
  reusedExisting: boolean;
  durationMs: number;
};

/**
 * Admin-triggered ingestion pipeline (no Redis/BullMQ in AI-2).
 *
 * Lifecycle:
 * PENDING → PROCESSING → extract → chunk → embed → persist → ACTIVE
 * On failure: new doc FAILED/OCR_REQUIRED; previous ACTIVE left intact.
 *
 * Future hardening: move multi-MB extract+embed off the request thread
 * into a dedicated worker/queue (requires separate approval — not Redis yet).
 */
@Injectable()
export class RagIngestionService {
  private readonly logger = new Logger(RagIngestionService.name);

  /** In-process lock to avoid concurrent reindex of the same material. */
  private readonly inFlight = new Set<string>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
    private readonly config: ConfigService,
    private readonly pdfExtraction: PdfExtractionService,
    private readonly chunking: ChunkingService,
    private readonly embedding: EmbeddingService,
  ) {}

  async reindexMaterial(materialId: string): Promise<ReindexResult> {
    const started = Date.now();
    const cfg = aiConfigFrom(this.config);

    if (!cfg.enabled || !cfg.rag.enabled) {
      throw new ServiceUnavailableException({
        code: 'AI_RAG_DISABLED',
        message: 'AI RAG is disabled',
      });
    }

    const material = await this.prisma.material.findUnique({
      where: { id: materialId },
    });
    if (!material) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Material not found' });
    }

    const eligibility = evaluateMaterialIngestEligibility(material);
    if (!eligibility.eligible) {
      throw new BadRequestException({
        code: eligibility.code,
        message: eligibility.message,
      });
    }

    if (this.inFlight.has(materialId)) {
      throw new BadRequestException({
        code: 'AI_INGEST_IN_PROGRESS',
        message: 'Reindex already in progress for this material',
      });
    }

    this.inFlight.add(materialId);
    let documentId: string | undefined;

    try {
      const maxBytes = cfg.rag.maxDocumentBytes;
      if (Number(material.fileSizeBytes) > maxBytes) {
        throw new BadRequestException({
          code: 'AI_INGEST_TOO_LARGE',
          message: `Material exceeds AI_RAG_MAX_DOCUMENT_SIZE (${maxBytes} bytes)`,
        });
      }

      const downloadStarted = Date.now();
      const buffer = await this.storage.downloadBuffer(material.fileKey);
      const downloadMs = Date.now() - downloadStarted;
      const contentHash = sha256Hex(buffer);

      const active = await this.prisma.aiDocument.findFirst({
        where: { materialId, status: AiDocumentStatus.ACTIVE },
        orderBy: { indexedAt: 'desc' },
      });

      // Idempotent: unchanged ACTIVE hash → no-op
      if (
        active &&
        active.contentHash === contentHash &&
        active.embeddingModel === cfg.rag.embeddingModel &&
        active.embeddingDimensions === cfg.rag.embeddingDimensions
      ) {
        this.logger.log(
          `Reindex no-op materialId=${materialId} documentId=${active.id} (unchanged hash)`,
        );
        return {
          materialId,
          documentId: active.id,
          status: active.status,
          contentHash,
          chunkCount: active.chunkCount,
          embeddingModel: active.embeddingModel,
          reusedExisting: true,
          durationMs: Date.now() - started,
        };
      }

      const { model: embeddingModel, dimensions } = this.embedding.getModelMeta();

      const pending = await this.prisma.aiDocument.create({
        data: {
          materialId,
          contentHash,
          status: AiDocumentStatus.PROCESSING,
          embeddingModel,
          embeddingDimensions: dimensions,
          chunkCount: 0,
        },
      });
      documentId = pending.id;

      this.logger.log(
        `Ingest start materialId=${materialId} documentId=${documentId} downloadMs=${downloadMs} bytes=${buffer.length}`,
      );

      const extractStarted = Date.now();
      const extraction = await this.pdfExtraction.extractPages(buffer);
      const extractMs = Date.now() - extractStarted;

      if (extraction.kind === 'ocr_required') {
        await this.failDocument(documentId, 'OCR_REQUIRED', extraction.reason, AiDocumentStatus.OCR_REQUIRED);
        return this.result(materialId, documentId, AiDocumentStatus.OCR_REQUIRED, contentHash, 0, embeddingModel, started);
      }
      if (extraction.kind === 'empty' || extraction.kind === 'malformed') {
        await this.failDocument(documentId, 'EXTRACT_FAILED', extraction.reason, AiDocumentStatus.FAILED);
        return this.result(materialId, documentId, AiDocumentStatus.FAILED, contentHash, 0, embeddingModel, started);
      }

      const chunkStarted = Date.now();
      const chunks = this.chunking.chunkPages(extraction.pages);
      const chunkMs = Date.now() - chunkStarted;

      if (chunks.length === 0) {
        await this.failDocument(
          documentId,
          'OCR_REQUIRED',
          'No chunks after extraction',
          AiDocumentStatus.OCR_REQUIRED,
        );
        return this.result(materialId, documentId, AiDocumentStatus.OCR_REQUIRED, contentHash, 0, embeddingModel, started);
      }

      const embedStarted = Date.now();
      const embedResult = await this.embedding.embedDocuments(chunks.map((c) => c.text));
      const embedMs = Date.now() - embedStarted;

      if (embedResult.embeddings.length !== chunks.length) {
        await this.failDocument(
          documentId,
          'EMBED_INCOMPLETE',
          'Embedding count does not match chunk count',
          AiDocumentStatus.FAILED,
        );
        return this.result(materialId, documentId, AiDocumentStatus.FAILED, contentHash, 0, embeddingModel, started);
      }

      const persistStarted = Date.now();
      await this.persistChunksAndActivate({
        documentId,
        materialId,
        chunks,
        embeddings: embedResult.embeddings,
        embeddingModel,
        dimensions,
      });
      const persistMs = Date.now() - persistStarted;

      const durationMs = Date.now() - started;
      this.logger.log(
        `Ingest complete materialId=${materialId} documentId=${documentId} status=ACTIVE chunks=${chunks.length} model=${embeddingModel} downloadMs=${downloadMs} extractMs=${extractMs} chunkMs=${chunkMs} embedMs=${embedMs} persistMs=${persistMs} durationMs=${durationMs}`,
      );

      return {
        materialId,
        documentId,
        status: AiDocumentStatus.ACTIVE,
        contentHash,
        chunkCount: chunks.length,
        embeddingModel,
        reusedExisting: false,
        durationMs,
      };
    } catch (err) {
      if (documentId) {
        const message = err instanceof Error ? err.message : String(err);
        const code =
          err && typeof err === 'object' && 'response' in err
            ? String((err as { response?: { code?: string } }).response?.code ?? 'INGEST_FAILED')
            : 'INGEST_FAILED';
        try {
          await this.failDocument(documentId, code, message, AiDocumentStatus.FAILED);
        } catch {
          // ignore secondary failure
        }
      }
      this.logger.error(
        `Ingest failed materialId=${materialId} documentId=${documentId ?? 'n/a'} err=${String(err)}`,
      );
      throw err;
    } finally {
      this.inFlight.delete(materialId);
    }
  }

  private async failDocument(
    documentId: string,
    errorCode: string,
    errorMessage: string,
    status: AiDocumentStatus,
  ) {
    await this.prisma.aiDocument.update({
      where: { id: documentId },
      data: {
        status,
        errorCode,
        errorMessage: errorMessage.slice(0, 2000),
      },
    });
  }

  private result(
    materialId: string,
    documentId: string,
    status: AiDocumentStatus,
    contentHash: string,
    chunkCount: number,
    embeddingModel: string,
    started: number,
  ): ReindexResult {
    return {
      materialId,
      documentId,
      status,
      contentHash,
      chunkCount,
      embeddingModel,
      reusedExisting: false,
      durationMs: Date.now() - started,
    };
  }

  private async persistChunksAndActivate(opts: {
    documentId: string;
    materialId: string;
    chunks: Array<{
      chunkIndex: number;
      text: string;
      pageStart: number | null;
      pageEnd: number | null;
      contentHash: string;
      charCount: number;
    }>;
    embeddings: number[][];
    embeddingModel: string;
    dimensions: number;
  }) {
    // Insert chunks with embeddings via raw SQL (Prisma Unsupported vector).
    // Keep document non-ACTIVE until all inserts succeed, then swap ACTIVE/STALE.
    for (let i = 0; i < opts.chunks.length; i++) {
      const chunk = opts.chunks[i];
      const vector = opts.embeddings[i];
      if (vector.length !== opts.dimensions) {
        throw new Error(
          `Dimension mismatch at chunk ${i}: expected ${opts.dimensions}, got ${vector.length}`,
        );
      }
      const vectorLiteral = `[${vector.join(',')}]`;
      const id = randomUUID();

      await this.prisma.$executeRawUnsafe(
        `INSERT INTO ai_document_chunks (
          id, document_id, material_id, chunk_index, text,
          page_start, page_end, char_count, content_hash, embedding, created_at
        ) VALUES (
          $1, $2, $3, $4, $5,
          $6, $7, $8, $9, $10::vector, NOW()
        )`,
        id,
        opts.documentId,
        opts.materialId,
        chunk.chunkIndex,
        chunk.text,
        chunk.pageStart,
        chunk.pageEnd,
        chunk.charCount,
        chunk.contentHash,
        vectorLiteral,
      );
    }

    const count = await this.prisma.aiDocumentChunk.count({
      where: { documentId: opts.documentId },
    });
    if (count !== opts.chunks.length) {
      throw new Error(`Incomplete chunk persistence: expected ${opts.chunks.length}, got ${count}`);
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.aiDocument.updateMany({
        where: {
          materialId: opts.materialId,
          status: AiDocumentStatus.ACTIVE,
          NOT: { id: opts.documentId },
        },
        data: { status: AiDocumentStatus.STALE },
      });

      await tx.aiDocument.update({
        where: { id: opts.documentId },
        data: {
          status: AiDocumentStatus.ACTIVE,
          chunkCount: count,
          indexedAt: new Date(),
          errorCode: null,
          errorMessage: null,
          embeddingModel: opts.embeddingModel,
          embeddingDimensions: opts.dimensions,
        },
      });
    });
  }
}
