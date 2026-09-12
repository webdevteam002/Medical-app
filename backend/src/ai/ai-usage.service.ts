import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  AI_CHAT_ENDPOINT,
  AI_EXPLAIN_ENDPOINT,
  AI_VERIFY_ENDPOINT,
  aiConfigFrom,
} from './ai.config';
import { aiQuotaExceeded } from './ai.errors';

@Injectable()
export class AiUsageService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  private startOfUtcDay(now = new Date()): Date {
    return new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );
  }

  private quotaMessage(endpoint: string): string {
    if (endpoint === AI_CHAT_ENDPOINT) return 'Daily AI assistant limit reached';
    if (endpoint === AI_VERIFY_ENDPOINT) {
      return 'Daily admin AI verification limit reached';
    }
    return 'Daily AI explanation limit reached';
  }

  /**
   * Race-safe daily quota reservation using a Postgres advisory lock.
   * Counts ALL events for the endpoint+UTC day (success and failure).
   */
  async reserveQuota(
    userId: string,
    endpoint: string,
    limit: number,
  ): Promise<{ usageEventId: string }> {
    const since = this.startOfUtcDay();
    const lockKey = this.advisoryLockKey(userId, endpoint);

    return this.prisma.$transaction(async (tx) => {
      await tx.$executeRaw`SELECT pg_advisory_xact_lock(${lockKey})`;

      const count = await tx.aiUsageEvent.count({
        where: {
          userId,
          endpoint,
          createdAt: { gte: since },
        },
      });

      if (count >= limit) {
        throw aiQuotaExceeded(this.quotaMessage(endpoint));
      }

      const event = await tx.aiUsageEvent.create({
        data: {
          userId,
          endpoint,
          provider: 'pending',
          model: 'pending',
          success: false,
          latencyMs: 0,
        },
      });

      return { usageEventId: event.id };
    });
  }

  async reserveExplainQuota(userId: string): Promise<{ usageEventId: string }> {
    const limit = aiConfigFrom(this.config).dailyExplanationLimit;
    return this.reserveQuota(userId, AI_EXPLAIN_ENDPOINT, limit);
  }

  async reserveChatQuota(userId: string): Promise<{ usageEventId: string }> {
    const limit = aiConfigFrom(this.config).dailyChatLimit;
    return this.reserveQuota(userId, AI_CHAT_ENDPOINT, limit);
  }

  async reserveAdminVerifyQuota(
    userId: string,
  ): Promise<{ usageEventId: string }> {
    const limit = aiConfigFrom(this.config).dailyAdminVerifyLimit;
    return this.reserveQuota(userId, AI_VERIFY_ENDPOINT, limit);
  }

  async finalizeUsageEvent(
    usageEventId: string,
    data: {
      provider: string;
      model: string;
      success: boolean;
      latencyMs: number;
      inputTokens?: number;
      outputTokens?: number;
    },
  ): Promise<void> {
    await this.prisma.aiUsageEvent.update({
      where: { id: usageEventId },
      data: {
        provider: data.provider,
        model: data.model,
        success: data.success,
        latencyMs: data.latencyMs,
        inputTokens: data.inputTokens ?? null,
        outputTokens: data.outputTokens ?? null,
      },
    });
  }

  /** Stable 32-bit signed int for pg_advisory_xact_lock. */
  advisoryLockKey(userId: string, endpoint: string): number {
    const input = `${userId}:${endpoint}`;
    let hash = 0;
    for (let i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.charCodeAt(i);
      hash |= 0;
    }
    return hash === 0 ? 1 : hash;
  }
}
