import {
  parseAiVerifyJson,
  validateAiVerifyModelPayload,
} from '../schemas/ai-verify.schema';

describe('ai-verify schema', () => {
  const valid = {
    issueType: 'POSSIBLE_KEY_ISSUE',
    confidence: 0.7,
    reasoning: 'Evidence appears to favor C over official B.',
    recommendation: 'Human review required; do not auto-change the key.',
    optionAnalysis: [
      { optionId: 'b', assessment: 'weak', notes: 'Official but less supported' },
      { optionId: 'c', assessment: 'best', notes: 'Matches source excerpt' },
    ],
    qualityFlags: ['key_conflict'],
    sourceSupport: {
      supportsOfficialKey: false,
      suggestedOptionId: 'c',
      notes: 'RAG excerpt supports C',
    },
  };

  it('accepts a valid payload', () => {
    const result = validateAiVerifyModelPayload(valid);
    expect(result.issueType).toBe('POSSIBLE_KEY_ISSUE');
    expect(result.confidence).toBe(0.7);
  });

  it('rejects invalid issueType', () => {
    expect(() =>
      validateAiVerifyModelPayload({ ...valid, issueType: 'WRONG' }),
    ).toThrow(/issueType/);
  });

  it('rejects confidence out of range', () => {
    expect(() =>
      validateAiVerifyModelPayload({ ...valid, confidence: 1.5 }),
    ).toThrow(/confidence/);
  });

  it('parses fenced JSON', () => {
    const raw = '```json\n' + JSON.stringify(valid) + '\n```';
    expect(validateAiVerifyModelPayload(parseAiVerifyJson(raw)).issueType).toBe(
      'POSSIBLE_KEY_ISSUE',
    );
  });
});
