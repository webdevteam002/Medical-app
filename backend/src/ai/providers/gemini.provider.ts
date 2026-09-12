import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { aiConfigFrom } from '../ai.config';
import { aiTimeout, aiUnavailable, aiInvalidResponse } from '../ai.errors';
import { redactSecrets } from '../ai-safe-log';
import {
  AiEmbedRequest,
  AiEmbedResult,
  AiProvider,
  AiStructuredCompleteRequest,
  AiStructuredCompleteResult,
} from './ai-provider';

@Injectable()
export class GeminiProvider implements AiProvider {
  readonly name = 'gemini';
  private readonly logger = new Logger(GeminiProvider.name);

  constructor(private readonly config: ConfigService) {}

  private getAiConfig() {
    return aiConfigFrom(this.config);
  }

  isReady(): boolean {
    const cfg = this.getAiConfig();
    return cfg.enabled && cfg.provider === 'gemini' && Boolean(cfg.geminiApiKey);
  }

  async structuredComplete(
    request: AiStructuredCompleteRequest,
  ): Promise<AiStructuredCompleteResult> {
    const cfg = this.getAiConfig();
    if (!cfg.enabled) {
      throw aiUnavailable('AI features are currently disabled');
    }
    if (!cfg.geminiApiKey) {
      this.logger.error('GEMINI_API_KEY missing while AI_ENABLED=true');
      throw aiUnavailable();
    }

    const model = (request.model || cfg.geminiModel).trim();
    const timeoutMs = request.timeoutMs ?? cfg.timeoutMs;
    const maxOutputTokens = request.maxOutputTokens ?? cfg.maxOutputTokens;
    const temperature = request.temperature ?? 0.2;

    // Prefer header auth so API keys never appear in URLs / error messages.
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const started = Date.now();

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': cfg.geminiApiKey,
        },
        signal: controller.signal,
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: request.systemInstruction }],
          },
          contents: [{ role: 'user', parts: [{ text: request.userContent }] }],
          generationConfig: {
            temperature,
            maxOutputTokens,
            responseMimeType: 'application/json',
          },
        }),
      });

      const bodyText = await response.text();
      const latencyMs = Date.now() - started;

      if (response.status === 429 || response.status === 503) {
        this.logger.warn(`Gemini transient HTTP ${response.status}`);
        throw aiUnavailable();
      }

      if (response.status === 401 || response.status === 403) {
        this.logger.error(`Gemini auth HTTP ${response.status}`);
        throw aiUnavailable();
      }

      if (!response.ok) {
        this.logger.error(`Gemini HTTP ${response.status}`);
        throw aiUnavailable();
      }

      let parsed: {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
        usageMetadata?: {
          promptTokenCount?: number;
          candidatesTokenCount?: number;
        };
      };
      try {
        parsed = JSON.parse(bodyText) as typeof parsed;
      } catch {
        throw aiUnavailable();
      }

      const text = parsed.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
      if (!text) {
        throw aiUnavailable();
      }

      return {
        text,
        model,
        provider: this.name,
        inputTokens: parsed.usageMetadata?.promptTokenCount,
        outputTokens: parsed.usageMetadata?.candidatesTokenCount,
        latencyMs,
      };
    } catch (err) {
      if (err && typeof err === 'object' && 'getStatus' in err) {
        throw err;
      }
      if (err instanceof Error && err.name === 'AbortError') {
        throw aiTimeout();
      }
      this.logger.error(`Gemini request failed: ${redactSecrets(err)}`);
      throw aiUnavailable();
    } finally {
      clearTimeout(timer);
    }
  }

  async embed(request: AiEmbedRequest): Promise<AiEmbedResult> {
    const cfg = this.getAiConfig();
    if (!cfg.enabled) {
      throw aiUnavailable('AI features are currently disabled');
    }
    if (!cfg.geminiApiKey) {
      this.logger.error('GEMINI_API_KEY missing while AI_ENABLED=true');
      throw aiUnavailable();
    }

    const texts = request.texts.filter((t) => typeof t === 'string' && t.trim().length > 0);
    if (texts.length === 0) {
      throw aiInvalidResponse('No texts provided for embedding');
    }

    const model = (request.model || cfg.rag.embeddingModel).trim();
    const dimensions = request.dimensions ?? cfg.rag.embeddingDimensions;
    const timeoutMs = request.timeoutMs ?? cfg.timeoutMs;
    const batchSize = Math.max(1, request.batchSize ?? cfg.rag.embedBatchSize);
    const taskType = request.taskType ?? 'RETRIEVAL_DOCUMENT';

    const started = Date.now();
    const embeddings: number[][] = [];

    for (let i = 0; i < texts.length; i += batchSize) {
      const batch = texts.slice(i, i + batchSize);
      const batchVectors = await this.embedBatch({
        apiKey: cfg.geminiApiKey,
        model,
        texts: batch,
        dimensions,
        taskType,
        timeoutMs,
      });
      embeddings.push(...batchVectors);
    }

    if (embeddings.length !== texts.length) {
      throw aiInvalidResponse('Embedding count mismatch');
    }

    return {
      embeddings,
      model,
      provider: this.name,
      dimensions,
      latencyMs: Date.now() - started,
    };
  }

  private async embedBatch(opts: {
    apiKey: string;
    model: string;
    texts: string[];
    dimensions: number;
    taskType: string;
    timeoutMs: number;
  }): Promise<number[][]> {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(opts.model)}:batchEmbedContents`;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), opts.timeoutMs);

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': opts.apiKey,
        },
        signal: controller.signal,
        body: JSON.stringify({
          requests: opts.texts.map((text) => ({
            model: `models/${opts.model}`,
            content: { parts: [{ text }] },
            taskType: opts.taskType,
            outputDimensionality: opts.dimensions,
          })),
        }),
      });

      const bodyText = await response.text();

      if (response.status === 429 || response.status === 503) {
        this.logger.warn(`Gemini embed transient HTTP ${response.status}`);
        throw aiUnavailable();
      }
      if (response.status === 401 || response.status === 403) {
        this.logger.error(`Gemini embed auth HTTP ${response.status}`);
        throw aiUnavailable();
      }
      if (!response.ok) {
        this.logger.error(`Gemini embed HTTP ${response.status}`);
        throw aiUnavailable();
      }

      let parsed: {
        embeddings?: Array<{ values?: number[] }>;
      };
      try {
        parsed = JSON.parse(bodyText) as typeof parsed;
      } catch {
        throw aiInvalidResponse('Malformed embedding response');
      }

      const rows = parsed.embeddings ?? [];
      if (rows.length !== opts.texts.length) {
        throw aiInvalidResponse('Malformed embedding batch size');
      }

      return rows.map((row) => {
        const values = row.values;
        if (!Array.isArray(values) || values.length === 0) {
          throw aiInvalidResponse('Empty embedding vector');
        }
        if (values.length !== opts.dimensions) {
          throw aiInvalidResponse(
            `Embedding dimension mismatch: expected ${opts.dimensions}, got ${values.length}`,
          );
        }
        // gemini-embedding-001 requires manual L2 normalize when dims < 3072.
        return l2Normalize(values);
      });
    } catch (err) {
      if (err && typeof err === 'object' && 'getStatus' in err) {
        throw err;
      }
      if (err instanceof Error && err.name === 'AbortError') {
        throw aiTimeout();
      }
      this.logger.error(`Gemini embed failed: ${redactSecrets(err)}`);
      throw aiUnavailable();
    } finally {
      clearTimeout(timer);
    }
  }
}

/** Unit-length vectors for cosine / inner-product similarity after truncation. */
export function l2Normalize(values: number[]): number[] {
  let sumSq = 0;
  for (const v of values) sumSq += v * v;
  const norm = Math.sqrt(sumSq);
  if (!Number.isFinite(norm) || norm === 0) {
    throw aiInvalidResponse('Zero or invalid embedding vector');
  }
  return values.map((v) => v / norm);
}
