import { randomUUID } from 'crypto';

const SECRET_PATTERNS: RegExp[] = [
  /key=[^&\s"']+/gi,
  /AIza[0-9A-Za-z\-_]{20,}/g,
  /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi,
  /postgresql:\/\/[^\s"']+/gi,
  /R2_[A-Z_]+=\S+/gi,
  /GEMINI_API_KEY=\S+/gi,
  /JWT_[A-Z_]+=\S+/gi,
];

/**
 * Redact secrets from log/error strings before writing to logs.
 * Never log Gemini keys, JWTs, DB URLs, or R2 credentials.
 */
export function redactSecrets(input: unknown): string {
  let text = String(input ?? '');
  for (const pattern of SECRET_PATTERNS) {
    text = text.replace(pattern, '[REDACTED]');
  }
  // Truncate oversized payloads (avoid dumping PDF/prompt text).
  if (text.length > 500) {
    text = `${text.slice(0, 500)}…[truncated]`;
  }
  return text;
}

export function newAiCorrelationId(): string {
  return randomUUID();
}

export type AiOpsEvent = {
  correlationId: string;
  endpoint: string;
  outcome:
    | 'success'
    | 'failure'
    | 'quota'
    | 'timeout'
    | 'disabled'
    | 'unavailable'
    | 'invalid_response'
    | 'unauthorized'
    | 'not_found';
  role?: string;
  grounding?: string | null;
  provider?: string | null;
  model?: string | null;
  latencyMs?: number;
  ragHitCount?: number;
  errorCode?: string;
};

/** Structured ops line — no prompts, PDF text, or secrets. */
export function formatAiOpsEvent(event: AiOpsEvent): string {
  return [
    `ai_ops`,
    `cid=${event.correlationId}`,
    `endpoint=${event.endpoint}`,
    `outcome=${event.outcome}`,
    event.role ? `role=${event.role}` : null,
    event.grounding ? `grounding=${event.grounding}` : null,
    event.provider ? `provider=${event.provider}` : null,
    event.model ? `model=${event.model}` : null,
    typeof event.latencyMs === 'number' ? `latencyMs=${event.latencyMs}` : null,
    typeof event.ragHitCount === 'number' ? `ragHits=${event.ragHitCount}` : null,
    event.errorCode ? `error=${event.errorCode}` : null,
  ]
    .filter(Boolean)
    .join(' ');
}
