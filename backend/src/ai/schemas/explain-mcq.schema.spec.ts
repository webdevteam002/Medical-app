import {
  parseExplainMcqJson,
  validateExplainMcqResponse,
} from './explain-mcq.schema';

describe('explain-mcq schema validation', () => {
  const valid = {
    officialAnswer: 'Femoral artery',
    selectedAnswer: 'Popliteal artery',
    whySelectedWrong: 'Wrong territory.',
    whyCorrect: 'Supplies anterior thigh.',
    whyOtherOptions: [{ option: 'Tibial', explanation: 'Distal.' }],
    concept: 'Lower limb arteries',
    examTakeaway: 'Map vessel to compartment.',
    confidence: 0.8,
    grounding: 'key',
    citations: [],
    questionQuality: 'valid',
    questionConcern: null,
  };

  it('accepts a valid structured response', () => {
    expect(validateExplainMcqResponse(valid).grounding).toBe('key');
  });

  it('downgrades model-claimed rag grounding to model (server sets rag)', () => {
    const result = validateExplainMcqResponse({ ...valid, grounding: 'rag' });
    expect(result.grounding).toBe('model');
    expect(result.citations).toEqual([]);
  });

  it('strips model-supplied citations', () => {
    const result = validateExplainMcqResponse({
      ...valid,
      citations: [{ title: 'Fake book' }],
    });
    expect(result.citations).toEqual([]);
  });

  it('rejects invalid confidence', () => {
    expect(() =>
      validateExplainMcqResponse({ ...valid, confidence: 1.5 }),
    ).toThrow(/confidence/);
  });

  it('rejects invalid questionQuality', () => {
    expect(() =>
      validateExplainMcqResponse({ ...valid, questionQuality: 'perfect' }),
    ).toThrow(/questionQuality/);
  });

  it('parses fenced JSON', () => {
    const parsed = parseExplainMcqJson('```json\n' + JSON.stringify(valid) + '\n```');
    expect(validateExplainMcqResponse(parsed).concept).toBe('Lower limb arteries');
  });

  it('rejects oversized fields', () => {
    expect(() =>
      validateExplainMcqResponse({
        ...valid,
        whyCorrect: 'x'.repeat(2500),
      }),
    ).toThrow(/too long/);
  });
});
