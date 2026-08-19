const {describe, it} = require('node:test');
const assert = require('node:assert/strict');
const {
  hasPremiumFromUserData,
  hasActiveRevenueCatEntitlements,
  sanitizeMemberIds,
  sanitizeGroupName,
  sanitizeAvatarColor,
  sanitizeImageUrl,
  sanitizeChannelId,
  buildGroupExtraData,
  isGrintaUserGroup,
  isGroupCreator,
  streamServerToken,
  resolveStreamApiKey,
  DEFAULT_STREAM_API_KEY,
  GRINTA_GROUP_FLAG,
  GRINTA_CREATED_BY,
} = require('./chat_group_helpers');

describe('hasPremiumFromUserData', () => {
  it('allows root users', () => {
    assert.equal(hasPremiumFromUserData({isRoot: true}), true);
  });

  it('allows an active trial', () => {
    const trialEndsAt = new Date('2026-09-01T00:00:00Z');
    assert.equal(
      hasPremiumFromUserData(
        {trialEndsAt},
        new Date('2026-08-19T12:00:00Z'),
      ),
      true,
    );
  });

  it('rejects an expired trial without subscription', () => {
    assert.equal(
      hasPremiumFromUserData(
        {trialEndsAt: new Date('2026-08-01T00:00:00Z')},
        new Date('2026-08-19T12:00:00Z'),
      ),
      false,
    );
  });

  it('allows a non-expired subscriptionAccess mirror', () => {
    assert.equal(
      hasPremiumFromUserData(
        {
          subscriptionAccess: {
            entitlements: ['player'],
            expiresAt: new Date('2026-12-01T00:00:00Z'),
          },
        },
        new Date('2026-08-19T12:00:00Z'),
      ),
      true,
    );
  });
});

describe('hasActiveRevenueCatEntitlements', () => {
  it('treats a future expires_date as active', () => {
    assert.equal(
      hasActiveRevenueCatEntitlements(
        {
          entitlements: {
            player: {expires_date: '2026-12-01T00:00:00Z'},
          },
        },
        new Date('2026-08-19T12:00:00Z'),
      ),
      true,
    );
  });

  it('rejects expired entitlements', () => {
    assert.equal(
      hasActiveRevenueCatEntitlements(
        {
          entitlements: {
            player: {expires_date: '2026-01-01T00:00:00Z'},
          },
        },
        new Date('2026-08-19T12:00:00Z'),
      ),
      false,
    );
  });
});

describe('group payload helpers', () => {
  it('always includes the creator and caps members', () => {
    const members = sanitizeMemberIds(
      ['a', ' a ', '', 'b', 'c'],
      'creator',
    );
    assert.ok(members.includes('creator'));
    assert.ok(members.includes('a'));
    assert.equal(new Set(members).size, members.length);
  });

  it('sanitizes name, color, image and channel id', () => {
    assert.equal(sanitizeGroupName('  Seniors 1  '), 'Seniors 1');
    assert.equal(sanitizeAvatarColor('E67E22'), '#E67E22');
    assert.equal(sanitizeAvatarColor('nope'), null);
    assert.equal(sanitizeImageUrl('https://example.com/a.jpg'), 'https://example.com/a.jpg');
    assert.equal(sanitizeImageUrl('http://insecure.example/a.jpg'), null);
    assert.ok(sanitizeChannelId('grp_abc123abc123abc123'));
    assert.equal(sanitizeChannelId('team-1'), null);
  });

  it('builds Stream extraData for a user group', () => {
    const extra = buildGroupExtraData({
      name: 'Seniors',
      memberIds: ['other'],
      currentUserId: 'creator',
      avatarColorHex: '#E67E22',
    });
    assert.equal(extra.name, 'Seniors');
    assert.equal(extra[GRINTA_GROUP_FLAG], true);
    assert.equal(extra[GRINTA_CREATED_BY], 'creator');
    assert.deepEqual(extra.members, ['creator', 'other']);
  });

  it('detects the creator of a Grinta group only', () => {
    const extra = {
      [GRINTA_GROUP_FLAG]: true,
      [GRINTA_CREATED_BY]: 'creator',
    };
    assert.equal(isGrintaUserGroup(extra), true);
    assert.equal(isGroupCreator(extra, 'creator'), true);
    assert.equal(isGroupCreator(extra, 'other'), false);
    assert.equal(isGrintaUserGroup({name: 'myTeam 1'}), false);
  });
});

describe('streamServerToken', () => {
  it('returns a three-part HS256 JWT', () => {
    const token = streamServerToken('test-secret', new Date('2026-08-19T12:00:00Z'));
    const parts = token.split('.');
    assert.equal(parts.length, 3);
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    assert.equal(payload.server, true);
  });

  it('falls back to the public Stream API key', () => {
    assert.equal(resolveStreamApiKey(''), DEFAULT_STREAM_API_KEY);
    assert.equal(resolveStreamApiKey('custom'), 'custom');
  });
});
