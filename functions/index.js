const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { buildSystemPrompt } = require('./ask_diego_prompt');
const { GEMINI_CHAT_MODEL } = require('./gemini_chat_config');
const {
  createWhoopOAuthStart,
  createWhoopOAuthCallback,
  createWhoopDisconnect,
  createWhoopRepairPlayerSync,
} = require('./whoop_oauth');
const {
  createWhoopListActivities,
  createWhoopImportActivity,
} = require('./whoop_activities');
const {
  createStravaOAuthStart,
  createStravaOAuthCallback,
  createStravaDisconnect,
} = require('./strava_oauth');
const {
  createStravaListActivities,
  createStravaImportActivity,
} = require('./strava_activities');
const {
  createPolarOAuthStart,
  createPolarOAuthCallback,
  createPolarDisconnect,
} = require('./polar_oauth');
const {
  createPolarListActivities,
  createPolarImportActivity,
} = require('./polar_activities');
const {
  createFitbitOAuthStart,
  createFitbitOAuthCallback,
  createFitbitDisconnect,
} = require('./fitbit_oauth');
const { createSendMailOnCreate } = require('./send_mail');
const { createSendPasswordResetMail } = require('./password_reset');
const { createSendPushFCMNotification } = require('./send_push_fcm');
const {
  normalizePromoCode,
  compactPromoCode,
  promoCodeLookupCandidates,
  promoCodesMatch,
} = require('./promo_code_helpers');

initializeApp();

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const revenueCatApiKey = defineSecret('REVENUECAT_API_KEY');

const VALID_ENTITLEMENTS = new Set([
  'player',
  'coach_basic',
  'coach_elite',
  'coach_pro',
]);

const PROMO_CODES_COLLECTION = 'admin_promo_codes';
const REVENUECAT_API_BASE = 'https://api.revenuecat.com/v1';

/**
 * Callable: chatWithGemini
 *
 * Request: { message, history?, context?, locale? }
 * Response: { actions: [{ type, text?, route?, params? }] }
 *
 * Deploy:
 *   firebase functions:secrets:set GEMINI_API_KEY
 *   firebase deploy --only functions:chatWithGemini
 */
exports.chatWithGemini = onCall(
  {
    region: 'europe-west1',
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required.');
    }

    const message = (request.data?.message ?? '').toString().trim();
    if (!message) {
      throw new HttpsError('invalid-argument', 'message is required.');
    }

    const history = Array.isArray(request.data?.history)
      ? request.data.history
      : [];
    const context = request.data?.context ?? {};
    const locale = (request.data?.locale ?? 'fr').toString();

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      throw new HttpsError(
        'failed-precondition',
        'GEMINI_API_KEY secret is not configured.',
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: GEMINI_CHAT_MODEL,
      generationConfig: {
        temperature: 0.4,
        responseMimeType: 'application/json',
      },
      systemInstruction: buildSystemPrompt(),
    });

    const contextBlock = JSON.stringify(
      {
        userId: request.auth.uid,
        locale,
        ...context,
      },
      null,
      2,
    );

    const historyLines = history
      .slice(-10)
      .map((entry) => {
        const role = entry?.role === 'assistant' ? 'Assistant' : 'Utilisateur';
        const text = (entry?.text ?? '').toString().trim();
        return text ? `${role}: ${text}` : null;
      })
      .filter(Boolean)
      .join('\n');

    const prompt = [
      'Contexte application (JSON):',
      contextBlock,
      historyLines ? `\nHistorique récent:\n${historyLines}` : '',
      `\nQuestion utilisateur: ${message}`,
      '\nRéponds avec le JSON des actions.',
    ]
      .filter(Boolean)
      .join('\n');

    try {
      const result = await model.generateContent(prompt);
      const raw = result.response.text();
      const parsed = parseModelResponse(raw);

      return {
        actions: normalizeActions(parsed.actions),
      };
    } catch (error) {
      console.error('chatWithGemini error', error);
      throw new HttpsError(
        'internal',
        'Gemini request failed.',
        error?.message ?? String(error),
      );
    }
  },
);

function parseModelResponse(raw) {
  const trimmed = (raw ?? '').toString().trim();
  if (!trimmed) {
    return { actions: [] };
  }

  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const jsonMatch = trimmed.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    return {
      actions: [{ type: 'answer', text: trimmed }],
    };
  }
}

function normalizeActions(actions) {
  if (!Array.isArray(actions) || actions.length === 0) {
    return [
      {
        type: 'answer',
        text: 'Je n\'ai pas pu formuler de réponse. Réessayez.',
      },
    ];
  }

  const normalized = [];

  for (const action of actions) {
    if (!action || typeof action !== 'object') continue;

    const type = (action.type ?? '').toString().toLowerCase();

    if (type === 'answer') {
      const text = (action.text ?? '').toString().trim();
      if (text) {
        normalized.push({ type: 'answer', text });
      }
      continue;
    }

    if (type === 'navigate') {
      const route = (action.route ?? '').toString().trim();
      if (!route) continue;
      const params =
        action.params && typeof action.params === 'object'
          ? action.params
          : {};
      normalized.push({ type: 'navigate', route, params });
      continue;
    }

    if (type === 'send_report') {
      const params =
        action.params && typeof action.params === 'object'
          ? action.params
          : {};
      normalized.push({ type: 'send_report', params });
    }
  }

  if (!normalized.some((a) => a.type === 'answer')) {
    normalized.unshift({
      type: 'answer',
      text: 'Voici ce que je peux vous proposer.',
    });
  }

  return normalized;
}

function readTimestamp(value) {
  if (!value) return null;
  if (value instanceof Timestamp) return value.toDate();
  if (value.toDate) return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

async function resolvePromoCodeRef(db, normalizedCode) {
  const candidates = promoCodeLookupCandidates(normalizedCode);
  const compactTarget = compactPromoCode(normalizedCode);

  for (const id of candidates) {
    const directRef = db.collection(PROMO_CODES_COLLECTION).doc(id);
    const directSnap = await directRef.get();
    if (directSnap.exists) {
      return directRef;
    }
  }

  for (const code of candidates) {
    const querySnap = await db
      .collection(PROMO_CODES_COLLECTION)
      .where('code', '==', code)
      .limit(1)
      .get();
    if (!querySnap.empty) {
      return querySnap.docs[0].ref;
    }
  }

  // Indexed compact field (written by admin UI) — DEMO-2026 ↔ DEMO2026.
  if (compactTarget) {
    const compactSnap = await db
      .collection(PROMO_CODES_COLLECTION)
      .where('codeCompact', '==', compactTarget)
      .limit(1)
      .get();
    if (!compactSnap.empty) {
      return compactSnap.docs[0].ref;
    }
  }

  // Last resort: small admin collection — match by normalized/compact stored code
  // (covers mixed-case doc ids or codes created outside the admin UI).
  const scanSnap = await db.collection(PROMO_CODES_COLLECTION).limit(500).get();
  for (const doc of scanSnap.docs) {
    const data = doc.data() ?? {};
    const storedRaw = (data.code ?? doc.id ?? '').toString();
    if (promoCodesMatch(storedRaw, normalizedCode)) {
      return doc.ref;
    }
    const storedCompact = (data.codeCompact ?? '').toString();
    if (storedCompact && compactPromoCode(storedCompact) === compactTarget) {
      return doc.ref;
    }
  }

  console.warn('resolvePromoCodeRef: no match', {
    normalizedCode,
    candidates,
    scanned: scanSnap.size,
  });
  return null;
}

/** Client maps [errorCode] in details to localized UI strings. */
function throwPromoError(status, errorCode, message) {
  throw new HttpsError(status, message, { errorCode });
}

function validatePromoData(data) {
  if (data.active === false) {
    throwPromoError(
      'failed-precondition',
      'PROMO_INACTIVE',
      'Promo code is inactive.',
    );
  }

  const expiresAt = readTimestamp(data.expiresAt);
  if (expiresAt && expiresAt.getTime() < Date.now()) {
    throwPromoError(
      'failed-precondition',
      'PROMO_EXPIRED',
      'Promo code has expired.',
    );
  }

  const maxUses = Number(data.maxUses ?? 0);
  const usedCount = Number(data.usedCount ?? 0);
  if (maxUses < 1 || usedCount >= maxUses) {
    throwPromoError(
      'resource-exhausted',
      'PROMO_EXHAUSTED',
      'Promo code is exhausted.',
    );
  }

  const entitlement = (data.entitlement ?? '').toString();
  if (!VALID_ENTITLEMENTS.has(entitlement)) {
    throwPromoError(
      'failed-precondition',
      'PROMO_INVALID',
      'Invalid promo entitlement.',
    );
  }

  const durationDays = Number(data.durationDays ?? 0);
  if (durationDays < 1) {
    throwPromoError(
      'failed-precondition',
      'PROMO_INVALID',
      'Invalid promo duration.',
    );
  }

  return { entitlement, durationDays, maxUses, usedCount };
}

async function collectUserMemberIds(db, uid) {
  const memberSnap = await db
    .collection('member')
    .where('users', 'array-contains', uid)
    .limit(20)
    .get();

  const memberIds = new Set();
  for (const doc of memberSnap.docs) {
    memberIds.add(doc.id);
    const keyMember = (doc.data()?.keyMember ?? '').toString().trim();
    if (keyMember) {
      memberIds.add(keyMember);
    }
  }
  return memberIds;
}

async function userBelongsToTeam(db, uid, teamId) {
  const teamSnap = await db.collection('team').doc(teamId).get();
  if (!teamSnap.exists) {
    return false;
  }

  const teamData = teamSnap.data() ?? {};
  const teamUsers = Array.isArray(teamData.users) ? teamData.users : [];
  if (teamUsers.some((entry) => String(entry) === uid)) {
    return true;
  }

  const userMemberIds = await collectUserMemberIds(db, uid);
  if (userMemberIds.size === 0) {
    return false;
  }

  const memberIds = Array.isArray(teamData.grintaPlayerMemberIds)
    ? teamData.grintaPlayerMemberIds
    : [];
  if (memberIds.some((entry) => userMemberIds.has(String(entry).trim()))) {
    return true;
  }

  const grintaPlayers = Array.isArray(teamData.grintaPlayers)
    ? teamData.grintaPlayers
    : [];
  return grintaPlayers.some((entry) => {
    const playerId = (entry?.playerId ?? entry?.playerID ?? '').toString().trim();
    return playerId && userMemberIds.has(playerId);
  });
}

function readRevenueCatEntitlementExpiry(entitlement) {
  if (!entitlement || typeof entitlement !== 'object') {
    return null;
  }

  const raw =
    entitlement.expires_date ??
    entitlement.expiresDate ??
    entitlement.grace_period_expires_date ??
    entitlement.gracePeriodExpiresDate ??
    null;
  if (!raw) return null;

  const parsed = new Date(raw);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function extractGrantedEntitlement(subscriber, entitlementId) {
  const entitlements = subscriber?.entitlements;
  if (!entitlements || typeof entitlements !== 'object') {
    return null;
  }
  return entitlements[entitlementId] ?? null;
}

async function grantPromotionalEntitlement(appUserId, entitlementId, durationDays) {
  const apiKey = revenueCatApiKey.value();
  if (!apiKey) {
    // Must carry errorCode — bare failed-precondition must never look like an invalid promo.
    throwPromoError(
      'failed-precondition',
      'PROMO_RC_NOT_CONFIGURED',
      'REVENUECAT_API_KEY secret is not configured.',
    );
  }

  const endTimeMs = Date.now() + durationDays * 24 * 60 * 60 * 1000;
  const url = `${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(appUserId)}/entitlements/${encodeURIComponent(entitlementId)}/promotional`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ end_time_ms: endTimeMs }),
  });

  const body = await response.text();

  if (!response.ok) {
    console.error('RevenueCat promotional grant failed', response.status, body);
    let detail = body.trim();
    try {
      const parsed = JSON.parse(body);
      detail =
        parsed?.message ??
        parsed?.error?.message ??
        parsed?.error ??
        detail;
    } catch (_) {
      // Keep raw body.
    }

    if (response.status === 401 || response.status === 403) {
      throwPromoError(
        'failed-precondition',
        'PROMO_RC_KEY_REJECTED',
        `RevenueCat API key rejected (${response.status}). Check REVENUECAT_API_KEY secret matches the same RC project as the app SDK keys.`,
      );
    }
    if (response.status === 404) {
      throwPromoError(
        'failed-precondition',
        'PROMO_RC_ENTITLEMENT_MISSING',
        `RevenueCat entitlement "${entitlementId}" was not found. Check RevenueCat dashboard identifiers.`,
      );
    }

    throwPromoError(
      'internal',
      'PROMO_GRANT_FAILED',
      `RevenueCat grant failed (${response.status}): ${detail || 'unknown error'}`,
    );
  }

  let parsed;
  try {
    parsed = body ? JSON.parse(body) : null;
  } catch (_) {
    parsed = null;
  }

  const subscriber = parsed?.subscriber ?? parsed;
  const granted = extractGrantedEntitlement(subscriber, entitlementId);
  const expiresAt = readRevenueCatEntitlementExpiry(granted);

  if (!granted) {
    console.error(
      'RevenueCat grant HTTP OK but entitlement missing in response',
      { appUserId, entitlementId, body },
    );
    throwPromoError(
      'internal',
      'PROMO_GRANT_FAILED',
      `RevenueCat grant did not activate entitlement "${entitlementId}".`,
    );
  }

  if (expiresAt && expiresAt.getTime() <= Date.now()) {
    throwPromoError(
      'internal',
      'PROMO_GRANT_FAILED',
      `RevenueCat grant returned an already-expired entitlement "${entitlementId}".`,
    );
  }

  console.log('RevenueCat promotional grant OK', {
    appUserId,
    entitlementId,
    durationDays,
    expiresAt: expiresAt ? expiresAt.toISOString() : null,
  });

  return {
    expiresAt: expiresAt ? expiresAt.toISOString() : null,
  };
}

/**
 * Callable: redeemPromoCode
 *
 * Request: { code }
 * Response: { entitlement, durationDays, expiresAt? }
 *
 * Deploy:
 *   firebase functions:secrets:set REVENUECAT_API_KEY
 *   firebase deploy --only functions:redeemPromoCode
 */
exports.redeemPromoCode = onCall(
  {
    region: 'europe-west1',
    secrets: [revenueCatApiKey],
    timeoutSeconds: 30,
  },
  async (request) => {
    if (!request.auth) {
      throwPromoError(
        'unauthenticated',
        'PROMO_UNAUTHENTICATED',
        'Authentication required.',
      );
    }

    const code = normalizePromoCode(request.data?.code);
    if (!code || code.length < 4) {
      throwPromoError(
        'invalid-argument',
        'PROMO_EMPTY',
        'code is required.',
      );
    }

    const db = getFirestore();
    const uid = request.auth.uid;

    const promoRef = await resolvePromoCodeRef(db, code);
    if (!promoRef) {
      throwPromoError(
        'not-found',
        'PROMO_NOT_FOUND',
        `Promo code "${code}" not found.`,
      );
    }

    const promoSnap = await promoRef.get();
    const data = promoSnap.data() ?? {};
    const { entitlement, durationDays } = validatePromoData(data);

    const teamId = (data.teamId ?? '').toString().trim();
    if (teamId) {
      const belongsToTeam = await userBelongsToTeam(db, uid, teamId);
      if (!belongsToTeam) {
        throwPromoError(
          'permission-denied',
          'PROMO_TEAM_MISMATCH',
          'Promo code is restricted to a specific club.',
        );
      }
    }

    const redemptionRef = promoRef.collection('redemptions').doc(uid);
    const redemptionSnap = await redemptionRef.get();
    if (redemptionSnap.exists) {
      throwPromoError(
        'failed-precondition',
        'ALREADY_REDEEMED',
        'You have already redeemed this promo code.',
      );
    }

    const grant = await grantPromotionalEntitlement(uid, entitlement, durationDays);

    await db.runTransaction(async (transaction) => {
      const latestPromoSnap = await transaction.get(promoRef);
      if (!latestPromoSnap.exists) {
        throwPromoError(
          'not-found',
          'PROMO_NOT_FOUND',
          `Promo code "${code}" not found.`,
        );
      }

      validatePromoData(latestPromoSnap.data() ?? {});

      const latestRedemptionSnap = await transaction.get(redemptionRef);
      if (latestRedemptionSnap.exists) {
        throwPromoError(
          'failed-precondition',
          'ALREADY_REDEEMED',
          'You have already redeemed this promo code.',
        );
      }

      transaction.update(promoRef, {
        usedCount: FieldValue.increment(1),
      });
      transaction.set(redemptionRef, {
        uid,
        redeemedAt: FieldValue.serverTimestamp(),
      });
    });

    // Mirror access outside the promo transaction so a user-doc write failure
    // never blocks / rolls back a successful redeem.
    try {
      const access = {
        entitlements: [entitlement],
        productId: null,
        source: 'promo',
        updatedAt: FieldValue.serverTimestamp(),
        expiresAt: grant.expiresAt
          ? Timestamp.fromDate(new Date(grant.expiresAt))
          : null,
      };
      await db.collection('users').doc(uid).set(
        {subscriptionAccess: access},
        {merge: true},
      );
    } catch (mirrorError) {
      console.error('redeemPromoCode: subscriptionAccess mirror failed', {
        uid,
        code,
        mirrorError,
      });
    }

    console.log('redeemPromoCode success', {
      uid,
      code,
      entitlement,
      durationDays,
      expiresAt: grant.expiresAt,
    });

    return {
      entitlement,
      durationDays,
      expiresAt: grant.expiresAt,
    };
  },
);

/**
 * Whoop OAuth + workout import.
 *
 * Deploy:
 *   firebase functions:secrets:set WHOOP_CLIENT_ID
 *   firebase functions:secrets:set WHOOP_CLIENT_SECRET
 *   firebase deploy --only functions:whoopOAuthStart,functions:whoopOAuthCallback,functions:whoopDisconnect,functions:whoopRepairPlayerSync,functions:whoopListActivities,functions:whoopImportActivity
 */
exports.whoopOAuthStart = createWhoopOAuthStart();
exports.whoopOAuthCallback = createWhoopOAuthCallback();
exports.whoopDisconnect = createWhoopDisconnect();
exports.whoopRepairPlayerSync = createWhoopRepairPlayerSync();
exports.whoopListActivities = createWhoopListActivities();
exports.whoopImportActivity = createWhoopImportActivity();

/**
 * Strava OAuth (Phase 1 scaffolding).
 *
 * Deploy:
 *   firebase functions:secrets:set STRAVA_CLIENT_ID
 *   firebase functions:secrets:set STRAVA_CLIENT_SECRET
 *   firebase deploy --only functions:stravaOAuthStart,functions:stravaOAuthCallback,functions:stravaDisconnect
 */
exports.stravaOAuthStart = createStravaOAuthStart();
exports.stravaOAuthCallback = createStravaOAuthCallback();
exports.stravaDisconnect = createStravaDisconnect();
exports.stravaListActivities = createStravaListActivities();
exports.stravaImportActivity = createStravaImportActivity();

/**
 * Polar AccessLink OAuth + exercise import (Verity Sense, Loop, watches via Flow).
 *
 * Deploy:
 *   firebase functions:secrets:set POLAR_CLIENT_ID
 *   firebase functions:secrets:set POLAR_CLIENT_SECRET
 *   firebase deploy --only functions:polarOAuthStart,functions:polarOAuthCallback,functions:polarDisconnect,functions:polarListActivities,functions:polarImportActivity
 */
exports.polarOAuthStart = createPolarOAuthStart();
exports.polarOAuthCallback = createPolarOAuthCallback();
exports.polarDisconnect = createPolarDisconnect();
exports.polarListActivities = createPolarListActivities();
exports.polarImportActivity = createPolarImportActivity();

/**
 * Fitbit Web API OAuth (Phase 1 scaffolding).
 *
 * Deploy:
 *   firebase functions:secrets:set FITBIT_CLIENT_ID
 *   firebase functions:secrets:set FITBIT_CLIENT_SECRET
 *   firebase deploy --only functions:fitbitOAuthStart,functions:fitbitOAuthCallback,functions:fitbitDisconnect
 */
exports.fitbitOAuthStart = createFitbitOAuthStart();
exports.fitbitOAuthCallback = createFitbitOAuthCallback();
exports.fitbitDisconnect = createFitbitDisconnect();

/**
 * Firestore trigger: send queued mail documents via SendGrid.
 *
 * Deploy:
 *   firebase functions:secrets:set SENDGRID_API_KEY
 *   firebase deploy --only functions:sendMailOnCreate
 */
exports.sendMailOnCreate = createSendMailOnCreate();
exports.sendPasswordResetMail = createSendPasswordResetMail();

/**
 * FCM push (Grinta + Aserstein dual-brand, shared project).
 *
 * Grinta clients always pass `brand: "grinta"` and typically `clubId: "0"`.
 * Icons: https://grinta.web.app/icons/Icon-192.png (and 512).
 *
 * Deploy:
 *   firebase deploy --only functions:sendPushFCMNotification
 */
exports.sendPushFCMNotification = createSendPushFCMNotification();
