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
  buildMulticastMessage,
  buildCollapseId,
  normalizeNotifType,
  shouldHonorReminderPreferences,
  collectLinkedUserIdsFromMemberData,
  filterTokensByRecipientPreferences,
  ANDROID_FCM_CHANNEL_ID,
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

describe('buildMulticastMessage', () => {
  it('targets the Android fcm_channel without a tray imageUrl', () => {
    const message = buildMulticastMessage({
      tokens: ['tok'],
      title: 'Alice',
      body: 'Salut',
      brand: BRAND_GRINTA,
      assets: { icon: GRINTA_ICON_192, image: GRINTA_ICON_512 },
      dataPayload: { type: 'chat', title: 'Alice', body: 'Salut' },
    });

    assert.equal(message.android.priority, 'high');
    assert.equal(message.android.notification.channelId, ANDROID_FCM_CHANNEL_ID);
    assert.equal(message.android.notification.icon, 'ic_notification');
    assert.equal(message.android.notification.imageUrl, undefined);
    assert.equal(message.notification.imageUrl, undefined);
    assert.equal(message.notification.title, 'Alice');
  });

  it('sends an iOS alert push for every type, not a silent content-available', () => {
    for (const type of ['convocation', 'RPEAfter', 'teamDetail', 'chat']) {
      const message = buildMulticastMessage({
        tokens: ['tok'],
        title: 'Titre',
        body: 'Corps',
        brand: BRAND_GRINTA,
        assets: { icon: GRINTA_ICON_192, image: GRINTA_ICON_512 },
        dataPayload: { type, title: 'Titre', body: 'Corps' },
      });

      assert.equal(message.apns.headers['apns-priority'], '10');
      assert.equal(message.apns.headers['apns-push-type'], 'alert');
      assert.equal(message.apns.payload.aps.alert.title, 'Titre');
      assert.equal(message.apns.payload.aps.alert.body, 'Corps');
      assert.equal(message.apns.payload.aps.sound, 'default');
      assert.equal(message.apns.payload.aps['interruption-level'], 'active');
      assert.equal(message.apns.payload.aps['content-available'], undefined);
      assert.equal(message.apns.fcmOptions, undefined);
    }
  });

  it('attaches collapse key and Android tag when provided', () => {
    const message = buildMulticastMessage({
      tokens: ['tok'],
      title: 'Titre',
      body: 'Corps',
      brand: BRAND_GRINTA,
      assets: { icon: GRINTA_ICON_192, image: GRINTA_ICON_512 },
      dataPayload: { type: 'RPEAfter' },
      collapseId: 'RPEAfter_event1',
    });
    assert.equal(message.android.collapseKey, 'RPEAfter_event1');
    assert.equal(message.android.notification.tag, 'RPEAfter_event1');
    assert.equal(message.apns.headers['apns-collapse-id'], 'RPEAfter_event1');
    assert.equal(message.webpush.notification.tag, 'RPEAfter_event1');
  });
});

describe('normalizeNotifType / reminder prefs', () => {
  it('strips NotifType. prefix', () => {
    assert.equal(normalizeNotifType('NotifType.RPEAfter'), 'RPEAfter');
    assert.equal(normalizeNotifType('RPEAfter'), 'RPEAfter');
  });

  it('honours quiet hours only for reminder types', () => {
    assert.equal(shouldHonorReminderPreferences('trainingReminder'), true);
    assert.equal(shouldHonorReminderPreferences('NotifType.RPEBefore'), true);
    assert.equal(shouldHonorReminderPreferences('RPEAfter'), false);
    assert.equal(shouldHonorReminderPreferences('NotifType.RPEAfter'), false);
    assert.equal(shouldHonorReminderPreferences('convocation'), false);
    assert.equal(shouldHonorReminderPreferences('event'), false);
    assert.equal(shouldHonorReminderPreferences('chat'), false);
  });

  it('builds a short collapse id', () => {
    assert.equal(
      buildCollapseId({ type: 'NotifType.RPEAfter', objectId: 'evt-1' }),
      'RPEAfter_evt-1',
    );
    assert.ok(buildCollapseId({ type: 'x', objectId: 'y'.repeat(80) }).length <= 64);
  });
});

describe('collectLinkedUserIdsFromMemberData', () => {
  it('reads userID and users[] including path-like values', () => {
    assert.deepEqual(
      collectLinkedUserIdsFromMemberData({
        userID: ' uid-a ',
        users: ['users/uid-b', { uid: 'uid-c' }, 'uid-a'],
      }).sort(),
      ['uid-a', 'uid-b', 'uid-c'],
    );
  });

  it('keeps a userID that equals the member id (may be an Auth uid)', () => {
    assert.deepEqual(
      collectLinkedUserIdsFromMemberData({ userID: 'member-1' }),
      ['member-1'],
    );
  });
});

function fakeDb({ prefsByUser = {}, tokensByUser = {} }) {
  return {
    collection(name) {
      if (name !== 'users') {
        throw new Error(`unexpected collection ${name}`);
      }
      return {
        doc(userId) {
          return {
            collection(sub) {
              if (sub === 'app_state') {
                return {
                  doc() {
                    return {
                      async get() {
                        const data = prefsByUser[userId];
                        return {
                          exists: data != null,
                          data: () => data,
                        };
                      },
                    };
                  },
                };
              }
              if (sub === 'fcmTokens') {
                const raw = tokensByUser[userId] ?? [];
                const docs = raw.map((entry) => {
                  if (typeof entry === 'string') {
                    return { id: entry, data: () => ({ app: 'grinta' }) };
                  }
                  return {
                    id: entry.id,
                    data: () => entry.data ?? { app: 'grinta' },
                  };
                });
                return {
                  where(_field, _op, value) {
                    return {
                      async get() {
                        const branded = docs.filter(
                          (doc) => (doc.data()?.app ?? '') === value,
                        );
                        return { empty: branded.length === 0, docs: branded };
                      },
                    };
                  },
                  async get() {
                    return { empty: docs.length === 0, docs };
                  },
                };
              }
              throw new Error(`unexpected subcollection ${sub}`);
            },
          };
        },
      };
    },
  };
}

describe('filterTokensByRecipientPreferences', () => {
  const quietPrefs = {
    remindersEnabled: true,
    quietHoursStart: 22,
    quietHoursEnd: 7,
    quietDays: [],
    timezone: 'UTC',
  };
  const duringQuiet = new Date('2026-08-03T23:00:00Z');

  it('sends RPEAfter immediately during quiet hours', async () => {
    const db = fakeDb({
      prefsByUser: { u1: quietPrefs },
      tokensByUser: { u1: ['tok-1'] },
    });
    const result = await filterTokensByRecipientPreferences({
      db,
      recipientUserIds: ['u1'],
      fcmTokens: [],
      type: 'RPEAfter',
      now: duringQuiet,
    });
    assert.deepEqual(result.tokens, ['tok-1']);
    assert.equal(result.skippedQuiet, 0);
    assert.equal(result.quietDeferred.length, 0);
  });

  it('defers trainingReminder during quiet hours', async () => {
    const db = fakeDb({
      prefsByUser: { u1: quietPrefs },
      tokensByUser: { u1: ['tok-1'] },
    });
    const result = await filterTokensByRecipientPreferences({
      db,
      recipientUserIds: ['u1'],
      fcmTokens: [],
      type: 'trainingReminder',
      now: duringQuiet,
    });
    assert.deepEqual(result.tokens, []);
    assert.equal(result.skippedQuiet, 1);
    assert.equal(result.quietDeferred.length, 1);
    assert.deepEqual(result.quietDeferred[0].tokens, ['tok-1']);
  });

  it('loads tokens from Firestore when the client sent none', async () => {
    const db = fakeDb({
      tokensByUser: { u1: ['tok-a'], u2: ['tok-b'] },
    });
    const result = await filterTokensByRecipientPreferences({
      db,
      recipientUserIds: ['u1', 'u2'],
      fcmTokens: [],
      type: 'convocation',
    });
    assert.deepEqual(result.tokens.sort(), ['tok-a', 'tok-b']);
  });
});
