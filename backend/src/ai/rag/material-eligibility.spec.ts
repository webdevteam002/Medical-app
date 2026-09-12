import { evaluateMaterialIngestEligibility } from './material-eligibility';

describe('evaluateMaterialIngestEligibility', () => {
  it('allows published PDF with aiIngestAllowed', () => {
    expect(
      evaluateMaterialIngestEligibility({
        type: 'PDF',
        isPublished: true,
        aiIngestAllowed: true,
      }),
    ).toEqual({ eligible: true });
  });

  it('rejects unpublished', () => {
    const r = evaluateMaterialIngestEligibility({
      type: 'PDF',
      isPublished: false,
      aiIngestAllowed: true,
    });
    expect(r.eligible).toBe(false);
    if (!r.eligible) expect(r.code).toBe('AI_INGEST_UNPUBLISHED');
  });

  it('rejects aiIngestAllowed=false', () => {
    const r = evaluateMaterialIngestEligibility({
      type: 'PDF',
      isPublished: true,
      aiIngestAllowed: false,
    });
    expect(r.eligible).toBe(false);
    if (!r.eligible) expect(r.code).toBe('AI_INGEST_NOT_ALLOWED');
  });

  it('rejects non-PDF', () => {
    const r = evaluateMaterialIngestEligibility({
      type: 'VIDEO',
      isPublished: true,
      aiIngestAllowed: true,
    });
    expect(r.eligible).toBe(false);
    if (!r.eligible) expect(r.code).toBe('AI_INGEST_NOT_PDF');
  });
});
