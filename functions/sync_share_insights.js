const { onSchedule } = require('firebase-functions/v2/scheduler');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const {
  metaAppId,
  metaAppSecret,
  INTEGRATIONS_COLLECTION,
  looksLikeMetaPlatformShareId,
  fetchMetaGraphInsights,
  refreshLongLivedUserToken,
} = require('./meta_graph');

const REGION = 'europe-west1';
const SHARE_COLLECTION = 'share';
const SHARE_SCORE_COLLECTION = 'shareScore';
const POINTS_PER_VIEW = 1;
const POINTS_PER_INTERACTION = 2;
const BATCH_LIMIT = 50;

/** Field names — keep in sync with lib/model/share.dart */
const SHARE_FIELDS = Object.freeze({
  userId: 'userId',
  shareAt: 'shareAt',
  where: 'where',
  platformShareId: 'platformShareId',
  statId: 'statId',
  statType: 'statType',
  status: 'status',
  views: 'views',
  interactions: 'interactions',
  lastSyncedAt: 'lastSyncedAt',
  postUrl: 'postUrl',
  error: 'error',
});

/**
 * Placeholder for share-sheet receipts (WhatsApp, Snapchat, activity types).
 * Snapchat: out of scope — no official insights API for this product slice.
 *
 * @param {{ where?: string, platformShareId?: string, postUrl?: string }} share
 * @returns {{ views: number, interactions: number, postUrl: string|null, skipped: boolean }}
 */
function fetchShareInsightsPlaceholder(share) {
  const platformShareId = (share[SHARE_FIELDS.platformShareId] ?? '')
    .toString()
    .trim();
  const postUrl = (share[SHARE_FIELDS.postUrl] ?? '').toString().trim();
  if (!platformShareId && !postUrl) {
    return { views: 0, interactions: 0, postUrl: null, skipped: true };
  }

  // Share-sheet activity ids are not Graph media ids — no insights.
  return {
    views: Number(share[SHARE_FIELDS.views] ?? 0),
    interactions: Number(share[SHARE_FIELDS.interactions] ?? 0),
    postUrl: postUrl || null,
    skipped: true,
  };
}

function shareInsightFields(share) {
  return {
    userId: (share[SHARE_FIELDS.userId] ?? '').toString().trim(),
    where: (share[SHARE_FIELDS.where] ?? '').toString().trim(),
    platformShareId: (share[SHARE_FIELDS.platformShareId] ?? '').toString().trim(),
    postUrl: (share[SHARE_FIELDS.postUrl] ?? '').toString().trim() || null,
    views: share[SHARE_FIELDS.views],
    interactions: share[SHARE_FIELDS.interactions],
  };
}

async function loadPageAccessToken(db, userId) {
  if (!userId) return null;
  const snap = await db.collection(INTEGRATIONS_COLLECTION).doc(userId).get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};
  if ((data.status ?? '') !== 'connected') return null;
  const pageToken = (data.tokens?.pageAccessToken ?? '').toString().trim();
  const userToken = (data.tokens?.userAccessToken ?? '').toString().trim();
  const expiresAt = data.tokens?.expiresAt?.toDate?.() ?? null;
  const expired = expiresAt && expiresAt.getTime() < Date.now();
  if (expired && userToken) {
    const refreshed = await refreshLongLivedUserToken(userToken);
    if (refreshed.refreshed && refreshed.accessToken) {
      await snap.ref.set(
        {
          tokens: {
            ...(data.tokens ?? {}),
            userAccessToken: refreshed.accessToken,
          },
        },
        { merge: true },
      );
    }
  }
  return pageToken || null;
}

/**
 * Graph insights when `platformShareId` looks like a Meta media/post id.
 * Otherwise leave counts unchanged (share sheet / WhatsApp / Snap).
 */
async function fetchShareInsights(share, options = {}) {
  const fields = shareInsightFields(share);
  if (!looksLikeMetaPlatformShareId(fields.platformShareId, fields.where)) {
    return fetchShareInsightsPlaceholder(share);
  }

  const pageAccessToken =
    options.pageAccessToken ??
    (options.db ? await loadPageAccessToken(options.db, fields.userId) : null);

  return fetchMetaGraphInsights(fields, {
    fetchImpl: options.fetchImpl,
    pageAccessToken,
  });
}

/**
 * Delta + score fields to write on `share` and roll up to `shareScore`.
 */
function computeInsightsDelta(current, next) {
  const prevViews = Number(current[SHARE_FIELDS.views] ?? 0);
  const prevInteractions = Number(current[SHARE_FIELDS.interactions] ?? 0);
  const views = Math.max(prevViews, Number(next[SHARE_FIELDS.views] ?? next.views ?? 0));
  const interactions = Math.max(
    prevInteractions,
    Number(next[SHARE_FIELDS.interactions] ?? next.interactions ?? 0),
  );
  const viewDelta = views - prevViews;
  const interactionDelta = interactions - prevInteractions;
  return {
    views,
    interactions,
    viewDelta,
    interactionDelta,
    viewPointsDelta: viewDelta * POINTS_PER_VIEW,
    interactionPointsDelta: interactionDelta * POINTS_PER_INTERACTION,
    postUrl:
      next[SHARE_FIELDS.postUrl] ??
      next.postUrl ??
      current[SHARE_FIELDS.postUrl] ??
      current.postUrl ??
      null,
  };
}

function shareScoreInsightsIncrement(delta) {
  const totalDelta = delta.viewPointsDelta + delta.interactionPointsDelta;
  return {
    views: FieldValue.increment(delta.viewDelta),
    interactions: FieldValue.increment(delta.interactionDelta),
    viewPoints: FieldValue.increment(delta.viewPointsDelta),
    interactionPoints: FieldValue.increment(delta.interactionPointsDelta),
    totalPoints: FieldValue.increment(totalDelta),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/**
 * Daily worker that will fill `views` / `interactions` on `share` docs.
 *
 * Deploy:
 *   firebase deploy --only functions:syncShareInsights
 */
function createSyncShareInsights() {
  return onSchedule(
    {
      schedule: '15 4 * * *',
      timeZone: 'Europe/Paris',
      region: REGION,
      timeoutSeconds: 120,
      secrets: [metaAppId, metaAppSecret],
    },
    async () => {
      const db = getFirestore();
      const snap = await db
        .collection(SHARE_COLLECTION)
        .where(SHARE_FIELDS.status, '==', 'shared')
        .limit(BATCH_LIMIT)
        .get();

      let updated = 0;
      let skipped = 0;

      for (const doc of snap.docs) {
        const data = doc.data() ?? {};
        const insights = await fetchShareInsights(data, { db });
        if (insights.skipped) {
          skipped += 1;
          continue;
        }

        const delta = computeInsightsDelta(data, insights);
        if (delta.viewDelta === 0 && delta.interactionDelta === 0) {
          skipped += 1;
          continue;
        }

        const userId = (data[SHARE_FIELDS.userId] ?? '').toString().trim();
        const batch = db.batch();
        batch.update(doc.ref, {
          [SHARE_FIELDS.views]: delta.views,
          [SHARE_FIELDS.interactions]: delta.interactions,
          [SHARE_FIELDS.postUrl]: delta.postUrl,
          [SHARE_FIELDS.lastSyncedAt]: FieldValue.serverTimestamp(),
          [SHARE_FIELDS.error]: null,
        });
        if (userId) {
          batch.set(
            db.collection(SHARE_SCORE_COLLECTION).doc(userId),
            shareScoreInsightsIncrement(delta),
            { merge: true },
          );
        }
        await batch.commit();
        updated += 1;
      }

      console.log(
        `syncShareInsights: scanned=${snap.size} updated=${updated} ` +
          `skipped=${skipped}`,
      );
    },
  );
}

module.exports = {
  SHARE_COLLECTION,
  SHARE_SCORE_COLLECTION,
  SHARE_FIELDS,
  POINTS_PER_VIEW,
  POINTS_PER_INTERACTION,
  fetchShareInsightsPlaceholder,
  fetchShareInsights,
  computeInsightsDelta,
  shareScoreInsightsIncrement,
  createSyncShareInsights,
};
