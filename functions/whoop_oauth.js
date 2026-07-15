const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const whoopClientId = defineSecret('WHOOP_CLIENT_ID');
const whoopClientSecret = defineSecret('WHOOP_CLIENT_SECRET');

const WHOOP_AUTH_URL = 'https://api.prod.whoop.com/oauth/oauth2/auth';
const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token';
const WHOOP_SCOPES = [
  'offline',
  'read:recovery',
  'read:sleep',
  'read:cycles',
  'read:workout',
  'read:profile',
  'read:body_measurement',
].join(' ');

const PENDING_COLLECTION = 'whoop_oauth_pending';
const INTEGRATIONS_COLLECTION = 'whoop_integrations';
const MEMBER_COLLECTION = 'member';
const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

const DEFAULT_COACH_VISIBILITY = {
  recovery: false,
  cycles: false,
  sleep: false,
  workout: false,
  profile: false,
  body_measurement: false,
};

function whoopCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/whoopOAuthCallback`;
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

async function collectUserMemberIds(db, uid) {
  const memberSnap = await db
    .collection(MEMBER_COLLECTION)
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
        'You cannot connect Whoop for this player profile.',
      );
    }
    return ownerUid ?? callerUid;
  }

  const canManage = await coachCanManagePlayer(db, callerUid, playerId);
  if (!canManage) {
    throw new HttpsError(
      'permission-denied',
      'You cannot connect Whoop for this player.',
    );
  }

  return ownerUid ?? callerUid;
}

async function fetchWhoopProfile(accessToken) {
  const response = await fetch('https://api.prod.whoop.com/developer/v1/user/profile/basic', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    console.error('Whoop profile fetch failed', response.status, body);
    return null;
  }

  const profile = await response.json();
  const whoopUserId =
    profile?.user_id ??
    profile?.userId ??
    profile?.id ??
    null;
  return whoopUserId != null ? String(whoopUserId) : null;
}

async function exchangeAuthorizationCode({ code, codeVerifier }) {
  const clientId = whoopClientId.value();
  const clientSecret = whoopClientSecret.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      'failed-precondition',
      'WHOOP client credentials are not configured.',
    );
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: whoopCallbackRedirectUri(),
    client_id: clientId,
    client_secret: clientSecret,
    code_verifier: codeVerifier,
  });

  const response = await fetch(WHOOP_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('Whoop token exchange failed', response.status, raw);
    throw new HttpsError(
      'internal',
      `Whoop token exchange failed (${response.status}).`,
    );
  }

  let parsed;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch (error) {
    throw new HttpsError('internal', 'Invalid Whoop token response.');
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

async function persistWhoopConnection(db, pending, tokenResponse) {
  const accessToken = (tokenResponse?.access_token ?? '').toString();
  const refreshToken = (tokenResponse?.refresh_token ?? '').toString();
  if (!accessToken || !refreshToken) {
    throw new HttpsError('internal', 'Whoop tokens missing from response.');
  }

  const whoopUserId = await fetchWhoopProfile(accessToken);
  const ownerUid = pending.ownerUid;
  const playerId = pending.playerId;
  const integrationId = integrationDocId(ownerUid, playerId);
  const expiresAt = tokenExpiryFromResponse(tokenResponse);

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
  const syncRef = db
    .collection('users')
    .doc(ownerUid)
    .collection('whoopSync')
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
        whoopUserId,
        status: 'connected',
        scopes: WHOOP_SCOPES.split(' '),
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
        whoopUserId,
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        coachVisibility: existingVisibility,
      },
      { merge: true },
    );
  });

  return { ownerUid, playerId, whoopUserId };
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

  const result = await persistWhoopConnection(db, pending, tokenResponse);
  await pendingRef.delete();
  return result;
}

function redirectToApp(res, params) {
  const query = new URLSearchParams(params).toString();
  res.redirect(302, `grinta://whoop/callback?${query}`);
}

/**
 * Callable: whoopOAuthStart
 *
 * Request: { playerId, initiatedBy: "coach"|"player" }
 * Response: { authUrl, state }
 */
function createWhoopOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [whoopClientId, whoopClientSecret],
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

      const clientId = whoopClientId.value();
      if (!clientId) {
        throw new HttpsError(
          'failed-precondition',
          'WHOOP_CLIENT_ID secret is not configured.',
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
        redirect_uri: whoopCallbackRedirectUri(),
        scope: WHOOP_SCOPES,
        state,
        code_challenge: codeChallenge,
        code_challenge_method: 'S256',
      });

      return {
        authUrl: `${WHOOP_AUTH_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

/**
 * HTTP: whoopOAuthCallback
 *
 * Whoop redirects here after user consent. Tokens are stored server-side,
 * then the user is sent back to the app via grinta://whoop/callback.
 */
function createWhoopOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [whoopClientId, whoopClientSecret],
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
        console.error('whoopOAuthCallback error', callbackError);
        redirectToApp(res, {
          success: '0',
          error: callbackError?.message ?? 'oauth_failed',
        });
      }
    },
  );
}

/**
 * Callable: whoopDisconnect
 *
 * Request: { playerId }
 */
function createWhoopDisconnect() {
  return onCall(
    {
      region: REGION,
      secrets: [whoopClientId, whoopClientSecret],
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
          'You cannot disconnect Whoop for this player.',
        );
      }

      const integrationId = integrationDocId(ownerUid, playerId);
      const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
      const syncRef = db
        .collection('users')
        .doc(ownerUid)
        .collection('whoopSync')
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

      // TODO(Phase 2): revoke refresh token at Whoop if/when supported.

      return { disconnected: true };
    },
  );
}

module.exports = {
  createWhoopOAuthStart,
  createWhoopOAuthCallback,
  createWhoopDisconnect,
  // Exported for Phase 2 token refresh / webhooks.
  WHOOP_TOKEN_URL,
  WHOOP_SCOPES,
  integrationDocId,
  tokenExpiryFromResponse,
};
