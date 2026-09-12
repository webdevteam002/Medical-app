import { AiCitation } from '../citations/ai-citation';

export type AiGrounding = 'key' | 'model' | 'rag';
export type AiQuestionQuality =
  | 'valid'
  | 'ambiguous'
  | 'potentially_incorrect'
  | 'insufficient_evidence';

export type WhyOtherOption = {
  option: string;
  explanation: string;
};

/** @deprecated Use AiCitation — kept as alias for explain-mcq responses. */
export type ExplainMcqCitation = AiCitation;

export type ExplainMcqResponse = {
  officialAnswer: string;
  selectedAnswer: string;
  whySelectedWrong: string | null;
  whyCorrect: string;
  whyOtherOptions: WhyOtherOption[];
  concept: string;
  examTakeaway: string;
  confidence: number;
  grounding: AiGrounding;
  citations: AiCitation[];
  questionQuality: AiQuestionQuality;
  questionConcern: string | null;
};

const GROUNDINGS = new Set<AiGrounding>(['key', 'model', 'rag']);
const QUALITIES = new Set<AiQuestionQuality>([
  'valid',
  'ambiguous',
  'potentially_incorrect',
  'insufficient_evidence',
]);

const MAX_TEXT = 2000;
const MAX_OTHER = 8;

/**
 * Validate model JSON shape. Citations from the model are ignored here —
 * McqExplainService always replaces them with server-built RAG citations.
 */
export function validateExplainMcqResponse(raw: unknown): ExplainMcqResponse {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    throw new Error('Response must be an object');
  }
  const o = raw as Record<string, unknown>;

  const officialAnswer = requireString(o.officialAnswer, 'officialAnswer');
  const selectedAnswer = requireString(o.selectedAnswer, 'selectedAnswer');
  const whyCorrect = requireString(o.whyCorrect, 'whyCorrect');
  const concept = requireString(o.concept, 'concept');
  const examTakeaway = requireString(o.examTakeaway, 'examTakeaway');

  let whySelectedWrong: string | null = null;
  if (o.whySelectedWrong !== null && o.whySelectedWrong !== undefined) {
    whySelectedWrong = requireString(o.whySelectedWrong, 'whySelectedWrong');
  }

  if (!Array.isArray(o.whyOtherOptions)) {
    throw new Error('whyOtherOptions must be an array');
  }
  if (o.whyOtherOptions.length > MAX_OTHER) {
    throw new Error('whyOtherOptions too long');
  }
  const whyOtherOptions: WhyOtherOption[] = o.whyOtherOptions.map((item, i) => {
    if (!item || typeof item !== 'object') {
      throw new Error(`whyOtherOptions[${i}] invalid`);
    }
    const row = item as Record<string, unknown>;
    return {
      option: requireString(row.option, `whyOtherOptions[${i}].option`),
      explanation: requireString(
        row.explanation,
        `whyOtherOptions[${i}].explanation`,
      ),
    };
  });

  const confidence = o.confidence;
  if (typeof confidence !== 'number' || Number.isNaN(confidence)) {
    throw new Error('confidence must be a number');
  }
  if (confidence < 0 || confidence > 1) {
    throw new Error('confidence must be between 0 and 1');
  }

  let grounding = o.grounding;
  if (typeof grounding !== 'string' || !GROUNDINGS.has(grounding as AiGrounding)) {
    throw new Error('grounding must be key, model, or rag');
  }
  // Model must not claim rag — server sets rag only when authorized contexts exist.
  if (grounding === 'rag') {
    grounding = 'model';
  }

  // Strip any model-supplied citations (fabricated textbooks/pages).
  if (o.citations !== undefined && !Array.isArray(o.citations)) {
    throw new Error('citations must be an array');
  }

  const questionQuality = o.questionQuality;
  if (
    typeof questionQuality !== 'string' ||
    !QUALITIES.has(questionQuality as AiQuestionQuality)
  ) {
    throw new Error('invalid questionQuality');
  }

  let questionConcern: string | null = null;
  if (o.questionConcern !== null && o.questionConcern !== undefined) {
    questionConcern = requireString(o.questionConcern, 'questionConcern');
  }

  return {
    officialAnswer,
    selectedAnswer,
    whySelectedWrong,
    whyCorrect,
    whyOtherOptions,
    concept,
    examTakeaway,
    confidence,
    grounding: grounding as AiGrounding,
    citations: [],
    questionQuality: questionQuality as AiQuestionQuality,
    questionConcern,
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

export function parseExplainMcqJson(rawText: string): unknown {
  let jsonText = rawText.trim();
  const fence = rawText.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fence?.[1]) jsonText = fence[1].trim();
  return JSON.parse(jsonText) as unknown;
}
