import { redactSecrets, formatAiOpsEvent, newAiCorrelationId } from './ai-safe-log';
import { validateAiConfig, clampAiConfig } from './ai-config.validation';
import { loadAiConfig, AI_DEFAULT_EMBEDDING_DIMENSIONS } from './ai.config';
import { readFileSync } from 'fs';
import { join } from 'path';

describe('AI-7/8 hardening', () => {
  describe('redactSecrets', () => {
    it('redacts Gemini key query params and API key shapes', () => {
      const raw =
        'fetch failed https://generativelanguage.googleapis.com/v1beta/models/x:generateContent?key=AIzaSyFakeSecretValue1234567890';
      const out = redactSecrets(raw);
      expect(out).not.toContain('AIza');
      expect(out).toContain('[REDACTED]');
    });

    it('redacts bearer tokens and database URLs', () => {
      const out = redactSecrets(
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.abc postgresql://user:pass@host/db',
      );
      expect(out).not.toContain('eyJ');
      expect(out).not.toContain('postgresql://');
      expect(out).toContain('[REDACTED]');
    });

    it('truncates oversized payloads', () => {
      const out = redactSecrets('x'.repeat(2000));
      expect(out.length).toBeLessThan(600);
      expect(out).toContain('[truncated]');
    });
  });

  describe('ops events', () => {
    it('formats correlation without prompts', () => {
      const line = formatAiOpsEvent({
        correlationId: newAiCorrelationId(),
        endpoint: 'explain-mcq',
        outcome: 'success',
        role: 'STUDENT',
        grounding: 'rag',
        latencyMs: 120,
        ragHitCount: 2,
      });
      expect(line).toContain('ai_ops');
      expect(line).toContain('endpoint=explain-mcq');
      expect(line).not.toContain('stem');
      expect(line).not.toContain('prompt');
    });
  });

  describe('config validation', () => {
    it('flags missing key when AI enabled', () => {
      const cfg = loadAiConfig((key, def) =>
        key === 'AI_ENABLED' ? 'true' : key === 'GEMINI_API_KEY' ? '' : def,
      );
      const issues = validateAiConfig(cfg, { nodeEnv: 'production' });
      expect(issues.some((i) => i.code === 'AI_KEY_MISSING' && i.severity === 'error')).toBe(
        true,
      );
    });

    it('flags embedding dim mismatch vs migration default in production', () => {
      const cfg = loadAiConfig((key, def) => {
        if (key === 'AI_ENABLED') return 'true';
        if (key === 'AI_RAG_ENABLED') return 'true';
        if (key === 'GEMINI_API_KEY') return 'k';
        if (key === 'AI_EMBEDDING_DIMENSIONS') return '1536';
        return def;
      });
      const issues = validateAiConfig(cfg, { nodeEnv: 'production' });
      expect(
        issues.some((i) => i.code === 'AI_EMBED_DIM_MISMATCH' && i.severity === 'error'),
      ).toBe(true);
      expect(AI_DEFAULT_EMBEDDING_DIMENSIONS).toBe(768);
    });

    it('clamps unbounded topK / timeout', () => {
      const cfg = clampAiConfig(
        loadAiConfig((key, def) => {
          if (key === 'AI_RAG_TOP_K') return '999';
          if (key === 'AI_TIMEOUT_MS') return '999999';
          return def;
        }),
      );
      expect(cfg.rag.topK).toBeLessThanOrEqual(20);
      expect(cfg.timeoutMs).toBeLessThanOrEqual(60_000);
    });
  });

  describe('security invariants', () => {
    const aiDir = __dirname;

    it('Gemini provider uses header API key (not query string)', () => {
      const src = readFileSync(join(aiDir, 'providers/gemini.provider.ts'), 'utf8');
      expect(src).toContain('x-goog-api-key');
      expect(src).not.toContain('?key=${');
      expect(src).toContain('redactSecrets');
    });

    it('student AI controller requires JWT + device session + throttle', () => {
      const src = readFileSync(join(aiDir, 'ai.controller.ts'), 'utf8');
      expect(src).toContain('JwtAuthGuard');
      expect(src).toContain('DeviceSessionGuard');
      expect(src).toContain('ThrottlerGuard');
      expect(src).toContain('explain-mcq');
      expect(src).toContain('chat');
    });

    it('admin AI controller requires RolesGuard ADMIN', () => {
      const src = readFileSync(join(aiDir, 'admin-ai.controller.ts'), 'utf8');
      expect(src).toContain('RolesGuard');
      expect(src).toContain('UserRole.ADMIN');
      expect(src).toContain('verify-question');
      expect(src).toContain('ThrottlerGuard');
    });

    it('health never returns API key material', () => {
      const src = readFileSync(join(aiDir, 'ai.controller.ts'), 'utf8');
      expect(src).toContain('apiKeyConfigured');
      expect(src).toContain('apiKeyPool');
      expect(src).not.toContain('geminiApiKey:');
      expect(src).not.toContain('cfg.geminiApiKey,');
      expect(src).not.toContain('slot.key');
    });
  });
});
