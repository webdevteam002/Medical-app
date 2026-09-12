import { routeAssistantIntent, assertToolAllowlist } from './assistant-intent';
import { ASSISTANT_TOOL_NAMES } from './assistant-tools.service';

describe('routeAssistantIntent', () => {
  it('routes year/subject app questions to tools without requiring RAG', () => {
    const r = routeAssistantIntent('Which subjects are available for Year 1?', {
      hasQuestionContext: false,
    });
    expect(r.intent).toBe('app_help');
    expect(r.tools.some((t) => t.name === 'getSubjects')).toBe(true);
  });

  it('routes medical explain questions to RAG', () => {
    const r = routeAssistantIntent('Explain nephrotic syndrome pathophysiology', {
      hasQuestionContext: false,
    });
    expect(r.useRag).toBe(true);
  });

  it('routes MCQ context to mcq intent', () => {
    const r = routeAssistantIntent('Why is option C correct?', {
      hasQuestionContext: true,
    });
    expect(r.intent).toBe('mcq');
    expect(r.useRag).toBe(true);
  });
});

describe('assistant tool allowlist', () => {
  it('exposes only read-only tools', () => {
    expect(ASSISTANT_TOOL_NAMES).not.toContain('grantSubscription');
    expect(ASSISTANT_TOOL_NAMES).not.toContain('updateQuestion');
    expect(ASSISTANT_TOOL_NAMES).toContain('getAccessibleYears');
  });

  it('rejects unknown tools', () => {
    expect(() => assertToolAllowlist('DROP TABLE')).toThrow(/allowlisted/);
  });
});
