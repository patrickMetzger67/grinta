const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  resolveBrand,
  resolveBrandAssets,
  normalizeTokenList,
  buildDataPayload,
  BRAND_GRINTA,
  BRAND_ASERSTEIN,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
} = require('./send_push_fcm_helpers');

describe('resolveBrand', () => {
  it('prefers explicit grinta brand', () => {
    assert.equal(resolveBrand('grinta', '9'), BRAND_GRINTA);
  });

  it('prefers explicit aserstein brand', () => {
    assert.equal(resolveBrand('aserstein', '0'), BRAND_ASERSTEIN);
  });

  it('maps clubId 0 to grinta when brand omitted', () => {
    assert.equal(resolveBrand(null, '0'), BRAND_GRINTA);
    assert.equal(resolveBrand('', '0'), BRAND_GRINTA);
  });

  it('defaults to grinta for unknown brand', () => {
    assert.equal(resolveBrand('other', '3'), BRAND_GRINTA);
  });
});

describe('resolveBrandAssets', () => {
  it('returns Grinta hosting icons', () => {
    const assets = resolveBrandAssets(BRAND_GRINTA);
    assert.equal(assets.icon, GRINTA_ICON_192);
    assert.equal(assets.image, GRINTA_ICON_512);
  });

  it('keeps explicit Grinta icon overrides', () => {
    const assets = resolveBrandAssets(BRAND_GRINTA, {
      icon: 'https://grinta.web.app/icons/Icon-192.png',
      image: 'https://grinta.web.app/icons/Icon-512.png',
    });
    assert.equal(assets.icon, GRINTA_ICON_192);
    assert.equal(assets.image, GRINTA_ICON_512);
  });

  it('rejects Aserstein favicon overrides for grinta brand', () => {
    const assets = resolveBrandAssets(BRAND_GRINTA, {
      icon: 'https://aserstein-2453e.web.app/favicon.png',
      image: 'https://aserstein-2453e.web.app/favicon.png',
    });
    assert.equal(assets.icon, GRINTA_ICON_192);
    assert.equal(assets.image, GRINTA_ICON_512);
  });

  it('does not reuse Grinta icons for aserstein', () => {
    const assets = resolveBrandAssets(BRAND_ASERSTEIN);
    assert.notEqual(assets.icon, GRINTA_ICON_192);
  });
});

describe('normalizeTokenList', () => {
  it('dedupes and trims tokens', () => {
    assert.deepEqual(
      normalizeTokenList([' a ', 'a', '', 'b', null]),
      ['a', 'b'],
    );
  });

  it('rejects non-arrays', () => {
    assert.deepEqual(normalizeTokenList('token'), []);
  });
});

describe('buildDataPayload', () => {
  it('forces Grinta brand icons and flattens payload', () => {
    const data = buildDataPayload({
      type: 'convocation',
      payload: {
        id: 'match-1',
        type: 'convocation',
        icon: 'https://aserstein-2453e.web.app/favicon.png',
        nested: { ok: true },
      },
      brand: BRAND_GRINTA,
      icon: GRINTA_ICON_192,
      image: GRINTA_ICON_512,
      title: 'Titre',
      body: 'Corps',
      clubId: '0',
    });

    assert.equal(data.brand, 'grinta');
    assert.equal(data.icon, GRINTA_ICON_192);
    assert.equal(data.image, GRINTA_ICON_512);
    assert.equal(data.id, 'match-1');
    assert.equal(data.type, 'convocation');
    assert.equal(data.clubId, '0');
    assert.equal(data.nested, '{"ok":true}');
  });
});
