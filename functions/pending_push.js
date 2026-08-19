const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const {
  readNonEmptyString,
  normalizeTokenList,
  parseNotificationPreferences,
  evaluatePushPermission,
  computeSendAfter,
  loadUserFcmTokens,
  resolveBrand,
  resolveBrandAssets,
  buildDataPayload,
  buildMulticastMessage,
  isInvalidTokenError,
  BRAND_GRINTA,
  PENDING_PUSH_COLLECTION,
  PENDING_PUSH_MAX_DEFER_MS,
} = require('./send_push_fcm_helpers');

const REGION = 'europe-west1';
const DRAIN_BATCH_SIZE = 50;

async function sendFcmToTokens({
  tokens,
  title,
  body,
  type,
  payload,
  brand,
  clubId,
  icon,
  image,
}) {
  const fcmTokens = normalizeTokenList(tokens);
  if (fcmTokens.length === 0) {
    return {
      total: 0,
      successCount: 0,
      failureCount: 0,
      invalidTokens: [],
    };
  }

  const assets = resolveBrandAssets(brand, { icon, image });
  const dataPayload = buildDataPayload({
    type,
    payload,
    brand,
    icon: assets.icon,
    image: assets.image,
    title,
    body,
    clubId,
  });

  const message = buildMulticastMessage({
    tokens: fcmTokens,
    title,
    body,
    brand,
    assets,
    dataPayload,
  });

  const response = await getMessaging().sendEachForMulticast(message);
  const invalidTokens = [];
  response.responses.forEach((resp, idx) => {
    if (resp.success) return;
    if (isInvalidTokenError(resp.error)) {
      invalidTokens.push(fcmTokens[idx]);
    }
  });

  return {
    total: fcmTokens.length,
    successCount: response.successCount,
    failureCount: response.failureCount,
    invalidTokens,
  };
}

/**
 * Enqueue one pending push per quiet recipient.
 * @returns {Promise<number>} number of docs created
 */
async function enqueueQuietDeferredPushes({
  db,
  quietDeferred,
  clubId,
  brand,
  title,
  body,
  type,
  payload,
  icon,
  image,
  now = new Date(),
}) {
  if (!Array.isArray(quietDeferred) || quietDeferred.length === 0) {
    return 0;
  }

  const batch = db.batch();
  let created = 0;
  const expiresAt = new Date(now.getTime() + PENDING_PUSH_MAX_DEFER_MS);

  for (const entry of quietDeferred) {
    const userId = readNonEmptyString(entry.userId);
    const tokens = normalizeTokenList(entry.tokens);
    if (!userId || tokens.length === 0) continue;

    const sendAfter = computeSendAfter(entry.prefs, now);
    if (!sendAfter) continue;

    const ref = db.collection(PENDING_PUSH_COLLECTION).doc();
    batch.set(ref, {
      recipientUserId: userId,
      fcmTokens: tokens,
      clubId,
      brand,
      title: title || '',
      body: body || '',
      type: type || '',
      payload: payload && typeof payload === 'object' ? payload : {},
      icon: icon || null,
      image: image || null,
      status: 'pending',
      skipReason: 'quiet',
      sendAfter: Timestamp.fromDate(sendAfter),
      expiresAt: Timestamp.fromDate(expiresAt),
      attempts: 0,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    created += 1;
  }

  if (created > 0) {
    await batch.commit();
  }
  return created;
}

async function processPendingPushDoc(db, doc) {
  const data = doc.data() ?? {};
  const now = new Date();
  const userId = readNonEmptyString(data.recipientUserId);
  const expiresAt = data.expiresAt?.toDate?.() ?? null;

  if (!userId) {
    await doc.ref.update({
      status: 'cancelled',
      cancelReason: 'missing_recipient',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 'cancelled';
  }

  if (expiresAt && expiresAt.getTime() <= now.getTime()) {
    await doc.ref.update({
      status: 'expired',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 'expired';
  }

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

  if (!decision.allowed && decision.reason === 'disabled') {
    await doc.ref.update({
      status: 'cancelled',
      cancelReason: 'disabled',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 'cancelled';
  }

  if (!decision.allowed && decision.reason === 'quiet') {
    const sendAfter = computeSendAfter(prefs, now);
    if (!sendAfter) {
      await doc.ref.update({
        status: 'expired',
        cancelReason: 'quiet_window_exceeded',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return 'expired';
    }
    await doc.ref.update({
      sendAfter: Timestamp.fromDate(sendAfter),
      updatedAt: FieldValue.serverTimestamp(),
      attempts: FieldValue.increment(1),
    });
    return 'rescheduled';
  }

  const brand = resolveBrand(data.brand, data.clubId);
  const storedTokens = normalizeTokenList(data.fcmTokens);
  const requested = new Set(storedTokens);
  let tokens = await loadUserFcmTokens(db, userId, brand, requested);
  if (tokens.length === 0) {
    // Fall back to stored tokens if live lookup is empty (e.g. race).
    tokens = storedTokens;
  }
  if (tokens.length === 0) {
    await doc.ref.update({
      status: 'cancelled',
      cancelReason: 'no_tokens',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 'cancelled';
  }

  const clubId = readNonEmptyString(data.clubId) || '0';
  const title = readNonEmptyString(data.title) ?? '';
  const body = readNonEmptyString(data.body) ?? '';
  const type = readNonEmptyString(data.type) ?? '';

  try {
    const result = await sendFcmToTokens({
      tokens,
      title,
      body,
      type,
      payload: data.payload,
      brand,
      clubId,
      icon: data.icon,
      image: data.image,
    });

    await doc.ref.update({
      status: 'sent',
      sentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      attempts: FieldValue.increment(1),
      lastSendSummary: {
        total: result.total,
        successCount: result.successCount,
        failureCount: result.failureCount,
        invalidTokensCount: result.invalidTokens.length,
      },
    });
    return 'sent';
  } catch (error) {
    console.error('[drainPendingPush] send failed', doc.id, error);
    await doc.ref.update({
      attempts: FieldValue.increment(1),
      lastError: error?.message ?? String(error),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return 'error';
  }
}

/**
 * Scheduled: drain due pending_push docs every 5 minutes.
 *
 * Deploy:
 *   firebase deploy --only functions:drainPendingPushNotifications
 */
function createDrainPendingPushNotifications() {
  return onSchedule(
    {
      schedule: 'every 5 minutes',
      region: REGION,
      timeoutSeconds: 120,
    },
    async () => {
      const db = getFirestore();
      const now = Timestamp.now();
      const snap = await db
        .collection(PENDING_PUSH_COLLECTION)
        .where('status', '==', 'pending')
        .where('sendAfter', '<=', now)
        .orderBy('sendAfter', 'asc')
        .limit(DRAIN_BATCH_SIZE)
        .get();

      if (snap.empty) {
        console.log('[drainPendingPush] nothing due');
        return;
      }

      const counts = {
        sent: 0,
        cancelled: 0,
        expired: 0,
        rescheduled: 0,
        error: 0,
      };

      for (const doc of snap.docs) {
        const outcome = await processPendingPushDoc(db, doc);
        counts[outcome] = (counts[outcome] ?? 0) + 1;
      }

      console.log('[drainPendingPush] done', JSON.stringify(counts));
    },
  );
}

module.exports = {
  createDrainPendingPushNotifications,
  enqueueQuietDeferredPushes,
  sendFcmToTokens,
  buildMulticastMessage,
  processPendingPushDoc,
};
