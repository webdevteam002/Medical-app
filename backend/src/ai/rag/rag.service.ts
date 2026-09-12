import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { RagIngestionService, ReindexResult } from './rag-ingestion.service';
import {
  RagContextChunk,
  RagRetrievalService,
  RagRetrieveOptions,
} from './rag-retrieval.service';

/**
 * Facade for AI-2 Medical RAG infrastructure.
 * Does not wire into AI-1 explain-mcq (grounding remains key|model).
 */
@Injectable()
export class RagService {
  constructor(
    private readonly ingestion: RagIngestionService,
    private readonly retrieval: RagRetrievalService,
  ) {}

  reindexMaterial(materialId: string): Promise<ReindexResult> {
    return this.ingestion.reindexMaterial(materialId);
  }

  retrieve(opts: RagRetrieveOptions): Promise<RagContextChunk[]> {
    return this.retrieval.retrieve(opts);
  }

  retrieveForUser(
    userId: string,
    role: UserRole,
    query: string,
    topK?: number,
  ): Promise<RagContextChunk[]> {
    return this.retrieval.retrieve({ userId, role, query, topK });
  }
}
