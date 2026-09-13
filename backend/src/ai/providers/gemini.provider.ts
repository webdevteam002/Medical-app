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
import {
  GeminiKeyPoolService,
  GeminiRotatableError,
} from './gemini-key-pool.service';
import {
  classifyGeminiErrorBody,
  classifyGeminiHttpStatus,
  GeminiKeyFailureKind,
} from './gemini-key-pool';

@Injectable()
export class GeminiProvider implements AiProvider {
  readonly name = 'gemini';
  private readonly logger = new Logger(GeminiProvider.name);

  constructor(
    private readonly config: ConfigService,
    private readonly keyPool: GeminiKeyPoolService,
  ) {}

  private getAiConfig() {
    return aiConfigFrom(this.config);
  }

  isReady(): boolean {
    const cfg = this.getAiConfig();
    return (
      cfg.enabled &&
      cfg.provider === 'gemini' &&
      this.keyPool.hasKeys()
    );
  }

  async structuredComplete(
    request: AiStructuredCompleteRequest,
  ): Promise<AiStructuredCompleteResult> {
    const cfg = this.getAiConfig();
    if (!cfg.enabled) {
      throw aiUnavailable('AI features are currently disabled');
    }
    if (!this.keyPool.hasKeys()) {
      this.logger.error('No Gemini API keys configured while AI_ENABLED=true');
      throw aiUnavailable();
    }

    const model = (request.model || cfg.geminiModel).trim();
    const timeoutMs = request.timeoutMs ?? cfg.timeoutMs;
    const maxOutputTokens = request.maxOutputTokens ?? cfg.maxOutputTokens;
    const temperature = request.temperature ?? 0.2;

    try {
      return await this.keyPool.executeWithFailover(
        async (slot) => {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;
          const controller = new AbortController();
          const timer = setTimeout(() => controller.abort(), timeoutMs);
          const started = Date.now();

          try {
            const response = await fetch(url, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': slot.key,
              },
              signal: controller.signal,
              body: JSON.stringify({
                systemInstruction: {
                  parts: [{ text: request.systemInstruction }],
                },
                contents: [
                  { role: 'user', parts: [{ text: request.userContent }] },
                ],
                generationConfig: {
                  temperature,
                  maxOutputTokens,
                  responseMimeType: 'application/json',
                },
              }),
            });

            const bodyText = await response.text();
            const latencyMs = Date.now() - started;
            this.throwIfRotatableHttp(response.status, bodyText, 'generate');

            if (!response.ok) {
              this.logger.error(
                `Gemini HTTP ${response.status} via ${slot.label}`,
              );
              throw aiUnavailable();
            }

            let parsed: {
              candidates?: Array<{
                content?: { parts?: Array<{ text?: string }> };
              }>;
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

            const text =
              parsed.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
            if (!text) {
              throw new GeminiRotatableError(
                'transient',
                'Empty Gemini generateContent response',
              );
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
            if (err instanceof Error && err.name === 'AbortError') {
              throw new GeminiRotatableError('timeout', 'Gemini request timed out');
            }
            throw err;
          } finally {
            clearTimeout(timer);
          }
        },
        {
          operation: 'structuredComplete',
          classifyFailure: (err) => this.classifyCaught(err),
        },
      );
    } catch (err) {
      if (err && typeof err === 'object' && 'getStatus' in err) {
        throw err;
      }
      if (err instanceof GeminiRotatableError && err.geminiFailureKind === 'timeout') {
        throw aiTimeout();
      }
      this.logger.error(`Gemini request failed: ${redactSecrets(err)}`);
      throw aiUnavailable();
    }
  }

  async embed(request: AiEmbedRequest): Promise<AiEmbedResult> {
    const cfg = this.getAiConfig();
    if (!cfg.enabled) {
      throw aiUnavailable('AI features are currently disabled');
    }
    if (!this.keyPool.hasKeys()) {
      this.logger.error('No Gemini API keys configured while AI_ENABLED=true');
      throw aiUnavailable();
    }

    const texts = request.texts.filter(
      (t) => typeof t === 'string' && t.trim().length > 0,
    );
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

    try {
      for (let i = 0; i < texts.length; i += batchSize) {
        const batch = texts.slice(i, i + batchSize);
        const batchVectors = await this.keyPool.executeWithFailover(
          (slot) =>
            this.embedBatch({
              apiKey: slot.key,
              keyLabel: slot.label,
              model,
              texts: batch,
              dimensions,
              taskType,
              timeoutMs,
            }),
          {
            operation: 'embed',
            classifyFailure: (err) => this.classifyCaught(err),
          },
        );
        embeddings.push(...batchVectors);
      }
    } catch (err) {
      if (err && typeof err === 'object' && 'getStatus' in err) {
        throw err;
      }
      if (err instanceof GeminiRotatableError && err.geminiFailureKind === 'timeout') {
        throw aiTimeout();
      }
      this.logger.error(`Gemini embed failed: ${redactSecrets(err)}`);
      throw aiUnavailable();
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
    keyLabel: string;
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
      this.throwIfRotatableHttp(response.status, bodyText, 'embed');

      if (!response.ok) {
        this.logger.error(
          `Gemini embed HTTP ${response.status} via ${opts.keyLabel}`,
        );
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
        return l2Normalize(values);
      });
    } catch (err) {
      if (err instanceof Error && err.name === 'AbortError') {
        throw new GeminiRotatableError('timeout', 'Gemini embed timed out');
      }
      throw err;
    } finally {
      clearTimeout(timer);
    }
  }

  private throwIfRotatableHttp(
    status: number,
    bodyText: string,
    op: string,
  ): void {
    const fromBody = classifyGeminiErrorBody(bodyText);
    const kind: GeminiKeyFailureKind =
      fromBody ?? classifyGeminiHttpStatus(status);

    if (status === 429 || status === 503 || fromBody === 'quota') {
      throw new GeminiRotatableError(
        kind === 'other' ? 'quota' : kind,
        `Gemini ${op} HTTP ${status}`,
      );
    }
    if (status === 401 || status === 403 || fromBody === 'auth') {
      throw new GeminiRotatableError('auth', `Gemini ${op} auth HTTP ${status}`);
    }
    if (status === 500 || status === 502 || status === 504) {
      throw new GeminiRotatableError('transient', `Gemini ${op} HTTP ${status}`);
    }
  }

  private classifyCaught(err: unknown): GeminiKeyFailureKind {
    if (err instanceof GeminiRotatableError) return err.geminiFailureKind;
    if (err instanceof Error && err.name === 'AbortError') return 'timeout';
    return 'other';
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
