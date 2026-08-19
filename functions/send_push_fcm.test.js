const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  resolveBrand,
  resolveBrandAssets,
  normalizeTokenList,
  buildDataPayload,
  parseNotificationPreferences,
  isQuietAt,
  evaluatePushPermission,
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

describe('notification preferences', () => {
  it('defaults remindersEnabled to true', () => {
    const prefs = parseNotificationPreferences(null);
    assert.equal(prefs.remindersEnabled, true);
    assert.equal(prefs.quietHoursStart, 22);
    assert.equal(prefs.quietHoursEnd, 7);
  });

  it('blocks when remindersEnabled is false', () => {
    const prefs = parseNotificationPreferences({ remindersEnabled: false });
    assert.deepEqual(evaluatePushPermission(prefs), {
      allowed: false,
      reason: 'disabled',
    });
  });

  it('detects overnight quiet hours in Europe/Paris', () => {
    const prefs = parseNotificationPreferences({
      remindersEnabled: true,
      quietHoursStart: 22,
      quietHoursEnd: 7,
      timezone: 'Europe/Paris',
      quietDays: [],
    });

    // 2026-08-03 23:30 UTC = 01:30 Paris (UTC+2 in August) → quiet
    const lateUtc = new Date('2026-08-03T23:30:00Z');
    assert.equal(isQuietAt(prefs, lateUtc), true);
    assert.equal(evaluatePushPermission(prefs, lateUtc).reason, 'quiet');

    // 2026-08-03 10:00 UTC = 12:00 Paris → not quiet
    const noonUtc = new Date('2026-08-03T10:00:00Z');
    assert.equal(isQuietAt(prefs, noonUtc), false);
    assert.equal(evaluatePushPermission(prefs, noonUtc).allowed, true);
  });

  it('blocks quiet weekdays', () => {
    // 2026-08-03 was a Monday
    const prefs = parseNotificationPreferences({
      remindersEnabled: true,
      quietDays: [1],
      quietHoursStart: 0,
      quietHoursEnd: 0,
      timezone: 'UTC',
    });
    const monday = new Date('2026-08-03T12:00:00Z');
    assert.equal(isQuietAt(prefs, monday), true);
  });

  it('computeSendAfter finds end of overnight quiet window', () => {
    const { computeSendAfter } = require('./send_push_fcm_helpers');
    const prefs = parseNotificationPreferences({
      remindersEnabled: true,
      quietHoursStart: 22,
      quietHoursEnd: 7,
      quietDays: [],
      timezone: 'UTC',
    });
    // 23:00 UTC → quiet until 07:00 UTC
    const duringQuiet = new Date('2026-08-03T23:00:00Z');
    const sendAfter = computeSendAfter(prefs, duringQuiet);
    assert.ok(sendAfter);
    assert.equal(sendAfter.getUTCHours(), 7);
    assert.equal(evaluatePushPermission(prefs, sendAfter).allowed, true);
  });

  it('computeSendAfter returns null when reminders disabled', () => {
    const { computeSendAfter } = require('./send_push_fcm_helpers');
    const prefs = parseNotificationPreferences({ remindersEnabled: false });
    assert.equal(
      computeSendAfter(prefs, new Date('2026-08-03T23:00:00Z')),
      null,
    );
  });
});
