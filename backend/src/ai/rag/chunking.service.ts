import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { aiConfigFrom } from '../ai.config';
import { ExtractedPage } from './pdf-extraction.service';
import { estimateTokenCount, sha256Hex } from './text-normalize';

export type TextChunk = {
  chunkIndex: number;
  text: string;
  pageStart: number | null;
  pageEnd: number | null;
  contentHash: string;
  charCount: number;
};

type Segment = {
  text: string;
  page: number;
};

/**
 * Heading/paragraph-aware chunking with controlled overlap.
 * Target size/overlap come from AI_RAG_CHUNK_SIZE / AI_RAG_CHUNK_OVERLAP (tokens).
 */
@Injectable()
export class ChunkingService {
  constructor(private readonly config: ConfigService) {}

  chunkPages(pages: ExtractedPage[]): TextChunk[] {
    const cfg = aiConfigFrom(this.config).rag;
    const targetTokens = cfg.chunkSizeTokens;
    const overlapTokens = Math.min(cfg.chunkOverlapTokens, Math.floor(targetTokens / 2));

    const segments = this.pagesToSegments(pages);
    if (segments.length === 0) return [];

    const chunks: TextChunk[] = [];
    let buffer: Segment[] = [];
    let bufferTokens = 0;

    const flush = (force = false) => {
      if (buffer.length === 0) return;
      if (!force && bufferTokens < Math.floor(targetTokens * 0.4) && chunks.length > 0) {
        return;
      }
      const text = buffer.map((s) => s.text).join('\n\n').trim();
      if (!text) {
        buffer = [];
        bufferTokens = 0;
        return;
      }
      const pageStart = buffer[0]?.page ?? null;
      const pageEnd = buffer[buffer.length - 1]?.page ?? null;
      chunks.push({
        chunkIndex: chunks.length,
        text,
        pageStart,
        pageEnd,
        contentHash: sha256Hex(text),
        charCount: text.length,
      });

      if (overlapTokens > 0 && buffer.length > 0) {
        const overlapSegs = this.takeOverlap(buffer, overlapTokens);
        buffer = overlapSegs;
        bufferTokens = overlapSegs.reduce((n, s) => n + estimateTokenCount(s.text), 0);
      } else {
        buffer = [];
        bufferTokens = 0;
      }
    };

    for (const seg of segments) {
      const tok = estimateTokenCount(seg.text);

      // Oversized single segment → hard-split by sentences/words
      if (tok > targetTokens * 1.5) {
        flush(true);
        for (const piece of this.splitLarge(seg.text, targetTokens)) {
          const pieceSeg: Segment = { text: piece, page: seg.page };
          buffer.push(pieceSeg);
          bufferTokens += estimateTokenCount(piece);
          if (bufferTokens >= targetTokens) flush(true);
        }
        continue;
      }

      if (bufferTokens + tok > targetTokens && buffer.length > 0) {
        flush(true);
      }
      buffer.push(seg);
      bufferTokens += tok;
      if (bufferTokens >= targetTokens) flush(true);
    }

    flush(true);
    return chunks;
  }

  private pagesToSegments(pages: ExtractedPage[]): Segment[] {
    const out: Segment[] = [];
    for (const page of pages) {
      if (!page.text.trim()) continue;
      const parts = this.splitIntoParagraphs(page.text);
      for (const part of parts) {
        if (part.trim()) out.push({ text: part.trim(), page: page.pageNumber });
      }
    }
    return out;
  }

  private splitIntoParagraphs(text: string): string[] {
    // Prefer blank-line / heading-like breaks
    const raw = text.split(/\n{2,}/);
    const refined: string[] = [];
    for (const block of raw) {
      const lines = block.split('\n');
      let current: string[] = [];
      for (const line of lines) {
        const trimmed = line.trim();
        const looksHeading =
          trimmed.length > 0 &&
          trimmed.length <= 80 &&
          (/^[A-Z0-9][A-Z0-9 \-:/()]{2,}$/.test(trimmed) ||
            /^\d+(\.\d+)*\s+\S/.test(trimmed) ||
            /^#{1,6}\s/.test(trimmed));
        if (looksHeading && current.length > 0) {
          refined.push(current.join('\n'));
          current = [trimmed];
        } else {
          current.push(trimmed);
        }
      }
      if (current.length) refined.push(current.join('\n'));
    }
    return refined.filter((p) => p.trim().length > 0);
  }

  private takeOverlap(segs: Segment[], overlapTokens: number): Segment[] {
    const rev: Segment[] = [];
    let tokens = 0;
    for (let i = segs.length - 1; i >= 0; i--) {
      const s = segs[i];
      const t = estimateTokenCount(s.text);
      if (tokens + t > overlapTokens && rev.length > 0) break;
      rev.unshift(s);
      tokens += t;
      if (tokens >= overlapTokens) break;
    }
    return rev;
  }

  private splitLarge(text: string, targetTokens: number): string[] {
    const maxChars = targetTokens * 4;
    const sentences = text.split(/(?<=[.!?])\s+/);
    const pieces: string[] = [];
    let buf = '';
    for (const s of sentences) {
      if ((buf + ' ' + s).trim().length > maxChars && buf) {
        pieces.push(buf.trim());
        buf = s;
      } else {
        buf = buf ? `${buf} ${s}` : s;
      }
    }
    if (buf.trim()) pieces.push(buf.trim());

    // Absolute fallback: hard char windows
    if (pieces.length === 0 && text.length > 0) {
      for (let i = 0; i < text.length; i += maxChars) {
        pieces.push(text.slice(i, i + maxChars));
      }
    }
    return pieces;
  }
}
