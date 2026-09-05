const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const { Timestamp } = require('firebase-admin/firestore');

const {
  isPushChannel,
  isAsersteinNotificationBrand,
  resolveRecipientUserIds,
  persistQuietDeferral,
} = require('./notify_on_create');
const {
  resolveNotificationPushBrand,
  BRAND_GRINTA,
  BRAND_ASERSTEIN,
} = require('./send_push_fcm_helpers');

describe('resolveNotificationPushBrand', () => {
  it('never maps a Grinta event clubId to aserstein', () => {
    assert.equal(
      resolveNotificationPushBrand({ clubId: '500554', type: 'convocation' }),
      BRAND_GRINTA,
    );
  });

  it('honours an explicit aserstein brand on the notification doc', () => {
    assert.equal(
      resolveNotificationPushBrand({ brand: 'aserstein' }),
      BRAND_ASERSTEIN,
    );
  });
});

describe('isAsersteinNotificationBrand', () => {
  it('skips only an explicit aserstein brand', () => {
    assert.equal(isAsersteinNotificationBrand({ clubId: '500554' }), false);
    assert.equal(isAsersteinNotificationBrand({ brand: 'grinta' }), false);
    assert.equal(isAsersteinNotificationBrand({ brand: 'aserstein' }), true);
  });
});

describe('isPushChannel', () => {
  it('treats missing and SendBy.notification as push', () => {
    assert.equal(isPushChannel(undefined), true);
    assert.equal(isPushChannel(''), true);
    assert.equal(isPushChannel('SendBy.notification'), true);
  });

  it('skips email and sms', () => {
    assert.equal(isPushChannel('SendBy.email'), false);
    assert.equal(isPushChannel('SendBy.sms'), false);
  });
});

describe('resolveRecipientUserIds', () => {
  it('prefers the notification userId', async () => {
    const ids = await resolveRecipientUserIds({
      db: {
        collection() {
          throw new Error('should not load member when userId is set');
        },
      },
      userId: ' auth-1 ',
      playerId: 'member-1',
    });
    assert.deepEqual(ids, ['auth-1']);
  });

  it('loads linked accounts from member when userId is empty', async () => {
    const db = {
      collection(name) {
        assert.equal(name, 'member');
        return {
          doc(id) {
            assert.equal(id, 'member-1');
            return {
              async get() {
                return {
                  exists: true,
                  data: () => ({
                    userID: 'auth-linked',
                    users: ['auth-parent'],
                    keyMember: 'member-1',
                  }),
                };
              },
            };
          },
        };
      },
    };
    const ids = await resolveRecipientUserIds({
      db,
      userId: '',
      playerId: 'member-1',
    });
    assert.deepEqual(ids.sort(), ['auth-linked', 'auth-parent']);
  });

  it('falls back to keyMember query', async () => {
    const db = {
      collection(name) {
        assert.equal(name, 'member');
        return {
          doc() {
            return {
              async get() {
                return { exists: false, data: () => null };
              },
            };
          },
          where(field, op, value) {
            assert.equal(field, 'keyMember');
            assert.equal(op, '==');
            assert.equal(value, 'alias-1');
            return {
              limit() {
                return {
                  async get() {
                    return {
                      empty: false,
                      docs: [
                        {
                          data: () => ({ userID: 'auth-from-alias' }),
                        },
                      ],
                    };
                  },
                };
              },
            };
          },
        };
      },
    };
    const ids = await resolveRecipientUserIds({
      db,
      userId: '',
      playerId: 'alias-1',
    });
    assert.deepEqual(ids, ['auth-from-alias']);
  });
});

describe('persistQuietDeferral', () => {
  it('stores sendAfter from user quiet-hours prefs', async () => {
    const written = {};
    const snap = {
      id: 'notif-1',
      ref: {
        async update(fields) {
          Object.assign(written, fields);
        },
      },
    };
    const prefs = {
      remindersEnabled: true,
      quietDays: [],
      quietHoursStart: 22,
      quietHoursEnd: 7,
      timezone: 'UTC',
    };
    const result = await persistQuietDeferral({
      snap,
      filtered: {
        skippedQuiet: 1,
        quietDeferred: [
          { userId: 'u1', prefs, tokens: ['tok'] },
        ],
      },
      recipientUserIds: ['u1'],
      assets: { icon: 'https://grinta.web.app/icons/Icon-192.png' },
      now: new Date('2026-08-03T23:00:00Z'),
    });

    assert.equal(result.reason, 'quiet');
    assert.equal(written['pushDispatch.status'], 'deferred');
    assert.equal(written['pushDispatch.reason'], 'quiet');
    assert.equal(written['pushDispatch.recipientUserId'], 'u1');
    assert.ok(written['pushDispatch.sendAfter'] instanceof Timestamp);
    assert.equal(written['pushDispatch.sendAfter'].toDate().getUTCHours(), 7);
  });
});
