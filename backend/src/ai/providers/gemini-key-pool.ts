/**
 * Pure helpers for Gemini API key pools (no Nest DI).
 * Never log raw keys — use maskGeminiKey / labelGeminiKey only.
 */

export type GeminiKeyFailureKind =
  | 'quota'
  | 'auth'
  | 'transient'
  | 'timeout'
  | 'other';

export function parseGeminiApiKeys(opts: {
  primary?: string | null;
  pool?: string | null;
}): string[] {
  const collected: string[] = [];

  const push = (raw: string | null | undefined) => {
    if (!raw) return;
    for (const part of raw.split(/[\s,;|\n\r]+/)) {
      const key = part.trim();
      if (key) collected.push(key);
    }
  };

  push(opts.primary);
  push(opts.pool);

  const seen = new Set<string>();
  const unique: string[] = [];
  for (const key of collected) {
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(key);
  }
  return unique;
}

/** Show only last 4 chars — safe for logs / health. */
export function maskGeminiKey(key: string): string {
  const trimmed = key.trim();
  if (trimmed.length <= 4) return '****';
  return `…${trimmed.slice(-4)}`;
}

export function labelGeminiKey(index: number, key: string): string {
  return `key#${index + 1}(${maskGeminiKey(key)})`;
}

export function classifyGeminiHttpStatus(status: number): GeminiKeyFailureKind {
  if (status === 429) return 'quota';
  if (status === 401 || status === 403) return 'auth';
  if (status === 503 || status === 500 || status === 502 || status === 504) {
    return 'transient';
  }
  return 'other';
}

/** Heuristic for body text when status alone is ambiguous. */
export function classifyGeminiErrorBody(body: string): GeminiKeyFailureKind | null {
  const lower = body.toLowerCase();
  if (
    lower.includes('resource_exhausted') ||
    lower.includes('quota') ||
    lower.includes('rate limit') ||
    lower.includes('ratelimit') ||
    lower.includes('billing')
  ) {
    return 'quota';
  }
  if (
    lower.includes('api key not valid') ||
    lower.includes('permission denied') ||
    lower.includes('unauthenticated') ||
    lower.includes('invalid api key')
  ) {
    return 'auth';
  }
  return null;
}

export function shouldRotateGeminiKey(kind: GeminiKeyFailureKind): boolean {
  return kind === 'quota' || kind === 'auth' || kind === 'transient' || kind === 'timeout';
}
