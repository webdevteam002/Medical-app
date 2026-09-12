import { MaterialType } from '@prisma/client';

export type MaterialEligibilityInput = {
  type: MaterialType | string;
  isPublished: boolean;
  aiIngestAllowed: boolean;
};

export type EligibilityResult =
  | { eligible: true }
  | { eligible: false; code: string; message: string };

/**
 * Copyright / AI governance gate for ingestion.
 * Only published PDFs with explicit admin aiIngestAllowed=true may be indexed.
 * Never auto-index all R2 content.
 */
export function evaluateMaterialIngestEligibility(
  material: MaterialEligibilityInput,
): EligibilityResult {
  if (material.type !== 'PDF') {
    return {
      eligible: false,
      code: 'AI_INGEST_NOT_PDF',
      message: 'Only PDF materials can be ingested for RAG',
    };
  }
  if (!material.isPublished) {
    return {
      eligible: false,
      code: 'AI_INGEST_UNPUBLISHED',
      message: 'Unpublished materials cannot be ingested',
    };
  }
  if (!material.aiIngestAllowed) {
    return {
      eligible: false,
      code: 'AI_INGEST_NOT_ALLOWED',
      message:
        'AI ingestion is not allowed for this material (aiIngestAllowed=false)',
    };
  }
  return { eligible: true };
}
