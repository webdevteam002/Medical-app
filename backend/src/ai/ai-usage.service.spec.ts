import { AiUsageService } from './ai-usage.service';
import { AiHttpException } from './ai.errors';

describe('AiUsageService quota', () => {
  const config = {
    get: (key: string, def?: string) => {
      const map: Record<string, string> = {
        AI_DAILY_EXPLANATION_LIMIT: '2',
        AI_ENABLED: 'true',
        AI_PROVIDER: 'gemini',
        GEMINI_API_KEY: 'k',
        GEMINI_MODEL: 'm',
        AI_TIMEOUT_MS: '1000',
        AI_MAX_OUTPUT_TOKENS: '100',
      };
      return map[key] ?? def;
    },
  };

  it('rejects when daily count is at limit', async () => {
    const prisma = {
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          $executeRaw: jest.fn().mockResolvedValue(undefined),
          aiUsageEvent: {
            count: jest.fn().mockResolvedValue(2),
            create: jest.fn(),
          },
        };
        return fn(tx);
      }),
    };

    const service = new AiUsageService(prisma as never, config as never);
    await expect(service.reserveExplainQuota('user-a')).rejects.toBeInstanceOf(
      AiHttpException,
    );
  });

  it('creates a reservation when under limit', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'evt-1' });
    const prisma = {
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          $executeRaw: jest.fn().mockResolvedValue(undefined),
          aiUsageEvent: {
            count: jest.fn().mockResolvedValue(1),
            create,
          },
        };
        return fn(tx);
      }),
    };

    const service = new AiUsageService(prisma as never, config as never);
    const result = await service.reserveExplainQuota('user-a');
    expect(result.usageEventId).toBe('evt-1');
    expect(create).toHaveBeenCalled();
  });

  it('uses distinct advisory keys per user', () => {
    const prisma = { $transaction: jest.fn() };
    const service = new AiUsageService(prisma as never, config as never);
    const a = service.advisoryLockKey('user-a', 'explain-mcq');
    const b = service.advisoryLockKey('user-b', 'explain-mcq');
    expect(a).not.toBe(b);
  });
});
