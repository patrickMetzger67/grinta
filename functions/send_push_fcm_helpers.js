/** Grinta PWA icons (Firebase Hosting site `grinta`). */
const GRINTA_ICON_192 = 'https://grinta.web.app/icons/Icon-192.png';
const GRINTA_ICON_512 = 'https://grinta.web.app/icons/Icon-512.png';

/**
 * Aserstein legacy defaults (shared Firebase project). Prefer explicit
 * `data.icon` / Storage URLs when Aserstein callers need a different asset.
 */
const ASERSTEIN_ICON = 'https://aserstein-2453e.web.app/favicon.png';

const BRAND_GRINTA = 'grinta';
const BRAND_ASERSTEIN = 'aserstein';

/** Must match iOS `PRODUCT_BUNDLE_IDENTIFIER` / GoogleService-Info BUNDLE_ID. */
const IOS_APNS_TOPIC = 'io.grinta.app';
const GRINTA_PACKAGE_NAME = 'io.grinta.app';
const ASERSTEIN_ANDROID_PACKAGE = 'com.tome4.asersteinv2';

/** Raw APNs device tokens are 32 bytes hex-encoded. FCM tokens are longer. */
const APNS_DEVICE_TOKEN_PATTERN = /^[0-9a-fA-F]{64}$/;

const DEFAULT_TIMEZONE = 'Europe/Paris';

/** Dart DateTime.monday=1 … sunday=7 */
const WEEKDAY_SHORT_TO_DART = {
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
  Sun: 7,
};

function readNonEmptyString(value) {
  const trimmed = (value ?? '').toString().trim();
  return trimmed.length > 0 ? trimmed : null;
}

function isLikelyApnsDeviceToken(token) {
  return APNS_DEVICE_TOKEN_PATTERN.test((token ?? '').toString().trim());
}

function isSendableFcmRegistrationToken(token) {
  const trimmed = (token ?? '').toString().trim();
  if (!trimmed) return false;
  return !isLikelyApnsDeviceToken(trimmed);
}

function tokenFromDoc(doc) {
  const data =
    typeof doc?.data === 'function' ? doc.data() : (doc?.data ?? {});
  const fromField = readNonEmptyString(data?.token);
  const fromId = (doc?.id ?? '').toString().trim();
  return fromField || fromId || null;
}

function normalizeTokenList(raw) {
  if (!Array.isArray(raw)) return [];
  return [
    ...new Set(
      raw
        .map((token) => (token ?? '').toString().trim())
        .filter((token) => isSendableFcmRegistrationToken(token)),
    ),
  ];
}

function docData(doc) {
  return typeof doc?.data === 'function' ? doc.data() : (doc?.data ?? {});
}

function isAsersteinPackage(packageName) {
  const lower = (packageName ?? '').toString().trim().toLowerCase();
  if (!lower) return false;
  if (lower === ASERSTEIN_ANDROID_PACKAGE.toLowerCase()) return true;
  return lower.includes('aserstein');
}

function isGrintaPackage(packageName) {
  const lower = (packageName ?? '').toString().trim().toLowerCase();
  if (!lower) return false;
  return lower === GRINTA_PACKAGE_NAME.toLowerCase();
}

function docLooksLikeAserstein(data) {
  const app = (data?.app ?? '').toString().trim().toLowerCase();
  if (app === BRAND_ASERSTEIN) return true;
  return isAsersteinPackage(data?.packageName);
}

/**
 * Whether a token doc may receive a Grinta push on the shared Firebase project.
 * Never targets Aserstein-tagged / Aserstein-package tokens. Naked unbranded
 * Android docs are skipped (common cross-app bleed); legacy iOS/web stay OK.
 */
function isGrintaEligibleTokenDoc(data) {
  const app = (data?.app ?? '').toString().trim().toLowerCase();
  if (app === BRAND_ASERSTEIN) return false;
  if (isAsersteinPackage(data?.packageName)) return false;
  if (app === BRAND_GRINTA) return true;
  if (app.length > 0) return false;

  if (isGrintaPackage(data?.packageName)) return true;

  const platform = (data?.platform ?? '').toString().trim().toLowerCase();
  if (platform === 'android') return false;
  return true;
}

function normalizeUserIdList(raw) {
  if (!Array.isArray(raw)) return [];
  return [
    ...new Set(
      raw
        .map((id) => (id ?? '').toString().trim())
        .filter((id) => id.length > 0),
    ),
  ];
}

/** `NotifType.RPEAfter` / `RPEAfter` → `RPEAfter`. */
function normalizeNotifType(raw) {
  let value = (raw ?? '').toString().trim();
  if (value.startsWith('NotifType.')) {
    value = value.slice('NotifType.'.length);
  }
  return value;
}

/**
 * Agenda reminders already use InternalReminderService + the OS scheduler.
 * The Firestore trigger must not also FCM those docs (duplicate banners).
 * Every other type respects user prefs: send now, or store `sendAfter`.
 */
const LOCAL_REMINDER_PUSH_TYPES = new Set([
  'trainingReminder',
  'matchOpponentStatsReminder',
  'RPEBefore',
]);

function isLocalReminderNotificationType(type) {
  return LOCAL_REMINDER_PUSH_TYPES.has(normalizeNotifType(type));
}

/** @deprecated Use [isLocalReminderNotificationType]. */
function shouldHonorReminderPreferences(type) {
  return isLocalReminderNotificationType(type);
}

function normalizeLinkedUserId(entry) {
  if (entry == null) return null;
  if (typeof entry === 'string') {
    const trimmed = entry.trim();
    if (!trimmed) return null;
    if (trimmed.includes('/')) {
      const segment = trimmed.split('/').pop().trim();
      return segment || null;
    }
    return trimmed;
  }
  if (typeof entry === 'object') {
    const refId = readNonEmptyString(entry.id);
    if (refId) return refId;
    const path = readNonEmptyString(entry.path);
    if (path) {
      const segment = path.split('/').pop().trim();
      return segment || null;
    }
    for (const key of ['uid', 'id', 'userId', 'userID']) {
      const nested = normalizeLinkedUserId(entry[key]);
      if (nested) return nested;
    }
  }
  const asString = `${entry}`.trim();
  return asString || null;
}

function collectLinkedUserIdsFromMemberData(data) {
  const ids = new Set();
  if (!data || typeof data !== 'object') return [];
  const add = (raw) => {
    const id = normalizeLinkedUserId(raw);
    if (id) ids.add(id);
  };
  add(data.userID);
  if (Array.isArray(data.users)) {
    for (const entry of data.users) add(entry);
  }
  return [...ids];
}

/** APNs collapse-id / Android tag, max 64 bytes. Per-device so shared keys are OK. */
function buildCollapseId({ type, objectId, userId } = {}) {
  const parts = [
    normalizeNotifType(type) || 'grinta',
    readNonEmptyString(objectId) || '',
    readNonEmptyString(userId) || '',
  ].filter((part) => part.length > 0);
  const raw = parts.join('_').replace(/[^A-Za-z0-9._-]/g, '_');
  return raw.slice(0, 64) || 'grinta';
}

function clampHour(value, fallback) {
  const parsed = Number.parseInt(`${value}`, 10);
  if (!Number.isFinite(parsed)) return fallback;
  return Math.min(23, Math.max(0, parsed));
}

/**
 * Parse `users/{uid}/app_state/notification_preferences` (same defaults as Flutter).
 */
function parseNotificationPreferences(map) {
  const data = map && typeof map === 'object' ? map : {};
  const rawDays = Array.isArray(data.quietDays) ? data.quietDays : [];
  const quietDays = rawDays
    .map((value) => Number.parseInt(`${value}`, 10))
    .filter((day) => Number.isFinite(day) && day >= 1 && day <= 7);

  return {
    remindersEnabled: data.remindersEnabled !== false,
    quietDays,
    quietHoursStart: clampHour(data.quietHoursStart, 22),
    quietHoursEnd: clampHour(data.quietHoursEnd, 7),
    morningReminderHour: clampHour(data.morningReminderHour, 8),
    timezone:
      readNonEmptyString(data.timezone) ?? DEFAULT_TIMEZONE,
  };
}

function getZonedWeekdayAndHour(date, timeZone) {
  const tz = readNonEmptyString(timeZone) ?? DEFAULT_TIMEZONE;
  let parts;
  try {
    parts = Object.fromEntries(
      new Intl.DateTimeFormat('en-US', {
        timeZone: tz,
        weekday: 'short',
        hour: 'numeric',
        hourCycle: 'h23',
      })
        .formatToParts(date)
        .filter((part) => part.type !== 'literal')
        .map((part) => [part.type, part.value]),
    );
  } catch (_) {
    parts = Object.fromEntries(
      new Intl.DateTimeFormat('en-US', {
        timeZone: DEFAULT_TIMEZONE,
        weekday: 'short',
        hour: 'numeric',
        hourCycle: 'h23',
      })
        .formatToParts(date)
        .filter((part) => part.type !== 'literal')
        .map((part) => [part.type, part.value]),
    );
  }

  let hour = Number.parseInt(parts.hour, 10);
  if (!Number.isFinite(hour)) hour = 0;
  // Some engines report midnight as 24 with h23.
  if (hour === 24) hour = 0;

  const weekday = WEEKDAY_SHORT_TO_DART[parts.weekday] ?? 1;
  return { weekday, hour };
}

/** Mirrors Flutter [NotificationPreferences.isQuietAt]. */
function isQuietAt(prefs, date = new Date()) {
  const { weekday, hour } = getZonedWeekdayAndHour(date, prefs.timezone);
  if (prefs.quietDays.includes(weekday)) {
    return true;
  }

  const start = prefs.quietHoursStart;
  const end = prefs.quietHoursEnd;
  if (start === end) {
    return false;
  }
  if (start < end) {
    return hour >= start && hour < end;
  }
  return hour >= start || hour < end;
}

/**
 * Whether push may be delivered for these prefs right now.
 * @returns {{ allowed: boolean, reason?: 'disabled'|'quiet' }}
 */
function evaluatePushPermission(prefs, date = new Date()) {
  if (!prefs.remindersEnabled) {
    return { allowed: false, reason: 'disabled' };
  }
  if (isQuietAt(prefs, date)) {
    return { allowed: false, reason: 'quiet' };
  }
  return { allowed: true };
}

/**
 * Resolve push brand. Grinta app always sends `brand: "grinta"` and uses
 * platform clubId `"0"`. Prefer explicit brand; fall back to clubId `"0"` →
 * Grinta so clubId-only callers stay on Grinta icons.
 */
function resolveBrand(rawBrand, clubId) {
  const brand = (rawBrand ?? '').toString().trim().toLowerCase();
  if (brand === BRAND_GRINTA || brand === BRAND_ASERSTEIN) {
    return brand;
  }
  // Unknown / missing brand: always Grinta (Grinta owns this CF).
  return BRAND_GRINTA;
}

function isGrintaAssetUrl(url) {
  if (!url) return false;
  const lower = url.toLowerCase();
  if (lower.includes('aserstein') || lower.endsWith('/favicon.png')) {
    return false;
  }
  return (
    lower.includes('grinta.web.app/icons/') ||
    (lower.includes('logoclubs') && lower.includes('grinta')) ||
    lower.includes('/icons/icon-')
  );
}

function resolveBrandAssets(brand, overrides = {}) {
  const overrideIcon = readNonEmptyString(overrides.icon);
  const overrideImage = readNonEmptyString(overrides.image);

  if (brand === BRAND_ASERSTEIN) {
    return {
      icon: overrideIcon ?? ASERSTEIN_ICON,
      image: overrideImage ?? ASERSTEIN_ICON,
    };
  }
  return {
    // Grinta: ignore non-Grinta overrides that might leak Aserstein favicons.
    icon: isGrintaAssetUrl(overrideIcon) ? overrideIcon : GRINTA_ICON_192,
    image: isGrintaAssetUrl(overrideImage) ? overrideImage : GRINTA_ICON_512,
  };
}

/** FCM `data` values must be strings. */
function stringifyDataValue(value) {
  if (value == null) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  try {
    return JSON.stringify(value);
  } catch (_) {
    return String(value);
  }
}

function buildDataPayload({
  type,
  payload,
  brand,
  icon,
  image,
  title,
  body,
  clubId,
}) {
  const data = {
    brand,
    icon,
    image,
    clubId,
  };

  if (title) data.title = title;
  if (body) data.body = body;
  if (type) data.type = type;

  if (payload && typeof payload === 'object' && !Array.isArray(payload)) {
    for (const [key, value] of Object.entries(payload)) {
      const asString = stringifyDataValue(value);
      if (asString == null) continue;
      // Do not let nested payload overwrite brand icons with legacy Aserstein URLs.
      if (key === 'icon' || key === 'image' || key === 'brand') continue;
      data[key] = asString;
    }
  }

  if (type) data.type = type;

  return data;
}

function buildMulticastMessage({
  tokens,
  title,
  body,
  brand,
  assets,
  dataPayload,
  collapseId,
}) {
  const collapse = readNonEmptyString(collapseId);
  const logo = readNonEmptyString(assets?.image) ?? GRINTA_ICON_512;
  const icon = readNonEmptyString(assets?.icon) ?? GRINTA_ICON_192;
  return {
    tokens,
    // No top-level imageUrl: FCM would copy it onto APNs as mutable-content,
    // which requires a Notification Service Extension Grinta does not ship.
    // Android / web keep the logo via their platform-specific blocks.
    notification: {
      title: title || 'Grinta',
      body: body || '',
    },
    data: dataPayload,
    android: {
      priority: 'high',
      ...(collapse ? { collapseKey: collapse } : {}),
      notification: {
        channelId: ANDROID_FCM_CHANNEL_ID,
        icon: 'ic_notification',
        imageUrl: logo,
        color: '#F95C1B',
        sound: 'default',
        defaultSound: true,
        visibility: 'public',
        ...(collapse ? { tag: collapse } : {}),
      },
    },
    // Visible APNs alert for every Grinta push (convocation, RPE, invite,
    // chat…). A silent content-available wake is dropped when iOS is killed.
    // apns-topic must be Grinta's bundle id — shared Firebase project also
    // hosts Aserstein; without it, iOS can attribute the push to the wrong app.
    // No mutable-content / fcmOptions.imageUrl: those need an NSE.
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert',
        'apns-topic': IOS_APNS_TOPIC,
        ...(collapse ? { 'apns-collapse-id': collapse } : {}),
      },
      payload: {
        aps: {
          alert: {
            title: title || 'Grinta',
            body: body || '',
          },
          sound: 'default',
          badge: 1,
          'interruption-level': 'active',
        },
      },
    },
    webpush: {
      headers: {
        Urgency: 'high',
      },
      notification: {
        title: title || 'Grinta',
        body: body || '',
        icon,
        image: logo,
        ...(collapse ? { tag: collapse, renotify: true } : {}),
      },
      fcmOptions: {
        link: '/',
      },
    },
  };
}

function isInvalidTokenError(error) {
  const code = (error?.code ?? '').toString();
  return (
    code.includes('registration-token-not-registered') ||
    code.includes('invalid-registration-token') ||
    code.includes('invalid-argument')
  );
}

const PENDING_PUSH_COLLECTION = 'pending_push';
/** Must match Flutter [NotificationFCMService.androidChannelId]. */
const ANDROID_FCM_CHANNEL_ID = 'fcm_channel';
/** Max deferral window when quiet (ms). */
const PENDING_PUSH_MAX_DEFER_MS = 48 * 60 * 60 * 1000;
/** Step used to find the next non-quiet instant. */
const PENDING_PUSH_SCAN_STEP_MS = 15 * 60 * 1000;

/**
 * Next Date when [evaluatePushPermission] allows push, or null if none within
 * [PENDING_PUSH_MAX_DEFER_MS].
 */
function computeSendAfter(prefs, now = new Date()) {
  const startMs = now.getTime();
  const maxMs = startMs + PENDING_PUSH_MAX_DEFER_MS;

  // If already allowed, send ASAP (caller normally won't enqueue).
  if (evaluatePushPermission(prefs, now).allowed) {
    return now;
  }
  // Disabled permanently for this window — do not schedule.
  if (!prefs.remindersEnabled) {
    return null;
  }

  for (
    let ts = startMs + PENDING_PUSH_SCAN_STEP_MS;
    ts <= maxMs;
    ts += PENDING_PUSH_SCAN_STEP_MS
  ) {
    const candidate = new Date(ts);
    if (evaluatePushPermission(prefs, candidate).allowed) {
      return candidate;
    }
  }
  return null;
}

async function loadUserFcmTokens(db, userId, brand, _requestedTokens) {
  const tokensRef = db.collection('users').doc(userId).collection('fcmTokens');
  const all = await tokensRef.get();
  const allDocs = all.docs;
  let tokenDocs = allDocs;

  if (brand === BRAND_GRINTA) {
    tokenDocs = allDocs.filter((doc) => isGrintaEligibleTokenDoc(docData(doc)));
  } else if (brand === BRAND_ASERSTEIN) {
    // Never fan out Aserstein-branded pushes to Grinta tokens.
    tokenDocs = allDocs.filter((doc) => {
      const data = docData(doc);
      const app = (data?.app ?? '').toString().trim().toLowerCase();
      if (app === BRAND_GRINTA || isGrintaPackage(data?.packageName)) {
        return false;
      }
      return (
        app === BRAND_ASERSTEIN ||
        isAsersteinPackage(data?.packageName) ||
        app.length === 0
      );
    });
  }

  const tokens = [];
  for (const doc of tokenDocs) {
    const token = tokenFromDoc(doc);
    if (!token || !isSendableFcmRegistrationToken(token)) continue;
    // Do not intersect with the client-supplied list. A partial snapshot
    // (Android + Chrome only) would drop a valid iOS token already in Firestore.
    tokens.push(token);
  }
  return tokens;
}

/**
 * Load prefs + evaluate push permission for each recipient uid.
 * Returns tokens to send now, skip stats, and quiet recipients to defer.
 */
async function filterTokensByRecipientPreferences({
  db,
  recipientUserIds,
  fcmTokens,
  brand = BRAND_GRINTA,
  now = new Date(),
  type,
}) {
  const userIds = normalizeUserIdList(recipientUserIds);
  const requestedTokens = new Set(normalizeTokenList(fcmTokens));

  if (userIds.length === 0) {
    // Legacy callers without recipientUserIds: keep previous behaviour.
    return {
      tokens: [...requestedTokens],
      skippedDisabled: 0,
      skippedQuiet: 0,
      allowedUserIds: [],
      skippedUserIds: [],
      quietDeferred: [],
    };
  }

  const allowedUserIds = [];
  const skippedUserIds = [];
  const quietDeferred = [];
  let skippedDisabled = 0;
  let skippedQuiet = 0;
  const allowedTokens = new Set();

  for (const userId of userIds) {
    const userTokens = await loadUserFcmTokens(
      db,
      userId,
      brand,
      requestedTokens,
    );

    const prefSnap = await db
      .collection('users')
      .doc(userId)
      .collection('app_state')
      .doc('notification_preferences')
      .get();
    const prefs = parseNotificationPreferences(
      prefSnap.exists ? prefSnap.data() : null,
    );
    const decision = evaluatePushPermission(prefs, now);

    if (!decision.allowed) {
      skippedUserIds.push(userId);
      if (decision.reason === 'disabled') {
        skippedDisabled += 1;
        continue;
      }
      if (decision.reason === 'quiet') {
        skippedQuiet += 1;
        // Queue even without tokens — the hourly drain reloads fcmTokens.
        quietDeferred.push({
          userId,
          prefs,
          tokens: userTokens,
        });
      }
      continue;
    }

    allowedUserIds.push(userId);
    for (const token of userTokens) {
      allowedTokens.add(token);
    }
  }

  return {
    tokens: [...allowedTokens],
    skippedDisabled,
    skippedQuiet,
    allowedUserIds,
    skippedUserIds,
    quietDeferred,
  };
}

module.exports = {
  readNonEmptyString,
  normalizeTokenList,
  isLikelyApnsDeviceToken,
  isSendableFcmRegistrationToken,
  tokenFromDoc,
  isGrintaEligibleTokenDoc,
  docLooksLikeAserstein,
  normalizeUserIdList,
  normalizeNotifType,
  normalizeLinkedUserId,
  collectLinkedUserIdsFromMemberData,
  shouldHonorReminderPreferences,
  isLocalReminderNotificationType,
  buildCollapseId,
  LOCAL_REMINDER_PUSH_TYPES,
  REMINDER_PUSH_TYPES: LOCAL_REMINDER_PUSH_TYPES,
  parseNotificationPreferences,
  getZonedWeekdayAndHour,
  isQuietAt,
  evaluatePushPermission,
  computeSendAfter,
  filterTokensByRecipientPreferences,
  loadUserFcmTokens,
  resolveBrand,
  resolveBrandAssets,
  isGrintaAssetUrl,
  buildDataPayload,
  buildMulticastMessage,
  ANDROID_FCM_CHANNEL_ID,
  IOS_APNS_TOPIC,
  GRINTA_PACKAGE_NAME,
  ASERSTEIN_ANDROID_PACKAGE,
  isInvalidTokenError,
  BRAND_GRINTA,
  BRAND_ASERSTEIN,
  GRINTA_ICON_192,
  GRINTA_ICON_512,
  ASERSTEIN_ICON,
  DEFAULT_TIMEZONE,
  PENDING_PUSH_COLLECTION,
  PENDING_PUSH_MAX_DEFER_MS,
  PENDING_PUSH_SCAN_STEP_MS,
};
