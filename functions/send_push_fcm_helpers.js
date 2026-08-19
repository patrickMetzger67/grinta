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

function normalizeTokenList(raw) {
  if (!Array.isArray(raw)) return [];
  return [
    ...new Set(
      raw
        .map((token) => (token ?? '').toString().trim())
        .filter((token) => token.length > 0),
    ),
  ];
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
}) {
  return {
    tokens,
    notification: {
      title: title || 'Grinta',
      body: body || '',
    },
    data: dataPayload,
    android: {
      priority: 'high',
      // No imageUrl: when the app process is dead, a failed image fetch can
      // drop the entire system-tray notification on Android.
      notification: {
        channelId: ANDROID_FCM_CHANNEL_ID,
        icon: 'ic_notification',
        sound: 'default',
        defaultSound: true,
        visibility: 'public',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          'content-available': 1,
        },
      },
      fcmOptions: {
        imageUrl: assets.image,
      },
    },
    webpush: {
      headers: {
        Urgency: 'high',
      },
      notification: {
        title: title || 'Grinta',
        body: body || '',
        icon: assets.icon,
        image: assets.image,
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

async function loadUserFcmTokens(db, userId, brand, requestedTokens) {
  const tokensRef = db.collection('users').doc(userId).collection('fcmTokens');
  let tokenDocs;
  if (brand === BRAND_GRINTA) {
    const branded = await tokensRef.where('app', '==', BRAND_GRINTA).get();
    if (!branded.empty) {
      tokenDocs = branded.docs;
    } else {
      const all = await tokensRef.get();
      tokenDocs = all.docs.filter((doc) => {
        const app = (doc.data()?.app ?? '').toString().trim();
        return app.length === 0 || app === BRAND_GRINTA;
      });
    }
  } else {
    const all = await tokensRef.get();
    tokenDocs = all.docs;
  }

  const tokens = [];
  for (const doc of tokenDocs) {
    const token = doc.id.trim();
    if (!token) continue;
    if (requestedTokens.size > 0 && !requestedTokens.has(token)) continue;
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
    const userTokens = await loadUserFcmTokens(
      db,
      userId,
      brand,
      requestedTokens,
    );

    if (!decision.allowed) {
      skippedUserIds.push(userId);
      if (decision.reason === 'disabled') {
        skippedDisabled += 1;
        continue;
      }
      if (decision.reason === 'quiet') {
        skippedQuiet += 1;
        if (userTokens.length > 0) {
          quietDeferred.push({
            userId,
            prefs,
            tokens: userTokens,
          });
        }
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
  normalizeUserIdList,
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
