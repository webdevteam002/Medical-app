import { createHash } from 'crypto';

/**
 * Safe normalization for medical PDF text before embedding.
 * Does NOT rewrite negations, dosages, units, numbers, or clinical terms.
 */
export function normalizeMedicalText(input: string): string {
  if (!input) return '';

  let text = input;

  // Strip NULs / control chars except tab/newline/carriage-return
  text = text.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '');

  // Normalize unicode form (compatibility) then NFC
  try {
    text = text.normalize('NFKC').normalize('NFC');
  } catch {
    // keep as-is if normalize unavailable
  }

  // Soft hyphen / zero-width / BOM cleanup
  text = text.replace(/[\u00AD\u200B-\u200D\uFEFF]/g, '');

  // Fix hyphenated line-wraps: "recom-\nmended" → "recommended"
  text = text.replace(/(\w)-\r?\n(\w)/g, '$1$2');

  // Collapse runs of spaces/tabs within a line; keep newlines
  text = text
    .split(/\r?\n/)
    .map((line) => line.replace(/[ \t]+/g, ' ').trimEnd())
    .join('\n');

  // Collapse 3+ blank lines to 2
  text = text.replace(/\n{3,}/g, '\n\n');

  return text.trim();
}

export function estimateTokenCount(text: string): number {
  if (!text) return 0;
  // Rough English medical estimate: ~4 chars/token
  return Math.max(1, Math.ceil(text.length / 4));
}

export function sha256Hex(data: string | Buffer): string {
  return createHash('sha256').update(data).digest('hex');
}

/** Meaningful extractable text threshold (after normalize). */
export function hasMeaningfulText(text: string): boolean {
  const letters = (text.match(/\p{L}/gu) ?? []).length;
  return letters >= 40;
}
