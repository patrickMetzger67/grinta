const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const stravaClientId = defineSecret('STRAVA_CLIENT_ID');
const stravaClientSecret = defineSecret('STRAVA_CLIENT_SECRET');

const INTEGRATIONS_COLLECTION = 'strava_integrations';
const PERSONAL_ACTIVITIES_COLLECTION = 'personalSportActivities';
const MEMBER_COLLECTION = 'member';
const REGION = 'europe-west1';
const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const STRAVA_ACTIVITIES_URL = 'https://www.strava.com/api/v3/athlete/activities';

function integrationDocId(uid, playerId) {
  return `${uid}_${playerId}`;
}

function userHasMemberAccess(memberData, uid) {
  if (!memberData || !uid) return false;
  if ((memberData.userID ?? '').toString().trim() === uid) return true;
  const users = Array.isArray(memberData.users) ? memberData.users : [];
  return users.some((entry) => String(entry).trim() === uid);
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

async function loadIntegration(db, callerUid, playerId) {
  const primaryId = integrationDocId(callerUid, playerId);
  let snap = await db.collection(INTEGRATIONS_COLLECTION).doc(primaryId).get();
  if (snap.exists && (snap.data()?.status ?? '') === 'connected') {
    return { id: primaryId, data: snap.data() };
  }

  const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
  const legacyOwner = readMemberOwnerUid(memberSnap.data() ?? {});
  if (legacyOwner && legacyOwner !== callerUid) {
    const legacyId = integrationDocId(legacyOwner, playerId);
    snap = await db.collection(INTEGRATIONS_COLLECTION).doc(legacyId).get();
    if (snap.exists && (snap.data()?.status ?? '') === 'connected') {
      return { id: legacyId, data: snap.data() };
    }
  }
  return null;
}

async function refreshAccessToken(integrationRef, tokens) {
  const refreshToken = (tokens?.refreshToken ?? '').toString();
  if (!refreshToken) {
    throw new HttpsError('failed-precondition', 'Strava refresh token missing.');
  }

  const body = new URLSearchParams({
    client_id: stravaClientId.value(),
    client_secret: stravaClientSecret.value(),
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
  });

  const response = await fetch(STRAVA_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });
  const raw = await response.text();
  if (!response.ok) {
    console.error('Strava token refresh failed', response.status, raw);
    throw new HttpsError('unauthenticated', 'Strava token refresh failed.');
  }

  const parsed = JSON.parse(raw);
  const accessToken = (parsed.access_token ?? '').toString();
  const nextRefresh = (parsed.refresh_token ?? refreshToken).toString();
  const expiresAtSec = Number(parsed.expires_at ?? 0);
  const expiresAt =
    Number.isFinite(expiresAtSec) && expiresAtSec > 0
      ? new Date(expiresAtSec * 1000)
      : null;

  await integrationRef.set(
    {
      tokens: {
        accessToken,
        refreshToken: nextRefresh,
        expiresAt: expiresAt ?? null,
        tokenType: (parsed.token_type ?? 'Bearer').toString(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  return accessToken;
}

async function getValidAccessToken(db, integration) {
  const tokens = integration.data?.tokens ?? {};
  const accessToken = (tokens.accessToken ?? '').toString();
  const expiresAt = tokens.expiresAt?.toDate?.() ?? null;
  const stillValid =
    accessToken &&
    (!expiresAt || expiresAt.getTime() > Date.now() + 60 * 1000);
  if (stillValid) return accessToken;

  const ref = db.collection(INTEGRATIONS_COLLECTION).doc(integration.id);
  return refreshAccessToken(ref, tokens);
}

function mapStravaActivityType(sportType, type) {
  const raw = `${sportType || ''} ${type || ''}`.toLowerCase();
  if (raw.includes('swim')) return 'natation';
  if (raw.includes('ride') || raw.includes('cycle') || raw.includes('bike')) {
    return 'velo';
  }
  if (raw.includes('walk') || raw.includes('hike')) return 'sortie_longue';
  if (raw.includes('run') || raw.includes('trail')) return 'course';
  return 'entrainement';
}

/**
 * Callable: stravaListActivities
 * Request: { playerId, page?, perPage? }
 * Response: { activities: [...] } — not yet imported into Grinta.
 */
function createStravaListActivities() {
  return onCall(
    {
      region: REGION,
      secrets: [stravaClientId, stravaClientSecret],
      timeoutSeconds: 60,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const playerId = (request.data?.playerId ?? '').toString().trim();
      const page = Math.max(1, Number(request.data?.page ?? 1) || 1);
      const perPage = Math.min(
        50,
        Math.max(1, Number(request.data?.perPage ?? 30) || 30),
      );
      if (!playerId) {
        throw new HttpsError('invalid-argument', 'playerId is required.');
      }

      const db = getFirestore();
      const callerUid = request.auth.uid;
      const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
      if (!memberSnap.exists) {
        throw new HttpsError('not-found', 'Player profile not found.');
      }
      if (!userHasMemberAccess(memberSnap.data() ?? {}, callerUid)) {
        throw new HttpsError(
          'permission-denied',
          'You cannot list Strava activities for this profile.',
        );
      }

      const integration = await loadIntegration(db, callerUid, playerId);
      if (!integration) {
        throw new HttpsError(
          'failed-precondition',
          'Strava is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const url = new URL(STRAVA_ACTIVITIES_URL);
      url.searchParams.set('page', String(page));
      url.searchParams.set('per_page', String(perPage));

      const response = await fetch(url.toString(), {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      const raw = await response.text();
      if (!response.ok) {
        console.error('Strava list activities failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Strava list activities failed (${response.status}).`,
        );
      }

      const list = raw ? JSON.parse(raw) : [];
      if (!Array.isArray(list)) {
        throw new HttpsError('internal', 'Unexpected Strava activities payload.');
      }

      const importedSnap = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'strava')
        .get();
      const imported = new Set(
        importedSnap.docs
          .map((doc) => (doc.data()?.externalId ?? '').toString().trim())
          .filter(Boolean),
      );

      const activities = [];
      for (const entry of list) {
        const id = entry?.id != null ? String(entry.id) : '';
        if (!id || imported.has(id)) continue;
        const distance = Number(entry.distance ?? 0);
        const movingTime = Number(entry.moving_time ?? entry.elapsed_time ?? 0);
        const pace =
          distance > 0 && movingTime > 0
            ? Math.round(movingTime / (distance / 1000))
            : null;
        activities.push({
          externalId: id,
          name: (entry.name ?? '').toString(),
          type: (entry.sport_type ?? entry.type ?? '').toString(),
          typeId: mapStravaActivityType(entry.sport_type, entry.type),
          // Prefer true UTC start_date. start_date_local is wall-clock with a
          // misleading trailing Z and shifts when interpreted as UTC.
          startDate: entry.start_date || entry.start_date_local || null,
          durationSeconds: Number.isFinite(movingTime) ? movingTime : null,
          distanceMeters: Number.isFinite(distance) ? distance : null,
          paceSecondsPerKm: pace,
        });
      }

      return { activities };
    },
  );
}

/**
 * Callable: stravaImportActivity
 * Request: { playerId, externalId, visibility?, feeling?, notes?, typeId? }
 */
function createStravaImportActivity() {
  return onCall(
    {
      region: REGION,
      secrets: [stravaClientId, stravaClientSecret],
      timeoutSeconds: 60,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError('unauthenticated', 'Authentication required.');
      }

      const playerId = (request.data?.playerId ?? '').toString().trim();
      const externalId = (request.data?.externalId ?? '').toString().trim();
      const visibility = (request.data?.visibility ?? 'private')
        .toString()
        .trim()
        .toLowerCase();
      const notes = (request.data?.notes ?? '').toString().trim();
      const feelingRaw = request.data?.feeling;
      const feeling =
        feelingRaw == null || feelingRaw === ''
          ? null
          : Number(feelingRaw);
      const typeIdOverride = (request.data?.typeId ?? '').toString().trim();

      if (!playerId || !externalId) {
        throw new HttpsError(
          'invalid-argument',
          'playerId and externalId are required.',
        );
      }

      const db = getFirestore();
      const callerUid = request.auth.uid;
      const memberSnap = await db.collection(MEMBER_COLLECTION).doc(playerId).get();
      if (!memberSnap.exists) {
        throw new HttpsError('not-found', 'Player profile not found.');
      }
      if (!userHasMemberAccess(memberSnap.data() ?? {}, callerUid)) {
        throw new HttpsError(
          'permission-denied',
          'You cannot import Strava activities for this profile.',
        );
      }

      const existing = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'strava')
        .where('externalId', '==', externalId)
        .limit(1)
        .get();
      if (!existing.empty) {
        throw new HttpsError('already-exists', 'Activity already imported.');
      }

      const integration = await loadIntegration(db, callerUid, playerId);
      if (!integration) {
        throw new HttpsError(
          'failed-precondition',
          'Strava is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const detailUrl = `https://www.strava.com/api/v3/activities/${encodeURIComponent(externalId)}`;
      const response = await fetch(detailUrl, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });
      const raw = await response.text();
      if (!response.ok) {
        console.error('Strava activity detail failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Strava activity detail failed (${response.status}).`,
        );
      }

      const activity = raw ? JSON.parse(raw) : null;
      if (!activity) {
        throw new HttpsError('not-found', 'Strava activity not found.');
      }

      const distance = Number(activity.distance ?? 0);
      const movingTime = Number(
        activity.moving_time ?? activity.elapsed_time ?? 0,
      );
      // Prefer true UTC start_date. start_date_local carries a fake "Z" and
      // must not be parsed as UTC (shifts local display by the TZ offset).
      const startRaw = activity.start_date || null;
      const startAt = startRaw ? new Date(startRaw) : new Date();
      const endAt = new Date(
        startAt.getTime() +
          (Number.isFinite(movingTime) ? movingTime : 0) * 1000,
      );
      const pace =
        distance > 0 && movingTime > 0
          ? Math.round(movingTime / (distance / 1000))
          : null;
      const caloriesRaw = Number(activity.calories ?? NaN);
      const avgHrRaw = Number(activity.average_heartrate ?? NaN);
      const typeId =
        typeIdOverride ||
        mapStravaActivityType(activity.sport_type, activity.type);

      const ref = db.collection(PERSONAL_ACTIVITIES_COLLECTION).doc();
      await ref.set({
        kind: 'personalSport',
        memberId: playerId,
        createdByUserId: callerUid,
        startAt,
        endAt,
        typeId,
        title: (activity.name ?? '').toString() || null,
        visibility: ['private', 'coach', 'team'].includes(visibility)
          ? visibility
          : 'private',
        entryMode: 'import',
        notes: notes || null,
        feeling:
          Number.isFinite(feeling) && feeling >= 1 && feeling <= 5
            ? feeling
            : null,
        durationSeconds: Number.isFinite(movingTime) ? movingTime : null,
        distanceMeters: Number.isFinite(distance) ? distance : null,
        paceSecondsPerKm: pace,
        caloriesKcal: Number.isFinite(caloriesRaw) ? caloriesRaw : null,
        averageHeartRateBpm: Number.isFinite(avgHrRaw)
          ? Math.round(avgHrRaw)
          : null,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: 'strava',
        externalId,
        teamIds: [],
        accessMemberIds: [playerId],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { id: ref.id, imported: true };
    },
  );
}

module.exports = {
  createStravaListActivities,
  createStravaImportActivity,
};
