const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { extractWhoopScoreMetrics } = require('./whoop_hr_zones');

const whoopClientId = defineSecret('WHOOP_CLIENT_ID');
const whoopClientSecret = defineSecret('WHOOP_CLIENT_SECRET');

const INTEGRATIONS_COLLECTION = 'whoop_integrations';
const PERSONAL_ACTIVITIES_COLLECTION = 'personalSportActivities';
const MEMBER_COLLECTION = 'member';
const REGION = 'europe-west1';
const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token';
const WHOOP_WORKOUTS_URL =
  'https://api.prod.whoop.com/developer/v2/activity/workout';
const WHOOP_BODY_URL =
  'https://api.prod.whoop.com/developer/v2/user/measurement/body';

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

/** Whoop refresh tokens rotate — always persist the new refresh_token. */
async function refreshAccessToken(integrationRef, tokens) {
  const refreshToken = (tokens?.refreshToken ?? '').toString();
  if (!refreshToken) {
    throw new HttpsError('failed-precondition', 'Whoop refresh token missing.');
  }

  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: whoopClientId.value(),
    client_secret: whoopClientSecret.value(),
  });

  const response = await fetch(WHOOP_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  });
  const raw = await response.text();
  if (!response.ok) {
    console.error('Whoop token refresh failed', response.status, raw);
    throw new HttpsError('unauthenticated', 'Whoop token refresh failed.');
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
    throw new HttpsError('unauthenticated', 'Whoop refresh returned no token.');
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

function mapWhoopSport(sportName) {
  const raw = (sportName || '').toString().toLowerCase();
  if (raw.includes('swim')) return 'natation';
  if (
    raw.includes('cycl') ||
    raw.includes('bike') ||
    raw.includes('ride') ||
    raw.includes('spin')
  ) {
    return 'velo';
  }
  if (raw.includes('walk') || raw.includes('hike') || raw.includes('ruck')) {
    return 'sortie_longue';
  }
  if (
    raw.includes('run') ||
    raw.includes('jog') ||
    raw.includes('trail') ||
    raw.includes('sprint')
  ) {
    return 'course';
  }
  if (
    raw.includes('recover') ||
    raw.includes('yoga') ||
    raw.includes('stretch') ||
    raw.includes('meditation') ||
    raw.includes('sauna') ||
    raw.includes('ice bath') ||
    raw.includes('massage')
  ) {
    return 'recuperation';
  }
  return 'entrainement';
}

function humanizeSportName(sportName) {
  const raw = (sportName ?? '').toString().trim();
  if (!raw) return 'Whoop';
  return raw
    .replace(/[_-]+/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (ch) => ch.toUpperCase());
}

function mapWorkoutSummary(entry) {
  const id = entry?.id != null ? String(entry.id) : '';
  const startRaw = (entry?.start ?? '').toString();
  const endRaw = (entry?.end ?? '').toString();
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

  const score =
    (entry?.score_state ?? '').toString().toUpperCase() === 'SCORED'
      ? entry?.score ?? null
      : entry?.score ?? null;
  const distanceRaw = Number(score?.distance_meter ?? NaN);
  const distance =
    Number.isFinite(distanceRaw) && distanceRaw > 0 ? distanceRaw : null;
  const pace =
    distance != null &&
    durationSeconds != null &&
    durationSeconds > 0 &&
    distance > 0
      ? Math.round(durationSeconds / (distance / 1000))
      : null;
  const kjRaw = Number(score?.kilojoule ?? NaN);
  const caloriesKcal = Number.isFinite(kjRaw) ? kjRaw / 4.184 : null;
  const sportName = (entry?.sport_name ?? '').toString();
  const metrics = extractWhoopScoreMetrics(entry);

  return {
    externalId: id,
    name: humanizeSportName(sportName),
    type: sportName,
    typeId: mapWhoopSport(sportName),
    startDate:
      startAt && !Number.isNaN(startAt.getTime())
        ? startAt.toISOString()
        : null,
    durationSeconds,
    distanceMeters: distance,
    paceSecondsPerKm: pace,
    caloriesKcal:
      caloriesKcal != null && Number.isFinite(caloriesKcal)
        ? Math.round(caloriesKcal)
        : null,
    averageHeartRateBpm: metrics.averageHeartRateBpm,
    maxHeartRateBpm: metrics.maxHeartRateBpm,
    strain: metrics.strain,
    altitudeGainMeters: metrics.altitudeGainMeters,
    hrZoneSeconds: metrics.hrZoneSeconds,
  };
}

/**
 * Optional body max HR for zone BPM labels (Whoop %-based zones).
 * @param {string} accessToken
 * @returns {Promise<number|null>}
 */
async function fetchWhoopBodyMaxHr(accessToken) {
  try {
    const response = await fetch(WHOOP_BODY_URL, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    if (!response.ok) {
      console.warn('Whoop body measurement failed', response.status);
      return null;
    }
    const raw = await response.text();
    const parsed = raw ? JSON.parse(raw) : null;
    const maxHr = Number(parsed?.max_heart_rate ?? NaN);
    return Number.isFinite(maxHr) && maxHr > 0 ? Math.round(maxHr) : null;
  } catch (err) {
    console.warn('Whoop body measurement error', err);
    return null;
  }
}

async function fetchWhoopWorkouts(accessToken, { limit = 25 } = {}) {
  const activities = [];
  let nextToken = null;
  let pages = 0;
  const maxPages = 4;

  do {
    const url = new URL(WHOOP_WORKOUTS_URL);
    url.searchParams.set('limit', String(Math.min(25, Math.max(1, limit))));
    if (nextToken) url.searchParams.set('nextToken', nextToken);

    const response = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    const raw = await response.text();
    if (!response.ok) {
      console.error('Whoop list workouts failed', response.status, raw);
      throw new HttpsError(
        'internal',
        `Whoop list workouts failed (${response.status}).`,
      );
    }

    let parsed;
    try {
      parsed = raw ? JSON.parse(raw) : {};
    } catch (_) {
      throw new HttpsError('internal', 'Unexpected Whoop workouts payload.');
    }

    const records = Array.isArray(parsed?.records)
      ? parsed.records
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
 * Callable: whoopListActivities
 * Request: { playerId }
 * Response: { activities, diagnostics }
 */
function createWhoopListActivities() {
  return onCall(
    {
      region: REGION,
      secrets: [whoopClientId, whoopClientSecret],
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
          'You cannot list Whoop activities for this profile.',
        );
      }

      const integration = await loadIntegration(db, callerUid, playerId);
      if (!integration) {
        throw new HttpsError(
          'failed-precondition',
          'Whoop is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const list = await fetchWhoopWorkouts(accessToken, { limit: 25 });

      const importedSnap = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'whoop')
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

      console.log('whoopListActivities result', {
        playerId,
        fetchedFromWhoop: list.length,
        skippedImported,
        importable: activities.length,
      });

      return {
        activities,
        diagnostics: {
          fetchedFromWhoop: list.length,
          skippedImported,
          importable: activities.length,
          emptyReason:
            list.length === 0
              ? 'whoop_no_workouts'
              : activities.length === 0
                ? 'all_already_imported'
                : null,
        },
      };
    },
  );
}

/**
 * Callable: whoopImportActivity
 * Request: { playerId, externalId, visibility?, feeling?, notes?, typeId? }
 */
function createWhoopImportActivity() {
  return onCall(
    {
      region: REGION,
      secrets: [whoopClientId, whoopClientSecret],
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
          'You cannot import Whoop activities for this profile.',
        );
      }

      const existing = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'whoop')
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
          'Whoop is not connected for this profile.',
        );
      }

      const accessToken = await getValidAccessToken(db, integration);
      const detailUrl = `${WHOOP_WORKOUTS_URL}/${encodeURIComponent(externalId)}`;
      const response = await fetch(detailUrl, {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          Accept: 'application/json',
        },
      });
      const raw = await response.text();
      if (!response.ok) {
        console.error('Whoop workout detail failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Whoop workout detail failed (${response.status}).`,
        );
      }

      let workout = null;
      try {
        workout = raw ? JSON.parse(raw) : null;
      } catch (_) {
        throw new HttpsError('internal', 'Invalid Whoop workout payload.');
      }
      if (!workout) {
        throw new HttpsError('not-found', 'Whoop workout not found.');
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
      const bodyMaxHr = await fetchWhoopBodyMaxHr(accessToken);
      const hrMaxUsedBpm = bodyMaxHr ?? summary.maxHeartRateBpm ?? null;

      const ref = db.collection(PERSONAL_ACTIVITIES_COLLECTION).doc();
      await ref.set({
        kind: 'personalSport',
        memberId: playerId,
        createdByUserId: callerUid,
        startAt,
        endAt,
        typeId,
        title: summary.name || 'Whoop',
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
        strain: summary.strain,
        altitudeGainMeters: summary.altitudeGainMeters,
        hrZoneSeconds: summary.hrZoneSeconds ?? {},
        hrMaxUsedBpm,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: 'whoop',
        externalId,
        externalDevice: 'Whoop',
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
  createWhoopListActivities,
  createWhoopImportActivity,
  mapWhoopSport,
  mapWorkoutSummary,
  fetchWhoopBodyMaxHr,
};
