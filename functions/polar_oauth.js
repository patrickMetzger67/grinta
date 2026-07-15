const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const polarClientId = defineSecret('POLAR_CLIENT_ID');
const polarClientSecret = defineSecret('POLAR_CLIENT_SECRET');

const POLAR_AUTH_URL = 'https://flow.polar.com/oauth2/authorization';
const POLAR_TOKEN_URL = 'https://polarremote.com/v2/oauth2/token';
const POLAR_ACCESSLINK_BASE = 'https://www.polaraccesslink.com/v3';
const POLAR_SCOPES = 'accesslink.read_all';

const PENDING_COLLECTION = 'polar_oauth_pending';
const INTEGRATIONS_COLLECTION = 'polar_integrations';
const MEMBER_COLLECTION = 'member';
const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

const DEFAULT_COACH_VISIBILITY = {
  training: false,
  sleep: false,
  recovery_hr: false,
  profile: false,
  body: false,
};

function polarCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/polarOAuthCallback`;
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
        'You cannot connect Polar for this player profile.',
      );
    }
    return ownerUid ?? callerUid;
  }

  const canManage = await coachCanManagePlayer(db, callerUid, playerId);
  if (!canManage) {
    throw new HttpsError(
      'permission-denied',
      'You cannot connect Polar for this player.',
    );
  }

  return ownerUid ?? callerUid;
}

function basicAuthHeader(clientId, clientSecret) {
  const encoded = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  return `Basic ${encoded}`;
}

async function exchangeAuthorizationCode({ code }) {
  const clientId = polarClientId.value();
  const clientSecret = polarClientSecret.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      'failed-precondition',
      'Polar client credentials are not configured.',
    );
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: polarCallbackRedirectUri(),
  });

  const response = await fetch(POLAR_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      Authorization: basicAuthHeader(clientId, clientSecret),
    },
    body: body.toString(),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('Polar token exchange failed', response.status, raw);
    throw new HttpsError(
      'internal',
      `Polar token exchange failed (${response.status}).`,
    );
  }

  let parsed;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch (error) {
    throw new HttpsError('internal', 'Invalid Polar token response.');
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

async function registerPolarUser(accessToken, memberId) {
  const response = await fetch(`${POLAR_ACCESSLINK_BASE}/users`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: JSON.stringify({ 'member-id': memberId }),
  });

  const raw = await response.text();
  if (response.ok) {
    try {
      return raw ? JSON.parse(raw) : null;
    } catch (error) {
      console.error('Polar user registration parse failed', raw);
      return null;
    }
  }

  if (response.status === 409) {
    console.warn('Polar user already registered for member-id', memberId);
    return { 'member-id': memberId };
  }

  console.error('Polar user registration failed', response.status, raw);
  throw new HttpsError(
    'internal',
    `Polar user registration failed (${response.status}).`,
  );
}

function readPolarUserId(registrationResponse) {
  const polarUserId =
    registrationResponse?.['polar-user-id'] ??
    registrationResponse?.polarUserId ??
    null;
  return polarUserId != null ? String(polarUserId) : null;
}

async function persistPolarConnection(db, pending, tokenResponse) {
  const accessToken = (tokenResponse?.access_token ?? '').toString();
  if (!accessToken) {
    throw new HttpsError('internal', 'Polar access token missing from response.');
  }

  const ownerUid = pending.ownerUid;
  const playerId = pending.playerId;
  const integrationId = integrationDocId(ownerUid, playerId);
  const memberId = integrationId;
  const registration = await registerPolarUser(accessToken, memberId);
  const polarUserId = readPolarUserId(registration);
  const expiresAt = tokenExpiryFromResponse(tokenResponse);

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
  const syncRef = db
    .collection('users')
    .doc(ownerUid)
    .collection('polarSync')
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
        polarUserId,
        memberId,
        status: 'connected',
        scopes: POLAR_SCOPES.split(' '),
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        tokens: {
          accessToken,
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
        polarUserId,
        memberId,
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        coachVisibility: existingVisibility,
      },
      { merge: true },
    );
  });

  return { ownerUid, playerId, polarUserId };
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
  const result = await persistPolarConnection(db, pending, tokenResponse);
  await pendingRef.delete();
  return result;
}

function redirectToApp(res, params) {
  const query = new URLSearchParams(params).toString();
  res.redirect(302, `grinta://polar/callback?${query}`);
}

/**
 * Callable: polarOAuthStart
 *
 * Request: { playerId, initiatedBy: "coach"|"player" }
 * Response: { authUrl, state }
 */
function createPolarOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [polarClientId, polarClientSecret],
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

      const clientId = polarClientId.value();
      if (!clientId) {
        throw new HttpsError(
          'failed-precondition',
          'POLAR_CLIENT_ID secret is not configured.',
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
        response_type: 'code',
        client_id: clientId,
        redirect_uri: polarCallbackRedirectUri(),
        scope: POLAR_SCOPES,
        state,
      });

      return {
        authUrl: `${POLAR_AUTH_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

/**
 * HTTP: polarOAuthCallback
 *
 * Polar redirects here after user consent. Tokens are stored server-side,
 * then the user is sent back to the app via grinta://polar/callback.
 */
function createPolarOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [polarClientId, polarClientSecret],
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
        console.error('polarOAuthCallback error', callbackError);
        redirectToApp(res, {
          success: '0',
          error: callbackError?.message ?? 'oauth_failed',
        });
      }
    },
  );
}

/**
 * Callable: polarDisconnect
 *
 * Request: { playerId }
 */
function createPolarDisconnect() {
  return onCall(
    {
      region: REGION,
      secrets: [polarClientId, polarClientSecret],
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
          'You cannot disconnect Polar for this player.',
        );
      }

      const integrationId = integrationDocId(ownerUid, playerId);
      const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
      const syncRef = db
        .collection('users')
        .doc(ownerUid)
        .collection('polarSync')
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

      // TODO(Phase 2): DELETE /v3/users/{polar-user-id} at Polar AccessLink.

      return { disconnected: true };
    },
  );
}

module.exports = {
  createPolarOAuthStart,
  createPolarOAuthCallback,
  createPolarDisconnect,
  POLAR_TOKEN_URL,
  POLAR_SCOPES,
  integrationDocId,
  tokenExpiryFromResponse,
};
