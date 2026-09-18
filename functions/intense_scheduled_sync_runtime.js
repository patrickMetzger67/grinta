/**
 * Runtime deps for `insidersScheduledIntenseSync`.
 *
 * Prefer sibling modules when present (grintaclub / goaltimefootball deploy).
 * Otherwise call the already-deployed HTTPS callables in the shared Firebase
 * project (`fetchIntensePreprocessedSamples`, `analyzeInsidersSensorData`) so
 * a deploy from this repo does not crash with:
 *   Cannot find module './insidersAnalysis'
 */

const REGION = 'europe-west1';
const PROJECT_ID =
  process.env.GCLOUD_PROJECT ||
  process.env.GCP_PROJECT ||
  process.env.GCLOUD_PROJECT_ID ||
  'aserstein-2453e';

const ANALYSIS_COLLECTION = 'TRACKER_Analysis';
const TEAM_ANALYSIS_COLLECTION = 'TRACKER_TeamAnalysis';

const METRIC_KEYS = [
  'distanceKm',
  'maxValidatedSpeedKmh',
  'sprintCount',
  'highAccelerationCount',
  'highSpeedDuration',
  'maxAccelerationMps2',
  'workloadScore',
  'workloadScorePerMinute',
];

function getFirestoreAdmin() {
  // Lazy require so unit tests of pure helpers do not need node_modules.
  return require('firebase-admin/firestore');
}

function formatInsidersApiTimestamp(isoOrDate) {
  const date =
    isoOrDate instanceof Date ? isoOrDate : new Date(String(isoOrDate ?? ''));
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid Insiders timestamp: ${isoOrDate}`);
  }
  const iso = date.toISOString();
  return iso.replace(/\.\d+Z$/, '+0000').replace(/Z$/, '+0000');
}

async function fetchIdentityToken(audience) {
  const metaUrl =
    'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity' +
    `?audience=${encodeURIComponent(audience)}`;
  const res = await fetch(metaUrl, {
    headers: { 'Metadata-Flavor': 'Google' },
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(
      `Failed to get identity token for ${audience}: ${res.status} ${text}`,
    );
  }
  return res.text();
}

/**
 * Invoke a Firebase HTTPS callable (v1/v2 URL shape) with an identity token.
 * Body protocol: `{ data: payload }` → `{ result }` or `{ error }`.
 */
async function callHttpsCallable(functionName, data) {
  const url = `https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${functionName}`;
  const token = await fetchIdentityToken(url);
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ data }),
  });

  let body = {};
  try {
    body = await res.json();
  } catch (_) {
    body = {};
  }

  if (!res.ok) {
    const message =
      body?.error?.message ||
      body?.error?.status ||
      (typeof body?.error === 'string' ? body.error : null) ||
      JSON.stringify(body) ||
      res.statusText;
    const err = new Error(
      `Callable ${functionName} failed (${res.status}): ${message}`,
    );
    err.code = body?.error?.status || String(res.status);
    err.details = body?.error?.details;
    throw err;
  }

  if (body?.error) {
    const err = new Error(
      `Callable ${functionName} error: ${body.error.message || JSON.stringify(body.error)}`,
    );
    err.code = body.error.status || body.error.code;
    err.details = body.error.details;
    throw err;
  }

  return body.result;
}

function createCallableFetchIntensePreprocessedSamplesCore() {
  return async function fetchIntensePreprocessedSamplesCore({
    insidersDeviceId,
    trackerId,
    startIso,
    stopIso,
  }) {
    return callHttpsCallable('fetchIntensePreprocessedSamples', {
      insidersDeviceId,
      trackerId,
      start: formatInsidersApiTimestamp(startIso),
      stop: formatInsidersApiTimestamp(stopIso),
    });
  };
}

function createCallableRunInsidersSensorAnalysis() {
  return async function runInsidersSensorAnalysis({
    trackerId,
    playerId,
    eventId,
    isMatch,
    docId,
    teamId = '0',
    insidersDeviceId,
    samples,
    fieldGps,
    generateHeatmaps = false,
    generatePng = false,
  }) {
    return callHttpsCallable('analyzeInsidersSensorData', {
      trackerId,
      playerId,
      eventId,
      isMatch: Boolean(isMatch),
      docId,
      teamId,
      insidersDeviceId,
      samples,
      ...(fieldGps && typeof fieldGps === 'object' ? { fieldGps } : {}),
      generateHeatmaps: Boolean(generateHeatmaps),
      generatePng: Boolean(generatePng),
      includeHeatmapPoints: false,
    });
  };
}

function toNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

function durationMsFromAnalysis(data) {
  const raw = data?.duration;
  if (raw && typeof raw === 'object') {
    if (Number.isFinite(Number(raw.inMilliseconds))) {
      return Math.max(0, Number(raw.inMilliseconds));
    }
    if (Number.isFinite(Number(raw.milliseconds))) {
      return Math.max(0, Number(raw.milliseconds));
    }
  }
  if (Number.isFinite(Number(data?.durationMs))) {
    return Math.max(0, Number(data.durationMs));
  }
  if (Number.isFinite(Number(data?.durationSeconds))) {
    return Math.max(0, Number(data.durationSeconds) * 1000);
  }
  return 0;
}

function highSpeedSeconds(data) {
  const raw = data?.highSpeedDuration;
  if (raw && typeof raw === 'object') {
    if (Number.isFinite(Number(raw.inMilliseconds))) {
      return Math.max(0, Number(raw.inMilliseconds) / 1000);
    }
    if (Number.isFinite(Number(raw.seconds))) {
      return Math.max(0, Number(raw.seconds));
    }
  }
  if (Number.isFinite(Number(data?.highSpeedDurationSeconds))) {
    return Math.max(0, Number(data.highSpeedDurationSeconds));
  }
  return toNumber(raw);
}

function extractMetricValue(data, metricKey) {
  switch (metricKey) {
    case 'distanceKm':
      return toNumber(data.distanceKm);
    case 'maxValidatedSpeedKmh':
      return toNumber(data.maxValidatedSpeedKmh);
    case 'sprintCount':
      return toNumber(data.sprintCount);
    case 'highAccelerationCount':
      return toNumber(data.highAccelerationCount);
    case 'highSpeedDuration':
      return highSpeedSeconds(data);
    case 'maxAccelerationMps2':
      return toNumber(data.maxAccelerationMps2);
    case 'workloadScore':
      return toNumber(data.workloadScore);
    case 'workloadScorePerMinute': {
      const explicit = toNumber(data.workloadScorePerMinute);
      if (explicit > 0) return explicit;
      const minutes = durationMsFromAnalysis(data) / 60000;
      if (minutes <= 0) return 0;
      return toNumber(data.workloadScore) / minutes;
    }
    default:
      return 0;
  }
}

function metricStatFromValues(metricKey, values) {
  const clean = values.filter((v) => Number.isFinite(v));
  if (!clean.length) {
    return {
      metricKey,
      mean: 0,
      standardDeviation: 0,
      min: 0,
      max: 0,
      count: 0,
    };
  }
  const total = clean.reduce((sum, v) => sum + v, 0);
  const mean = total / clean.length;
  const variance =
    clean.reduce((sum, v) => {
      const diff = v - mean;
      return sum + diff * diff;
    }, 0) / clean.length;
  return {
    metricKey,
    mean,
    standardDeviation: Math.sqrt(variance),
    min: Math.min(...clean),
    max: Math.max(...clean),
    count: clean.length,
  };
}

/**
 * Lightweight fallback when `teamWorkloadSummary.js` is not in the deploy
 * bundle. Aggregates `TRACKER_Analysis` → `TRACKER_TeamAnalysis` (same
 * collection the app reads for agenda rings).
 */
async function computeAndSaveTeamWorkloadSummaryFallback({
  eventId,
  sessionDurationMs,
}) {
  const id = String(eventId ?? '').trim();
  if (!id) return null;

  const { getFirestore, FieldValue } = getFirestoreAdmin();
  const db = getFirestore();
  const snap = await db
    .collection(ANALYSIS_COLLECTION)
    .where('eventId', '==', id)
    .get();

  const analyses = snap.docs
    .map((doc) => doc.data() ?? {})
    .filter((data) => {
      const samplesCount = toNumber(data.samplesCount);
      return samplesCount > 0 && durationMsFromAnalysis(data) > 0;
    });

  if (!analyses.length) {
    console.log(
      `[intenseScheduledSync] team workload skip event=${id}: no analyses`,
    );
    return null;
  }

  const playersCount = analyses.length;
  const totalWorkloadScore = analyses.reduce(
    (sum, data) => sum + toNumber(data.workloadScore),
    0,
  );
  const averageWorkloadScore = totalWorkloadScore / playersCount;

  let resolvedSessionMs = Number(sessionDurationMs);
  if (!Number.isFinite(resolvedSessionMs) || resolvedSessionMs <= 0) {
    resolvedSessionMs = Math.max(
      ...analyses.map((data) => durationMsFromAnalysis(data)),
      0,
    );
  }
  const sessionMinutes = resolvedSessionMs / 60000;
  const teamWorkloadPerMinute =
    sessionMinutes > 0 ? totalWorkloadScore / sessionMinutes : 0;
  const averagePlayerWorkloadPerMinute =
    analyses.reduce(
      (sum, data) => sum + extractMetricValue(data, 'workloadScorePerMinute'),
      0,
    ) / playersCount;

  const metricStats = {};
  for (const metricKey of METRIC_KEYS) {
    metricStats[metricKey] = metricStatFromValues(
      metricKey,
      analyses.map((data) => extractMetricValue(data, metricKey)),
    );
  }

  const playerScores = analyses.map((data) => {
    const metrics = {};
    for (const metricKey of METRIC_KEYS) {
      const value = extractMetricValue(data, metricKey);
      const stat = metricStats[metricKey];
      const zScore =
        stat.standardDeviation > 0
          ? (value - stat.mean) / stat.standardDeviation
          : 0;
      metrics[metricKey] = {
        metricKey,
        value,
        zScore,
        tScore: 50 + 10 * zScore,
      };
    }
    return {
      playerId: String(data.playerId ?? ''),
      trackerId: String(data.trackerId ?? ''),
      metrics,
    };
  });

  const payload = {
    eventId: id,
    totalWorkloadScore,
    averageWorkloadScore,
    teamWorkloadPerMinute,
    averagePlayerWorkloadPerMinute,
    playersCount,
    sessionDurationMs: resolvedSessionMs,
    sessionDuration: { inMilliseconds: resolvedSessionMs },
    metricStats,
    playerScores,
    updatedAt: FieldValue.serverTimestamp(),
  };

  const ref = db.collection(TEAM_ANALYSIS_COLLECTION).doc(id);
  const existing = await ref.get();
  if (!existing.exists) {
    payload.createdAt = FieldValue.serverTimestamp();
  }
  await ref.set(payload, { merge: true });

  console.log(
    `[intenseScheduledSync] team workload saved event=${id} players=${playersCount}`,
  );
  return payload;
}

function loadIntenseScheduledSyncRuntimeDeps(defaults = {}) {
  let fetchIntensePreprocessedSamplesCore;
  let runInsidersSensorAnalysis;
  let readIntenseAutoSyncConfig;
  let computeAndSaveTeamWorkloadSummary;
  let analysisSource = 'callable';
  let workloadSource = 'fallback';

  try {
    ({
      fetchIntensePreprocessedSamplesCore,
      runInsidersSensorAnalysis,
    } = require('./insidersAnalysis'));
    analysisSource = 'local';
  } catch (e) {
    console.warn(
      `[intenseScheduledSync] local insidersAnalysis.js missing (${e.message}) — ` +
        'using deployed callables fetchIntensePreprocessedSamples / analyzeInsidersSensorData',
    );
    fetchIntensePreprocessedSamplesCore =
      createCallableFetchIntensePreprocessedSamplesCore();
    runInsidersSensorAnalysis = createCallableRunInsidersSensorAnalysis();
  }

  try {
    ({ readIntenseAutoSyncConfig } = require('./intenseAutoSyncConfig'));
  } catch (_) {
    readIntenseAutoSyncConfig = async () => ({ ...defaults });
  }

  try {
    ({ computeAndSaveTeamWorkloadSummary } = require('./teamWorkloadSummary'));
    workloadSource = 'local';
  } catch (e) {
    console.warn(
      `[intenseScheduledSync] local teamWorkloadSummary.js missing (${e.message}) — ` +
        'using Firestore TRACKER_Analysis aggregation fallback',
    );
    computeAndSaveTeamWorkloadSummary =
      computeAndSaveTeamWorkloadSummaryFallback;
  }

  return {
    fetchIntensePreprocessedSamplesCore,
    runInsidersSensorAnalysis,
    readIntenseAutoSyncConfig,
    computeAndSaveTeamWorkloadSummary,
    analysisSource,
    workloadSource,
  };
}

module.exports = {
  REGION,
  PROJECT_ID,
  formatInsidersApiTimestamp,
  callHttpsCallable,
  loadIntenseScheduledSyncRuntimeDeps,
  computeAndSaveTeamWorkloadSummaryFallback,
  createCallableFetchIntensePreprocessedSamplesCore,
  createCallableRunInsidersSensorAnalysis,
};
