export type AiStructuredCompleteRequest = {
  /** Trusted system instructions (never include untrusted MCQ text). */
  systemInstruction: string;
  /** Untrusted / delimited user payload. */
  userContent: string;
  temperature?: number;
  maxOutputTokens?: number;
  timeoutMs?: number;
  model?: string;
};

export type AiStructuredCompleteResult = {
  text: string;
  model: string;
  provider: string;
  inputTokens?: number;
  outputTokens?: number;
  latencyMs: number;
};

export type AiEmbedTaskType =
  | 'RETRIEVAL_DOCUMENT'
  | 'RETRIEVAL_QUERY'
  | 'SEMANTIC_SIMILARITY'
  | 'CLASSIFICATION'
  | 'CLUSTERING';

export type AiEmbedRequest = {
  texts: string[];
  /** Defaults to configured AI_EMBEDDING_MODEL. */
  model?: string;
  /** Defaults to configured AI_EMBEDDING_DIMENSIONS. */
  dimensions?: number;
  taskType?: AiEmbedTaskType;
  timeoutMs?: number;
  /** Max texts per provider batch call. */
  batchSize?: number;
};

export type AiEmbedResult = {
  embeddings: number[][];
  model: string;
  provider: string;
  dimensions: number;
  latencyMs: number;
};

/**
 * Provider-agnostic AI surface used by business services.
 * Gemini is the only implementation in AI-0/AI-1/AI-2.
 */
export interface AiProvider {
  readonly name: string;

  isReady(): boolean;

  structuredComplete(
    request: AiStructuredCompleteRequest,
  ): Promise<AiStructuredCompleteResult>;

  /** Dense embeddings for RAG. Must not mix incompatible model/dim spaces. */
  embed(request: AiEmbedRequest): Promise<AiEmbedResult>;
}

export const AI_PROVIDER = Symbol('AI_PROVIDER');
