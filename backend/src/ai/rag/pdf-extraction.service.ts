import { Injectable, Logger } from '@nestjs/common';
import {
  hasMeaningfulText,
  normalizeMedicalText,
} from './text-normalize';

export type ExtractedPage = {
  pageNumber: number;
  text: string;
};

export type PdfExtractionResult =
  | {
      kind: 'ok';
      pageCount: number;
      pages: ExtractedPage[];
    }
  | {
      kind: 'ocr_required';
      pageCount: number;
      reason: string;
    }
  | {
      kind: 'empty';
      pageCount: number;
      reason: string;
    }
  | {
      kind: 'malformed';
      reason: string;
    };

type PdfJsModule = {
  getDocument: (src: {
    data: Uint8Array;
    useSystemFonts?: boolean;
    disableWorker?: boolean;
    isEvalSupported?: boolean;
  }) => { promise: Promise<PdfJsDocument> };
  GlobalWorkerOptions?: { workerSrc: string };
};

type PdfJsDocument = {
  numPages: number;
  getPage: (n: number) => Promise<{
    getTextContent: () => Promise<{ items: Array<{ str?: string }> }>;
  }>;
};

/**
 * Page-aware PDF text extraction via pdfjs-dist (CJS legacy build).
 * Scanned/image-only PDFs are marked OCR_REQUIRED — no OCR in AI-2.
 */
@Injectable()
export class PdfExtractionService {
  private readonly logger = new Logger(PdfExtractionService.name);

  async extractPages(buffer: Buffer): Promise<PdfExtractionResult> {
    if (!buffer || buffer.length === 0) {
      return { kind: 'empty', pageCount: 0, reason: 'Empty PDF buffer' };
    }

    if (buffer.subarray(0, 5).toString('utf8') !== '%PDF-') {
      return { kind: 'malformed', reason: 'Not a PDF (missing %PDF- header)' };
    }

    try {
      // pdfjs-dist@3.x ships a CommonJS legacy build suitable for Nest/Jest.
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const pdfjs = require('pdfjs-dist/legacy/build/pdf.js') as PdfJsModule;

      if (pdfjs.GlobalWorkerOptions) {
        pdfjs.GlobalWorkerOptions.workerSrc = '';
      }

      const loadingTask = pdfjs.getDocument({
        data: new Uint8Array(buffer),
        useSystemFonts: true,
        disableWorker: true,
        isEvalSupported: false,
      });
      const doc = await loadingTask.promise;
      const pageCount = doc.numPages ?? 0;

      if (pageCount <= 0) {
        return { kind: 'empty', pageCount: 0, reason: 'PDF has no pages' };
      }

      const pages: ExtractedPage[] = [];
      let meaningfulPages = 0;

      for (let pageNumber = 1; pageNumber <= pageCount; pageNumber++) {
        const page = await doc.getPage(pageNumber);
        const content = await page.getTextContent();
        const raw = (content.items as Array<{ str?: string }>)
          .map((item) => (typeof item.str === 'string' ? item.str : ''))
          .join(' ');
        const text = normalizeMedicalText(raw);
        pages.push({ pageNumber, text });
        if (hasMeaningfulText(text)) meaningfulPages += 1;
      }

      if (meaningfulPages === 0) {
        this.logger.warn(
          `PDF extraction produced no meaningful text across ${pageCount} page(s) — OCR_REQUIRED`,
        );
        return {
          kind: 'ocr_required',
          pageCount,
          reason: 'No extractable text (likely scanned/image-only PDF)',
        };
      }

      return { kind: 'ok', pageCount, pages };
    } catch (err) {
      this.logger.warn(`PDF parse failed: ${String(err)}`);
      return { kind: 'malformed', reason: 'Malformed or unreadable PDF' };
    }
  }
}
