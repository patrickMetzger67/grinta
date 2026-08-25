const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

const {
  tsToDate,
  resolveMatchIntenseFetchWindow,
  matchIntenseEnd,
  filterSamplesToMatchPeriods,
  isEligibleForAutoSync,
} = require('./intense_match_window');

const REGION = 'europe-west1';

const TRAINING_COLLECTION = 'training';
const MATCH_COLLECTION = 'matchCalendar';
const OWNER_COLLECTION = 'TRACKER_Owner';
const DEVICE_OWNER_COLLECTION = 'TRACKER_DeviceOwner';
const MATCH_COMPO_COLLECTION = 'matchCompo';
const FIELDS_COLLECTION = 'TRACKER_Fields';
const HIGHLIGHTS_COLLECTION = 'highLights';

const DEFAULT_AUTO_SYNC_CONFIG = {
  graceMinutes: 10,
  insidersRetentionHours: 48,
  maxDevicesPerEvent: 30,
  maxEventsPerRun: 10,
};

function getDb() {
  return getFirestore();
}

function loadRuntimeDeps() {
  let fetchIntensePreprocessedSamplesCore;
  let runInsidersSensorAnalysis;
  let readIntenseAutoSyncConfig;
  let computeAndSaveTeamWorkloadSummary;

  try {
    ({
      fetchIntensePreprocessedSamplesCore,
      runInsidersSensorAnalysis,
    } = require('./insidersAnalysis'));
  } catch (e) {
    throw new Error(
      `insidersAnalysis.js is required for insidersScheduledIntenseSync: ${e.message}`,
    );
  }

  try {
    ({ readIntenseAutoSyncConfig } = require('./intenseAutoSyncConfig'));
  } catch (_) {
    readIntenseAutoSyncConfig = async () => ({ ...DEFAULT_AUTO_SYNC_CONFIG });
  }

  try {
    ({ computeAndSaveTeamWorkloadSummary } = require('./teamWorkloadSummary'));
  } catch (e) {
    throw new Error(
      `teamWorkloadSummary.js is required for insidersScheduledIntenseSync: ${e.message}`,
    );
  }

  return {
    fetchIntensePreprocessedSamplesCore,
    runInsidersSensorAnalysis,
    readIntenseAutoSyncConfig,
    computeAndSaveTeamWorkloadSummary,
  };
}

function resolveTrainingStartAt(data) {
  return tsToDate(data.trainingStartAt) ?? tsToDate(data.dateTime);
}

function resolveScheduledEnd({ startAt, durationMinutes }) {
  if (!startAt) return null;
  const duration = Number(durationMinutes) > 0 ? Number(durationMinutes) : 90;
  return new Date(startAt.getTime() + duration * 60 * 1000);
}

function resolveTrainingScheduledEnd(data) {
  const startAt = resolveTrainingStartAt(data);
  return resolveScheduledEnd({ startAt, durationMinutes: data.duration });
}

function toIsoUtc(date) {
  return date.toISOString();
}

function resolveSessionDurationMs({ startAt, scheduledEnd, durationMinutes }) {
  const duration = Number(durationMinutes);
  if (Number.isFinite(duration) && duration > 0) {
    return duration * 60 * 1000;
  }
  if (startAt && scheduledEnd) {
    const ms = scheduledEnd.getTime() - startAt.getTime();
    if (ms > 0) return ms;
  }
  return null;
}

async function loadIntenseOwnerIds() {
  const snap = await getDb()
    .collection(OWNER_COLLECTION)
    .where('withSyncing', '==', false)
    .get();
  const ids = new Set();
  for (const doc of snap.docs) {
    ids.add(doc.id);
    const storedId = String(doc.data()?.id ?? '').trim();
    if (storedId) ids.add(storedId);
  }
  return ids;
}

const deviceOwnerCache = new Map();

async function loadDeviceOwner(docId) {
  const key = String(docId ?? '').trim();
  if (!key) return null;
  if (deviceOwnerCache.has(key)) {
    return deviceOwnerCache.get(key);
  }
  const doc = await getDb().collection(DEVICE_OWNER_COLLECTION).doc(key).get();
  if (!doc.exists) {
    deviceOwnerCache.set(key, null);
    return null;
  }
  const data = { id: doc.id, ...doc.data() };
  deviceOwnerCache.set(key, data);
  return data;
}

function trackerIdForAnalysis(deviceOwner) {
  const custom = String(deviceOwner?.customeName ?? deviceOwner?.customName ?? '').trim();
  if (custom) return custom;
  return String(deviceOwner?.deviceId ?? '').trim();
}

function isPresentPlayerTraining(entry) {
  const raw = entry?.presenceType;
  if (raw == null || raw === '') return true;
  const value = String(raw).toLowerCase();
  return value.includes('present');
}

async function collectTrainingDeviceTargets(trainingData) {
  const playerTraining = Array.isArray(trainingData.playerTraining)
    ? trainingData.playerTraining
    : [];
  const targets = [];

  for (const pt of playerTraining) {
    if (!isPresentPlayerTraining(pt)) continue;

    const playerId = String(pt?.playerId ?? '').trim();
    const deviceOwnerDocId = String(pt?.deviceId ?? '').trim();
    if (!playerId || !deviceOwnerDocId) continue;

    const deviceOwner = await loadDeviceOwner(deviceOwnerDocId);
    if (!deviceOwner) continue;

    const insidersDeviceId = String(deviceOwner.deviceId ?? '').trim();
    const trackerId = trackerIdForAnalysis(deviceOwner);
    if (!insidersDeviceId || !trackerId) continue;

    targets.push({
      playerId,
      deviceOwnerDocId,
      insidersDeviceId,
      trackerId,
    });
  }

  return targets;
}

function collectPlayersFromCompoLists(...lists) {
  const players = [];
  for (const list of lists) {
    if (!Array.isArray(list)) continue;
    for (const entry of list) {
      if (entry && typeof entry === 'object') {
        players.push(entry);
      }
    }
  }
  return players;
}

async function collectMatchDeviceTargets(matchId, matchData, config) {
  const compoSnap = await getDb()
    .collection(MATCH_COMPO_COLLECTION)
    .where('matchID', '==', matchId)
    .limit(3)
    .get();

  if (compoSnap.empty) return [];

  const teamId = String(matchData.teamID ?? '').trim();
  let compoDoc = compoSnap.docs[0];
  if (teamId) {
    const matched = compoSnap.docs.find(
      (d) => String(d.data()?.teamID ?? '').trim() === teamId,
    );
    if (matched) compoDoc = matched;
  }

  const compo = compoDoc.data() ?? {};
  const players = collectPlayersFromCompoLists(
    compo.goalkeeper,
    compo.defender,
    compo.midfielder,
    compo.midfielderAttacking,
    compo.midfielderDefensive,
    compo.stricker,
    compo.substitute,
  );

  const targets = [];
  const seen = new Set();

  for (const player of players) {
    const playerId = String(player?.playerID ?? player?.playerId ?? '').trim();
    const deviceOwnerDocId = String(
      player?.deviceOwnerId ?? player?.deviceId ?? '',
    ).trim();
    if (!playerId || !deviceOwnerDocId) continue;

    const dedupeKey = `${playerId}:${deviceOwnerDocId}`;
    if (seen.has(dedupeKey)) continue;
    seen.add(dedupeKey);

    const deviceOwner = await loadDeviceOwner(deviceOwnerDocId);
    if (!deviceOwner) continue;

    const insidersDeviceId = String(deviceOwner.deviceId ?? '').trim();
    const trackerId = trackerIdForAnalysis(deviceOwner);
    if (!insidersDeviceId || !trackerId) continue;

    targets.push({
      playerId,
      deviceOwnerDocId,
      insidersDeviceId,
      trackerId,
    });
  }

  return targets.slice(0, config.maxDevicesPerEvent);
}

async function loadFieldGps(fieldId) {
  const id = String(fieldId ?? '').trim();
  if (!id) return null;

  const doc = await getDb().collection(FIELDS_COLLECTION).doc(id).get();
  if (!doc.exists) return null;

  const data = doc.data() ?? {};
  const corners = data.fieldGpsCorners ?? data.fieldGps ?? null;
  if (!corners || typeof corners !== 'object') return null;

  return corners;
}

async function loadMatchHighlights(matchId) {
  const snap = await getDb()
    .collection(HIGHLIGHTS_COLLECTION)
    .where('matchCalendarId', '==', matchId)
    .get();
  return snap.docs.map((doc) => doc.data() ?? {});
}

async function syncDeviceForScheduler({
  insidersDeviceId,
  trackerId,
  playerId,
  eventId,
  isMatch,
  startIso,
  stopIso,
  fieldGps,
  playPeriods = [],
  fetchIntensePreprocessedSamplesCore,
  runInsidersSensorAnalysis,
}) {
  try {
    const fetchResult = await fetchIntensePreprocessedSamplesCore({
      insidersDeviceId,
      trackerId,
      startIso,
      stopIso,
    });

    let samples = Array.isArray(fetchResult?.samples) ? fetchResult.samples : [];
    if (isMatch && playPeriods.length > 0 && samples.length > 0) {
      samples = filterSamplesToMatchPeriods(samples, playPeriods);
    }

    if (!samples.length) {
      console.log(
        `[intenseScheduledSync] empty samples event=${eventId} tracker=${trackerId} — OK`,
      );
      return { status: 'empty', samplesCount: 0 };
    }

    await runInsidersSensorAnalysis({
      trackerId,
      playerId,
      eventId,
      isMatch,
      docId: `${eventId}_${trackerId}`,
      teamId: '0',
      insidersDeviceId,
      samples,
      fieldGps,
      generateHeatmaps: Boolean(isMatch && fieldGps),
      generatePng: false,
    });

    return { status: 'ok', samplesCount: samples.length };
  } catch (e) {
    const message = e?.message ? String(e.message) : String(e);
    console.warn(
      `[intenseScheduledSync] device sync failed event=${eventId} tracker=${trackerId}: ${message}`,
    );
    return { status: 'error', message };
  }
}

async function processEventDevices({
  eventId,
  isMatch,
  startAt,
  scheduledEnd,
  targets,
  fieldGps,
  config,
  playPeriods = [],
  fetchIntensePreprocessedSamplesCore,
  runInsidersSensorAnalysis,
}) {
  const startIso = toIsoUtc(startAt);
  const stopIso = toIsoUtc(scheduledEnd);

  const results = [];
  for (const target of targets.slice(0, config.maxDevicesPerEvent)) {
    const result = await syncDeviceForScheduler({
      insidersDeviceId: target.insidersDeviceId,
      trackerId: target.trackerId,
      playerId: target.playerId,
      eventId,
      isMatch,
      startIso,
      stopIso,
      fieldGps,
      playPeriods,
      fetchIntensePreprocessedSamplesCore,
      runInsidersSensorAnalysis,
    });
    results.push({ ...target, ...result });
  }

  return results;
}

async function processTrainingDoc(doc, now, config, deps) {
  const data = doc.data() ?? {};
  const scheduledEnd = resolveTrainingScheduledEnd(data);
  if (!isEligibleForAutoSync(scheduledEnd, now, config)) {
    return null;
  }

  const startAt = resolveTrainingStartAt(data);
  if (!startAt) return null;

  const targets = await collectTrainingDeviceTargets(data);
  const fieldGps = await loadFieldGps(data.fieldId);

  const deviceResults =
    targets.length > 0
      ? await processEventDevices({
          eventId: doc.id,
          isMatch: false,
          startAt,
          scheduledEnd,
          targets,
          fieldGps,
          config,
          fetchIntensePreprocessedSamplesCore: deps.fetchIntensePreprocessedSamplesCore,
          runInsidersSensorAnalysis: deps.runInsidersSensorAnalysis,
        })
      : [];

  await deps.computeAndSaveTeamWorkloadSummary({
    eventId: doc.id,
    sessionDurationMs: resolveSessionDurationMs({
      startAt,
      scheduledEnd,
      durationMinutes: data.duration,
    }),
  });

  await doc.ref.update({
    isFinish: true,
    trainingEndAt: Timestamp.fromDate(scheduledEnd),
    isTrackerDataUploaded: true,
    intenseAutoSyncAt: FieldValue.serverTimestamp(),
    intenseAutoSyncDeviceCount: deviceResults.length,
  });

  console.log(
    `[intenseScheduledSync] training finished id=${doc.id} devices=${deviceResults.length}`,
  );

  return {
    type: 'training',
    id: doc.id,
    devices: deviceResults.length,
  };
}

async function processMatchDoc(doc, now, config, deps) {
  const data = doc.data() ?? {};
  if (data.isTrackerDataUploaded === true) {
    return null;
  }

  const highlights = await loadMatchHighlights(doc.id);
  const window = resolveMatchIntenseFetchWindow(data, highlights);
  if (!window) {
    return null;
  }

  const eligibilityEnd = matchIntenseEnd(data, highlights, {
    scheduledEnd: window.stop,
  });
  if (!isEligibleForAutoSync(eligibilityEnd, now, config)) {
    return null;
  }

  const targets = await collectMatchDeviceTargets(doc.id, data, config);
  const fieldGps =
    (data.fieldGpsCorners && typeof data.fieldGpsCorners === 'object'
      ? data.fieldGpsCorners
      : null) ?? (await loadFieldGps(data.fieldId));

  const deviceResults =
    targets.length > 0
      ? await processEventDevices({
          eventId: doc.id,
          isMatch: true,
          startAt: window.start,
          scheduledEnd: window.stop,
          targets,
          fieldGps,
          config,
          playPeriods: window.playPeriods,
          fetchIntensePreprocessedSamplesCore: deps.fetchIntensePreprocessedSamplesCore,
          runInsidersSensorAnalysis: deps.runInsidersSensorAnalysis,
        })
      : [];

  await deps.computeAndSaveTeamWorkloadSummary({
    eventId: doc.id,
    sessionDurationMs: resolveSessionDurationMs({
      startAt: window.start,
      scheduledEnd: window.stop,
      durationMinutes: data.duration,
    }),
  });

  await doc.ref.update({
    isMatchPlayed: true,
    isTrackerDataUploaded: true,
    intenseAutoSyncAt: FieldValue.serverTimestamp(),
    intenseAutoSyncDeviceCount: deviceResults.length,
  });

  console.log(
    `[intenseScheduledSync] match finished id=${doc.id} devices=${deviceResults.length} ` +
      `start=${window.start.toISOString()} stop=${window.stop.toISOString()} ` +
      `periods=${window.playPeriods.length}`,
  );

  return {
    type: 'match',
    id: doc.id,
    devices: deviceResults.length,
  };
}

async function queryOpenTrainingsForOwner(ownerId) {
  const snap = await getDb()
    .collection(TRAINING_COLLECTION)
    .where('ownerId', '==', ownerId)
    .where('withTracker', '==', true)
    .limit(30)
    .get();

  return snap.docs.filter((doc) => doc.data()?.isTrackerDataUploaded !== true);
}

async function queryOpenMatchesForOwner(ownerId) {
  const snap = await getDb()
    .collection(MATCH_COLLECTION)
    .where('ownerId', '==', ownerId)
    .where('withTracker', '==', true)
    .limit(30)
    .get();

  // Include matches already marked played (Temps fort fin de match) but
  // whose Intense data was never uploaded.
  return snap.docs.filter((doc) => doc.data()?.isTrackerDataUploaded !== true);
}

async function runIntenseScheduledSyncCore(injectedDeps) {
  deviceOwnerCache.clear();

  const deps = injectedDeps ?? loadRuntimeDeps();
  const config = {
    ...DEFAULT_AUTO_SYNC_CONFIG,
    ...(await deps.readIntenseAutoSyncConfig()),
  };
  const now = new Date();
  const intenseOwnerIds = await loadIntenseOwnerIds();

  if (!intenseOwnerIds.size) {
    console.log('[intenseScheduledSync] no Intense owners (withSyncing=false)');
    return { processed: [], skippedOwners: 0 };
  }

  const processed = [];
  let eventsHandled = 0;

  for (const ownerId of intenseOwnerIds) {
    if (eventsHandled >= config.maxEventsPerRun) break;

    const [trainingDocs, matchDocs] = await Promise.all([
      queryOpenTrainingsForOwner(ownerId),
      queryOpenMatchesForOwner(ownerId),
    ]);

    const candidates = [
      ...trainingDocs.map((doc) => ({ kind: 'training', doc })),
      ...matchDocs.map((doc) => ({ kind: 'match', doc })),
    ];

    for (const candidate of candidates) {
      if (eventsHandled >= config.maxEventsPerRun) break;

      try {
        const result =
          candidate.kind === 'training'
            ? await processTrainingDoc(candidate.doc, now, config, deps)
            : await processMatchDoc(candidate.doc, now, config, deps);

        if (result) {
          processed.push(result);
          eventsHandled += 1;
        }
      } catch (e) {
        console.error(
          `[intenseScheduledSync] failed ${candidate.kind} id=${candidate.doc.id}:`,
          e,
        );
      }
    }
  }

  console.log(
    `[intenseScheduledSync] done processed=${processed.length} owners=${intenseOwnerIds.size}`,
  );

  return { processed, ownerCount: intenseOwnerIds.size };
}

/**
 * Cloud Scheduler (every 30 min): auto-recover Intense tracker data for
 * trainings/matches whose owner has withSyncing=false and that were not
 * uploaded within the configured grace period after the session end.
 *
 * Match start/stop follow the same rules as the in-app manual sync:
 *   - kick-off = Match.timestamp (never dateCh/timeCh)
 *   - end = Temps fort TimeType.end if present, else timestamp + duration + 15'
 *   - play periods exclude the half-time break when halves are known
 *
 * Tunable via Firestore `config/intenseAutoSync` (re-read each run; see
 * intenseAutoSyncConfig.js for defaults).
 *
 * Deploy:
 *   cd functions && npm install
 *   firebase deploy --only functions:insidersScheduledIntenseSync
 *
 * Firestore composite indexes (create in Firebase console or firestore.indexes.json):
 *   training: ownerId ASC, withTracker ASC
 *   matchCalendar: ownerId ASC, withTracker ASC
 *   TRACKER_Owner: withSyncing ASC (single-field, auto)
 */
const insidersScheduledIntenseSync = onSchedule(
  {
    region: REGION,
    schedule: 'every 30 minutes',
    timeZone: 'Europe/Paris',
    timeoutSeconds: 540,
    memory: '1GiB',
  },
  async () => {
    await runIntenseScheduledSyncCore();
  },
);

module.exports = {
  runIntenseScheduledSyncCore,
  insidersScheduledIntenseSync,
  DEFAULT_AUTO_SYNC_CONFIG,
};
