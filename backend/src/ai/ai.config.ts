import { ConfigService } from '@nestjs/config';

export type AiProviderName = 'gemini';

export interface AiRagConfig {
  enabled: boolean;
  embeddingModel: string;
  /** Must match the pgvector column width in the migration (default 768). */
  embeddingDimensions: number;
  topK: number;
  /** Approximate token target per chunk (chars ≈ tokens * 4). */
  chunkSizeTokens: number;
  chunkOverlapTokens: number;
  maxDocumentBytes: number;
  embedBatchSize: number;
}

export interface AiConfig {
  enabled: boolean;
  provider: AiProviderName;
  geminiApiKey: string;
  geminiModel: string;
  timeoutMs: number;
  maxOutputTokens: number;
  dailyExplanationLimit: number;
  dailyChatLimit: number;
  dailyAdminVerifyLimit: number;
  chatHistoryLimit: number;
  chatMaxMessageChars: number;
  rag: AiRagConfig;
}

export const AI_EXPLAIN_ENDPOINT = 'explain-mcq';
export const AI_CHAT_ENDPOINT = 'chat';
export const AI_VERIFY_ENDPOINT = 'verify-question';

/** Documented default vector width — keep in sync with migration vector(768). */
export const AI_DEFAULT_EMBEDDING_DIMENSIONS = 768;
export const AI_DEFAULT_EMBEDDING_MODEL = 'gemini-embedding-001';

type EnvGetter = (key: string, defaultValue?: string) => string | undefined;

export function loadAiConfig(get: EnvGetter): AiConfig {
  const enabledRaw = (get('AI_ENABLED', 'false') || 'false').toLowerCase();
  const providerRaw = (get('AI_PROVIDER', 'gemini') || 'gemini').toLowerCase();
  const provider: AiProviderName = providerRaw === 'gemini' ? 'gemini' : 'gemini';

  const timeoutMs = parsePositiveInt(get('AI_TIMEOUT_MS', '18000'), 18000);
  const maxOutputTokens = parsePositiveInt(get('AI_MAX_OUTPUT_TOKENS', '1200'), 1200);
  const dailyExplanationLimit = parsePositiveInt(
    get('AI_DAILY_EXPLANATION_LIMIT', '20'),
    20,
  );
  const dailyChatLimit = parsePositiveInt(get('AI_DAILY_CHAT_LIMIT', '40'), 40);
  const dailyAdminVerifyLimit = parsePositiveInt(
    get('AI_DAILY_ADMIN_VERIFY_LIMIT', '40'),
    40,
  );
  const chatHistoryLimit = parsePositiveInt(get('AI_CHAT_HISTORY_LIMIT', '8'), 8);
  const chatMaxMessageChars = parsePositiveInt(
    get('AI_CHAT_MAX_MESSAGE_CHARS', '2000'),
    2000,
  );

  const ragEnabledRaw = (get('AI_RAG_ENABLED', 'false') || 'false').toLowerCase();
  const embeddingDimensions = parsePositiveInt(
    get('AI_EMBEDDING_DIMENSIONS', String(AI_DEFAULT_EMBEDDING_DIMENSIONS)),
    AI_DEFAULT_EMBEDDING_DIMENSIONS,
  );

  return {
    enabled: enabledRaw === 'true' || enabledRaw === '1',
    provider,
    geminiApiKey: (get('GEMINI_API_KEY', '') || '').trim(),
    geminiModel: (get('GEMINI_MODEL', 'gemini-flash-latest') || 'gemini-flash-latest').trim(),
    timeoutMs,
    maxOutputTokens,
    dailyExplanationLimit,
    dailyChatLimit,
    dailyAdminVerifyLimit,
    chatHistoryLimit,
    chatMaxMessageChars,
    rag: {
      enabled: ragEnabledRaw === 'true' || ragEnabledRaw === '1',
      embeddingModel: (
        get('AI_EMBEDDING_MODEL', AI_DEFAULT_EMBEDDING_MODEL) ||
        AI_DEFAULT_EMBEDDING_MODEL
      ).trim(),
      embeddingDimensions,
      topK: parsePositiveInt(get('AI_RAG_TOP_K', '6'), 6),
      chunkSizeTokens: parsePositiveInt(get('AI_RAG_CHUNK_SIZE', '650'), 650),
      chunkOverlapTokens: parsePositiveInt(get('AI_RAG_CHUNK_OVERLAP', '80'), 80),
      maxDocumentBytes: parsePositiveInt(
        get('AI_RAG_MAX_DOCUMENT_SIZE', String(25 * 1024 * 1024)),
        25 * 1024 * 1024,
      ),
      embedBatchSize: parsePositiveInt(get('AI_RAG_EMBED_BATCH_SIZE', '16'), 16),
    },
  };
}

/** Nest ConfigService adapter — avoids overloaded get() typing issues. */
export function aiConfigFrom(config: ConfigService): AiConfig {
  const loaded = loadAiConfig((key, defaultValue) => {
    const value = config.get(key);
    if (value === undefined || value === null || value === '') {
      return defaultValue;
    }
    return String(value);
  });
  return clampLoaded(loaded);
}

/** Apply hard upper bounds so misconfigured env cannot create unbounded cost/DoS. */
function clampLoaded(cfg: AiConfig): AiConfig {
  return {
    ...cfg,
    timeoutMs: Math.min(Math.max(cfg.timeoutMs, 1000), 60_000),
    maxOutputTokens: Math.min(Math.max(cfg.maxOutputTokens, 64), 4096),
    chatHistoryLimit: Math.min(Math.max(cfg.chatHistoryLimit, 1), 32),
    chatMaxMessageChars: Math.min(Math.max(cfg.chatMaxMessageChars, 100), 4000),
    dailyExplanationLimit: Math.min(cfg.dailyExplanationLimit, 500),
    dailyChatLimit: Math.min(cfg.dailyChatLimit, 500),
    dailyAdminVerifyLimit: Math.min(cfg.dailyAdminVerifyLimit, 500),
    rag: {
      ...cfg.rag,
      topK: Math.min(Math.max(cfg.rag.topK, 1), 20),
      embedBatchSize: Math.min(Math.max(cfg.rag.embedBatchSize, 1), 64),
      maxDocumentBytes: Math.min(
        Math.max(cfg.rag.maxDocumentBytes, 1024),
        50 * 1024 * 1024,
      ),
      chunkSizeTokens: Math.min(Math.max(cfg.rag.chunkSizeTokens, 50), 4000),
      chunkOverlapTokens: Math.min(
        Math.max(cfg.rag.chunkOverlapTokens, 0),
        Math.floor(cfg.rag.chunkSizeTokens / 2),
      ),
    },
  };
}

function parsePositiveInt(raw: string | undefined, fallback: number): number {
  const n = Number.parseInt(raw ?? '', 10);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return n;
}
