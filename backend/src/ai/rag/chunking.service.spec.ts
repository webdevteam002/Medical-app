import { ConfigService } from '@nestjs/config';
import { ChunkingService } from './chunking.service';
import { estimateTokenCount } from './text-normalize';

function configWith(chunkSize = 100, overlap = 20): ConfigService {
  const map: Record<string, string> = {
    AI_RAG_CHUNK_SIZE: String(chunkSize),
    AI_RAG_CHUNK_OVERLAP: String(overlap),
  };
  return {
    get: (key: string, def?: string) => map[key] ?? def,
  } as unknown as ConfigService;
}

describe('ChunkingService', () => {
  it('preserves page metadata and indexes', () => {
    const svc = new ChunkingService(configWith(80, 10));
    const page1 =
      'Introduction to cardiology. '.repeat(40) +
      '\n\n' +
      'SECTION A\n' +
      'Myocardial infarction is not recommended to ignore. Dose 5 mg/kg.';
    const page2 =
      'Further notes on STEMI and NSTEMI management pathways. '.repeat(30);

    const chunks = svc.chunkPages([
      { pageNumber: 1, text: page1 },
      { pageNumber: 2, text: page2 },
    ]);

    expect(chunks.length).toBeGreaterThan(1);
    chunks.forEach((c, i) => {
      expect(c.chunkIndex).toBe(i);
      expect(c.pageStart).toBeGreaterThanOrEqual(1);
      expect(c.pageEnd).toBeGreaterThanOrEqual(c.pageStart!);
      expect(c.text.length).toBeGreaterThan(0);
      expect(c.contentHash).toHaveLength(64);
    });

    const joined = chunks.map((c) => c.text).join(' ');
    expect(joined).toContain('not recommended');
    expect(joined).toContain('5 mg/kg');
  });

  it('targets approximate chunk size with overlap effect', () => {
    const svc = new ChunkingService(configWith(50, 15));
    const text = Array.from({ length: 40 }, (_, i) =>
      `Paragraph ${i + 1}: clinical sentence about hypertension and ACE inhibitors.`,
    ).join('\n\n');

    const chunks = svc.chunkPages([{ pageNumber: 1, text }]);
    expect(chunks.length).toBeGreaterThan(2);

    for (const c of chunks) {
      const tokens = estimateTokenCount(c.text);
      // Soft upper bound — oversized segments may exceed briefly before split
      expect(tokens).toBeLessThan(200);
    }

    // Overlap should cause some shared tokens between adjacent chunks
    if (chunks.length >= 2) {
      const aWords = new Set(chunks[0].text.split(/\s+/).slice(-15));
      const bWords = chunks[1].text.split(/\s+/).slice(0, 20);
      const overlapHits = bWords.filter((w) => aWords.has(w)).length;
      expect(overlapHits).toBeGreaterThan(0);
    }
  });
});
