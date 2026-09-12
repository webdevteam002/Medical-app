import { UserRole } from '@prisma/client';
import { ConfigService } from '@nestjs/config';
import { RagRetrievalService } from './rag-retrieval.service';
import { EmbeddingService } from './embedding.service';

function makeConfig(): ConfigService {
  const map: Record<string, string> = {
    AI_ENABLED: 'true',
    AI_RAG_ENABLED: 'true',
    AI_EMBEDDING_MODEL: 'gemini-embedding-001',
    AI_EMBEDDING_DIMENSIONS: '4',
    AI_RAG_TOP_K: '4',
  };
  return {
    get: (key: string, def?: string) => map[key] ?? def,
  } as unknown as ConfigService;
}

describe('RagRetrievalService authorization', () => {
  it('returns empty when user has no accessible years', async () => {
    const svc = new RagRetrievalService(
      { material: { findMany: jest.fn() } } as never,
      { getAccessibleYearSlugs: jest.fn().mockResolvedValue([]) } as never,
      {} as EmbeddingService,
      makeConfig(),
    );
    const rows = await svc.retrieve({
      userId: 'u1',
      role: UserRole.STUDENT,
      query: 'hypertension',
    });
    expect(rows).toEqual([]);
  });

  it('constrains to published + aiIngestAllowed + ACTIVE before similarity', async () => {
    const findMany = jest.fn().mockResolvedValue([
      {
        id: 'mat-ok',
        title: 'Cardio',
        subject: { name: 'Medicine', year: { slug: 'year-1' } },
        topic: { name: 'Cardiology' },
        aiDocuments: [
          {
            id: 'doc-1',
            embeddingModel: 'gemini-embedding-001',
            embeddingDimensions: 4,
            contentHash: 'hash-v1',
          },
        ],
      },
    ]);
    const queryRawUnsafe = jest.fn().mockResolvedValue([
      {
        id: 'chunk-1',
        document_id: 'doc-1',
        material_id: 'mat-ok',
        text: 'ACE inhibitors are first-line.',
        page_start: 2,
        page_end: 2,
        chunk_index: 0,
        similarity: 0.91,
      },
    ]);
    const embedQuery = jest.fn().mockResolvedValue({
      embeddings: [[0.5, 0.5, 0.5, 0.5]],
    });

    const svc = new RagRetrievalService(
      { material: { findMany }, $queryRawUnsafe: queryRawUnsafe } as never,
      {
        getAccessibleYearSlugs: jest.fn().mockResolvedValue(['year-1']),
      } as never,
      {
        getModelMeta: () => ({
          model: 'gemini-embedding-001',
          dimensions: 4,
        }),
        embedQuery,
      } as never,
      makeConfig(),
    );

    const rows = await svc.retrieve({
      userId: 'u1',
      role: UserRole.STUDENT,
      query: 'ACE inhibitor',
      topK: 4,
    });

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          isPublished: true,
          aiIngestAllowed: true,
          type: 'PDF',
          subject: { year: { slug: { in: ['year-1'] } } },
          aiDocuments: { some: { status: 'ACTIVE' } },
        }),
      }),
    );
    expect(queryRawUnsafe).toHaveBeenCalled();
    const sql = String(queryRawUnsafe.mock.calls[0][0]);
    expect(sql).toContain("d.status = 'ACTIVE'");
    expect(sql).toContain('m.is_published = true');
    expect(sql).toContain('m.ai_ingest_allowed = true');
    expect(rows).toHaveLength(1);
    expect(rows[0].chunkId).toBe('chunk-1');
    expect(rows[0].similarity).toBeCloseTo(0.91);
    expect(rows[0].subjectName).toBe('Medicine');
    expect(rows[0].topicName).toBe('Cardiology');
    expect(rows[0].yearSlug).toBe('year-1');
    expect(rows[0].contentHash).toBe('hash-v1');
    expect(rows[0].chunkIndex).toBe(0);
    expect(rows[0]).not.toHaveProperty('fileKey');
  });

  it('skips documents with incompatible embedding model/dims', async () => {
    const findMany = jest.fn().mockResolvedValue([
      {
        id: 'mat-old',
        title: 'Old',
        aiDocuments: [
          {
            id: 'doc-old',
            embeddingModel: 'other-model',
            embeddingDimensions: 768,
          },
        ],
      },
    ]);
    const queryRawUnsafe = jest.fn();

    const svc = new RagRetrievalService(
      { material: { findMany }, $queryRawUnsafe: queryRawUnsafe } as never,
      {
        getAccessibleYearSlugs: jest.fn().mockResolvedValue(['year-1']),
      } as never,
      {
        getModelMeta: () => ({
          model: 'gemini-embedding-001',
          dimensions: 4,
        }),
        embedQuery: jest.fn(),
      } as never,
      makeConfig(),
    );

    const rows = await svc.retrieve({
      userId: 'u1',
      role: UserRole.STUDENT,
      query: 'test',
    });
    expect(rows).toEqual([]);
    expect(queryRawUnsafe).not.toHaveBeenCalled();
  });
});
