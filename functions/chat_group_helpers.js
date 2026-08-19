const crypto = require('crypto');

const STREAM_API_BASE = 'https://chat.stream-io-api.com';
const STREAM_CHANNEL_TYPE = 'messaging';
const GRINTA_GROUP_FLAG = 'grinta_group';
const GRINTA_CREATED_BY = 'grinta_created_by';
const GRINTA_AVATAR_COLOR = 'grinta_avatar_color';
const DEFAULT_STREAM_API_KEY = 'vg9g2zz7s2fc';
const NAME_MAX_LENGTH = 80;
const MAX_MEMBERS = 50;
const CHANNEL_ID_PATTERN = /^grp_[a-z0-9]{16,64}$/;
const COLOR_PATTERN = /^#[0-9A-Fa-f]{6}$/;

function readNonEmptyString(value) {
  const trimmed = (value ?? '').toString().trim();
  return trimmed.length > 0 ? trimmed : null;
}

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') {
    const date = value.toDate();
    return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
  }
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? new Date(parsed) : null;
  }
  if (typeof value === 'object') {
    if (typeof value._seconds === 'number') {
      return new Date(value._seconds * 1000);
    }
    if (typeof value.seconds === 'number') {
      return new Date(value.seconds * 1000);
    }
  }
  return null;
}

function hasPremiumFromUserData(data, now = new Date()) {
  if (!data || typeof data !== 'object') return false;
  if (data.isRoot === true) return true;

  const trialEndsAt = toDate(data.trialEndsAt);
  if (trialEndsAt && trialEndsAt.getTime() > now.getTime()) return true;

  const access = data.subscriptionAccess;
  if (!access || typeof access !== 'object') return false;
  const entitlements = Array.isArray(access.entitlements)
    ? access.entitlements.filter((id) => (id ?? '').toString().trim().length > 0)
    : [];
  if (entitlements.length === 0) return false;
  const expiresAt = toDate(access.expiresAt);
  if (expiresAt && expiresAt.getTime() <= now.getTime()) return false;
  return true;
}

function hasActiveRevenueCatEntitlements(subscriber, now = new Date()) {
  const entitlements = subscriber?.entitlements;
  if (!entitlements || typeof entitlements !== 'object') return false;
  const nowMs = now.getTime();
  return Object.values(entitlements).some((entry) => {
    if (!entry || typeof entry !== 'object') return false;
    const expires = entry.expires_date
      ? Date.parse(entry.expires_date)
      : null;
    if (expires == null || Number.isNaN(expires)) return true;
    return expires > nowMs;
  });
}

function sanitizeMemberIds(rawIds, currentUserId) {
  const members = new Set();
  const creator = readNonEmptyString(currentUserId);
  if (creator) members.add(creator);
  const list = Array.isArray(rawIds) ? rawIds : [];
  for (const value of list) {
    const id = readNonEmptyString(value);
    if (id) members.add(id);
    if (members.size >= MAX_MEMBERS) break;
  }
  return [...members];
}

function sanitizeGroupName(value) {
  const name = readNonEmptyString(value);
  if (!name) return null;
  return name.slice(0, NAME_MAX_LENGTH);
}

function sanitizeAvatarColor(value) {
  const hex = readNonEmptyString(value);
  if (!hex) return null;
  const withHash = hex.startsWith('#') ? hex : `#${hex}`;
  return COLOR_PATTERN.test(withHash) ? withHash : null;
}

function sanitizeImageUrl(value) {
  const url = readNonEmptyString(value);
  if (!url) return null;
  if (!/^https:\/\//i.test(url)) return null;
  return url.slice(0, 2048);
}

function sanitizeChannelId(value) {
  const id = readNonEmptyString(value);
  if (!id) return null;
  return CHANNEL_ID_PATTERN.test(id) ? id : null;
}

function newGroupChannelId() {
  return `grp_${crypto.randomUUID().replace(/-/g, '')}`;
}

function buildGroupExtraData({
  name,
  memberIds,
  currentUserId,
  avatarColorHex,
  imageUrl,
}) {
  const members = sanitizeMemberIds(memberIds, currentUserId);
  const extra = {
    name,
    members,
    [GRINTA_GROUP_FLAG]: true,
    [GRINTA_CREATED_BY]: currentUserId,
    created_by_id: currentUserId,
  };
  if (avatarColorHex) extra[GRINTA_AVATAR_COLOR] = avatarColorHex;
  if (imageUrl) extra.image = imageUrl;
  return extra;
}

function isGrintaUserGroup(channelData) {
  const flag = channelData?.[GRINTA_GROUP_FLAG];
  return flag === true || flag === 'true';
}

function groupCreatedById(channelData) {
  const fromExtra = readNonEmptyString(channelData?.[GRINTA_CREATED_BY]);
  if (fromExtra) return fromExtra;
  return readNonEmptyString(channelData?.created_by?.id);
}

function isGroupCreator(channelData, uid) {
  const creator = groupCreatedById(channelData);
  const current = readNonEmptyString(uid);
  return Boolean(creator && current && creator === current);
}

function streamServerToken(apiSecret, now = new Date()) {
  const header = Buffer.from(
    JSON.stringify({ alg: 'HS256', typ: 'JWT' }),
  ).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({
      server: true,
      iat: Math.floor(now.getTime() / 1000),
    }),
  ).toString('base64url');
  const signature = crypto
    .createHmac('sha256', apiSecret)
    .update(`${header}.${payload}`)
    .digest('base64url');
  return `${header}.${payload}.${signature}`;
}

function resolveStreamApiKey(explicit) {
  return readNonEmptyString(explicit) || DEFAULT_STREAM_API_KEY;
}

async function streamRequest({
  apiKey,
  apiSecret,
  method,
  path,
  body,
  fetchImpl = fetch,
}) {
  const token = streamServerToken(apiSecret);
  const url = new URL(path, STREAM_API_BASE);
  url.searchParams.set('api_key', apiKey);
  const response = await fetchImpl(url, {
    method,
    headers: {
      Authorization: token,
      'Stream-Auth-Type': 'jwt',
      'Content-Type': 'application/json',
    },
    body: body == null ? undefined : JSON.stringify(body),
  });
  const json = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      readNonEmptyString(json?.message) ||
      readNonEmptyString(json?.error) ||
      `Stream HTTP ${response.status}`;
    const error = new Error(message);
    error.status = response.status;
    error.payload = json;
    throw error;
  }
  return json;
}

function channelPath(channelId, suffix = '') {
  return `/channels/${STREAM_CHANNEL_TYPE}/${encodeURIComponent(channelId)}${suffix}`;
}

module.exports = {
  STREAM_API_BASE,
  STREAM_CHANNEL_TYPE,
  GRINTA_GROUP_FLAG,
  GRINTA_CREATED_BY,
  GRINTA_AVATAR_COLOR,
  DEFAULT_STREAM_API_KEY,
  NAME_MAX_LENGTH,
  MAX_MEMBERS,
  readNonEmptyString,
  toDate,
  hasPremiumFromUserData,
  hasActiveRevenueCatEntitlements,
  sanitizeMemberIds,
  sanitizeGroupName,
  sanitizeAvatarColor,
  sanitizeImageUrl,
  sanitizeChannelId,
  newGroupChannelId,
  buildGroupExtraData,
  isGrintaUserGroup,
  groupCreatedById,
  isGroupCreator,
  streamServerToken,
  resolveStreamApiKey,
  streamRequest,
  channelPath,
};
