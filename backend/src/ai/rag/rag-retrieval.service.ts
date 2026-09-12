import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';
import { aiConfigFrom } from '../ai.config';
import { EmbeddingService } from './embedding.service';

export type RagContextChunk = {
  materialId: string;
  title: string;
  pageStart: number | null;
  pageEnd: number | null;
  chunkId: string;
  documentId: string;
  text: string;
  similarity: number;
  /** Display metadata for AI-6 citations (authorized materials only). */
  subjectName: string | null;
  topicName: string | null;
  yearSlug: string | null;
  /** AiDocument.contentHash at retrieval — source version identity. */
  contentHash: string | null;
  chunkIndex: number | null;
};

export type RagRetrieveOptions = {
  userId: string;
  role: UserRole;
  query: string;
  topK?: number;
  /** Optional explicit material whitelist (still filtered by auth). */
  materialIds?: string[];
};

/**
 * Authorization-aware retrieval.
 *
 * Order is intentional and mandatory:
 * USER → authorization → eligible materials → constrained vector search → top-K
 *
 * Never retrieve-then-filter after model context assembly.
 * PDF chunk text is UNTRUSTED evidence — not instructions.
 */
@Injectable()
export class RagRetrievalService {
  private readonly logger = new Logger(RagRetrievalService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly subscriptions: SubscriptionsService,
    private readonly embedding: EmbeddingService,
    private readonly config: ConfigService,
  ) {}

  async retrieve(opts: RagRetrieveOptions): Promise<RagContextChunk[]> {
    const cfg = aiConfigFrom(this.config);
    if (!cfg.enabled || !cfg.rag.enabled) {
      return [];
    }

    const query = opts.query?.trim();
    if (!query) return [];

    const topK = opts.topK ?? cfg.rag.topK;
    const accessibleYearSlugs = await this.subscriptions.getAccessibleYearSlugs(
      opts.userId,
      opts.role,
    );
    if (accessibleYearSlugs.length === 0) {
      return [];
    }

    const eligibleMaterials = await this.prisma.material.findMany({
      where: {
        isPublished: true,
        aiIngestAllowed: true,
        type: 'PDF',
        ...(opts.materialIds?.length ? { id: { in: opts.materialIds } } : {}),
        subject: { year: { slug: { in: accessibleYearSlugs } } },
        aiDocuments: { some: { status: 'ACTIVE' } },
      },
      select: {
        id: true,
        title: true,
        subject: {
          select: {
            name: true,
            year: { select: { slug: true } },
          },
        },
        topic: { select: { name: true } },
        aiDocuments: {
          where: { status: 'ACTIVE' },
          select: {
            id: true,
            embeddingModel: true,
            embeddingDimensions: true,
            contentHash: true,
          },
          take: 1,
          orderBy: { indexedAt: 'desc' },
        },
      },
    });

    if (eligibleMaterials.length === 0) {
      return [];
    }

    const { model, dimensions } = this.embedding.getModelMeta();
    const compatibleMaterialIds: string[] = [];
    const metaByMaterialId = new Map<
      string,
      {
        title: string;
        subjectName: string | null;
        topicName: string | null;
        yearSlug: string | null;
        contentHash: string | null;
      }
    >();
    const activeDocIds: string[] = [];

    for (const m of eligibleMaterials) {
      const doc = m.aiDocuments[0];
      if (!doc) continue;
      // Do not mix incompatible embedding spaces
      if (doc.embeddingModel !== model || doc.embeddingDimensions !== dimensions) {
        continue;
      }
      compatibleMaterialIds.push(m.id);
      metaByMaterialId.set(m.id, {
        title: m.title,
        subjectName: m.subject?.name ?? null,
        topicName: m.topic?.name ?? null,
        yearSlug: m.subject?.year?.slug ?? null,
        contentHash: doc.contentHash ?? null,
      });
      activeDocIds.push(doc.id);
    }

    if (compatibleMaterialIds.length === 0 || activeDocIds.length === 0) {
      return [];
    }

    const embedStarted = Date.now();
    const queryEmbed = await this.embedding.embedQuery(query);
    const queryVector = queryEmbed.embeddings[0];
    const embedMs = Date.now() - embedStarted;
    const vectorLiteral = `[${queryVector.join(',')}]`;

    const retrieveStarted = Date.now();
    type Row = {
      id: string;
      document_id: string;
      material_id: string;
      text: string;
      page_start: number | null;
      page_end: number | null;
      chunk_index: number | null;
      similarity: number;
    };

    const rows = await this.prisma.$queryRawUnsafe<Row[]>(
      `
      SELECT
        c.id,
        c.document_id,
        c.material_id,
        c.text,
        c.page_start,
        c.page_end,
        c.chunk_index,
        (1 - (c.embedding <=> $1::vector))::float8 AS similarity
      FROM ai_document_chunks c
      INNER JOIN ai_documents d ON d.id = c.document_id
      INNER JOIN materials m ON m.id = c.material_id
      WHERE d.status = 'ACTIVE'
        AND d.id = ANY($2::text[])
        AND m.is_published = true
        AND m.ai_ingest_allowed = true
        AND m.type = 'PDF'
        AND c.material_id = ANY($3::text[])
        AND c.embedding IS NOT NULL
      ORDER BY c.embedding <=> $1::vector
      LIMIT $4
      `,
      vectorLiteral,
      activeDocIds,
      compatibleMaterialIds,
      topK,
    );

    const retrieveMs = Date.now() - retrieveStarted;
    this.logger.log(
      `RAG retrieve userId=${opts.userId} candidates=${compatibleMaterialIds.length} hits=${rows.length} topK=${topK} embedMs=${embedMs} retrieveMs=${retrieveMs}`,
    );

    return rows.map((row) => {
      const meta = metaByMaterialId.get(row.material_id);
      return {
        materialId: row.material_id,
        title: meta?.title ?? '',
        pageStart: row.page_start,
        pageEnd: row.page_end,
        chunkId: row.id,
        documentId: row.document_id,
        // UNTRUSTED document evidence — consumers must not treat as instructions
        text: row.text,
        similarity: Number(row.similarity),
        subjectName: meta?.subjectName ?? null,
        topicName: meta?.topicName ?? null,
        yearSlug: meta?.yearSlug ?? null,
        contentHash: meta?.contentHash ?? null,
        chunkIndex: row.chunk_index ?? null,
      };
    });
  }
}
