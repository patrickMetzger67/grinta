const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const {
  metaAppId,
  metaAppSecret,
  GRAPH_BASE,
  FACEBOOK_DIALOG_URL,
  META_SCOPES,
  INTEGRATIONS_COLLECTION,
  PENDING_COLLECTION,
  META_SYNC_COLLECTION,
  META_SYNC_DOC_ID,
  readMetaAppCredentials,
  graphGetJson,
} = require('./meta_graph');

const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

function metaCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/metaOAuthCallback`;
}

function redirectToApp(res, params) {
  const query = new URLSearchParams(params).toString();
  res.redirect(302, `grinta://meta/callback?${query}`);
}

async function exchangeAuthorizationCode(code, fetchImpl = fetch) {
  const { appId, appSecret } = readMetaAppCredentials();
  if (!appId || !appSecret) {
    throw new HttpsError(
      'failed-precondition',
      'TODO: set META_APP_ID and META_APP_SECRET (Firebase secrets / env).',
    );
  }

  const params = new URLSearchParams({
    client_id: appId,
    client_secret: appSecret,
    redirect_uri: metaCallbackRedirectUri(),
    code,
  });
  const result = await graphGetJson(
    `${GRAPH_BASE}/oauth/access_token?${params}`,
    fetchImpl,
  );
  const accessToken = (result.parsed?.access_token ?? '').toString().trim();
  if (!result.ok || !accessToken) {
    throw new HttpsError(
      'internal',
      result.parsed?.error?.message ||
        `Meta token exchange failed (${result.status}).`,
    );
  }
  return result.parsed;
}

async function exchangeLongLivedUserToken(shortLivedToken, fetchImpl = fetch) {
  const { appId, appSecret } = readMetaAppCredentials();
  const params = new URLSearchParams({
    grant_type: 'fb_exchange_token',
    client_id: appId,
    client_secret: appSecret,
    fb_exchange_token: shortLivedToken,
  });
  const result = await graphGetJson(
    `${GRAPH_BASE}/oauth/access_token?${params}`,
    fetchImpl,
  );
  const accessToken = (result.parsed?.access_token ?? '').toString().trim();
  if (!result.ok || !accessToken) {
    throw new HttpsError(
      'internal',
      result.parsed?.error?.message ||
        `Meta long-lived token exchange failed (${result.status}).`,
    );
  }
  return result.parsed;
}

function pickBestPage(pages) {
  const list = Array.isArray(pages) ? pages : [];
  const withIg = list.find((page) => page?.instagram_business_account?.id);
  return withIg || list[0] || null;
}

async function loadPages(userToken, fetchImpl = fetch) {
  const params = new URLSearchParams({
    fields: 'id,name,access_token,instagram_business_account{id,username}',
    access_token: userToken,
  });
  const result = await graphGetJson(
    `${GRAPH_BASE}/me/accounts?${params}`,
    fetchImpl,
  );
  if (!result.ok) {
    throw new HttpsError(
      'internal',
      result.parsed?.error?.message ||
        `Meta /me/accounts failed (${result.status}).`,
    );
  }
  return Array.isArray(result.parsed?.data) ? result.parsed.data : [];
}

async function persistMetaConnection(db, uid, tokenResponse, pages) {
  const userAccessToken = (tokenResponse?.access_token ?? '').toString();
  if (!userAccessToken) {
    throw new HttpsError('internal', 'Meta user token missing.');
  }

  const page = pickBestPage(pages);
  if (!page?.id || !page?.access_token) {
    throw new HttpsError(
      'failed-precondition',
      'No Facebook Page found. Connect a Page (and Instagram Business if you want IG publish).',
    );
  }

  const ig = page.instagram_business_account ?? {};
  const igId = (ig.id ?? '').toString().trim() || null;
  const igUsername = (ig.username ?? '').toString().trim() || null;
  const expiresIn = Number(tokenResponse?.expires_in ?? 0);
  const expiresAt =
    Number.isFinite(expiresIn) && expiresIn > 0
      ? new Date(Date.now() + expiresIn * 1000)
      : null;

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(uid);
  const syncRef = db
    .collection('users')
    .doc(uid)
    .collection(META_SYNC_COLLECTION)
    .doc(META_SYNC_DOC_ID);

  await db.runTransaction(async (transaction) => {
    transaction.set(
      integrationRef,
      {
        uid,
        status: 'connected',
        pageId: String(page.id),
        pageName: (page.name ?? '').toString() || null,
        instagramBusinessAccountId: igId,
        instagramUsername: igUsername,
        tokens: {
          userAccessToken,
          pageAccessToken: String(page.access_token),
          expiresAt,
          tokenType: (tokenResponse?.token_type ?? 'Bearer').toString(),
        },
        scopes: META_SCOPES.split(','),
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    transaction.set(
      syncRef,
      {
        connected: true,
        connectedAt: FieldValue.serverTimestamp(),
        pageId: String(page.id),
        pageName: (page.name ?? '').toString() || null,
        instagramUsername: igUsername,
        hasInstagram: Boolean(igId),
        hasFacebookPage: true,
      },
      { merge: true },
    );
  });

  return {
    pageId: String(page.id),
    hasInstagram: Boolean(igId),
    hasFacebookPage: true,
  };
}

async function completeOAuthFromPending(db, state, code) {
  const pendingRef = db.collection(PENDING_COLLECTION).doc(state);
  const pendingSnap = await pendingRef.get();
  if (!pendingSnap.exists) {
    throw new HttpsError('not-found', 'OAuth session expired or invalid.');
  }

  const pending = pendingSnap.data() ?? {};
  const expiresAt = pending.expiresAt?.toDate?.() ?? null;
  if (expiresAt && expiresAt.getTime() < Date.now()) {
    await pendingRef.delete();
    throw new HttpsError('deadline-exceeded', 'OAuth session expired.');
  }

  const shortLived = await exchangeAuthorizationCode(code);
  const longLived = await exchangeLongLivedUserToken(shortLived.access_token);
  const pages = await loadPages(longLived.access_token);
  const result = await persistMetaConnection(
    db,
    pending.uid,
    longLived,
    pages,
  );
  await pendingRef.delete();
  return result;
}

/**
 * Callable: metaOAuthStart
 *
 * Optional connect (settings). Never required to share via the sheet.
 * Response: { authUrl, state }
 */
function createMetaOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [metaAppId, metaAppSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const { appId } = readMetaAppCredentials();
      if (!appId) {
        throw new HttpsError(
          'failed-precondition',
          'TODO: set META_APP_ID (Firebase secrets / env).',
        );
      }

      const db = getFirestore();
      const state = crypto.randomBytes(16).toString('hex');
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

      await db.collection(PENDING_COLLECTION).doc(state).set({
        uid: request.auth.uid,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

      const authParams = new URLSearchParams({
        client_id: appId,
        redirect_uri: metaCallbackRedirectUri(),
        response_type: 'code',
        scope: META_SCOPES,
        state,
        auth_type: 'rerequest',
      });

      return {
        authUrl: `${FACEBOOK_DIALOG_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

function createMetaOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [metaAppId, metaAppSecret],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      const error = (req.query.error ?? '').toString();
      if (error) {
        redirectToApp(res, { success: '0', error });
        return;
      }

      const code = (req.query.code ?? '').toString();
      const state = (req.query.state ?? '').toString();
      if (!code || !state) {
        redirectToApp(res, { success: '0', error: 'missing_code_or_state' });
        return;
      }

      try {
        const db = getFirestore();
        await completeOAuthFromPending(db, state, code);
        redirectToApp(res, { success: '1' });
      } catch (callbackError) {
        console.error('metaOAuthCallback error', callbackError);
        redirectToApp(res, {
          success: '0',
          error: callbackError?.message ?? 'oauth_failed',
        });
      }
    },
  );
}

function createMetaDisconnect() {
  return onCall(
    {
      region: REGION,
      timeoutSeconds: 30,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const db = getFirestore();
      const uid = request.auth.uid;
      const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(uid);
      const syncRef = db
        .collection('users')
        .doc(uid)
        .collection(META_SYNC_COLLECTION)
        .doc(META_SYNC_DOC_ID);

      await db.runTransaction(async (transaction) => {
        transaction.delete(integrationRef);
        transaction.set(
          syncRef,
          {
            connected: false,
            hasInstagram: false,
            hasFacebookPage: false,
            disconnectedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      return { disconnected: true };
    },
  );
}

module.exports = {
  createMetaOAuthStart,
  createMetaOAuthCallback,
  createMetaDisconnect,
  metaCallbackRedirectUri,
  pickBestPage,
};
