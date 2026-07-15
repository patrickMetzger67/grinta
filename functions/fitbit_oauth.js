const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const fitbitClientId = defineSecret('FITBIT_CLIENT_ID');
const fitbitClientSecret = defineSecret('FITBIT_CLIENT_SECRET');

const FITBIT_AUTH_URL = 'https://www.fitbit.com/oauth2/authorize';
const FITBIT_TOKEN_URL = 'https://api.fitbit.com/oauth2/token';
const FITBIT_SCOPES = [
  'activity',
  'heartrate',
  'sleep',
  'profile',
  'weight',
].join(' ');

const PENDING_COLLECTION = 'fitbit_oauth_pending';
const INTEGRATIONS_COLLECTION = 'fitbit_integrations';
const MEMBER_COLLECTION = 'member';
const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

const DEFAULT_COACH_VISIBILITY = {
  activity: false,
  heartrate: false,
  sleep: false,
  profile: false,
  body: false,
};

function fitbitCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/fitbitOAuthCallback`;
}

function integrationDocId(uid, playerId) {
  return `${uid}_${playerId}`;
}

function base64UrlEncode(buffer) {
  return buffer
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function createPkcePair() {
  const codeVerifier = base64UrlEncode(crypto.randomBytes(32));
  const codeChallenge = base64UrlEncode(
    crypto.createHash('sha256').update(codeVerifier).digest(),
  );
  return { codeVerifier, codeChallenge };
}

function basicAuthHeader(clientId, clientSecret) {
  const encoded = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  return `Basic ${encoded}`;
}

function readMemberOwnerUid(memberData) {
  const userId = (memberData?.userID ?? '').toString().trim();
  if (userId) return userId;

  const users = Array.isArray(memberData?.users) ? memberData.users : [];
  for (const entry of users) {
    const id = String(entry).trim();
    if (id) return id;
  }

  const creator = (memberData?.creatorUserId ?? '').toString().trim();
  return creator || null;
}

function userHasMemberAccess(memberData, uid) {
  if (!memberData || !uid) return false;
  if ((memberData.userID ?? '').toString().trim() === uid) return true;
  const users = Array.isArray(memberData.users) ? memberData.users : [];
  return users.some((entry) => String(entry).trim() === uid);
}

async function coachCanManagePlayer(db, coachUid, playerId) {
  const trimmedPlayerId = playerId.trim();
  if (!trimmedPlayerId) return false;

  const teamsSnap = await db
    .collection('team')
    .where('users', 'array-contains', coachUid)
    .limit(50)
    .get();

  for (const teamDoc of teamsSnap.docs) {
    const team = teamDoc.data() ?? {};
    const grintaPlayers = Array.isArray(team.grintaPlayers)
      ? team.grintaPlayers
      : [];
    for (const entry of grintaPlayers) {
      const id = (entry?.playerId ?? entry?.playerID ?? '').toString().trim();
      if (id === trimmedPlayerId) {
        return true;
      }
    }

    const legacyPlayers = Array.isArray(team.players) ? team.players : [];
    for (const entry of legacyPlayers) {
      const id = (entry?.playerId ?? entry?.playerID ?? entry ?? '')
        .toString()
        .trim();
      if (id === trimmedPlayerId) {
        return true;
      }
    }
  }

  return false;
}

async function resolveSyncOwnerUid(db, playerId, callerUid, initiatedBy) {
  const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
  if (!memberSnap.exists) {
    throw new HttpsError('not-found', 'Player profile not found.');
  }

  const memberData = memberSnap.data() ?? {};
  const ownerUid = readMemberOwnerUid(memberData);

  if (initiatedBy === 'player') {
    if (!userHasMemberAccess(memberData, callerUid)) {
      throw new HttpsError(
        'permission-denied',
        'You cannot connect Fitbit for this player profile.',
      );
    }
    return ownerUid ?? callerUid;
  }

  const canManage = await coachCanManagePlayer(db, callerUid, playerId);
  if (!canManage) {
    throw new HttpsError(
      'permission-denied',
      'You cannot connect Fitbit for this player.',
    );
  }

  return ownerUid ?? callerUid;
}

async function fetchFitbitProfile(accessToken) {
  const response = await fetch('https://api.fitbit.com/1/user/-/profile.json', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    console.error('Fitbit profile fetch failed', response.status, body);
    return null;
  }

  const profile = await response.json();
  const fitbitUserId =
    profile?.user?.encodedId ??
    profile?.user?.encodedID ??
    profile?.user?.id ??
    null;
  return fitbitUserId != null ? String(fitbitUserId) : null;
}

async function exchangeAuthorizationCode({ code, codeVerifier }) {
  const clientId = fitbitClientId.value();
  const clientSecret = fitbitClientSecret.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      'failed-precondition',
      'Fitbit client credentials are not configured.',
    );
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: fitbitCallbackRedirectUri(),
    code_verifier: codeVerifier,
  });

  const response = await fetch(FITBIT_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: basicAuthHeader(clientId, clientSecret),
    },
    body: body.toString(),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('Fitbit token exchange failed', response.status, raw);
    throw new HttpsError(
      'internal',
      `Fitbit token exchange failed (${response.status}).`,
    );
  }

  let parsed;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch (error) {
    throw new HttpsError('internal', 'Invalid Fitbit token response.');
  }

  return parsed;
}

function tokenExpiryFromResponse(tokenResponse) {
  const expiresIn = Number(tokenResponse?.expires_in ?? 0);
  if (!Number.isFinite(expiresIn) || expiresIn <= 0) {
    return null;
  }
  return new Date(Date.now() + expiresIn * 1000);
}

async function persistFitbitConnection(db, pending, tokenResponse) {
  const accessToken = (tokenResponse?.access_token ?? '').toString();
  const refreshToken = (tokenResponse?.refresh_token ?? '').toString();
  if (!accessToken || !refreshToken) {
    throw new HttpsError('internal', 'Fitbit tokens missing from response.');
  }

  const fitbitUserId = await fetchFitbitProfile(accessToken);
  const ownerUid = pending.ownerUid;
  const playerId = pending.playerId;
  const integrationId = integrationDocId(ownerUid, playerId);
  const expiresAt = tokenExpiryFromResponse(tokenResponse);

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
  const syncRef = db
    .collection('users')
    .doc(ownerUid)
    .collection('fitbitSync')
    .doc(playerId);

  const existingSync = await syncRef.get();
  const existingVisibility =
    existingSync.exists && existingSync.data()?.coachVisibility
      ? existingSync.data().coachVisibility
      : DEFAULT_COACH_VISIBILITY;

  await db.runTransaction(async (transaction) => {
    transaction.set(
      integrationRef,
      {
        uid: ownerUid,
        playerId,
        fitbitUserId,
        status: 'connected',
        scopes: FITBIT_SCOPES.split(' '),
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        tokens: {
          accessToken,
          refreshToken,
          expiresAt: expiresAt ?? null,
          tokenType: (tokenResponse?.token_type ?? 'Bearer').toString(),
        },
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
        fitbitUserId,
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        coachVisibility: existingVisibility,
      },
      { merge: true },
    );
  });

  return { ownerUid, playerId, fitbitUserId };
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

  const tokenResponse = await exchangeAuthorizationCode({
    code,
    codeVerifier: pending.codeVerifier,
  });

  const result = await persistFitbitConnection(db, pending, tokenResponse);
  await pendingRef.delete();
  return result;
}

function redirectToApp(res, params) {
  const query = new URLSearchParams(params).toString();
  res.redirect(302, `grinta://fitbit/callback?${query}`);
}

/**
 * Callable: fitbitOAuthStart
 *
 * Request: { playerId, initiatedBy: "coach"|"player" }
 * Response: { authUrl, state }
 */
function createFitbitOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [fitbitClientId, fitbitClientSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const playerId = (request.data?.playerId ?? '').toString().trim();
      const initiatedBy = (request.data?.initiatedBy ?? 'player')
        .toString()
        .trim()
        .toLowerCase();

      if (!playerId) {
        throw new HttpsError('invalid-argument', 'playerId is required.');
      }
      if (initiatedBy !== 'coach' && initiatedBy !== 'player') {
        throw new HttpsError(
          'invalid-argument',
          'initiatedBy must be "coach" or "player".',
        );
      }

      const db = getFirestore();
      const callerUid = request.auth.uid;
      const ownerUid = await resolveSyncOwnerUid(
        db,
        playerId,
        callerUid,
        initiatedBy,
      );

      const clientId = fitbitClientId.value();
      if (!clientId) {
        throw new HttpsError(
          'failed-precondition',
          'FITBIT_CLIENT_ID secret is not configured.',
        );
      }

      const state = crypto.randomBytes(16).toString('hex');
      const { codeVerifier, codeChallenge } = createPkcePair();
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

      await db.collection(PENDING_COLLECTION).doc(state).set({
        ownerUid,
        playerId,
        initiatedBy,
        coachUid: initiatedBy === 'coach' ? callerUid : null,
        codeVerifier,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

      const authParams = new URLSearchParams({
        response_type: 'code',
        client_id: clientId,
        redirect_uri: fitbitCallbackRedirectUri(),
        scope: FITBIT_SCOPES,
        state,
        code_challenge: codeChallenge,
        code_challenge_method: 'S256',
      });

      return {
        authUrl: `${FITBIT_AUTH_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

/**
 * HTTP: fitbitOAuthCallback
 *
 * Fitbit redirects here after user consent. Tokens are stored server-side,
 * then the user is sent back to the app via grinta://fitbit/callback.
 */
function createFitbitOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [fitbitClientId, fitbitClientSecret],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      const error = (req.query.error ?? '').toString();
      if (error) {
        redirectToApp(res, {
          success: '0',
          error,
        });
        return;
      }

      const code = (req.query.code ?? '').toString();
      const state = (req.query.state ?? '').toString();

      if (!code || !state) {
        redirectToApp(res, {
          success: '0',
          error: 'missing_code_or_state',
        });
        return;
      }

      try {
        const db = getFirestore();
        const result = await completeOAuthFromPending(db, state, code);
        redirectToApp(res, {
          success: '1',
          playerId: result.playerId,
        });
      } catch (callbackError) {
        console.error('fitbitOAuthCallback error', callbackError);
        redirectToApp(res, {
          success: '0',
          error: callbackError?.message ?? 'oauth_failed',
        });
      }
    },
  );
}

/**
 * Callable: fitbitDisconnect
 *
 * Request: { playerId }
 */
function createFitbitDisconnect() {
  return onCall(
    {
      region: REGION,
      secrets: [fitbitClientId, fitbitClientSecret],
      timeoutSeconds: 30,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const playerId = (request.data?.playerId ?? '').toString().trim();
      if (!playerId) {
        throw new HttpsError('invalid-argument', 'playerId is required.');
      }

      const db = getFirestore();
      const callerUid = request.auth.uid;

      const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
      if (!memberSnap.exists) {
        throw new HttpsError('not-found', 'Player profile not found.');
      }

      const memberData = memberSnap.data() ?? {};
      const ownerUid = readMemberOwnerUid(memberData) ?? callerUid;

      const canDisconnect =
        userHasMemberAccess(memberData, callerUid) ||
        (await coachCanManagePlayer(db, callerUid, playerId));

      if (!canDisconnect) {
        throw new HttpsError(
          'permission-denied',
          'You cannot disconnect Fitbit for this player.',
        );
      }

      const integrationId = integrationDocId(ownerUid, playerId);
      const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
      const syncRef = db
        .collection('users')
        .doc(ownerUid)
        .collection('fitbitSync')
        .doc(playerId);

      await db.runTransaction(async (transaction) => {
        transaction.delete(integrationRef);
        transaction.set(
          syncRef,
          {
            connected: false,
            disconnectedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      // TODO(Phase 2): revoke Fitbit subscription / refresh token at disconnect.

      return { disconnected: true };
    },
  );
}

module.exports = {
  createFitbitOAuthStart,
  createFitbitOAuthCallback,
  createFitbitDisconnect,
  FITBIT_TOKEN_URL,
  FITBIT_SCOPES,
  integrationDocId,
  tokenExpiryFromResponse,
};
