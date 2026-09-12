export type AiVerifyGrounding = 'key' | 'model' | 'rag';

export type AiVerificationIssueTypeValue =
  | 'NONE'
  | 'AMBIGUOUS'
  | 'POSSIBLE_KEY_ISSUE'
  | 'MULTIPLE_PLAUSIBLE_ANSWERS'
  | 'INSUFFICIENT_INFORMATION'
  | 'EXPLANATION_ISSUE'
  | 'OPTION_QUALITY_ISSUE';

const ISSUE_TYPES = new Set<AiVerificationIssueTypeValue>([
  'NONE',
  'AMBIGUOUS',
  'POSSIBLE_KEY_ISSUE',
  'MULTIPLE_PLAUSIBLE_ANSWERS',
  'INSUFFICIENT_INFORMATION',
  'EXPLANATION_ISSUE',
  'OPTION_QUALITY_ISSUE',
]);

export type AiVerifyOptionAnalysis = {
  optionId: string;
  assessment: string;
  notes: string;
};

export type AiVerifySourceSupport = {
  /** Whether authorized evidence appears to support the official key. */
  supportsOfficialKey: boolean | null;
  /** Option the evidence appears to favor, if any (advisory). */
  suggestedOptionId: string | null;
  notes: string;
};

/** Model-validated assessment fields (citations stripped / ignored). */
export type AiVerifyModelPayload = {
  issueType: AiVerificationIssueTypeValue;
  confidence: number;
  reasoning: string;
  recommendation: string;
  optionAnalysis: AiVerifyOptionAnalysis[];
  qualityFlags: string[];
  sourceSupport: AiVerifySourceSupport;
};

/** @deprecated Prefer AiCitation — evidence stored on verifications is AI-6 citation shape. */
export type AiVerifyEvidence = import('../citations/ai-citation').AiCitation;

const MAX_TEXT = 4000;
const MAX_OPTIONS = 8;
const MAX_FLAGS = 12;

/**
 * Validate model JSON for AI-5 verification.
 * Model-supplied citations are rejected/stripped — server attaches evidence.
 */
export function validateAiVerifyModelPayload(raw: unknown): AiVerifyModelPayload {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new Error('Response must be an object');
  }
  const o = raw as Record<string, unknown>;

  const issueType = o.issueType;
  if (typeof issueType !== 'string' || !ISSUE_TYPES.has(issueType as AiVerificationIssueTypeValue)) {
    throw new Error('invalid issueType');
  }

  const confidence = o.confidence;
  if (typeof confidence !== 'number' || Number.isNaN(confidence)) {
    throw new Error('confidence must be a number');
  }
  if (confidence < 0 || confidence > 1) {
    throw new Error('confidence must be between 0 and 1');
  }

  const reasoning = requireString(o.reasoning, 'reasoning');
  const recommendation = requireString(o.recommendation, 'recommendation');

  if (!Array.isArray(o.optionAnalysis)) {
    throw new Error('optionAnalysis must be an array');
  }
  if (o.optionAnalysis.length > MAX_OPTIONS) {
    throw new Error('optionAnalysis too long');
  }
  const optionAnalysis: AiVerifyOptionAnalysis[] = o.optionAnalysis.map((item, i) => {
    if (!item || typeof item !== 'object') {
      throw new Error(`optionAnalysis[${i}] invalid`);
    }
    const row = item as Record<string, unknown>;
    return {
      optionId: requireString(row.optionId, `optionAnalysis[${i}].optionId`),
      assessment: requireString(row.assessment, `optionAnalysis[${i}].assessment`),
      notes: requireString(row.notes, `optionAnalysis[${i}].notes`),
    };
  });

  if (!Array.isArray(o.qualityFlags)) {
    throw new Error('qualityFlags must be an array');
  }
  if (o.qualityFlags.length > MAX_FLAGS) {
    throw new Error('qualityFlags too long');
  }
  const qualityFlags = o.qualityFlags.map((f, i) => {
    if (typeof f !== 'string' || !f.trim()) {
      throw new Error(`qualityFlags[${i}] invalid`);
    }
    return f.trim().slice(0, 80);
  });

  if (!o.sourceSupport || typeof o.sourceSupport !== 'object' || Array.isArray(o.sourceSupport)) {
    throw new Error('sourceSupport must be an object');
  }
  const ss = o.sourceSupport as Record<string, unknown>;
  let supportsOfficialKey: boolean | null = null;
  if (ss.supportsOfficialKey === true || ss.supportsOfficialKey === false) {
    supportsOfficialKey = ss.supportsOfficialKey;
  } else if (ss.supportsOfficialKey !== null && ss.supportsOfficialKey !== undefined) {
    throw new Error('sourceSupport.supportsOfficialKey invalid');
  }

  let suggestedOptionId: string | null = null;
  if (ss.suggestedOptionId !== null && ss.suggestedOptionId !== undefined) {
    suggestedOptionId = requireString(
      ss.suggestedOptionId,
      'sourceSupport.suggestedOptionId',
    );
  }

  // Ignore any model citations field entirely (fabricated refs).
  if (o.citations !== undefined && !Array.isArray(o.citations) && o.citations !== null) {
    throw new Error('citations must be an array if present');
  }

  return {
    issueType: issueType as AiVerificationIssueTypeValue,
    confidence,
    reasoning,
    recommendation,
    optionAnalysis,
    qualityFlags,
    sourceSupport: {
      supportsOfficialKey,
      suggestedOptionId,
      notes: requireString(ss.notes, 'sourceSupport.notes'),
    },
  };
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== 'string') {
    throw new Error(`${field} must be a string`);
  }
  const trimmed = value.trim();
  if (!trimmed) {
    throw new Error(`${field} must be non-empty`);
  }
  if (trimmed.length > MAX_TEXT) {
    throw new Error(`${field} too long`);
  }
  return trimmed;
}

export function parseAiVerifyJson(rawText: string): unknown {
  let jsonText = rawText.trim();
  const fence = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence?.[1]) jsonText = fence[1].trim();
  return JSON.parse(jsonText) as unknown;
}

/** Map issue type to a clear AI assessment label for admins. */
export function aiAssessmentFromIssue(
  issueType: AiVerificationIssueTypeValue,
): string {
  return issueType;
}
