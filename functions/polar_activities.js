const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const INTEGRATIONS_COLLECTION = 'polar_integrations';
const PERSONAL_ACTIVITIES_COLLECTION = 'personalSportActivities';
const MEMBER_COLLECTION = 'member';
const REGION = 'europe-west1';
const POLAR_ACCESSLINK_BASE = 'https://www.polaraccesslink.com/v3';
const POLAR_EXERCISES_URL = `${POLAR_ACCESSLINK_BASE}/exercises`;

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

/**
 * Polar AccessLink tokens typically last ~1 year and have no refresh_token.
 * If expired, the athlete must reconnect in Devices / Apps.
 */
function getValidAccessToken(integration) {
  const tokens = integration.data?.tokens ?? {};
  const accessToken = (tokens.accessToken ?? '').toString();
  if (!accessToken) {
    throw new HttpsError(
      'failed-precondition',
      'Polar access token missing. Reconnect Polar in Devices / Apps.',
    );
  }
  const expiresAt = tokens.expiresAt?.toDate?.() ?? null;
  if (expiresAt && expiresAt.getTime() <= Date.now() + 60 * 1000) {
    throw new HttpsError(
      'failed-precondition',
      'Polar access token expired. Reconnect Polar in Devices / Apps.',
    );
  }
  return accessToken;
}

function mapPolarSport(sport, detailedSportInfo) {
  const raw = `${sport || ''} ${detailedSportInfo || ''}`.toLowerCase();
  if (raw.includes('swim')) return 'natation';
  if (
    raw.includes('cycl') ||
    raw.includes('bike') ||
    raw.includes('ride') ||
    raw.includes('spinning')
  ) {
    return 'velo';
  }
  if (raw.includes('walk') || raw.includes('hike') || raw.includes('trek')) {
    return 'sortie_longue';
  }
  if (
    raw.includes('run') ||
    raw.includes('jog') ||
    raw.includes('trail') ||
    raw.includes('marathon')
  ) {
    return 'course';
  }
  if (raw.includes('recover') || raw.includes('stretch')) {
    return 'recuperation';
  }
  return 'entrainement';
}

/**
 * Polar start_time is local wall-clock without Z; start_time_utc_offset is
 * minutes east of UTC. Convert to a real UTC Date.
 */
function polarStartToUtc(startTime, utcOffsetMinutes) {
  const raw = (startTime ?? '').toString().trim();
  if (!raw) return new Date();
  const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/.exec(raw);
  if (!match) {
    const parsed = new Date(raw);
    return Number.isNaN(parsed.getTime()) ? new Date() : parsed;
  }
  const offset = Number(utcOffsetMinutes);
  const offsetMs =
    Number.isFinite(offset) ? offset * 60 * 1000 : 0;
  const asUtcMs = Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    Number(match[4]),
    Number(match[5]),
    Number(match[6]),
  );
  return new Date(asUtcMs - offsetMs);
}

/** Parse ISO-8601 duration like PT2H44M / PT1H38M13S → seconds. */
function parseIsoDurationSeconds(iso) {
  const raw = (iso ?? '').toString().trim();
  if (!raw) return null;
  const match =
    /^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?$/i.exec(
      raw,
    );
  if (!match) return null;
  const days = Number(match[1] || 0);
  const hours = Number(match[2] || 0);
  const minutes = Number(match[3] || 0);
  const seconds = Number(match[4] || 0);
  if (![days, hours, minutes, seconds].every((n) => Number.isFinite(n))) {
    return null;
  }
  return Math.round(days * 86400 + hours * 3600 + minutes * 60 + seconds);
}

function humanizeSportLabel(sport, detailedSportInfo) {
  const detailed = (detailedSportInfo ?? '').toString().replace(/_/g, ' ').trim();
  const base = (sport ?? '').toString().replace(/_/g, ' ').trim();
  const label = detailed || base || 'Polar';
  return label
    .toLowerCase()
    .replace(/\b\w/g, (ch) => ch.toUpperCase());
}

function mapExerciseSummary(entry) {
  const id = entry?.id != null ? String(entry.id) : '';
  const distanceRaw = Number(entry?.distance ?? NaN);
  const distance =
    Number.isFinite(distanceRaw) && distanceRaw > 0 ? distanceRaw : null;
  const durationSeconds = parseIsoDurationSeconds(entry?.duration);
  const pace =
    distance != null &&
    durationSeconds != null &&
    durationSeconds > 0 &&
    distance > 0
      ? Math.round(durationSeconds / (distance / 1000))
      : null;
  const caloriesRaw = Number(entry?.calories ?? NaN);
  const avgHrRaw = Number(entry?.heart_rate?.average ?? NaN);
  const startAt = polarStartToUtc(
    entry?.start_time,
    entry?.start_time_utc_offset,
  );

  return {
    externalId: id,
    name: humanizeSportLabel(entry?.sport, entry?.detailed_sport_info),
    type: (entry?.sport ?? '').toString(),
    typeId: mapPolarSport(entry?.sport, entry?.detailed_sport_info),
    device: (entry?.device ?? '').toString() || null,
    startDate: startAt.toISOString(),
    durationSeconds,
    distanceMeters: distance,
    paceSecondsPerKm: pace,
    caloriesKcal: Number.isFinite(caloriesRaw) ? caloriesRaw : null,
    averageHeartRateBpm: Number.isFinite(avgHrRaw)
      ? Math.round(avgHrRaw)
      : null,
  };
}

async function fetchPolarJson(url, accessToken) {
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: 'application/json',
    },
  });
  const raw = await response.text();
  return { response, raw };
}

/**
 * Callable: polarListActivities
 * Request: { playerId }
 * Response: { activities: [...] } — exercises not yet imported into Grinta.
 *
 * AccessLink exposes exercises uploaded to Polar Flow in the last ~30 days
 * (Verity Sense HR sessions, Loop workouts, watches, etc.). Fields vary by
 * device: Verity Sense often has HR/duration/calories without GPS distance.
 */
function createPolarListActivities() {
  return onCall(
    {
      region: REGION,
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
          'You cannot list Polar activities for this profile.',
        );
      }

      const integration = await loadIntegration(db, callerUid, playerId);
      if (!integration) {
        throw new HttpsError(
          'failed-precondition',
          'Polar is not connected for this profile.',
        );
      }

      const accessToken = getValidAccessToken(integration);
      const { response, raw } = await fetchPolarJson(
        POLAR_EXERCISES_URL,
        accessToken,
      );
      if (!response.ok) {
        console.error('Polar list exercises failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Polar list exercises failed (${response.status}).`,
        );
      }

      let list = [];
      try {
        const parsed = raw ? JSON.parse(raw) : [];
        if (Array.isArray(parsed)) {
          list = parsed;
        } else if (Array.isArray(parsed?.exercises)) {
          list = parsed.exercises;
        }
      } catch (error) {
        throw new HttpsError('internal', 'Unexpected Polar exercises payload.');
      }

      const importedSnap = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'polar')
        .get();
      const imported = new Set(
        importedSnap.docs
          .map((doc) => (doc.data()?.externalId ?? '').toString().trim())
          .filter(Boolean),
      );

      const activities = [];
      for (const entry of list) {
        const summary = mapExerciseSummary(entry);
        if (!summary.externalId || imported.has(summary.externalId)) continue;
        activities.push(summary);
      }

      // Newest first (AccessLink order is not guaranteed).
      activities.sort((a, b) => {
        const ta = Date.parse(a.startDate || '') || 0;
        const tb = Date.parse(b.startDate || '') || 0;
        return tb - ta;
      });

      return { activities };
    },
  );
}

/**
 * Callable: polarImportActivity
 * Request: { playerId, externalId, visibility?, feeling?, notes?, typeId? }
 */
function createPolarImportActivity() {
  return onCall(
    {
      region: REGION,
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
          'You cannot import Polar activities for this profile.',
        );
      }

      const existing = await db
        .collection(PERSONAL_ACTIVITIES_COLLECTION)
        .where('memberId', '==', playerId)
        .where('externalSource', '==', 'polar')
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
          'Polar is not connected for this profile.',
        );
      }

      const accessToken = getValidAccessToken(integration);
      const detailUrl = `${POLAR_EXERCISES_URL}/${encodeURIComponent(externalId)}`;
      const { response, raw } = await fetchPolarJson(detailUrl, accessToken);
      if (!response.ok) {
        console.error('Polar exercise detail failed', response.status, raw);
        throw new HttpsError(
          'internal',
          `Polar exercise detail failed (${response.status}).`,
        );
      }

      let exercise = null;
      try {
        exercise = raw ? JSON.parse(raw) : null;
      } catch (error) {
        throw new HttpsError('internal', 'Invalid Polar exercise payload.');
      }
      if (!exercise) {
        throw new HttpsError('not-found', 'Polar exercise not found.');
      }

      const summary = mapExerciseSummary(exercise);
      const durationSeconds = summary.durationSeconds ?? 0;
      const startAt = new Date(summary.startDate);
      const endAt = new Date(
        startAt.getTime() +
          (Number.isFinite(durationSeconds) ? durationSeconds : 0) * 1000,
      );
      const typeId = typeIdOverride || summary.typeId;
      const title = summary.name || 'Polar';

      const ref = db.collection(PERSONAL_ACTIVITIES_COLLECTION).doc();
      await ref.set({
        kind: 'personalSport',
        memberId: playerId,
        createdByUserId: callerUid,
        startAt,
        endAt,
        typeId,
        title,
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
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: 'polar',
        externalId,
        externalDevice: summary.device,
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
  createPolarListActivities,
  createPolarImportActivity,
  mapPolarSport,
  parseIsoDurationSeconds,
  polarStartToUtc,
};
