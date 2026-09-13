import {
  classifyGeminiHttpStatus,
  labelGeminiKey,
  maskGeminiKey,
  parseGeminiApiKeys,
  shouldRotateGeminiKey,
} from './gemini-key-pool';
import { GeminiKeyPoolService } from './gemini-key-pool.service';
import { ConfigService } from '@nestjs/config';
import { GeminiRotatableError } from './gemini-key-pool.service';

describe('gemini-key-pool helpers', () => {
  it('parses and dedupes GEMINI_API_KEY + GEMINI_API_KEYS', () => {
    const keys = parseGeminiApiKeys({
      primary: 'key-a',
      pool: 'key-b, key-a; key-c\nkey-b',
    });
    expect(keys).toEqual(['key-a', 'key-b', 'key-c']);
  });

  it('masks keys for logs', () => {
    expect(maskGeminiKey('AIzaSySecretABCD')).toBe('…ABCD');
    expect(labelGeminiKey(0, 'AIzaSySecretABCD')).toBe('key#1(…ABCD)');
  });

  it('classifies rotatable HTTP statuses', () => {
    expect(classifyGeminiHttpStatus(429)).toBe('quota');
    expect(classifyGeminiHttpStatus(403)).toBe('auth');
    expect(classifyGeminiHttpStatus(503)).toBe('transient');
    expect(shouldRotateGeminiKey('quota')).toBe(true);
    expect(shouldRotateGeminiKey('other')).toBe(false);
  });
});

describe('GeminiKeyPoolService', () => {
  function makeConfig(map: Record<string, string>): ConfigService {
    return {
      get: (key: string, def?: string) => map[key] ?? def,
    } as unknown as ConfigService;
  }

  it('failovers across keys and cools down quota failures', async () => {
    const config = makeConfig({
      GEMINI_API_KEY: 'alpha-1111',
      GEMINI_API_KEYS: 'beta-2222',
      GEMINI_KEY_COOLDOWN_MS: '60000',
    });
    const pool = new GeminiKeyPoolService(config);

    const seen: string[] = [];
    const result = await pool.executeWithFailover(async (slot) => {
      seen.push(slot.key);
      if (slot.key === 'alpha-1111') {
        throw new GeminiRotatableError('quota', 'exhausted');
      }
      return 'ok';
    });

    expect(result).toBe('ok');
    expect(seen).toEqual(['alpha-1111', 'beta-2222']);
    const status = pool.getStatus();
    expect(status.configured).toBe(2);
    expect(status.inCooldown).toBe(1);
    expect(status.healthy).toBe(1);
    expect(JSON.stringify(status)).not.toContain('alpha-1111');
    expect(JSON.stringify(status)).not.toContain('beta-2222');
  });

  it('disables key after auth failure', async () => {
    const config = makeConfig({
      GEMINI_API_KEY: 'bad-key-zzzz',
      GEMINI_API_KEYS: 'good-key-yyyy',
      GEMINI_KEY_COOLDOWN_MS: '60000',
    });
    const pool = new GeminiKeyPoolService(config);

    const seen: string[] = [];
    const result = await pool.executeWithFailover(async (slot) => {
      seen.push(slot.key);
      if (slot.key === 'bad-key-zzzz') {
        throw new GeminiRotatableError('auth', 'denied');
      }
      return 'ok';
    });

    expect(result).toBe('ok');
    expect(seen).toEqual(['bad-key-zzzz', 'good-key-yyyy']);
    expect(pool.getStatus().disabled).toBe(1);
    expect(pool.getStatus().healthy).toBe(1);
  });
});
