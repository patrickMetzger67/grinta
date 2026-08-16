const crypto = require('crypto');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const ouraClientId = defineSecret('OURA_CLIENT_ID');
const ouraClientSecret = defineSecret('OURA_CLIENT_SECRET');

const OURA_AUTH_URL = 'https://cloud.ouraring.com/oauth/authorize';
const OURA_TOKEN_URL = 'https://api.ouraring.com/oauth/token';
const OURA_SCOPES = [
  'email',
  'personal',
  'daily',
  'heartrate',
  'workout',
].join(' ');

const PENDING_COLLECTION = 'oura_oauth_pending';
const INTEGRATIONS_COLLECTION = 'oura_integrations';
const MEMBER_COLLECTION = 'member';
const PROJECT_ID = 'aserstein-2453e';
const REGION = 'europe-west1';

const DEFAULT_COACH_VISIBILITY = {
  workout: false,
  heartrate: false,
  daily: false,
  personal: false,
  email: false,
};

function ouraCallbackRedirectUri() {
  return `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/ouraOAuthCallback`;
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

/**
 * Player-initiated connects are stored under the signed-in Firebase uid so the
 * Appareils/Applications badge (users/{authUid}/ouraSync/{playerId}) can read
 * them. Legacy docs may live under member.userID — migrate those to callerUid.
 */
async function migrateOuraDocsToCaller(db, legacyOwnerUid, callerUid, playerId) {
  if (!legacyOwnerUid || legacyOwnerUid === callerUid || !playerId) {
    return false;
  }

  const legacyIntegrationRef = db
    .collection(INTEGRATIONS_COLLECTION)
    .doc(integrationDocId(legacyOwnerUid, playerId));
  const callerIntegrationRef = db
    .collection(INTEGRATIONS_COLLECTION)
    .doc(integrationDocId(callerUid, playerId));
  const legacySyncRef = db
    .collection('users')
    .doc(legacyOwnerUid)
    .collection('ouraSync')
    .doc(playerId);
  const callerSyncRef = db
    .collection('users')
    .doc(callerUid)
    .collection('ouraSync')
    .doc(playerId);

  const [legacyIntegration, callerIntegration, legacySync, callerSync] =
    await Promise.all([
      legacyIntegrationRef.get(),
      callerIntegrationRef.get(),
      legacySyncRef.get(),
      callerSyncRef.get(),
    ]);

  let migrated = false;
  const legacyConnected =
    legacyIntegration.exists &&
    (legacyIntegration.data()?.status ?? '') === 'connected';
  const callerConnected =
    callerIntegration.exists &&
    (callerIntegration.data()?.status ?? '') === 'connected';

  if (legacyConnected && !callerConnected) {
    const data = legacyIntegration.data() ?? {};
    await callerIntegrationRef.set(
      {
        ...data,
        uid: callerUid,
        playerId,
        migratedFrom: legacyOwnerUid,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    migrated = true;
  }

  const legacySyncConnected =
    legacySync.exists && legacySync.data()?.connected === true;
  const callerSyncConnected =
    callerSync.exists && callerSync.data()?.connected === true;

  if (legacySyncConnected && !callerSyncConnected) {
    const data = legacySync.data() ?? {};
    await callerSyncRef.set(
      {
        ...data,
        migratedFrom: legacyOwnerUid,
      },
      { merge: true },
    );
    migrated = true;
  }

  if (migrated) {
    console.log('oura migrate to caller', {
      playerId,
      legacyOwnerUid,
      callerUid,
    });
  }

  return migrated;
}

async function resolveSyncOwnerUid(db, playerId, callerUid, initiatedBy) {
  const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
  if (!memberSnap.exists) {
    throw new HttpsError('not-found', 'Player profile not found.');
  }

  const memberData = memberSnap.data() ?? {};
  const memberOwnerUid = readMemberOwnerUid(memberData);

  if (initiatedBy === 'player') {
    if (!userHasMemberAccess(memberData, callerUid)) {
      throw new HttpsError(
        'permission-denied',
        'You cannot connect Oura for this player profile.',
      );
    }
    // Settings badge watches the signed-in user path.
    await migrateOuraDocsToCaller(db, memberOwnerUid, callerUid, playerId);
    return callerUid;
  }

  const canManage = await coachCanManagePlayer(db, callerUid, playerId);
  if (!canManage) {
    throw new HttpsError(
      'permission-denied',
      'You cannot connect Oura for this player.',
    );
  }

  return memberOwnerUid ?? callerUid;
}

async function fetchOuraProfile(accessToken) {
  const response = await fetch('https://api.ouraring.com/v2/usercollection/personal_info', {
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    console.error('Oura profile fetch failed', response.status, body);
    return null;
  }

  const profile = await response.json();
  // personal_info has no stable user id; use email or a synthetic fingerprint.
  const email = (profile?.email ?? '').toString().trim();
  if (email) return email.toLowerCase();
  const age = profile?.age != null ? String(profile.age) : '';
  const weight = profile?.weight != null ? String(profile.weight) : '';
  const fingerprint = [age, weight].filter(Boolean).join('_');
  return fingerprint || null;
}

async function exchangeAuthorizationCode({ code }) {
  const clientId = ouraClientId.value();
  const clientSecret = ouraClientSecret.value();
  if (!clientId || !clientSecret) {
    throw new HttpsError(
      'failed-precondition',
      'OURA client credentials are not configured.',
    );
  }

  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    code,
    redirect_uri: ouraCallbackRedirectUri(),
    client_id: clientId,
    client_secret: clientSecret,
  });

  const response = await fetch(OURA_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: body.toString(),
  });

  const raw = await response.text();
  if (!response.ok) {
    console.error('Oura token exchange failed', response.status, raw);
    throw new HttpsError(
      'internal',
      `Oura token exchange failed (${response.status}).`,
    );
  }

  let parsed;
  try {
    parsed = raw ? JSON.parse(raw) : null;
  } catch (error) {
    throw new HttpsError('internal', 'Invalid Oura token response.');
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

async function persistOuraConnection(db, pending, tokenResponse) {
  const accessToken = (tokenResponse?.access_token ?? '').toString();
  const refreshToken = (tokenResponse?.refresh_token ?? '').toString();
  if (!accessToken || !refreshToken) {
    throw new HttpsError('internal', 'Oura tokens missing from response.');
  }

  const ouraUserId = await fetchOuraProfile(accessToken);
  const ownerUid = pending.ownerUid;
  const playerId = pending.playerId;
  const integrationId = integrationDocId(ownerUid, playerId);
  const expiresAt = tokenExpiryFromResponse(tokenResponse);

  const integrationRef = db.collection(INTEGRATIONS_COLLECTION).doc(integrationId);
  const syncRef = db
    .collection('users')
    .doc(ownerUid)
    .collection('ouraSync')
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
        ouraUserId,
        ouraAccountHint: pending.ouraAccountHint ?? null,
        status: 'connected',
        scopes: ((tokenResponse?.scope ?? OURA_SCOPES).toString().trim() || OURA_SCOPES).split(/\s+/),
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
        ouraUserId,
        ouraAccountHint: pending.ouraAccountHint ?? null,
        initiatedBy: pending.initiatedBy,
        coachUid: pending.coachUid ?? null,
        coachVisibility: existingVisibility,
      },
      { merge: true },
    );
  });

  return { ownerUid, playerId, ouraUserId };
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
  });

  const result = await persistOuraConnection(db, pending, tokenResponse);
  await pendingRef.delete();
  return { ...result, returnTo: pending.returnTo ?? null };
}

function isAllowedWebReturnTo(returnTo) {
  if (!returnTo || typeof returnTo !== 'string') return false;
  let parsed;
  try {
    parsed = new URL(returnTo);
  } catch (_) {
    return false;
  }
  if (parsed.protocol === 'http:' || parsed.protocol === 'https:') {
    const host = parsed.hostname.toLowerCase();
    if (host === 'localhost' || host === '127.0.0.1') return true;
    if (host === 'grinta.web.app' || host === 'grinta.firebaseapp.com') {
      return true;
    }
    if (host.endsWith('.web.app') || host.endsWith('.firebaseapp.com')) {
      return true;
    }
  }
  return false;
}

function redirectToApp(res, params, returnTo) {
  const query = new URLSearchParams(params).toString();
  if (isAllowedWebReturnTo(returnTo)) {
    const target = new URL(returnTo);
    target.searchParams.set('ouraOAuth', '1');
    for (const [key, value] of Object.entries(params)) {
      if (value != null && value !== '') {
        target.searchParams.set(key, String(value));
      }
    }
    console.log('ouraOAuthCallback redirect web', target.toString());
    res.redirect(302, target.toString());
    return;
  }
  const deepLink = `grinta://oura/callback?${query}`;
  console.log('ouraOAuthCallback redirect deepLink', deepLink);
  res.redirect(302, deepLink);
}

/**
 * Callable: ouraOAuthStart
 *
 * Request: { playerId, initiatedBy: "coach"|"player", ouraAccountHint, returnTo? }
 * Response: { authUrl, state }
 */
function createOuraOAuthStart() {
  return onCall(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
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
      const ouraAccountHint = (request.data?.ouraAccountHint ?? '')
        .toString()
        .trim();
      const returnToRaw = (request.data?.returnTo ?? '').toString().trim();
      const returnTo = isAllowedWebReturnTo(returnToRaw) ? returnToRaw : null;

      if (!playerId) {
        throw new HttpsError('invalid-argument', 'playerId is required.');
      }
      if (initiatedBy !== 'coach' && initiatedBy !== 'player') {
        throw new HttpsError(
          'invalid-argument',
          'initiatedBy must be "coach" or "player".',
        );
      }
      if (!ouraAccountHint) {
        throw new HttpsError(
          'invalid-argument',
          'ouraAccountHint is required.',
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

      const clientId = ouraClientId.value();
      if (!clientId) {
        throw new HttpsError(
          'failed-precondition',
          'OURA_CLIENT_ID secret is not configured.',
        );
      }

      const state = crypto.randomBytes(16).toString('hex');
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

      await db.collection(PENDING_COLLECTION).doc(state).set({
        ownerUid,
        playerId,
        initiatedBy,
        ouraAccountHint,
        returnTo,
        coachUid: initiatedBy === 'coach' ? callerUid : null,
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

      const authParams = new URLSearchParams({
        response_type: 'code',
        client_id: clientId,
        redirect_uri: ouraCallbackRedirectUri(),
        scope: OURA_SCOPES,
        state,
      });

      return {
        authUrl: `${OURA_AUTH_URL}?${authParams.toString()}`,
        state,
      };
    },
  );
}

/**
 * HTTP: ouraOAuthCallback
 *
 * Oura redirects here after user consent. Tokens are stored server-side,
 * then the user is sent back to the app via grinta://oura/callback.
 */
function createOuraOAuthCallback() {
  return onRequest(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      console.log('ouraOAuthCallback hit', {
        method: req.method,
        query: req.query,
      });

      const error = (req.query.error ?? '').toString();
      if (error) {
        console.warn('ouraOAuthCallback provider error', error);
        redirectToApp(res, {
          success: '0',
          error,
        });
        return;
      }

      const code = (req.query.code ?? '').toString();
      const state = (req.query.state ?? '').toString();

      if (!code || !state) {
        console.warn('ouraOAuthCallback missing code/state');
        redirectToApp(res, {
          success: '0',
          error: 'missing_code_or_state',
        });
        return;
      }

      try {
        const db = getFirestore();
        const result = await completeOAuthFromPending(db, state, code);
        console.log('ouraOAuthCallback success', {
          playerId: result.playerId,
          ouraUserId: result.ouraUserId,
          returnTo: result.returnTo ?? null,
        });
        redirectToApp(
          res,
          {
            success: '1',
            playerId: result.playerId,
          },
          result.returnTo,
        );
      } catch (callbackError) {
        console.error('ouraOAuthCallback error', {
          code: callbackError?.code,
          message: callbackError?.message,
        });
        // Best-effort: recover returnTo from pending if still present.
        let returnTo = null;
        try {
          const pendingSnap = await getFirestore()
            .collection(PENDING_COLLECTION)
            .doc(state)
            .get();
          returnTo = pendingSnap.data()?.returnTo ?? null;
        } catch (_) {
          // ignore
        }
        redirectToApp(
          res,
          {
            success: '0',
            error: callbackError?.message ?? 'oauth_failed',
          },
          returnTo,
        );
      }
    },
  );
}

/**
 * Callable: ouraDisconnect
 *
 * Request: { playerId }
 */
function createOuraDisconnect() {
  return onCall(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
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
      const memberOwnerUid = readMemberOwnerUid(memberData);

      const canDisconnect =
        userHasMemberAccess(memberData, callerUid) ||
        (await coachCanManagePlayer(db, callerUid, playerId));

      if (!canDisconnect) {
        throw new HttpsError(
          'permission-denied',
          'You cannot disconnect Oura for this player.',
        );
      }

      // Clear caller path (current) and legacy member-owner path if different.
      const ownerUids = new Set([callerUid]);
      if (memberOwnerUid) ownerUids.add(memberOwnerUid);

      await db.runTransaction(async (transaction) => {
        for (const ownerUid of ownerUids) {
          const integrationRef = db
            .collection(INTEGRATIONS_COLLECTION)
            .doc(integrationDocId(ownerUid, playerId));
          const syncRef = db
            .collection('users')
            .doc(ownerUid)
            .collection('ouraSync')
            .doc(playerId);
          transaction.delete(integrationRef);
          transaction.set(
            syncRef,
            {
              connected: false,
              disconnectedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
        }
      });

      // TODO(Phase 2): revoke refresh token at Oura if/when supported.

      return { disconnected: true };
    },
  );
}

/**
 * Callable: ouraRepairPlayerSync
 *
 * Migrates a legacy ouraSync / oura_integrations doc from member.userID onto
 * the signed-in uid so the settings badge can see the connection.
 */
function createOuraRepairPlayerSync() {
  return onCall(
    {
      region: REGION,
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
      if (!userHasMemberAccess(memberData, callerUid)) {
        throw new HttpsError(
          'permission-denied',
          'You cannot repair Oura sync for this player profile.',
        );
      }

      const memberOwnerUid = readMemberOwnerUid(memberData);
      const migrated = await migrateOuraDocsToCaller(
        db,
        memberOwnerUid,
        callerUid,
        playerId,
      );

      const syncSnap = await db
        .collection('users')
        .doc(callerUid)
        .collection('ouraSync')
        .doc(playerId)
        .get();

      return {
        migrated,
        connected: syncSnap.exists && syncSnap.data()?.connected === true,
        syncOwnerUid: callerUid,
      };
    },
  );
}

module.exports = {
  createOuraOAuthStart,
  createOuraOAuthCallback,
  createOuraDisconnect,
  createOuraRepairPlayerSync,
  // Exported for Phase 2 token refresh / webhooks.
  OURA_TOKEN_URL,
  OURA_SCOPES,
  integrationDocId,
  tokenExpiryFromResponse,
};
