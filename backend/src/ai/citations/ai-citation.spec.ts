import {
  assertCitationSafe,
  buildCitationsFromRag,
  formatCitationPages,
} from './ai-citation';

describe('AI-6 buildCitationsFromRag', () => {
  const chunk = {
    materialId: 'mat-1',
    title: 'Renal Notes',
    pageStart: 12,
    pageEnd: 13,
    chunkId: 'chk-1',
    documentId: 'doc-1',
    text: 'UNTRUSTED long excerpt that must not appear in citations',
    similarity: 0.91234,
    subjectName: 'Medicine',
    topicName: 'Nephrology',
    yearSlug: 'year-1',
    contentHash: 'abc123hash',
    chunkIndex: 4,
  };

  it('builds server citations without chunk text', () => {
    const citations = buildCitationsFromRag([chunk]);
    expect(citations).toHaveLength(1);
    expect(citations[0]).toEqual({
      materialId: 'mat-1',
      title: 'Renal Notes',
      subjectName: 'Medicine',
      topicName: 'Nephrology',
      yearSlug: 'year-1',
      pageStart: 12,
      pageEnd: 13,
      chunkId: 'chk-1',
      documentId: 'doc-1',
      contentHash: 'abc123hash',
      chunkIndex: 4,
      sourceType: 'rag',
      similarity: 0.912,
    });
    expect(JSON.stringify(citations[0])).not.toContain('UNTRUSTED');
    expect(citations[0]).not.toHaveProperty('text');
  });

  it('returns empty when no RAG chunks', () => {
    expect(buildCitationsFromRag([])).toEqual([]);
  });

  it('preserves null pages (never invents)', () => {
    const citations = buildCitationsFromRag([
      { ...chunk, pageStart: null, pageEnd: null },
    ]);
    expect(citations[0].pageStart).toBeNull();
    expect(citations[0].pageEnd).toBeNull();
    expect(formatCitationPages(null, null)).toBeNull();
  });

  it('does not expose R2/file keys or signed URLs', () => {
    const citations = buildCitationsFromRag([
      {
        ...chunk,
        // @ts-expect-error intentional leak attempt
        fileKey: 'materials/secret.pdf',
        signedUrl: 'https://r2.example/signed',
      },
    ]);
    const json = JSON.stringify(citations[0]);
    expect(json).not.toContain('fileKey');
    expect(json).not.toContain('signedUrl');
    expect(json).not.toContain('materials/secret');
    assertCitationSafe(citations[0]);
  });

  it('keeps contentHash for document version identity', () => {
    const a = buildCitationsFromRag([chunk])[0];
    const b = buildCitationsFromRag([
      { ...chunk, contentHash: 'new-hash-after-reindex' },
    ])[0];
    expect(a.contentHash).toBe('abc123hash');
    expect(b.contentHash).toBe('new-hash-after-reindex');
    expect(a.contentHash).not.toBe(b.contentHash);
  });

  it('formats pages only when present', () => {
    expect(formatCitationPages(12, 13)).toBe('pp. 12–13');
    expect(formatCitationPages(12, 12)).toBe('p. 12');
    expect(formatCitationPages(12, null)).toBe('p. 12');
  });
});
