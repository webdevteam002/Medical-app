import { PdfExtractionService } from './pdf-extraction.service';

/** Minimal text PDF (1 page, Helvetica). */
function makeTextPdf(line: string): Buffer {
  const content = `BT /F1 12 Tf 50 700 Td (${line.replace(/[()\\]/g, '')}) Tj ET`;
  const objects = [
    '1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj\n',
    '2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj\n',
    '3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources<< /Font<< /F1 5 0 R >> >> >>endobj\n',
    `4 0 obj<< /Length ${content.length} >>stream\n${content}\nendstream\nendobj\n`,
    '5 0 obj<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>endobj\n',
  ];
  let body = '%PDF-1.4\n';
  const offsets: number[] = [0];
  for (const obj of objects) {
    offsets.push(Buffer.byteLength(body, 'utf8'));
    body += obj;
  }
  const xrefStart = Buffer.byteLength(body, 'utf8');
  let xref = `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (let i = 1; i <= objects.length; i++) {
    xref += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }
  body += xref;
  body += `trailer<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF\n`;
  return Buffer.from(body, 'utf8');
}

/** PDF with pages but no text operators — simulates scanned/image-only. */
function makeEmptyTextPdf(): Buffer {
  const objects = [
    '1 0 obj<< /Type /Catalog /Pages 2 0 R >>endobj\n',
    '2 0 obj<< /Type /Pages /Kids [3 0 R] /Count 1 >>endobj\n',
    '3 0 obj<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>endobj\n',
    '4 0 obj<< /Length 0 >>stream\n\nendstream\nendobj\n',
  ];
  let body = '%PDF-1.4\n';
  const offsets: number[] = [0];
  for (const obj of objects) {
    offsets.push(Buffer.byteLength(body, 'utf8'));
    body += obj;
  }
  const xrefStart = Buffer.byteLength(body, 'utf8');
  let xref = `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (let i = 1; i <= objects.length; i++) {
    xref += `${String(offsets[i]).padStart(10, '0')} 00000 n \n`;
  }
  body += xref;
  body += `trailer<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF\n`;
  return Buffer.from(body, 'utf8');
}

describe('PdfExtractionService', () => {
  const svc = new PdfExtractionService();

  it('returns empty for empty buffer', async () => {
    const r = await svc.extractPages(Buffer.alloc(0));
    expect(r.kind).toBe('empty');
  });

  it('returns malformed for non-PDF', async () => {
    const r = await svc.extractPages(Buffer.from('not a pdf'));
    expect(r.kind).toBe('malformed');
  });

  it('extracts text with page boundaries from digital PDF', async () => {
    const buf = makeTextPdf(
      'Myocardial infarction treatment is not recommended without ECG. Dose 75 mg aspirin.',
    );
    const r = await svc.extractPages(buf);
    expect(r.kind).toBe('ok');
    if (r.kind !== 'ok') return;
    expect(r.pageCount).toBe(1);
    expect(r.pages[0].pageNumber).toBe(1);
    expect(r.pages[0].text).toContain('not recommended');
    expect(r.pages[0].text).toContain('75 mg');
  });

  it('marks scanned/no-text PDF as OCR_REQUIRED', async () => {
    const r = await svc.extractPages(makeEmptyTextPdf());
    expect(r.kind).toBe('ocr_required');
  });

  it('marks truncated PDF as malformed', async () => {
    const r = await svc.extractPages(Buffer.from('%PDF-1.4\nbroken'));
    expect(r.kind).toBe('malformed');
  });
});
