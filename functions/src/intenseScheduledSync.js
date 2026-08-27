import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";

import {
  fetchIntensePreprocessedSamplesCore,
  runInsidersSensorAnalysis,
} from "./insidersAnalysis.js";
import { readIntenseAutoSyncConfig } from "./intenseAutoSyncConfig.js";
import { computeAndSaveTeamWorkloadSummary } from "./teamWorkloadSummary.js";

const REGION = "europe-west1";

const TRAINING_COLLECTION = "training";
const MATCH_COLLECTION = "matchCalendar";
const OWNER_COLLECTION = "TRACKER_Owner";
const DEVICE_OWNER_COLLECTION = "TRACKER_DeviceOwner";
const MATCH_COMPO_COLLECTION = "matchCompo";
const FIELDS_COLLECTION = "TRACKER_Fields";
const HIGHLIGHTS_COLLECTION = "highLights";

const HALFTIME_BREAK_MINUTES = 15;
const MIN_PLAUSIBLE_MATCH_MINUTES = 5;
const MAX_PLAUSIBLE_MATCH_HOURS = 4;
const DEFAULT_DURATION_MINUTES = 90;

const TIME_EVENT_ACTION = "ActionType.timeEvent";
const TIME_TYPE = {
  kickOff: "kickOff",
  halfTime: "halTime",
  secondHalf: "secondHalf",
  startExtraTime: "startExtraTime",
  end: "end",
};

const db = getFirestore();

// -----------------------------
// Time / match-window helpers (same rules as the Grinta app)
// -----------------------------

function tsToDate(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value.toDate === "function") {
    try {
      const date = value.toDate();
      return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
    } catch (_) {
      return null;
    }
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (typeof value === "string" && value.trim()) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  return null;
}

function matchDurationMinutes(matchData) {
  const duration = Number(matchData?.duration);
  return Number.isFinite(duration) && duration > 0
    ? duration
    : DEFAULT_DURATION_MINUTES;
}

function matchTimestampKickoff(matchData) {
  return tsToDate(matchData?.timestamp);
}

function matchScheduledSlotEnd(startAt, durationMinutes) {
  if (!startAt) return null;
  const minutes = Number(durationMinutes) > 0
    ? Number(durationMinutes)
    : DEFAULT_DURATION_MINUTES;
  const halfMinutes = Math.floor(minutes / 2);
  return new Date(
    startAt.getTime() +
      (halfMinutes + HALFTIME_BREAK_MINUTES + halfMinutes) * 60 * 1000,
  );
}

function timeEventTypeName(raw) {
  const value = String(raw ?? "").trim();
  if (!value) return null;
  const name = value.includes(".") ? value.split(".").pop() : value;
  if (name === TIME_TYPE.kickOff) return TIME_TYPE.kickOff;
  if (name === TIME_TYPE.halfTime || name === "halfTime") return TIME_TYPE.halfTime;
  if (name === TIME_TYPE.secondHalf) return TIME_TYPE.secondHalf;
  if (name === TIME_TYPE.startExtraTime) return TIME_TYPE.startExtraTime;
  if (name === TIME_TYPE.end) return TIME_TYPE.end;
  return null;
}

function isTimeEventHighlight(data) {
  const action = String(data?.action ?? "");
  return action === TIME_EVENT_ACTION || action.endsWith("timeEvent");
}

function findTimeEventDate(highlights, typeName) {
  if (!Array.isArray(highlights)) return null;
  for (const highlight of highlights) {
    if (!highlight || !isTimeEventHighlight(highlight)) continue;
    const type = timeEventTypeName(highlight.value?.type ?? highlight.value);
    if (type !== typeName) continue;
    const at = tsToDate(highlight.dateTime);
    if (at) return at;
  }
  return null;
}

function isPlausibleMatchEnd(startAt, candidateEnd) {
  if (!startAt || !candidateEnd) return false;
  if (
    candidateEnd.getTime() <=
    startAt.getTime() + MIN_PLAUSIBLE_MATCH_MINUTES * 60 * 1000
  ) {
    return false;
  }
  if (
    candidateEnd.getTime() >
    startAt.getTime() + MAX_PLAUSIBLE_MATCH_HOURS * 60 * 60 * 1000
  ) {
    return false;
  }
  return true;
}

function scheduleFallbackPeriods(matchData, fallbackStart) {
  const start = fallbackStart ?? matchTimestampKickoff(matchData);
  const minutes = matchDurationMinutes(matchData);
  if (!start || minutes <= 0) return [];

  const halfMinutes = Math.floor(minutes / 2);
  if (halfMinutes <= 0) return [];

  const firstHalfEnd = new Date(start.getTime() + halfMinutes * 60 * 1000);
  const secondHalfStart = new Date(
    firstHalfEnd.getTime() + HALFTIME_BREAK_MINUTES * 60 * 1000,
  );
  const secondHalfEnd = new Date(
    secondHalfStart.getTime() + halfMinutes * 60 * 1000,
  );

  if (
    firstHalfEnd.getTime() <= start.getTime() ||
    secondHalfEnd.getTime() <= secondHalfStart.getTime()
  ) {
    return [];
  }

  return [
    { start, end: firstHalfEnd },
    { start: secondHalfStart, end: secondHalfEnd },
  ];
}

function resolveMatchSensorSyncPeriods({
  matchData,
  highlights = [],
  fallbackStart = null,
} = {}) {
  const kickOff = findTimeEventDate(highlights, TIME_TYPE.kickOff);
  const halfTime = findTimeEventDate(highlights, TIME_TYPE.halfTime);
  const secondHalf = findTimeEventDate(highlights, TIME_TYPE.secondHalf);
  const fullTime = findTimeEventDate(highlights, TIME_TYPE.end);

  if (kickOff && fullTime && fullTime.getTime() > kickOff.getTime()) {
    if (
      halfTime &&
      secondHalf &&
      halfTime.getTime() > kickOff.getTime() &&
      secondHalf.getTime() >= halfTime.getTime() &&
      fullTime.getTime() > secondHalf.getTime()
    ) {
      return [
        { start: kickOff, end: halfTime },
        { start: secondHalf, end: fullTime },
      ];
    }

    return [{ start: kickOff, end: fullTime }];
  }

  return scheduleFallbackPeriods(matchData, fallbackStart);
}

function matchLiveStart(matchData, highlights) {
  const fromTimestamp = matchTimestampKickoff(matchData);
  if (fromTimestamp) return fromTimestamp;
  return findTimeEventDate(highlights, TIME_TYPE.kickOff);
}

function matchSessionStart(matchData, highlights) {
  const recorded = findTimeEventDate(highlights, TIME_TYPE.kickOff);
  if (recorded) return recorded;
  return matchTimestampKickoff(matchData);
}

function matchIntenseEnd(matchData, highlights, { scheduledEnd = null } = {}) {
  const endHighlight = findTimeEventDate(highlights, TIME_TYPE.end);
  if (endHighlight) return endHighlight;
  if (scheduledEnd) return scheduledEnd;

  const start =
    matchLiveStart(matchData, highlights) ??
    matchSessionStart(matchData, highlights);
  if (start) {
    return matchScheduledSlotEnd(start, matchDurationMinutes(matchData));
  }
  return null;
}

function resolveMatchIntenseFetchWindow(matchData, highlights = []) {
  const startLocal =
    matchLiveStart(matchData, highlights) ??
    matchSessionStart(matchData, highlights);
  if (!startLocal) return null;

  const durationMinutes = matchDurationMinutes(matchData);
  const playPeriods = resolveMatchSensorSyncPeriods({
    matchData,
    highlights,
    fallbackStart: startLocal,
  });

  let windowStart = startLocal;
  let endLocal = matchScheduledSlotEnd(startLocal, durationMinutes);

  if (playPeriods.length > 0) {
    windowStart = playPeriods[0].start;
    endLocal = playPeriods[playPeriods.length - 1].end;
  } else {
    const endHighlight = findTimeEventDate(highlights, TIME_TYPE.end);
    if (endHighlight && isPlausibleMatchEnd(startLocal, endHighlight)) {
      endLocal = endHighlight;
    }
  }

  if (!endLocal || endLocal.getTime() <= windowStart.getTime()) {
    endLocal = matchScheduledSlotEnd(windowStart, durationMinutes);
  }

  if (!endLocal || endLocal.getTime() <= windowStart.getTime()) {
    return null;
  }

  return {
    start: windowStart,
    stop: endLocal,
    playPeriods,
  };
}

function sampleTimeMs(sample) {
  if (!sample || typeof sample !== "object") return null;
  if (Number.isFinite(sample.timeMs)) return Number(sample.timeMs);
  const fromDate = tsToDate(sample.timestamp ?? sample.time ?? sample.dateTime);
  return fromDate ? fromDate.getTime() : null;
}

function filterSamplesToMatchPeriods(samples, periods) {
  if (!Array.isArray(samples) || samples.length === 0) return samples ?? [];
  if (!Array.isArray(periods) || periods.length === 0) return samples;

  return samples.filter((sample) => {
    const timeMs = sampleTimeMs(sample);
    if (timeMs == null) return false;
    return periods.some((period) => {
      const startMs = period.start.getTime();
      const endMs = period.end.getTime();
      return timeMs >= startMs && timeMs <= endMs;
    });
  });
}

function isEligibleForAutoSync(scheduledEnd, now, config) {
  if (!scheduledEnd) return false;

  const graceMs = Number(config?.graceMinutes) * 60 * 1000;
  const retentionMs = Number(config?.insidersRetentionHours) * 60 * 60 * 1000;
  if (!Number.isFinite(graceMs) || !Number.isFinite(retentionMs)) return false;

  const nowMs = now.getTime();
  const endMs = scheduledEnd.getTime();
  if (nowMs < endMs + graceMs) return false;
  if (nowMs - endMs > retentionMs) return false;
  return true;
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

// -----------------------------
// Owner / device resolution
// -----------------------------

async function loadIntenseOwnerIds() {
  const snap = await db
    .collection(OWNER_COLLECTION)
    .where("withSyncing", "==", false)
    .get();
  const ids = new Set();
  for (const doc of snap.docs) {
    ids.add(doc.id);
    const storedId = String(doc.data()?.id ?? "").trim();
    if (storedId) ids.add(storedId);
  }
  return ids;
}

const deviceOwnerCache = new Map();

async function loadDeviceOwner(docId) {
  const key = String(docId ?? "").trim();
  if (!key) return null;
  if (deviceOwnerCache.has(key)) {
    return deviceOwnerCache.get(key);
  }
  const doc = await db.collection(DEVICE_OWNER_COLLECTION).doc(key).get();
  if (!doc.exists) {
    deviceOwnerCache.set(key, null);
    return null;
  }
  const data = { id: doc.id, ...doc.data() };
  deviceOwnerCache.set(key, data);
  return data;
}

function trackerIdForAnalysis(deviceOwner) {
  const custom = String(
    deviceOwner?.customeName ?? deviceOwner?.customName ?? "",
  ).trim();
  if (custom) return custom;
  return String(deviceOwner?.deviceId ?? "").trim();
}

function isPresentPlayerTraining(entry) {
  const raw = entry?.presenceType;
  if (raw == null || raw === "") return true;
  const value = String(raw).toLowerCase();
  return value.includes("present");
}

async function collectTrainingDeviceTargets(trainingData) {
  const playerTraining = Array.isArray(trainingData.playerTraining)
    ? trainingData.playerTraining
    : [];
  const targets = [];

  for (const pt of playerTraining) {
    if (!isPresentPlayerTraining(pt)) continue;

    const playerId = String(pt?.playerId ?? "").trim();
    const deviceOwnerDocId = String(pt?.deviceId ?? "").trim();
    if (!playerId || !deviceOwnerDocId) continue;

    const deviceOwner = await loadDeviceOwner(deviceOwnerDocId);
    if (!deviceOwner) continue;

    const insidersDeviceId = String(deviceOwner.deviceId ?? "").trim();
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
      if (entry && typeof entry === "object") {
        players.push(entry);
      }
    }
  }
  return players;
}

async function collectMatchDeviceTargets(matchId, matchData, config) {
  const compoSnap = await db
    .collection(MATCH_COMPO_COLLECTION)
    .where("matchID", "==", matchId)
    .limit(3)
    .get();

  if (compoSnap.empty) return [];

  const teamId = String(matchData.teamID ?? "").trim();
  let compoDoc = compoSnap.docs[0];
  if (teamId) {
    const matched = compoSnap.docs.find(
      (d) => String(d.data()?.teamID ?? "").trim() === teamId,
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
    const playerId = String(player?.playerID ?? player?.playerId ?? "").trim();
    const deviceOwnerDocId = String(
      player?.deviceOwnerId ?? player?.deviceId ?? "",
    ).trim();
    if (!playerId || !deviceOwnerDocId) continue;

    const dedupeKey = `${playerId}:${deviceOwnerDocId}`;
    if (seen.has(dedupeKey)) continue;
    seen.add(dedupeKey);

    const deviceOwner = await loadDeviceOwner(deviceOwnerDocId);
    if (!deviceOwner) continue;

    const insidersDeviceId = String(deviceOwner.deviceId ?? "").trim();
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
  const id = String(fieldId ?? "").trim();
  if (!id) return null;

  const doc = await db.collection(FIELDS_COLLECTION).doc(id).get();
  if (!doc.exists) return null;

  const data = doc.data() ?? {};
  const corners = data.fieldGpsCorners ?? data.fieldGps ?? null;
  if (!corners || typeof corners !== "object") return null;

  return corners;
}

async function loadMatchHighlights(matchId) {
  const snap = await db
    .collection(HIGHLIGHTS_COLLECTION)
    .where("matchCalendarId", "==", matchId)
    .get();
  return snap.docs.map((doc) => doc.data() ?? {});
}

// -----------------------------
// Per-device sync
// -----------------------------

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
      return { status: "empty", samplesCount: 0 };
    }

    await runInsidersSensorAnalysis({
      trackerId,
      playerId,
      eventId,
      isMatch,
      docId: `${eventId}_${trackerId}`,
      teamId: "0",
      insidersDeviceId,
      samples,
      fieldGps,
      generateHeatmaps: Boolean(isMatch && fieldGps),
      generatePng: false,
    });

    return { status: "ok", samplesCount: samples.length };
  } catch (e) {
    const message = e?.message ? String(e.message) : String(e);
    console.warn(
      `[intenseScheduledSync] device sync failed event=${eventId} tracker=${trackerId}: ${message}`,
    );
    return { status: "error", message };
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
    });
    results.push({ ...target, ...result });
  }

  return results;
}

// -----------------------------
// Event processors
// -----------------------------

async function processTrainingDoc(doc, now, config) {
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
        })
      : [];

  await computeAndSaveTeamWorkloadSummary({
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
    type: "training",
    id: doc.id,
    devices: deviceResults.length,
  };
}

async function processMatchDoc(doc, now, config) {
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
    (data.fieldGpsCorners && typeof data.fieldGpsCorners === "object"
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
        })
      : [];

  await computeAndSaveTeamWorkloadSummary({
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
    type: "match",
    id: doc.id,
    devices: deviceResults.length,
  };
}

async function queryOpenTrainingsForOwner(ownerId) {
  const snap = await db
    .collection(TRAINING_COLLECTION)
    .where("ownerId", "==", ownerId)
    .where("withTracker", "==", true)
    .limit(30)
    .get();

  return snap.docs.filter((doc) => doc.data()?.isTrackerDataUploaded !== true);
}

async function queryOpenMatchesForOwner(ownerId) {
  const snap = await db
    .collection(MATCH_COLLECTION)
    .where("ownerId", "==", ownerId)
    .where("withTracker", "==", true)
    .limit(30)
    .get();

  return snap.docs.filter((doc) => doc.data()?.isTrackerDataUploaded !== true);
}

// -----------------------------
// Scheduler entry point
// -----------------------------

export async function runIntenseScheduledSyncCore() {
  deviceOwnerCache.clear();

  const config = await readIntenseAutoSyncConfig();
  const now = new Date();
  const intenseOwnerIds = await loadIntenseOwnerIds();

  if (!intenseOwnerIds.size) {
    console.log("[intenseScheduledSync] no Intense owners (withSyncing=false)");
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
      ...trainingDocs.map((doc) => ({ kind: "training", doc })),
      ...matchDocs.map((doc) => ({ kind: "match", doc })),
    ];

    for (const candidate of candidates) {
      if (eventsHandled >= config.maxEventsPerRun) break;

      try {
        const result =
          candidate.kind === "training"
            ? await processTrainingDoc(candidate.doc, now, config)
            : await processMatchDoc(candidate.doc, now, config);

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
 * ESM named export for grintaclub/functions/src (imported by index.js).
 *
 * Deploy:
 *   cd functions && firebase deploy --only functions:insidersScheduledIntenseSync
 */
export const insidersScheduledIntenseSync = onSchedule(
  {
    region: REGION,
    schedule: "every 30 minutes",
    timeZone: "Europe/Paris",
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async () => {
    await runIntenseScheduledSyncCore();
  },
);
