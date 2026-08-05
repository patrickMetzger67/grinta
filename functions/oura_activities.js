const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const ouraClientId = defineSecret('OURA_CLIENT_ID');
const ouraClientSecret = defineSecret('OURA_CLIENT_SECRET');

const INTEGRATIONS_COLLECTION = 'oura_integrations';
const PERSONAL_ACTIVITIES_COLLECTION = 'personalSportActivities';
const MEMBER_COLLECTION = 'member';
const REGION = 'europe-west1';
const OURA_TOKEN_URL = 'https://api.ouraring.com/oauth/token';
const OURA_WORKOUTS_URL =
  'https://api.ouraring.com/v2/usercollection/workout';

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

/** Oura refresh tokens are single-use — always persist the new refresh_token. */
async function refreshAccessToken(integrationRef, tokens) {
  const refreshToken = (tokens?.refreshToken ?? '').toString();
  if (!refreshToken) {
    throw new HttpsError('failed-precondition', 'Oura refresh token missing.');
  }

  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: ouraClientId.value(),
    client_secret: ouraClientSecret.value(),
  });

  const response = await fetch(OURA_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });
  const raw = await response.text();
  if (!response.ok) {
    console.error('Oura token refresh failed', response.status, raw);
    throw new HttpsError('unauthenticated', 'Oura token refresh failed.');
  }

  const parsed = JSON.parse(raw);
  const accessToken = (parsed.access_token ?? '').toString();
  const nextRefresh = (parsed.refresh_token ?? refreshToken).toString();
  const expiresIn = Number(parsed.expires_in ?? 0);
  const expiresAt =
    Number.isFinite(expiresIn) && expiresIn > 0
      ? new Date(Date.now() + expiresIn * 1000)
      : null;

  if (!accessToken) {
    throw new HttpsError('unauthenticated', 'Oura refresh returned no token.');
  }

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

function mapOuraSport(activity) {
  const raw = (activity || '').toString().toLowerCase();
  if (raw.includes('swim') || raw.includes('aqua')) return 'natation';
  if (
    raw.includes('cycl') ||
    raw.includes('bike') ||
    raw.includes('ride') ||
    raw.includes('spin') ||
    raw.includes('rowing')
  ) {
    return 'velo';
  }
  if (
    raw.includes('walk') ||
    raw.includes('hike') ||
    raw.includes('trek') ||
    raw.includes('hiking')
  ) {
    return 'sortie_longue';
  }
  if (
    raw.includes('run') ||
    raw.includes('jog') ||
    raw.includes('trail') ||
    raw.includes('sprint') ||
    raw.includes('elliptical')
  ) {
    return 'course';
  }
  if (
    raw.includes('yoga') ||
    raw.includes('stretch') ||
    raw.includes('meditation') ||
    raw.includes('breath') ||
    raw.includes('restorative') ||
    raw.includes('recover') ||
    raw.includes('sauna') ||
    raw.includes('massage')
  ) {
    return 'recuperation';
  }
  return 'entrainement';
}

function humanizeActivityName(activity, label) {
  const custom = (label ?? '').toString().trim();
  if (custom) return custom;
  const raw = (activity ?? '').toString().trim();
  if (!raw) return 'Oura';
  return raw
    .replace(/[_-]+/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (ch) => ch.toUpperCase());
}

function mapWorkoutSummary(entry) {
  const id = entry?.id != null ? String(entry.id) : '';
  const startRaw = (entry?.start_datetime ?? entry?.startDatetime ?? '').toString();
  const endRaw = (entry?.end_datetime ?? entry?.endDatetime ?? '').toString();
  const startAt = startRaw ? new Date(startRaw) : null;
  const endAt = endRaw ? new Date(endRaw) : null;
  let durationSeconds = null;
  if (
    startAt &&
    endAt &&
    !Number.isNaN(startAt.getTime()) &&
    !Number.isNaN(endAt.getTime()) &&
    endAt.getTime() >= startAt.getTime()
  ) {
    durationSeconds = Math.round((endAt.getTime() - startAt.getTime()) / 1000);
  }

  const distanceRaw = Number(entry?.distance ?? NaN);
  const distance =
    Number.isFinite(distanceRaw) && distanceRaw > 0 ? distanceRaw : null;
  const pace =
    distance != null &&
    durationSeconds != null &&
    durationSeconds > 0 &&
    distance > 0
      ? Math.round(durationSeconds / (distance / 1000))
      : null;
  const caloriesRaw = Number(entry?.calories ?? NaN);
  const caloriesKcal =
    Number.isFinite(caloriesRaw) && caloriesRaw > 0
      ? Math.round(caloriesRaw)
      : null;
  const activity = (entry?.activity ?? '').toString();
  const label = entry?.label ?? null;
  const intensity = (entry?.intensity ?? '').toString() || null;

  // Public workout schema does not always include HR; accept optional fields.
  const hr = entry?.heart_rate ?? entry?.heartRate ?? null;
  const avgHrRaw = Number(hr?.avg ?? hr?.average ?? entry?.average_heart_rate ?? NaN);
  const maxHrRaw = Number(hr?.max ?? hr?.maximum ?? entry?.max_heart_rate ?? NaN);

  return {
    externalId: id,
    name: humanizeActivityName(activity, label),
    type: activity,
    typeId: mapOuraSport(activity),
    intensity,
    startDate:
      startAt && !Number.isNaN(startAt.getTime())
        ? startAt.toISOString()
        : null,
    durationSeconds,
    distanceMeters: distance,
    paceSecondsPerKm: pace,
    caloriesKcal,
    averageHeartRateBpm:
      Number.isFinite(avgHrRaw) && avgHrRaw > 0 ? Math.round(avgHrRaw) : null,
    maxHeartRateBpm:
      Number.isFinite(maxHrRaw) && maxHrRaw > 0 ? Math.round(maxHrRaw) : null,
  };
}

async function fetchOuraWorkouts(accessToken, { maxPages = 4 } = {}) {
  const activities = [];
  let nextToken = null;
  let pages = 0;

  // Default window: last ~90 days when no token pagination yet.
  const end = new Date();
  const start = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const startDate = start.toISOString().slice(0, 10);
  const endDate = end.toISOString().slice(0, 10);

  do {
    const url = new URL(OURA_WORKOUTS_URL);
    url.searchParams.set('start_date', startDate);
    url.searchParams.set('end_date', endDate);
    if (nextToken) url.searchParams.set('next_token', nextToken);

    const response = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    const raw = await response.text();
    if (!response.ok) {
      console.error('Oura list workouts failed', response.status, raw);
      throw new HttpsError(
        'internal',
        `Oura list workouts failed (${response.status}).`,
      );
    }

    let parsed;
    try {
      parsed = raw ? JSON.parse(raw) : {};
    } catch (_) {
      throw new HttpsError('internal', 'Unexpected Oura workouts payload.');
    }

    const records = Array.isArray(parsed?.data)
      ? parsed.data
      : Array.isArray(parsed)
        ? parsed
        : [];
    activities.push(...records);
    nextToken = (parsed?.next_token ?? parsed?.nextToken ?? '').toString() || null;
    pages += 1;
  } while (nextToken && pages < maxPages);

  return activities;
}

/**
 * Callable: ouraListActivities
 * Request: { playerId }
 * Response: { activities, diagnostics }
 */
function createOuraListActivities() {
  return onCall(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
      timeoutSeconds: 60,
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
      if (!userHasMemberAccess(memberSnap.data() ?? {}, callerUid)) {
        throw new HttpsError(
          'permission-denied',
          'You cannot list Oura activities for this profile.',
        );
      }

      const integration = await loadIntegration(db, callerUid, playerId);
      if (!integration) {
        throw new HttpsError(
          'failed-precondition',
          'Oura is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const list = await fetchOuraWorkouts(accessToken);

      const importedSnap = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'oura')
        .get();
      const imported = new Set(
        importedSnap.docs
          .map((doc) => (doc.data()?.externalId ?? '').toString().trim())
          .filter(Boolean),
      );

      const activities = [];
      let skippedImported = 0;
      for (const entry of list) {
        const summary = mapWorkoutSummary(entry);
        if (!summary.externalId) continue;
        if (imported.has(summary.externalId)) {
          skippedImported += 1;
          continue;
        }
        activities.push(summary);
      }

      activities.sort((a, b) => {
        const ta = Date.parse(a.startDate || '') || 0;
        const tb = Date.parse(b.startDate || '') || 0;
        return tb - ta;
      });

      console.log('ouraListActivities result', {
        playerId,
        fetchedFromOura: list.length,
        skippedImported,
        importable: activities.length,
      });

      return {
        activities,
        diagnostics: {
          fetchedFromOura: list.length,
          skippedImported,
          importable: activities.length,
          emptyReason:
            list.length === 0
              ? 'oura_no_workouts'
              : activities.length === 0
                ? 'all_already_imported'
                : null,
        },
      };
    },
  );
}

/**
 * Callable: ouraImportActivity
 * Request: { playerId, externalId, visibility?, feeling?, notes?, typeId? }
 */
function createOuraImportActivity() {
  return onCall(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
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
        feelingRaw == null || feelingRaw === '' ? null : Number(feelingRaw);
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
          'You cannot import Oura activities for this profile.',
        );
      }

      const existing = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'oura')
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
          'Oura is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const detailUrl = `${OURA_WORKOUTS_URL}/${encodeURIComponent(externalId)}`;
      const response = await fetch(detailUrl, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/json',
        },
      });
      const raw = await response.text();
      if (!response.ok) {
        console.error('Oura workout detail failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Oura workout detail failed (${response.status}).`,
        );
      }

      let workout = null;
      try {
        workout = raw ? JSON.parse(raw) : null;
      } catch (_) {
        throw new HttpsError('internal', 'Invalid Oura workout payload.');
      }
      if (!workout) {
        throw new HttpsError('not-found', 'Oura workout not found.');
      }

      const summary = mapWorkoutSummary(workout);
      const durationSeconds = summary.durationSeconds ?? 0;
      const startAt = summary.startDate
        ? new Date(summary.startDate)
        : new Date();
      const endAt = new Date(
        startAt.getTime() +
          (Number.isFinite(durationSeconds) ? durationSeconds : 0) * 1000,
      );
      const typeId = typeIdOverride || summary.typeId;

      const ref = db.collection(PERSONAL_ACTIVITIES_COLLECTION).doc();
      await ref.set({
        kind: 'personalSport',
        memberId: playerId,
        createdByUserId: callerUid,
        startAt,
        endAt,
        typeId,
        title: summary.name || 'Oura',
        visibility: ['private', 'coach', 'team'].includes(visibility)
          ? visibility
          : 'private',
        entryMode: 'import',
        notes: notes || null,
        feeling:
          Number.isFinite(feeling) && feeling >= 1 && feeling <= 5
            ? feeling
            : null,
        durationSeconds: summary.durationSeconds,
        distanceMeters: summary.distanceMeters,
        paceSecondsPerKm: summary.paceSecondsPerKm,
        caloriesKcal: summary.caloriesKcal,
        averageHeartRateBpm: summary.averageHeartRateBpm,
        maxHeartRateBpm: summary.maxHeartRateBpm,
        intensity: summary.intensity,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: 'oura',
        externalId,
        externalDevice: 'Oura',
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
  createOuraListActivities,
  createOuraImportActivity,
  mapOuraSport,
  mapWorkoutSummary,
};
