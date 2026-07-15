const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const stravaClientId = defineSecret('STRAVA_CLIENT_ID');
const stravaClientSecret = defineSecret('STRAVA_CLIENT_SECRET');

const STRAVA_AUTH_URL = 'https://www.strava.com/oauth/authorize';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const STRAVA_SCOPES = ['read', 'activity:read_all'].join(',');

const PENDING_COLLECTION = 'strava_oauth_pending';
const INTEGRATIONS_COLLECTION = 'strava_integrations';
const MEMBER_COLLECTION = 'member';
const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

const DEFAULT_COACH_VISIBILITY = {
  activities: false,
  profile: false,
};

function stravaCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/stravaOAuthCallback`;
}

function integrationDocId(uid, playerId) {
  return `${uid}_${playerId}`;
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
  const users = Array.isArray(memberData?.users) ? memberData.users : [];
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
        'You cannot connect Strava for this player profile.',
      );
    }
    return ownerUid ?? callerUid;
  }

  const canManage = await coachCanManagePlayer(db, callerUid, playerId);
  if (!canManage) {
    throw new HttpsError(
      'permission-denied',
      'You cannot connect Strava for this player.',
    );
  }

  return ownerUid ?? callerUid;
}

function readStravaAthleteId(tokenResponse) {
  const athlete = tokenResponse?.athlete ?? null;
  const athleteId = athlete?.id ?? tokenResponse?.athlete_id ?? null;
  return athleteId != null ? String(athleteId) : null;
}

async function exchangeAuthorizationCode({ code }) {
  const clientId = stravaClientId.value();
  const clientSecret = stravaClientSecret.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      'failed-precondition',
      'Strava client credentials are not configured.',
    );
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: stravaCallbackRedirectUri(),
    client_id: clientId,
    client_secret: clientSecret,
  });

  const response = await fetch(STRAVA_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('Strava token exchange failed', response.status, raw);
    throw new HttpsError(
      'internal',
      `Strava token exchange failed (${response.status}).`,
    );
  }

  let parsed;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch (error) {
    throw new HttpsError('internal', 'Invalid Strava token response.');
  }

  return parsed;
}

function tokenExpiryFromResponse(tokenResponse) {
  const expiresAt = Number(tokenResponse?.expires_at ?? 0);
  if (!Number.isFinite(expiresAt) || expiresAt <= 0) {
    return null;
  }
  return new Date(expiresAt * 1000);
}

async function persistStravaConnection(db, pending, tokenResponse) {
  const accessToken = (tokenResponse?.access_token ?? '').toString();
  const refreshToken = (tokenResponse?.refresh_token ?? '').toString();
  if (!accessToken || !refreshToken) {
    throw new HttpsError('internal', 'Strava tokens missing from response.');
  }

  const stravaAthleteId = readStravaAthleteId(tokenResponse);
  const ownerUid = pending.ownerUid;
  const playerId = pending.playerId;
  const integrationId = integrationDocId(ownerUid, playerId);
  const expiresAt = tokenExpiryFromResponse(tokenResponse);

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
  const syncRef = db
    .collection('users')
    .doc(ownerUid)
    .collection('stravaSync')
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
        stravaAthleteId,
        status: 'connected',
        scopes: STRAVA_SCOPES.split(','),
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
        stravaAthleteId,
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        coachVisibility: existingVisibility,
      },
      { merge: true },
    );
  });

  return { ownerUid, playerId, stravaAthleteId };
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

  const tokenResponse = await exchangeAuthorizationCode({ code });
  const result = await persistStravaConnection(db, pending, tokenResponse);
  await pendingRef.delete();
  return result;
}

function redirectToApp(res, params) {
  const query = new URLSearchParams(params).toString();
  res.redirect(302, `grinta://strava/callback?${query}`);
}

/**
 * Callable: stravaOAuthStart
 *
 * Request: { playerId, initiatedBy: "coach"|"player" }
 * Response: { authUrl, state }
 */
function createStravaOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [stravaClientId, stravaClientSecret],
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

      const clientId = stravaClientId.value();
      if (!clientId) {
        throw new HttpsError(
          'failed-precondition',
          'STRAVA_CLIENT_ID secret is not configured.',
        );
      }

      const state = crypto.randomBytes(16).toString('hex');
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

      await db.collection(PENDING_COLLECTION).doc(state).set({
        ownerUid,
        playerId,
        initiatedBy,
        coachUid: initiatedBy === 'coach' ? callerUid : null,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

      const authParams = new URLSearchParams({
        client_id: clientId,
        redirect_uri: stravaCallbackRedirectUri(),
        response_type: 'code',
        approval_prompt: 'auto',
        scope: STRAVA_SCOPES,
        state,
      });

      return {
        authUrl: `${STRAVA_AUTH_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

/**
 * HTTP: stravaOAuthCallback
 *
 * Strava redirects here after user consent. Tokens are stored server-side,
 * then the user is sent back to the app via grinta://strava/callback.
 */
function createStravaOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [stravaClientId, stravaClientSecret],
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
        console.error('stravaOAuthCallback error', callbackError);
        redirectToApp(res, {
          success: '0',
          error: callbackError?.message ?? 'oauth_failed',
        });
      }
    },
  );
}

/**
 * Callable: stravaDisconnect
 *
 * Request: { playerId }
 */
function createStravaDisconnect() {
  return onCall(
    {
      region: REGION,
      secrets: [stravaClientId, stravaClientSecret],
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
          'You cannot disconnect Strava for this player.',
        );
      }

      const integrationId = integrationDocId(ownerUid, playerId);
      const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
      const syncRef = db
        .collection('users')
        .doc(ownerUid)
        .collection('stravaSync')
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

      // TODO(Phase 2): deauthorize athlete at Strava via POST /oauth/deauthorize.

      return { disconnected: true };
    },
  );
}

module.exports = {
  createStravaOAuthStart,
  createStravaOAuthCallback,
  createStravaDisconnect,
  // Exported for Phase 2 token refresh / webhooks.
  STRAVA_TOKEN_URL,
  STRAVA_SCOPES,
  integrationDocId,
  tokenExpiryFromResponse,
};
