import { GeminiProvider, l2Normalize } from '../providers/gemini.provider';
import { ConfigService } from '@nestjs/config';
import { AiHttpException } from '../ai.errors';

describe('GeminiProvider.embed', () => {
  const configMap: Record<string, string> = {
    AI_ENABLED: 'true',
    AI_PROVIDER: 'gemini',
    GEMINI_API_KEY: 'test-key',
    GEMINI_MODEL: 'gemini-flash-latest',
    AI_TIMEOUT_MS: '5000',
    AI_MAX_OUTPUT_TOKENS: '800',
    AI_DAILY_EXPLANATION_LIMIT: '20',
    AI_RAG_ENABLED: 'true',
    AI_EMBEDDING_MODEL: 'gemini-embedding-001',
    AI_EMBEDDING_DIMENSIONS: '4',
    AI_RAG_EMBED_BATCH_SIZE: '16',
  };

  const config = {
    get: (key: string, def?: string) => configMap[key] ?? def,
  } as unknown as ConfigService;

  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('l2Normalize produces unit vector', () => {
    const v = l2Normalize([3, 4]);
    expect(Math.hypot(v[0], v[1])).toBeCloseTo(1, 5);
  });

  it('embeds successfully and normalizes', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () =>
        JSON.stringify({
          embeddings: [{ values: [3, 0, 0, 4] }],
        }),
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config);
    const result = await provider.embed({
      texts: ['hello'],
      dimensions: 4,
      model: 'gemini-embedding-001',
    });
    expect(result.embeddings).toHaveLength(1);
    expect(result.embeddings[0]).toHaveLength(4);
    expect(Math.hypot(...result.embeddings[0])).toBeCloseTo(1, 5);
    expect(result.model).toBe('gemini-embedding-001');
    const call = (global.fetch as jest.Mock).mock.calls[0];
    expect(String(call[0])).not.toContain('key=');
    expect(call[1].headers['x-goog-api-key']).toBe('test-key');
  });

  it('maps timeout', async () => {
    global.fetch = jest.fn().mockImplementation(() => {
      const err = new Error('aborted');
      err.name = 'AbortError';
      return Promise.reject(err);
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config);
    await expect(provider.embed({ texts: ['x'], dimensions: 4 })).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'AI_TIMEOUT' }),
    });
  });

  it('maps provider failure', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 503,
      text: async () => 'busy',
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config);
    await expect(provider.embed({ texts: ['x'], dimensions: 4 })).rejects.toBeInstanceOf(
      AiHttpException,
    );
  });

  it('rejects malformed response', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () => 'not-json',
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config);
    await expect(provider.embed({ texts: ['x'], dimensions: 4 })).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'AI_INVALID_RESPONSE' }),
    });
  });

  it('rejects dimension mismatch', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () =>
        JSON.stringify({
          embeddings: [{ values: [1, 2] }],
        }),
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config);
    await expect(provider.embed({ texts: ['x'], dimensions: 4 })).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'AI_INVALID_RESPONSE' }),
    });
  });
});
