const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const {
  metaAppId,
  metaAppSecret,
  GRAPH_BASE,
  INTEGRATIONS_COLLECTION,
  graphGetJson,
} = require('./meta_graph');
const {
  SHARE_COLLECTION,
  SHARE_SCORE_COLLECTION,
  SHARE_FIELDS,
} = require('./sync_share_insights');

const REGION = 'europe-west1';
const SHARE_POINTS = 10;
const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const CONTAINER_POLL_MS = 2000;
const CONTAINER_POLL_ATTEMPTS = 10;

function decodePngBase64(raw) {
  const text = (raw ?? '').toString().trim();
  if (!text) {
    throw new HttpsError('invalid-argument', 'imageBase64 is required.');
  }
  const stripped = text.replace(/^data:image\/\w+;base64,/, '');
  const buffer = Buffer.from(stripped, 'base64');
  if (!buffer.length) {
    throw new HttpsError('invalid-argument', 'imageBase64 is empty.');
  }
  if (buffer.length > MAX_IMAGE_BYTES) {
    throw new HttpsError('invalid-argument', 'Image is too large.');
  }
  return buffer;
}

async function uploadSharePng(uid, buffer) {
  const path = `share_publish/${uid}/${Date.now()}.png`;
  const file = getStorage().bucket().file(path);
  await file.save(buffer, {
    contentType: 'image/png',
    resumable: false,
    metadata: { cacheControl: 'public,max-age=3600' },
  });
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000,
  });
  return { path, url };
}

async function graphPostJson(url, body, fetchImpl = fetch) {
  const response = await fetchImpl(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(body).toString(),
  });
  const raw = await response.text();
  let parsed = null;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch {
    parsed = null;
  }
  return { ok: response.ok, status: response.status, parsed, raw };
}

async function waitForIgContainer(creationId, pageToken, fetchImpl) {
  for (let i = 0; i < CONTAINER_POLL_ATTEMPTS; i += 1) {
    const params = new URLSearchParams({
      fields: 'status_code,status',
      access_token: pageToken,
    });
    const result = await graphGetJson(
      `${GRAPH_BASE}/${encodeURIComponent(creationId)}?${params}`,
      fetchImpl,
    );
    const status = (result.parsed?.status_code ?? '').toString().toUpperCase();
    if (status === 'FINISHED' || status === 'PUBLISHED') return;
    if (status === 'ERROR' || status === 'EXPIRED') {
      throw new HttpsError(
        'internal',
        result.parsed?.status || 'Instagram media container failed.',
      );
    }
    await new Promise((resolve) => setTimeout(resolve, CONTAINER_POLL_MS));
  }
}

async function publishInstagram({ igUserId, pageToken, imageUrl, caption, fetchImpl }) {
  const create = await graphPostJson(
    `${GRAPH_BASE}/${encodeURIComponent(igUserId)}/media`,
    {
      image_url: imageUrl,
      caption: caption || '',
      access_token: pageToken,
    },
    fetchImpl,
  );
  const creationId = (create.parsed?.id ?? '').toString().trim();
  if (!create.ok || !creationId) {
    throw new HttpsError(
      'internal',
      create.parsed?.error?.message ||
        `Instagram media container failed (${create.status}).`,
    );
  }

  await waitForIgContainer(creationId, pageToken, fetchImpl);

  const publish = await graphPostJson(
    `${GRAPH_BASE}/${encodeURIComponent(igUserId)}/media_publish`,
    {
      creation_id: creationId,
      access_token: pageToken,
    },
    fetchImpl,
  );
  const mediaId = (publish.parsed?.id ?? '').toString().trim();
  if (!publish.ok || !mediaId) {
    throw new HttpsError(
      'internal',
      publish.parsed?.error?.message ||
        `Instagram publish failed (${publish.status}).`,
    );
  }

  const permalinkParams = new URLSearchParams({
    fields: 'permalink',
    access_token: pageToken,
  });
  const permalink = await graphGetJson(
    `${GRAPH_BASE}/${encodeURIComponent(mediaId)}?${permalinkParams}`,
    fetchImpl,
  );
  return {
    platformShareId: mediaId,
    postUrl: (permalink.parsed?.permalink ?? '').toString().trim() || null,
  };
}

async function publishFacebookPage({ pageId, pageToken, imageUrl, caption, fetchImpl }) {
  const posted = await graphPostJson(
    `${GRAPH_BASE}/${encodeURIComponent(pageId)}/photos`,
    {
      url: imageUrl,
      caption: caption || '',
      published: 'true',
      access_token: pageToken,
    },
    fetchImpl,
  );
  const postId = (
    posted.parsed?.post_id ??
    posted.parsed?.id ??
    ''
  )
    .toString()
    .trim();
  if (!posted.ok || !postId) {
    throw new HttpsError(
      'internal',
      posted.parsed?.error?.message ||
        `Facebook Page photo failed (${posted.status}).`,
    );
  }
  return {
    platformShareId: postId,
    postUrl: `https://www.facebook.com/${postId}`,
  };
}

async function writeShareAndScore(db, { uid, where, platformShareId, postUrl, statId, statType }) {
  const shareRef = db.collection(SHARE_COLLECTION).doc();
  const scoreRef = db.collection(SHARE_SCORE_COLLECTION).doc(uid);
  await db.runTransaction(async (transaction) => {
    const scoreSnap = await transaction.get(scoreRef);
    transaction.set(shareRef, {
      [SHARE_FIELDS.userId]: uid,
      [SHARE_FIELDS.shareAt]: FieldValue.serverTimestamp(),
      [SHARE_FIELDS.where]: where,
      [SHARE_FIELDS.platformShareId]: platformShareId,
      [SHARE_FIELDS.statId]: statId,
      [SHARE_FIELDS.statType]: statType,
      [SHARE_FIELDS.status]: 'shared',
      [SHARE_FIELDS.views]: 0,
      [SHARE_FIELDS.interactions]: 0,
      ...(postUrl ? { [SHARE_FIELDS.postUrl]: postUrl } : {}),
    });
    if (!scoreSnap.exists) {
      transaction.set(scoreRef, {
        userId: uid,
        shareCount: 1,
        sharePoints: SHARE_POINTS,
        views: 0,
        interactions: 0,
        viewPoints: 0,
        interactionPoints: 0,
        totalPoints: SHARE_POINTS,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return;
    }
    transaction.update(scoreRef, {
      shareCount: FieldValue.increment(1),
      sharePoints: FieldValue.increment(SHARE_POINTS),
      totalPoints: FieldValue.increment(SHARE_POINTS),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

/**
 * Callable: publishShareToMeta
 *
 * Used only when the user already connected IG/FB. Tokens stay server-side.
 */
function createPublishShareToMeta() {
  return onCall(
    {
      region: REGION,
      secrets: [metaAppId, metaAppSecret],
      timeoutSeconds: 60,
      memory: '512MiB',
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const platform = (request.data?.platform ?? '').toString().trim().toLowerCase();
      if (platform !== 'instagram' && platform !== 'facebook') {
        throw new HttpsError(
          'invalid-argument',
          'platform must be "instagram" or "facebook".',
        );
      }

      const statId = (request.data?.statId ?? '').toString().trim();
      const statType = (request.data?.statType ?? '').toString().trim();
      if (!statId || !statType) {
        throw new HttpsError('invalid-argument', 'statId and statType are required.');
      }

      const caption = (request.data?.caption ?? '').toString();
      const png = decodePngBase64(request.data?.imageBase64);

      const db = getFirestore();
      const uid = request.auth.uid;
      const integrationSnap = await db
        .collection(INTEGRATIONS_COLLECTION)
        .doc(uid)
        .get();
      const integration = integrationSnap.data() ?? {};
      if (!integrationSnap.exists || integration.status !== 'connected') {
        throw new HttpsError(
          'failed-precondition',
          'Meta is not connected. Use the native share sheet.',
        );
      }

      const pageToken = (integration.tokens?.pageAccessToken ?? '').toString().trim();
      const pageId = (integration.pageId ?? '').toString().trim();
      const igUserId = (integration.instagramBusinessAccountId ?? '')
        .toString()
        .trim();
      if (!pageToken) {
        throw new HttpsError(
          'failed-precondition',
          'Stored Meta Page token is missing. Reconnect Instagram / Facebook.',
        );
      }
      if (platform === 'instagram' && !igUserId) {
        throw new HttpsError(
          'failed-precondition',
          'No Instagram Business account on the connected Page.',
        );
      }
      if (platform === 'facebook' && !pageId) {
        throw new HttpsError(
          'failed-precondition',
          'No Facebook Page on the connected account.',
        );
      }

      const uploaded = await uploadSharePng(uid, png);
      let published;
      if (platform === 'instagram') {
        published = await publishInstagram({
          igUserId,
          pageToken,
          imageUrl: uploaded.url,
          caption,
        });
      } else {
        published = await publishFacebookPage({
          pageId,
          pageToken,
          imageUrl: uploaded.url,
          caption,
        });
      }

      await writeShareAndScore(db, {
        uid,
        where: platform,
        platformShareId: published.platformShareId,
        postUrl: published.postUrl,
        statId,
        statType,
      });

      return {
        where: platform,
        platformShareId: published.platformShareId,
        postUrl: published.postUrl,
      };
    },
  );
}

module.exports = {
  createPublishShareToMeta,
  decodePngBase64,
  SHARE_POINTS,
};
