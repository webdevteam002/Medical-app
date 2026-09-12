import { computeQuestionContentHash } from './question-content-hash';

describe('computeQuestionContentHash', () => {
  const base = {
    subjectId: 'sub-1',
    stem: 'What is X?',
    options: [
      { id: 'b', text: 'B' },
      { id: 'a', text: 'A' },
    ],
    correctOptionId: 'a',
    explanation: 'Because A',
    difficulty: 'MEDIUM',
    isPublished: true,
  };

  it('is stable regardless of option order', () => {
    const h1 = computeQuestionContentHash(base);
    const h2 = computeQuestionContentHash({
      ...base,
      options: [
        { id: 'a', text: 'A' },
        { id: 'b', text: 'B' },
      ],
    });
    expect(h1).toBe(h2);
  });

  it('changes when official key changes', () => {
    const h1 = computeQuestionContentHash(base);
    const h2 = computeQuestionContentHash({ ...base, correctOptionId: 'b' });
    expect(h1).not.toBe(h2);
  });

  it('changes when stem changes', () => {
    const h1 = computeQuestionContentHash(base);
    const h2 = computeQuestionContentHash({ ...base, stem: 'What is Y?' });
    expect(h1).not.toBe(h2);
  });
});
