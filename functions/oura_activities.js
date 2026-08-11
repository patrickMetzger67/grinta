const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const {
  extractMetricsFromHrSamples,
  mapOuraZoneDurationsToSeconds,
  estimateHrMaxFromPersonalInfo,
} = require('./oura_hr_zones');

const ouraClientId = defineSecret('OURA_CLIENT_ID');
const ouraClientSecret = defineSecret('OURA_CLIENT_SECRET');

const INTEGRATIONS_COLLECTION = 'oura_integrations';
const PERSONAL_ACTIVITIES_COLLECTION = 'personalSportActivities';
const MEMBER_COLLECTION = 'member';
const REGION = 'europe-west1';
const OURA_TOKEN_URL = 'https://api.ouraring.com/oauth/token';
const OURA_WORKOUTS_URL = 'https://api.ouraring.com/v2/usercollection/workout';
const OURA_HEARTRATE_URL =
  'https://api.ouraring.com/v2/usercollection/heart_rate';
const OURA_PERSONAL_INFO_URL =
  'https://api.ouraring.com/v2/usercollection/personal_info';

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

function mapOuraActivity(activityName) {
  const raw = (activityName || '').toString().toLowerCase();
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
    raw.includes('rest')
  ) {
    return 'recuperation';
  }
  if (raw.includes('soccer') || raw.includes('football')) {
    return 'entrainement';
  }
  return 'entrainement';
}

function humanizeActivityName(activityName, label) {
  const custom = (label ?? '').toString().trim();
  if (custom) return custom;
  const raw = (activityName ?? '').toString().trim();
  if (!raw) return 'Oura';
  return raw
    .replace(/[_-]+/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (ch) => ch.toUpperCase());
}

function mapWorkoutSummary(entry, hrMetrics = null) {
  const id = entry?.id != null ? String(entry.id) : '';
  const startRaw = (entry?.start_datetime ?? entry?.start ?? '').toString();
  const endRaw = (entry?.end_datetime ?? entry?.end ?? '').toString();
  const startAt = startRaw ? new Date(startRaw) : null;
  const endAt = endRaw ? new Date(endRaw) : null;
  let durationSeconds = null;
  const durationRaw = Number(entry?.duration ?? NaN);
  if (Number.isFinite(durationRaw) && durationRaw > 0) {
    durationSeconds = Math.round(durationRaw);
  } else if (
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
  const calRaw = Number(entry?.calories ?? NaN);
  const caloriesKcal =
    Number.isFinite(calRaw) && calRaw > 0 ? Math.round(calRaw) : null;
  const activityName = (entry?.activity ?? '').toString();

  const avgFromWorkout = Number(
    entry?.average_heart_rate ?? entry?.averageHeartRate ?? NaN,
  );
  const maxFromWorkout = Number(
    entry?.maximum_heart_rate ?? entry?.max_heart_rate ?? NaN,
  );
  const zonesFromWorkout = mapOuraZoneDurationsToSeconds(
    entry?.heart_rate_zones ?? entry?.heartRateZones ?? null,
  );
  const hasWorkoutZones = Object.values(zonesFromWorkout).some((s) => s > 0);

  const averageHeartRateBpm =
    hrMetrics?.averageHeartRateBpm ??
    (Number.isFinite(avgFromWorkout) ? Math.round(avgFromWorkout) : null);
  const maxHeartRateBpm =
    hrMetrics?.maxHeartRateBpm ??
    (Number.isFinite(maxFromWorkout) ? Math.round(maxFromWorkout) : null);
  const hrZoneSeconds =
    hrMetrics?.hrZoneSeconds &&
    Object.values(hrMetrics.hrZoneSeconds).some((s) => s > 0)
      ? hrMetrics.hrZoneSeconds
      : hasWorkoutZones
        ? zonesFromWorkout
        : zonesFromWorkout;

  return {
    externalId: id,
    name: humanizeActivityName(activityName, entry?.label),
    type: activityName,
    typeId: mapOuraActivity(activityName),
    intensity: (entry?.intensity ?? '').toString() || null,
    source: (entry?.source ?? '').toString() || null,
    startDate:
      startAt && !Number.isNaN(startAt.getTime())
        ? startAt.toISOString()
        : null,
    endDate:
      endAt && !Number.isNaN(endAt.getTime()) ? endAt.toISOString() : null,
    durationSeconds,
    distanceMeters: distance,
    paceSecondsPerKm: pace,
    caloriesKcal,
    averageHeartRateBpm,
    maxHeartRateBpm,
    hrZoneSeconds,
  };
}

async function fetchOuraPersonalInfo(accessToken) {
  try {
    const response = await fetch(OURA_PERSONAL_INFO_URL, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    if (!response.ok) {
      console.warn('Oura personal_info failed', response.status);
      return null;
    }
    return JSON.parse(await response.text());
  } catch (err) {
    console.warn('Oura personal_info error', err);
    return null;
  }
}

async function fetchOuraHeartRateSamples(accessToken, startIso, endIso) {
  const samples = [];
  let nextToken = null;
  let pages = 0;
  const maxPages = 6;

  do {
    const url = new URL(OURA_HEARTRATE_URL);
    if (startIso) url.searchParams.set('start_datetime', startIso);
    if (endIso) url.searchParams.set('end_datetime', endIso);
    if (nextToken) url.searchParams.set('next_token', nextToken);

    const response = await fetch(url.toString(), {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });
    const raw = await response.text();
    if (!response.ok) {
      console.warn('Oura heart_rate failed', response.status, raw);
      break;
    }
    let parsed;
    try {
      parsed = raw ? JSON.parse(raw) : {};
    } catch (_) {
      break;
    }
    const rows = Array.isArray(parsed?.data) ? parsed.data : [];
    samples.push(...rows);
    nextToken = (parsed?.next_token ?? '').toString() || null;
    pages += 1;
  } while (nextToken && pages < maxPages);

  return samples;
}

async function fetchOuraWorkouts(accessToken) {
  const activities = [];
  let nextToken = null;
  let pages = 0;
  const maxPages = 6;

  // Last ~90 days of workouts.
  const end = new Date();
  const start = new Date(end.getTime() - 90 * 24 * 60 * 60 * 1000);
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

    const records = Array.isArray(parsed?.data) ? parsed.data : [];
    activities.push(...records);
    nextToken = (parsed?.next_token ?? '').toString() || null;
    pages += 1;
  } while (nextToken && pages < maxPages);

  return activities;
}

async function enrichWorkoutWithHr(accessToken, workout, hrMaxBpm) {
  const summary = mapWorkoutSummary(workout);
  const startIso = summary.startDate;
  const endIso =
    summary.endDate ||
    (summary.startDate && summary.durationSeconds != null
      ? new Date(
          Date.parse(summary.startDate) + summary.durationSeconds * 1000,
        ).toISOString()
      : null);

  if (!startIso || !endIso) {
    return summary;
  }

  const samples = await fetchOuraHeartRateSamples(accessToken, startIso, endIso);
  const hrMetrics = extractMetricsFromHrSamples(samples, {
    hrMaxBpm,
    workoutDurationSeconds: summary.durationSeconds,
  });
  return mapWorkoutSummary(workout, hrMetrics);
}

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

function createOuraImportActivity() {
  return onCall(
    {
      region: REGION,
      secrets: [ouraClientId, ouraClientSecret],
      timeoutSeconds: 120,
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

      const personalInfo = await fetchOuraPersonalInfo(accessToken);
      const estimatedMax = estimateHrMaxFromPersonalInfo(personalInfo);
      const summary = await enrichWorkoutWithHr(
        accessToken,
        workout,
        estimatedMax,
      );
      const durationSeconds = summary.durationSeconds ?? 0;
      const startAt = summary.startDate
        ? new Date(summary.startDate)
        : new Date();
      const endAt = summary.endDate
        ? new Date(summary.endDate)
        : new Date(
            startAt.getTime() +
              (Number.isFinite(durationSeconds) ? durationSeconds : 0) * 1000,
          );
      const typeId = typeIdOverride || summary.typeId;
      const hrMaxUsedBpm = estimatedMax ?? summary.maxHeartRateBpm ?? null;

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
        strain: null,
        altitudeGainMeters: null,
        hrZoneSeconds: summary.hrZoneSeconds ?? {},
        hrMaxUsedBpm,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: 'oura',
        externalId,
        externalDevice: 'Oura',
        ouraIntensity: summary.intensity,
        ouraWorkoutSource: summary.source,
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
  mapOuraActivity,
  mapWorkoutSummary,
  enrichWorkoutWithHr,
};
