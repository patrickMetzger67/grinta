const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizePromoCode,
  compactPromoCode,
  promoCodeLookupCandidates,
  promoCodesMatch,
} = require('./promo_code_helpers');

describe('normalizePromoCode', () => {
  it('trims, uppercases, and strips whitespace', () => {
    assert.equal(normalizePromoCode('  demo 2026 '), 'DEMO2026');
    assert.equal(normalizePromoCode('Demo-2026'), 'DEMO-2026');
  });
});

describe('compactPromoCode', () => {
  it('removes separators so DEMO-2026 matches DEMO2026', () => {
    assert.equal(compactPromoCode('DEMO-2026'), 'DEMO2026');
    assert.equal(compactPromoCode('demo_2026'), 'DEMO2026');
    assert.equal(compactPromoCode('DEMO.2026'), 'DEMO2026');
  });
});

describe('promoCodeLookupCandidates', () => {
  it('includes upper, lower, and compact forms', () => {
    const candidates = promoCodeLookupCandidates('demo-2026');
    assert.ok(candidates.includes('DEMO-2026'));
    assert.ok(candidates.includes('demo-2026'));
    assert.ok(candidates.includes('DEMO2026'));
    assert.ok(candidates.includes('demo2026'));
  });
});

describe('promoCodesMatch', () => {
  it('matches exact normalized codes', () => {
    assert.equal(promoCodesMatch('DEMO2026', 'demo2026'), true);
  });

  it('matches across hyphens/underscores (demo regression)', () => {
    assert.equal(promoCodesMatch('DEMO-2026', 'DEMO2026'), true);
    assert.equal(promoCodesMatch('DEMO2026', 'demo-2026'), true);
    assert.equal(promoCodesMatch('GRINTA_PRO', 'grinta.pro'), true);
  });

  it('rejects different codes', () => {
    assert.equal(promoCodesMatch('DEMO2026', 'DEMO2027'), false);
    assert.equal(promoCodesMatch('', 'DEMO'), false);
  });
});
