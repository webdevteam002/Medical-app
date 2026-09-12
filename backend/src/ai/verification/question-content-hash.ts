import { createHash } from 'crypto';

export type QuestionOption = { id: string; text: string };

/**
 * Stable fingerprint of the MCQ content reviewed by AI-5.
 * Question has no updatedAt — content hash is the version marker.
 */
export function computeQuestionContentHash(input: {
  subjectId: string;
  stem: string;
  options: unknown;
  correctOptionId: string;
  explanation: string;
  difficulty: string;
  isPublished: boolean;
}): string {
  const options = normalizeOptions(input.options);
  const payload = JSON.stringify({
    subjectId: input.subjectId,
    stem: input.stem,
    options,
    correctOptionId: input.correctOptionId,
    explanation: input.explanation,
    difficulty: input.difficulty,
    isPublished: input.isPublished,
  });
  return createHash('sha256').update(payload).digest('hex');
}

function normalizeOptions(raw: unknown): QuestionOption[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((item) => {
      if (!item || typeof item !== 'object') return null;
      const o = item as Record<string, unknown>;
      if (typeof o.id !== 'string' || typeof o.text !== 'string') return null;
      return { id: o.id, text: o.text };
    })
    .filter((x): x is QuestionOption => x !== null)
    .sort((a, b) => a.id.localeCompare(b.id));
}
