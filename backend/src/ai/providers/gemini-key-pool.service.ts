import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { aiConfigFrom } from '../ai.config';
import {
  GeminiKeyFailureKind,
  labelGeminiKey,
  parseGeminiApiKeys,
  shouldRotateGeminiKey,
} from './gemini-key-pool';

export type GeminiKeySlot = {
  index: number;
  key: string;
  label: string;
};

export type GeminiKeyPoolStatus = {
  configured: number;
  healthy: number;
  inCooldown: number;
  disabled: number;
  /** Masked labels only — never raw secrets. */
  slots: Array<{
    label: string;
    healthy: boolean;
    inCooldown: boolean;
    disabled: boolean;
    cooldownRemainingMs: number;
  }>;
};

type InternalSlot = {
  index: number;
  key: string;
  label: string;
  cooldownUntil: number;
  disabled: boolean;
  consecutiveAuthFailures: number;
  lastFailureKind?: GeminiKeyFailureKind;
};

/**
 * Multi-key Gemini pool with cooldown + automatic failover.
 * Keys stay server-side only. Prefer GEMINI_API_KEYS for pools;
 * GEMINI_API_KEY remains supported as the first (or only) key.
 */
@Injectable()
export class GeminiKeyPoolService {
  private readonly logger = new Logger(GeminiKeyPoolService.name);
  private slots: InternalSlot[] = [];
  private cursor = 0;
  private lastFingerprint = '';

  constructor(private readonly config: ConfigService) {
    this.reloadFromEnv();
  }

  reloadFromEnv(): void {
    const cfg = aiConfigFrom(this.config);
    const keys = cfg.geminiApiKeys;
    const fingerprint = keys.join('|');
    if (fingerprint === this.lastFingerprint && this.slots.length === keys.length) {
      return;
    }

    const previous = new Map(this.slots.map((s) => [s.key, s]));
    this.slots = keys.map((key, index) => {
      const prior = previous.get(key);
      return {
        index,
        key,
        label: labelGeminiKey(index, key),
        cooldownUntil: prior?.cooldownUntil ?? 0,
        disabled: prior?.disabled ?? false,
        consecutiveAuthFailures: prior?.consecutiveAuthFailures ?? 0,
        lastFailureKind: prior?.lastFailureKind,
      };
    });
    this.lastFingerprint = fingerprint;
    this.cursor = 0;

    if (keys.length > 0) {
      this.logger.log(
        `Gemini key pool loaded: ${keys.length} key(s) [${this.slots
          .map((s) => s.label)
          .join(', ')}]`,
      );
    }
  }

  hasKeys(): boolean {
    this.reloadFromEnv();
    return this.slots.length > 0;
  }

  /** Primary key for backward-compat checks (first configured). */
  primaryKey(): string | null {
    this.reloadFromEnv();
    return this.slots[0]?.key ?? null;
  }

  getStatus(): GeminiKeyPoolStatus {
    this.reloadFromEnv();
    const now = Date.now();
    const slots = this.slots.map((s) => {
      const inCooldown = !s.disabled && s.cooldownUntil > now;
      const healthy = !s.disabled && !inCooldown;
      return {
        label: s.label,
        healthy,
        inCooldown,
        disabled: s.disabled,
        cooldownRemainingMs: inCooldown ? Math.max(0, s.cooldownUntil - now) : 0,
      };
    });
    return {
      configured: this.slots.length,
      healthy: slots.filter((s) => s.healthy).length,
      inCooldown: slots.filter((s) => s.inCooldown).length,
      disabled: slots.filter((s) => s.disabled).length,
      slots,
    };
  }

  /**
   * Run `fn` with a healthy key; on rotatable failures, cool that key down
   * and try the next until the pool is exhausted.
   */
  async executeWithFailover<T>(
    fn: (slot: GeminiKeySlot) => Promise<T>,
    opts?: {
      isRotatableFailure?: (err: unknown) => boolean;
      classifyFailure?: (err: unknown) => GeminiKeyFailureKind;
      operation?: string;
    },
  ): Promise<T> {
    this.reloadFromEnv();
    if (this.slots.length === 0) {
      throw new Error('No Gemini API keys configured');
    }

    const tried = new Set<string>();
    let lastError: unknown;

    while (tried.size < this.slots.length) {
      const slot = this.pickHealthySlot(tried);
      if (!slot) break;

      tried.add(slot.key);
      try {
        const result = await fn({
          index: slot.index,
          key: slot.key,
          label: slot.label,
        });
        this.markSuccess(slot.key);
        return result;
      } catch (err) {
        lastError = err;
        const kind =
          opts?.classifyFailure?.(err) ??
          (opts?.isRotatableFailure?.(err)
            ? 'transient'
            : this.inferKindFromError(err));

        if (!shouldRotateGeminiKey(kind) && !opts?.isRotatableFailure?.(err)) {
          throw err;
        }

        this.markFailure(slot.key, kind);
        const op = opts?.operation ?? 'gemini';
        this.logger.warn(
          `${op}: ${slot.label} failed (${kind}) — trying next key if available`,
        );
      }
    }

    const status = this.getStatus();
    this.logger.error(
      `Gemini key pool exhausted (configured=${status.configured} healthy=${status.healthy} cooldown=${status.inCooldown} disabled=${status.disabled})`,
    );
    throw lastError instanceof Error
      ? lastError
      : new Error('All Gemini API keys failed');
  }

  markFailure(key: string, kind: GeminiKeyFailureKind): void {
    const slot = this.slots.find((s) => s.key === key);
    if (!slot) return;

    const cfg = aiConfigFrom(this.config);
    slot.lastFailureKind = kind;

    if (kind === 'auth') {
      slot.consecutiveAuthFailures += 1;
      // Invalid keys rarely recover — disable quickly so traffic moves on.
      if (slot.consecutiveAuthFailures >= 1) {
        slot.disabled = true;
        this.logger.error(
          `${slot.label} disabled for this process after auth failure — remove/replace the key in env`,
        );
        return;
      }
      slot.cooldownUntil = Date.now() + Math.min(cfg.geminiKeyCooldownMs, 60_000);
      return;
    }

    if (kind === 'quota') {
      slot.cooldownUntil = Date.now() + cfg.geminiKeyCooldownMs;
      this.logger.warn(
        `${slot.label} in cooldown ${cfg.geminiKeyCooldownMs}ms (quota/rate limit)`,
      );
      return;
    }

    if (kind === 'transient' || kind === 'timeout') {
      // Short cooldown so we don't immediately re-pick the same overloaded key.
      slot.cooldownUntil = Date.now() + Math.min(cfg.geminiKeyCooldownMs, 30_000);
    }
  }

  markSuccess(key: string): void {
    const slot = this.slots.find((s) => s.key === key);
    if (!slot) return;
    slot.consecutiveAuthFailures = 0;
    slot.cooldownUntil = 0;
    slot.lastFailureKind = undefined;
  }

  private pickHealthySlot(exclude: Set<string>): InternalSlot | null {
    const now = Date.now();
    const healthy = this.slots.filter(
      (s) => !s.disabled && s.cooldownUntil <= now && !exclude.has(s.key),
    );
    if (healthy.length === 0) return null;

    // Round-robin across healthy keys to spread quota.
    for (let i = 0; i < this.slots.length; i++) {
      const idx = (this.cursor + i) % this.slots.length;
      const candidate = this.slots[idx];
      if (
        !candidate.disabled &&
        candidate.cooldownUntil <= now &&
        !exclude.has(candidate.key)
      ) {
        this.cursor = (idx + 1) % this.slots.length;
        return candidate;
      }
    }
    return healthy[0] ?? null;
  }

  private inferKindFromError(err: unknown): GeminiKeyFailureKind {
    if (err instanceof Error && err.name === 'AbortError') return 'timeout';
    if (err && typeof err === 'object' && 'geminiFailureKind' in err) {
      return (err as { geminiFailureKind: GeminiKeyFailureKind }).geminiFailureKind;
    }
    const msg = String(err).toLowerCase();
    if (msg.includes('quota') || msg.includes('429') || msg.includes('resource_exhausted')) {
      return 'quota';
    }
    if (msg.includes('401') || msg.includes('403') || msg.includes('auth')) {
      return 'auth';
    }
    if (msg.includes('503') || msg.includes('502') || msg.includes('timeout')) {
      return 'transient';
    }
    return 'other';
  }
}

/** Attach a failure kind so the pool can rotate without parsing Nest exceptions. */
export class GeminiRotatableError extends Error {
  readonly geminiFailureKind: GeminiKeyFailureKind;

  constructor(kind: GeminiKeyFailureKind, message: string) {
    super(message);
    this.name = 'GeminiRotatableError';
    this.geminiFailureKind = kind;
  }
}
