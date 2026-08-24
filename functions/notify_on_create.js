const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const {
  readNonEmptyString,
  normalizeNotifType,
  collectLinkedUserIdsFromMemberData,
  filterTokensByRecipientPreferences,
  shouldHonorReminderPreferences,
  resolveBrand,
  resolveBrandAssets,
  BRAND_GRINTA,
} = require('./send_push_fcm_helpers');
const {
  enqueueQuietDeferredPushes,
  sendFcmToTokens,
} = require('./pending_push');

const REGION = 'europe-west1';
const MEMBER_COLLECTION = 'member';
const DONE_DISPATCH_STATUSES = new Set(['sent', 'skipped', 'deferred']);

/**
 * In-app docs (`notification/{id}`) are the source of truth. Creating one
 * must also deliver an OS/web push — the Flutter client can fail to read
 * other users' tokens or skip the callable after hours calmes.
 *
 * Deploy:
 *   firebase deploy --only functions:sendPushOnNotificationCreated
 */
function createSendPushOnNotificationCreated() {
  return onDocumentCreated(
    {
      document: 'notification/{notificationId}',
      region: REGION,
      timeoutSeconds: 60,
    },
    async (event) => {
      const snap = event.data;
      if (!snap) return;
      await dispatchNotificationPush({
        db: getFirestore(),
        snap,
      });
    },
  );
}

function isPushChannel(sendBy) {
  const value = (sendBy ?? 'SendBy.notification').toString().trim();
  return value === '' || value === 'SendBy.notification';
}

async function loadMemberData(db, playerId) {
  const id = readNonEmptyString(playerId);
  if (!id) return null;

  const direct = await db.collection(MEMBER_COLLECTION).doc(id).get();
  if (direct.exists) return direct.data();

  const query = await db
    .collection(MEMBER_COLLECTION)
    .where('keyMember', '==', id)
    .limit(1)
    .get();
  if (query.empty) return null;
  return query.docs[0].data();
}

async function resolveRecipientUserIds({ db, userId, playerId }) {
  const direct = readNonEmptyString(userId);
  if (direct) return [direct];

  const member = await loadMemberData(db, playerId);
  return collectLinkedUserIdsFromMemberData(member);
}

async function claimDispatch(snap) {
  return snap.ref.firestore.runTransaction(async (tx) => {
    const fresh = await tx.get(snap.ref);
    if (!fresh.exists) return false;
    const status = fresh.data()?.pushDispatch?.status;
    if (DONE_DISPATCH_STATUSES.has(status)) return false;
    tx.update(snap.ref, {
      'pushDispatch.status': 'sending',
      'pushDispatch.claimedAt': FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function markDispatch(snap, fields) {
  const update = {};
  for (const [key, value] of Object.entries(fields)) {
    update[`pushDispatch.${key}`] = value;
  }
  update['pushDispatch.updatedAt'] = FieldValue.serverTimestamp();
  await snap.ref.update(update);
}

async function dispatchNotificationPush({ db, snap }) {
  const data = snap.data() ?? {};
  if (DONE_DISPATCH_STATUSES.has(data.pushDispatch?.status)) {
    return { skipped: true, reason: 'already_dispatched' };
  }

  if (!isPushChannel(data.sendBy)) {
    await markDispatch(snap, { status: 'skipped', reason: 'not_push_channel' });
    return { skipped: true, reason: 'not_push_channel' };
  }

  const type = normalizeNotifType(data.type);
  // Local agenda reminders already use InternalReminderService + the OS
  // scheduler. Do not also FCM them from this trigger.
  if (shouldHonorReminderPreferences(type)) {
    await markDispatch(snap, { status: 'skipped', reason: 'local_reminder' });
    return { skipped: true, reason: 'local_reminder' };
  }

  const claimed = await claimDispatch(snap);
  if (!claimed) {
    return { skipped: true, reason: 'lost_claim' };
  }

  const title = readNonEmptyString(data.title) ?? '';
  const body = readNonEmptyString(data.body) ?? '';
  const clubId = readNonEmptyString(data.clubId) || '0';
  const objectId = readNonEmptyString(data.objectId) ?? snap.id;
  const brand = resolveBrand(BRAND_GRINTA, clubId);
  const assets = resolveBrandAssets(brand);

  const recipientUserIds = await resolveRecipientUserIds({
    db,
    userId: data.userId,
    playerId: data.playerId,
  });

  if (recipientUserIds.length === 0) {
    await markDispatch(snap, { status: 'skipped', reason: 'no_recipient' });
    console.log(
      '[sendPushOnNotificationCreated] no recipient',
      JSON.stringify({ id: snap.id, type, playerId: data.playerId }),
    );
    return { skipped: true, reason: 'no_recipient' };
  }

  const filtered = await filterTokensByRecipientPreferences({
    db,
    recipientUserIds,
    fcmTokens: [],
    brand,
    type,
  });

  const deferredCount = await enqueueQuietDeferredPushes({
    db,
    quietDeferred: filtered.quietDeferred ?? [],
    clubId,
    brand,
    title,
    body,
    type,
    payload: {
      id: objectId,
      type,
      playerId: data.playerId ?? '',
      body,
    },
    icon: assets.icon,
    image: assets.image,
  });

  if (filtered.tokens.length === 0) {
    const status = deferredCount > 0 ? 'deferred' : 'skipped';
    const reason = deferredCount > 0 ? 'quiet' : 'no_tokens';
    await markDispatch(snap, {
      status,
      reason,
      skippedDisabled: filtered.skippedDisabled,
      skippedQuiet: filtered.skippedQuiet,
      deferredCount,
    });
    console.log(
      '[sendPushOnNotificationCreated] no immediate tokens',
      JSON.stringify({
        id: snap.id,
        type,
        recipients: recipientUserIds.length,
        skippedDisabled: filtered.skippedDisabled,
        skippedQuiet: filtered.skippedQuiet,
        deferredCount,
      }),
    );
    return { skipped: true, reason, deferredCount };
  }

  try {
    const result = await sendFcmToTokens({
      tokens: filtered.tokens,
      title,
      body,
      type,
      payload: {
        id: objectId,
        type,
        playerId: data.playerId ?? '',
        body,
      },
      brand,
      clubId,
      icon: assets.icon,
      image: assets.image,
    });

    await markDispatch(snap, {
      status: 'sent',
      reason: null,
      total: result.total,
      successCount: result.successCount,
      failureCount: result.failureCount,
      invalidTokensCount: result.invalidTokens.length,
    });

    console.log(
      '[sendPushOnNotificationCreated]',
      JSON.stringify({
        id: snap.id,
        type,
        total: result.total,
        successCount: result.successCount,
        failureCount: result.failureCount,
      }),
    );

    return {
      skipped: false,
      reason: null,
      total: result.total,
      successCount: result.successCount,
    };
  } catch (error) {
    console.error('[sendPushOnNotificationCreated] send failed', snap.id, error);
    await markDispatch(snap, {
      status: 'failed',
      reason: 'send_error',
      error: error?.message ?? String(error),
    });
    throw error;
  }
}

module.exports = {
  createSendPushOnNotificationCreated,
  dispatchNotificationPush,
  resolveRecipientUserIds,
  collectLinkedUserIdsFromMemberData,
  isPushChannel,
  loadMemberData,
};
