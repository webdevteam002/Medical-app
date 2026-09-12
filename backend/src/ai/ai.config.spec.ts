import { loadAiConfig, aiConfigFrom } from './ai.config';

describe('loadAiConfig', () => {
  it('defaults AI to disabled', () => {
    const cfg = loadAiConfig(() => undefined);
    expect(cfg.enabled).toBe(false);
    expect(cfg.dailyExplanationLimit).toBe(20);
    expect(cfg.timeoutMs).toBe(18000);
  });

  it('parses enabled flag', () => {
    const cfg = loadAiConfig((key, def) =>
      key === 'AI_ENABLED' ? 'true' : def,
    );
    expect(cfg.enabled).toBe(true);
  });
});

describe('aiConfigFrom clamping', () => {
  it('clamps oversized timeout and topK via ConfigService adapter', () => {
    const config = {
      get: (key: string) => {
        const map: Record<string, string> = {
          AI_TIMEOUT_MS: '999999',
          AI_RAG_TOP_K: '100',
          AI_MAX_OUTPUT_TOKENS: '99999',
        };
        return map[key];
      },
    };
    const cfg = aiConfigFrom(config as never);
    expect(cfg.timeoutMs).toBeLessThanOrEqual(60_000);
    expect(cfg.rag.topK).toBeLessThanOrEqual(20);
    expect(cfg.maxOutputTokens).toBeLessThanOrEqual(4096);
  });
});
