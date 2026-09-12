import { BadRequestException } from '@nestjs/common';
import { AiDocumentStatus } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { RagIngestionService } from './rag-ingestion.service';
import { PdfExtractionService } from './pdf-extraction.service';
import { ChunkingService } from './chunking.service';
import { EmbeddingService } from './embedding.service';
import { sha256Hex } from './text-normalize';

function makeConfig(extra: Record<string, string> = {}): ConfigService {
  const map: Record<string, string> = {
    AI_ENABLED: 'true',
    AI_RAG_ENABLED: 'true',
    AI_EMBEDDING_MODEL: 'gemini-embedding-001',
    AI_EMBEDDING_DIMENSIONS: '4',
    AI_RAG_MAX_DOCUMENT_SIZE: '1000000',
    AI_RAG_CHUNK_SIZE: '50',
    AI_RAG_CHUNK_OVERLAP: '5',
    ...extra,
  };
  return {
    get: (key: string, def?: string) => map[key] ?? def,
  } as unknown as ConfigService;
}

describe('RagIngestionService versioning / eligibility', () => {
  it('rejects non-eligible material', async () => {
    const prisma = {
      material: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'm1',
          type: 'PDF',
          isPublished: true,
          aiIngestAllowed: false,
          fileKey: 'k',
          fileSizeBytes: 10n,
        }),
      },
    };
    const svc = new RagIngestionService(
      prisma as never,
      { downloadBuffer: jest.fn() } as never,
      makeConfig(),
      {} as PdfExtractionService,
      {} as ChunkingService,
      {} as EmbeddingService,
    );

    await expect(svc.reindexMaterial('m1')).rejects.toBeInstanceOf(BadRequestException);
  });

  it('no-ops when ACTIVE hash/model/dims unchanged', async () => {
    const buf = Buffer.from('%PDF-1.4 content');
    const hash = sha256Hex(buf);
    const prisma = {
      material: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'm1',
          type: 'PDF',
          isPublished: true,
          aiIngestAllowed: true,
          fileKey: 'k',
          fileSizeBytes: BigInt(buf.length),
        }),
      },
      aiDocument: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'doc-old',
          status: AiDocumentStatus.ACTIVE,
          contentHash: hash,
          embeddingModel: 'gemini-embedding-001',
          embeddingDimensions: 4,
          chunkCount: 3,
        }),
        create: jest.fn(),
      },
    };
    const storage = { downloadBuffer: jest.fn().mockResolvedValue(buf) };
    const svc = new RagIngestionService(
      prisma as never,
      storage as never,
      makeConfig(),
      {} as PdfExtractionService,
      {} as ChunkingService,
      {} as EmbeddingService,
    );

    const result = await svc.reindexMaterial('m1');
    expect(result.reusedExisting).toBe(true);
    expect(result.documentId).toBe('doc-old');
    expect(prisma.aiDocument.create).not.toHaveBeenCalled();
  });

  it('leaves prior ACTIVE usable when new extraction fails', async () => {
    const buf = Buffer.from('%PDF-1.4 new');
    const prisma = {
      material: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'm1',
          type: 'PDF',
          isPublished: true,
          aiIngestAllowed: true,
          fileKey: 'k',
          fileSizeBytes: BigInt(buf.length),
        }),
      },
      aiDocument: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'doc-old',
          status: AiDocumentStatus.ACTIVE,
          contentHash: 'oldhash',
          embeddingModel: 'gemini-embedding-001',
          embeddingDimensions: 4,
          chunkCount: 2,
        }),
        create: jest.fn().mockResolvedValue({ id: 'doc-new' }),
        update: jest.fn().mockResolvedValue({}),
      },
    };
    const pdfExtraction = {
      extractPages: jest.fn().mockResolvedValue({
        kind: 'malformed',
        reason: 'bad',
      }),
    };
    const embedding = {
      getModelMeta: () => ({ model: 'gemini-embedding-001', dimensions: 4 }),
      embedDocuments: jest.fn(),
    };

    const svc = new RagIngestionService(
      prisma as never,
      { downloadBuffer: jest.fn().mockResolvedValue(buf) } as never,
      makeConfig(),
      pdfExtraction as never,
      {} as ChunkingService,
      embedding as never,
    );

    const result = await svc.reindexMaterial('m1');
    expect(result.status).toBe(AiDocumentStatus.FAILED);
    expect(result.documentId).toBe('doc-new');
    expect(prisma.aiDocument.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'doc-new' },
        data: expect.objectContaining({ status: AiDocumentStatus.FAILED }),
      }),
    );
    // Old ACTIVE never marked STALE on failure path
    expect(embedding.embedDocuments).not.toHaveBeenCalled();
  });

  it('marks OCR_REQUIRED without activating', async () => {
    const buf = Buffer.from('%PDF-1.4 scan');
    const prisma = {
      material: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'm1',
          type: 'PDF',
          isPublished: true,
          aiIngestAllowed: true,
          fileKey: 'k',
          fileSizeBytes: BigInt(buf.length),
        }),
      },
      aiDocument: {
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({ id: 'doc-new' }),
        update: jest.fn().mockResolvedValue({}),
      },
    };
    const pdfExtraction = {
      extractPages: jest.fn().mockResolvedValue({
        kind: 'ocr_required',
        pageCount: 2,
        reason: 'scan',
      }),
    };

    const svc = new RagIngestionService(
      prisma as never,
      { downloadBuffer: jest.fn().mockResolvedValue(buf) } as never,
      makeConfig(),
      pdfExtraction as never,
      {} as ChunkingService,
      {
        getModelMeta: () => ({ model: 'gemini-embedding-001', dimensions: 4 }),
      } as never,
    );

    const result = await svc.reindexMaterial('m1');
    expect(result.status).toBe(AiDocumentStatus.OCR_REQUIRED);
  });
});
