import { GeminiProvider } from './gemini.provider';
import { ConfigService } from '@nestjs/config';
import { AiHttpException } from '../ai.errors';
import { GeminiKeyPoolService } from './gemini-key-pool.service';

function makePool(config: ConfigService): GeminiKeyPoolService {
  return new GeminiKeyPoolService(config);
}

describe('GeminiProvider', () => {
  const configMap: Record<string, string> = {
    AI_ENABLED: 'true',
    AI_PROVIDER: 'gemini',
    GEMINI_API_KEY: 'test-key',
    GEMINI_MODEL: 'gemini-flash-latest',
    AI_TIMEOUT_MS: '5000',
    AI_MAX_OUTPUT_TOKENS: '800',
    AI_DAILY_EXPLANATION_LIMIT: '20',
  };

  const config = {
    get: (key: string, def?: string) => configMap[key] ?? def,
  } as unknown as ConfigService;

  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('isReady when enabled with key', () => {
    const provider = new GeminiProvider(config, makePool(config));
    expect(provider.isReady()).toBe(true);
  });

  it('returns structured text on success', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () =>
        JSON.stringify({
          candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }],
          usageMetadata: { promptTokenCount: 10, candidatesTokenCount: 5 },
        }),
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config, makePool(config));
    const result = await provider.structuredComplete({
      systemInstruction: 'sys',
      userContent: 'user',
    });
    expect(result.text).toContain('ok');
    expect(result.provider).toBe('gemini');
    expect(result.inputTokens).toBe(10);
    const call = (global.fetch as jest.Mock).mock.calls[0];
    expect(String(call[0])).not.toContain('test-key');
    expect(String(call[0])).not.toContain('key=');
    expect(call[1].headers['x-goog-api-key']).toBe('test-key');
  });

  it('failovers to second key on HTTP 429', async () => {
    const map: Record<string, string> = {
      ...configMap,
      GEMINI_API_KEY: 'key-one-aaaa',
      GEMINI_API_KEYS: 'key-two-bbbb',
    };
    const multiConfig = {
      get: (key: string, def?: string) => map[key] ?? def,
    } as unknown as ConfigService;

    global.fetch = jest
      .fn()
      .mockResolvedValueOnce({
        ok: false,
        status: 429,
        text: async () => 'RESOURCE_EXHAUSTED',
      })
      .mockResolvedValueOnce({
        ok: true,
        status: 200,
        text: async () =>
          JSON.stringify({
            candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }],
          }),
      }) as unknown as typeof fetch;

    const provider = new GeminiProvider(multiConfig, makePool(multiConfig));
    const result = await provider.structuredComplete({
      systemInstruction: 's',
      userContent: 'u',
    });
    expect(result.text).toContain('ok');
    expect((global.fetch as jest.Mock).mock.calls).toHaveLength(2);
    expect((global.fetch as jest.Mock).mock.calls[0][1].headers['x-goog-api-key']).toBe(
      'key-one-aaaa',
    );
    expect((global.fetch as jest.Mock).mock.calls[1][1].headers['x-goog-api-key']).toBe(
      'key-two-bbbb',
    );
  });

  it('maps HTTP 401 to AI_UNAVAILABLE without leaking body', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 401,
      text: async () => 'secret-key-in-body test-key',
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config, makePool(config));
    await expect(
      provider.structuredComplete({ systemInstruction: 's', userContent: 'u' }),
    ).rejects.toBeInstanceOf(AiHttpException);
  });

  it('maps HTTP 503 to AI_UNAVAILABLE', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 503,
      text: async () => 'busy',
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config, makePool(config));
    await expect(
      provider.structuredComplete({ systemInstruction: 's', userContent: 'u' }),
    ).rejects.toBeInstanceOf(AiHttpException);
  });

  it('maps abort to AI_TIMEOUT', async () => {
    global.fetch = jest.fn().mockImplementation(() => {
      const err = new Error('aborted');
      err.name = 'AbortError';
      return Promise.reject(err);
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config, makePool(config));
    await expect(
      provider.structuredComplete({ systemInstruction: 's', userContent: 'u' }),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'AI_TIMEOUT' }),
    });
  });

  it('rejects empty model text', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      text: async () =>
        JSON.stringify({ candidates: [{ content: { parts: [{ text: '' }] } }] }),
    }) as unknown as typeof fetch;

    const provider = new GeminiProvider(config, makePool(config));
    await expect(
      provider.structuredComplete({ systemInstruction: 's', userContent: 'u' }),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'AI_UNAVAILABLE' }),
    });
  });
});
