import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Inject } from '@nestjs/common';
import { aiConfigFrom } from '../ai.config';
import { AI_PROVIDER, AiProvider } from '../providers/ai-provider';

/**
 * Thin embedding facade over AiProvider — keeps RAG decoupled from Gemini.
 */
@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);

  constructor(
    private readonly config: ConfigService,
    @Inject(AI_PROVIDER) private readonly aiProvider: AiProvider,
  ) {}

  getModelMeta(): { model: string; dimensions: number } {
    const rag = aiConfigFrom(this.config).rag;
    return { model: rag.embeddingModel, dimensions: rag.embeddingDimensions };
  }

  async embedDocuments(texts: string[]) {
    const rag = aiConfigFrom(this.config).rag;
    this.logger.log(
      `Embedding ${texts.length} document chunk(s) model=${rag.embeddingModel} dims=${rag.embeddingDimensions}`,
    );
    return this.aiProvider.embed({
      texts,
      model: rag.embeddingModel,
      dimensions: rag.embeddingDimensions,
      taskType: 'RETRIEVAL_DOCUMENT',
      batchSize: rag.embedBatchSize,
    });
  }

  async embedQuery(text: string) {
    const rag = aiConfigFrom(this.config).rag;
    return this.aiProvider.embed({
      texts: [text],
      model: rag.embeddingModel,
      dimensions: rag.embeddingDimensions,
      taskType: 'RETRIEVAL_QUERY',
      batchSize: 1,
    });
  }
}
