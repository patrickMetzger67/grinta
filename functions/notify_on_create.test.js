const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  isPushChannel,
  resolveRecipientUserIds,
} = require('./notify_on_create');

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
