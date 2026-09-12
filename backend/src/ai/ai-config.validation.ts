import {
  AI_DEFAULT_EMBEDDING_DIMENSIONS,
  AiConfig,
  loadAiConfig,
} from './ai.config';

export type AiConfigIssue = {
  code: string;
  message: string;
  severity: 'error' | 'warning';
};

/**
 * Validate AI config for production readiness.
 * Does not log secrets. Used at bootstrap and in tests.
 */
export function validateAiConfig(cfg: AiConfig, opts?: {
  nodeEnv?: string;
}): AiConfigIssue[] {
  const issues: AiConfigIssue[] = [];
  const nodeEnv = (opts?.nodeEnv ?? process.env.NODE_ENV ?? 'development').toLowerCase();
  const isProd = nodeEnv === 'production';

  if (cfg.enabled && !cfg.geminiApiKey) {
    issues.push({
      code: 'AI_KEY_MISSING',
      message: 'AI_ENABLED=true but GEMINI_API_KEY is empty',
      severity: isProd ? 'error' : 'warning',
    });
  }

  if (cfg.rag.enabled && !cfg.enabled) {
    issues.push({
      code: 'AI_RAG_WITHOUT_AI',
      message: 'AI_RAG_ENABLED=true while AI_ENABLED=false — RAG will not run',
      severity: 'warning',
    });
  }

  if (cfg.rag.enabled && cfg.rag.embeddingDimensions !== AI_DEFAULT_EMBEDDING_DIMENSIONS) {
    issues.push({
      code: 'AI_EMBED_DIM_MISMATCH',
      message: `AI_EMBEDDING_DIMENSIONS=${cfg.rag.embeddingDimensions} differs from migration default ${AI_DEFAULT_EMBEDDING_DIMENSIONS}; requires matching pgvector column + full reindex`,
      severity: isProd ? 'error' : 'warning',
    });
  }

  if (cfg.timeoutMs > 60_000) {
    issues.push({
      code: 'AI_TIMEOUT_TOO_HIGH',
      message: 'AI_TIMEOUT_MS exceeds 60000',
      severity: 'warning',
    });
  }

  if (cfg.maxOutputTokens > 4096) {
    issues.push({
      code: 'AI_MAX_TOKENS_TOO_HIGH',
      message: 'AI_MAX_OUTPUT_TOKENS exceeds 4096',
      severity: 'warning',
    });
  }

  if (cfg.rag.topK > 20) {
    issues.push({
      code: 'AI_RAG_TOP_K_TOO_HIGH',
      message: 'AI_RAG_TOP_K exceeds 20',
      severity: 'warning',
    });
  }

  if (isProd && cfg.enabled) {
    if (!cfg.geminiModel) {
      issues.push({
        code: 'AI_MODEL_MISSING',
        message: 'GEMINI_MODEL required when AI is enabled in production',
        severity: 'error',
      });
    }
  }

  return issues;
}

export function assertAiConfigOrThrow(
  get: (key: string, defaultValue?: string) => string | undefined,
  opts?: { nodeEnv?: string },
): AiConfig {
  const cfg = loadAiConfig(get);
  const issues = validateAiConfig(cfg, opts);
  const fatal = issues.filter((i) => i.severity === 'error');
  if (fatal.length > 0) {
    throw new Error(
      `Invalid AI configuration: ${fatal.map((f) => f.code).join(', ')}`,
    );
  }
  return cfg;
}

/** Clamp numeric env-derived values to safe production bounds. */
export function clampAiConfig(cfg: AiConfig): AiConfig {
  return {
    ...cfg,
    timeoutMs: Math.min(cfg.timeoutMs, 60_000),
    maxOutputTokens: Math.min(cfg.maxOutputTokens, 4096),
    chatHistoryLimit: Math.min(cfg.chatHistoryLimit, 32),
    chatMaxMessageChars: Math.min(cfg.chatMaxMessageChars, 4000),
    rag: {
      ...cfg.rag,
      topK: Math.min(cfg.rag.topK, 20),
      embedBatchSize: Math.min(cfg.rag.embedBatchSize, 64),
      maxDocumentBytes: Math.min(cfg.rag.maxDocumentBytes, 50 * 1024 * 1024),
    },
  };
}
