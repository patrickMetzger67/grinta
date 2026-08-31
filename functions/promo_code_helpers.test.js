const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizePromoCode,
  compactPromoCode,
  promoCodeLookupCandidates,
  promoCodesMatch,
  canonicalizePromoEntitlement,
  revenueCatGrantEntitlementIds,
  mergePromoMirrorEntitlements,
  entitlementsIncludeGranted,
} = require('./promo_code_helpers');

describe('normalizePromoCode', () => {
  it('trims, uppercases, and strips whitespace', () => {
    assert.equal(normalizePromoCode('  demo 2026 '), 'DEMO2026');
    assert.equal(normalizePromoCode('Demo-2026'), 'DEMO-2026');
  });

  it('strips a leading hash from tag-icon UX (# JOUEURGPS)', () => {
    assert.equal(normalizePromoCode('# JOUEURGPS'), 'JOUEURGPS');
    assert.equal(normalizePromoCode('#JOUEURGPS'), 'JOUEURGPS');
    assert.equal(normalizePromoCode('## joueur-gps'), 'JOUEUR-GPS');
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

  it('normalizes hashed input before building candidates', () => {
    const candidates = promoCodeLookupCandidates('# joueurgps');
    assert.ok(candidates.includes('JOUEURGPS'));
    assert.ok(candidates.includes('joueurgps'));
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

  it('matches hashed typed codes against stored codes', () => {
    assert.equal(promoCodesMatch('JOUEURGPS', '# JOUEURGPS'), true);
    assert.equal(promoCodesMatch('JOUEURGPS', '#JOUEURGPS'), true);
  });

  it('rejects different codes', () => {
    assert.equal(promoCodesMatch('DEMO2026', 'DEMO2027'), false);
    assert.equal(promoCodesMatch('', 'DEMO'), false);
  });
});

describe('canonicalizePromoEntitlement', () => {
  it('keeps canonical ids', () => {
    assert.equal(canonicalizePromoEntitlement('player'), 'player');
    assert.equal(canonicalizePromoEntitlement('player_gps'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('coach_pro'), 'coach_pro');
  });

  it('accepts playerGPS aliases used in RevenueCat / console', () => {
    assert.equal(canonicalizePromoEntitlement('playerGPS'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('playerGps'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('PLAYERGPS'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('player-gps'), 'player_gps');
  });

  it('accepts JOUEURGPS / French product-name aliases as player_gps', () => {
    assert.equal(canonicalizePromoEntitlement('JOUEURGPS'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('joueurGPS'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('joueur_gps'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('joueur-gps'), 'player_gps');
    assert.equal(canonicalizePromoEntitlement('Joueur GPS'), 'player_gps');
  });

  it('rejects unknown entitlements', () => {
    assert.equal(canonicalizePromoEntitlement(''), null);
    assert.equal(canonicalizePromoEntitlement('gold'), null);
    assert.equal(canonicalizePromoEntitlement('joueur_pro'), null);
  });
});

describe('revenueCatGrantEntitlementIds from JOUEURGPS alias', () => {
  it('maps JOUEURGPS to player_gps RC grant ids', () => {
    assert.deepEqual(revenueCatGrantEntitlementIds('JOUEURGPS'), [
      'player_gps',
      'playerGPS',
      'playerGps',
    ]);
  });
});

describe('revenueCatGrantEntitlementIds', () => {
  it('tries player_gps aliases for Joueur GPS upgrades', () => {
    assert.deepEqual(revenueCatGrantEntitlementIds('player_gps'), [
      'player_gps',
      'playerGPS',
      'playerGps',
    ]);
    assert.deepEqual(revenueCatGrantEntitlementIds('playerGPS'), [
      'player_gps',
      'playerGPS',
      'playerGps',
    ]);
  });

  it('returns a single id for other entitlements', () => {
    assert.deepEqual(revenueCatGrantEntitlementIds('player'), ['player']);
  });
});

describe('mergePromoMirrorEntitlements', () => {
  it('adds player_gps beside existing player (Joueur → Joueur GPS)', () => {
    assert.deepEqual(
      mergePromoMirrorEntitlements(['player'], 'player_gps').sort(),
      ['player', 'player_gps'],
    );
  });

  it('canonicalizes aliases when merging', () => {
    assert.deepEqual(
      mergePromoMirrorEntitlements(['playerGPS'], 'playerGps').sort(),
      ['player_gps'],
    );
    assert.deepEqual(
      mergePromoMirrorEntitlements(['player'], 'playerGPS').sort(),
      ['player', 'player_gps'],
    );
    assert.deepEqual(
      mergePromoMirrorEntitlements(['player'], 'JOUEURGPS').sort(),
      ['player', 'player_gps'],
    );
  });

  it('returns null for unknown granted entitlement', () => {
    assert.equal(mergePromoMirrorEntitlements(['player'], 'gold'), null);
  });

  it('works with empty existing list', () => {
    assert.deepEqual(mergePromoMirrorEntitlements([], 'player_gps'), [
      'player_gps',
    ]);
    assert.deepEqual(mergePromoMirrorEntitlements(null, 'player'), ['player']);
  });
});

describe('entitlementsIncludeGranted', () => {
  it('is false when only player is present for a player_gps upgrade', () => {
    assert.equal(
      entitlementsIncludeGranted(['player'], 'player_gps'),
      false,
    );
    assert.equal(
      entitlementsIncludeGranted(['player'], 'JOUEURGPS'),
      false,
    );
  });

  it('is true when player_gps (or alias) is already mirrored', () => {
    assert.equal(
      entitlementsIncludeGranted(['player', 'player_gps'], 'player_gps'),
      true,
    );
    assert.equal(
      entitlementsIncludeGranted(['playerGPS'], 'JOUEURGPS'),
      true,
    );
  });

  it('rejects unknown granted entitlements', () => {
    assert.equal(entitlementsIncludeGranted(['player'], 'gold'), false);
  });
});
