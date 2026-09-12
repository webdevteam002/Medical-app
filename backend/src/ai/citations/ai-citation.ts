/**
 * AI-6 shared citation model — server-authored from authorized RAG only.
 * Never trust model-invented titles/pages/URLs.
 */

export type AiCitationSourceType = 'rag';

/** Safe client-facing citation. No R2 keys, signed URLs, or raw chunk text. */
export type AiCitation = {
  materialId: string;
  title: string;
  subjectName: string | null;
  topicName: string | null;
  yearSlug: string | null;
  pageStart: number | null;
  pageEnd: number | null;
  chunkId: string;
  /** Indexed document id used at retrieval time (version identity). */
  documentId: string;
  /** AiDocument.contentHash at retrieval — stable source version marker. */
  contentHash: string | null;
  chunkIndex: number | null;
  sourceType: AiCitationSourceType;
  /** Optional relevance (0–1), rounded for display; not authoritative. */
  similarity: number | null;
};

export type RagCitationSource = {
  materialId: string;
  title: string;
  pageStart: number | null;
  pageEnd: number | null;
  chunkId: string;
  documentId: string;
  text?: string;
  similarity?: number;
  subjectName?: string | null;
  topicName?: string | null;
  yearSlug?: string | null;
  contentHash?: string | null;
  chunkIndex?: number | null;
};

const FORBIDDEN_KEYS = [
  'fileKey',
  'file_key',
  'signedUrl',
  'signed_url',
  'url',
  'password',
  'apiKey',
  'credential',
  'secret',
] as const;

/**
 * Build client-safe citations from authorized RAG retrieval rows.
 * Strips chunk text and any storage/credential fields.
 */
export function buildCitationsFromRag(
  chunks: RagCitationSource[],
): AiCitation[] {
  if (!Array.isArray(chunks) || chunks.length === 0) return [];

  return chunks.map((c) => {
    const similarity =
      typeof c.similarity === 'number' && Number.isFinite(c.similarity)
        ? Math.round(Math.min(1, Math.max(0, c.similarity)) * 1000) / 1000
        : null;

    const citation: AiCitation = {
      materialId: String(c.materialId ?? ''),
      title: String(c.title ?? '').trim() || 'MedStudy material',
      subjectName: nullableString(c.subjectName),
      topicName: nullableString(c.topicName),
      yearSlug: nullableString(c.yearSlug),
      pageStart: nullablePage(c.pageStart),
      pageEnd: nullablePage(c.pageEnd),
      chunkId: String(c.chunkId ?? ''),
      documentId: String(c.documentId ?? ''),
      contentHash: nullableString(c.contentHash),
      chunkIndex:
        typeof c.chunkIndex === 'number' && Number.isFinite(c.chunkIndex)
          ? c.chunkIndex
          : null,
      sourceType: 'rag',
      similarity,
    };

    // Defensive: ensure no accidental leakage of forbidden keys if callers spread raw rows.
    for (const key of FORBIDDEN_KEYS) {
      if (key in (citation as object)) {
        delete (citation as Record<string, unknown>)[key];
      }
    }

    return citation;
  }).filter((c) => c.materialId && c.chunkId);
}

/** Format page range only when metadata exists — never invent pages. */
export function formatCitationPages(
  pageStart: number | null | undefined,
  pageEnd: number | null | undefined,
): string | null {
  if (pageStart == null || !Number.isFinite(pageStart)) return null;
  if (pageEnd != null && Number.isFinite(pageEnd) && pageEnd !== pageStart) {
    return `pp. ${pageStart}–${pageEnd}`;
  }
  return `p. ${pageStart}`;
}

export function assertCitationSafe(citation: AiCitation): void {
  const raw = JSON.stringify(citation).toLowerCase();
  for (const key of FORBIDDEN_KEYS) {
    if (raw.includes(`"${key.toLowerCase()}"`)) {
      throw new Error(`Citation must not expose ${key}`);
    }
  }
  if ('text' in (citation as object)) {
    throw new Error('Citation must not expose chunk text');
  }
}

function nullableString(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  const t = value.trim();
  return t.length > 0 ? t : null;
}

function nullablePage(value: unknown): number | null {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0) {
    return null;
  }
  return Math.floor(value);
}
