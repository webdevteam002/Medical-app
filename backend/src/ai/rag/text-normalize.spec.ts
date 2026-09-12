import {
  hasMeaningfulText,
  normalizeMedicalText,
  sha256Hex,
} from './text-normalize';

describe('normalizeMedicalText', () => {
  it('preserves negations', () => {
    expect(normalizeMedicalText('Drug is not recommended.')).toContain(
      'not recommended',
    );
  });

  it('preserves dosages and units', () => {
    const out = normalizeMedicalText('Give 5 mg/kg  q8h  and keep K+ 3.5–5.0 mmol/L');
    expect(out).toContain('5 mg/kg');
    expect(out).toContain('q8h');
    expect(out).toMatch(/3\.5/);
    expect(out).toContain('mmol/L');
  });

  it('collapses whitespace without rewriting clinical terms', () => {
    const out = normalizeMedicalText('  MI   /   ACS  \n\n\n  STEMI  ');
    expect(out).toContain('MI / ACS');
    expect(out).toContain('STEMI');
    expect(out).not.toMatch(/\n{3,}/);
  });

  it('joins hyphenated line wraps', () => {
    expect(normalizeMedicalText('recom-\nmended')).toBe('recommended');
  });
});

describe('hasMeaningfulText / sha256Hex', () => {
  it('rejects short noise', () => {
    expect(hasMeaningfulText('abc')).toBe(false);
  });

  it('accepts longer letter content', () => {
    expect(
      hasMeaningfulText(
        'This page discusses myocardial infarction pathophysiology in adults.',
      ),
    ).toBe(true);
  });

  it('hashes stably', () => {
    expect(sha256Hex('abc')).toBe(sha256Hex('abc'));
    expect(sha256Hex('abc')).not.toBe(sha256Hex('abd'));
  });
});
