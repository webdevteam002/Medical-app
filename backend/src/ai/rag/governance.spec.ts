/**
 * AI-2 copyright / governance policy tests (documentation as executable checks).
 *
 * Policy: never auto-ingest commercial textbooks or R2 blobs.
 * The only ingestion gate is Material.aiIngestAllowed = true (admin-set),
 * combined with type=PDF and isPublished=true.
 */
import { evaluateMaterialIngestEligibility } from './material-eligibility';

describe('AI-2 copyright governance', () => {
  it('defaults deny when aiIngestAllowed is false even if published PDF', () => {
    const r = evaluateMaterialIngestEligibility({
      type: 'PDF',
      isPublished: true,
      aiIngestAllowed: false,
    });
    expect(r.eligible).toBe(false);
  });

  it('requires explicit allow flag — no hidden bypass path in eligibility helper', () => {
    expect(
      evaluateMaterialIngestEligibility({
        type: 'PDF',
        isPublished: true,
        aiIngestAllowed: true,
      }).eligible,
    ).toBe(true);
  });
});
