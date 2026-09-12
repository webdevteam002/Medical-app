import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { AiController } from './ai.controller';
import { AdminAiController } from './admin-ai.controller';
import { McqExplainService } from './mcq-explain.service';
import { AiUsageService } from './ai-usage.service';
import { GeminiProvider } from './providers/gemini.provider';
import { AI_PROVIDER } from './providers/ai-provider';
import { PdfExtractionService } from './rag/pdf-extraction.service';
import { ChunkingService } from './rag/chunking.service';
import { EmbeddingService } from './rag/embedding.service';
import { RagIngestionService } from './rag/rag-ingestion.service';
import { RagRetrievalService } from './rag/rag-retrieval.service';
import { RagService } from './rag/rag.service';
import { AssistantToolsService } from './assistant/assistant-tools.service';
import { AiChatService } from './assistant/ai-chat.service';
import { AiVerifyQuestionService } from './verification/ai-verify-question.service';
import { AiBootstrapService } from './ai-bootstrap.service';

@Module({
  imports: [StorageModule, SubscriptionsModule],
  controllers: [AiController, AdminAiController],
  providers: [
    GeminiProvider,
    {
      provide: AI_PROVIDER,
      useExisting: GeminiProvider,
    },
    AiUsageService,
    McqExplainService,
    PdfExtractionService,
    ChunkingService,
    EmbeddingService,
    RagIngestionService,
    RagRetrievalService,
    RagService,
    AssistantToolsService,
    AiChatService,
    AiVerifyQuestionService,
    AiBootstrapService,
  ],
  exports: [
    AI_PROVIDER,
    AiUsageService,
    McqExplainService,
    RagService,
    RagRetrievalService,
    AiChatService,
    AiVerifyQuestionService,
  ],
})
export class AiModule {}
