/**
 * Pure helpers for Oura workout + HR samples → zone seconds + BPM bands.
 * Kept free of Firebase so unit tests can run with `node --test`.
 */

const ZONE_KEYS = ['z0', 'z1', 'z2', 'z3', 'z4', 'z5'];

/** Same %-of-HRmax bands as Whoop / Grinta training zones. */
const ZONE_FRACTIONS = [
  { zone: 'z0', min: 0.0, max: 0.5 },
  { zone: 'z1', min: 0.5, max: 0.6 },
  { zone: 'z2', min: 0.6, max: 0.7 },
  { zone: 'z3', min: 0.7, max: 0.8 },
  { zone: 'z4', min: 0.8, max: 0.9 },
  { zone: 'z5', min: 0.9, max: 1.0 },
];

/**
 * @param {{ hrMaxBpm?: number|null }} [args]
 * @returns {Array<{ zone: string, y1: number, y2: number }>}
 */
function ouraHrZoneBandsBpm({ hrMaxBpm } = {}) {
  const max =
    Number.isFinite(hrMaxBpm) && hrMaxBpm > 0 ? Math.round(hrMaxBpm) : null;
  if (max == null) {
    return [
      { zone: 'z0', y1: 40, y2: 100 },
      { zone: 'z1', y1: 100, y2: 120 },
      { zone: 'z2', y1: 120, y2: 140 },
      { zone: 'z3', y1: 140, y2: 160 },
      { zone: 'z4', y1: 160, y2: 180 },
      { zone: 'z5', y1: 180, y2: 200 },
    ];
  }
  return ZONE_FRACTIONS.map((band, index) => {
    const y1 = Math.round(max * band.min);
    const y2 =
      index === ZONE_FRACTIONS.length - 1
        ? Math.max(max, Math.round(max * band.max))
        : Math.round(max * band.max);
    return { zone: band.zone, y1, y2 };
  });
}

/**
 * Map an unknown zone payload → `{ z0…z5: seconds }`.
 * Accepts arrays of seconds, objects keyed z0–z5 / zone_1…, or milli fields.
 * @param {unknown} raw
 * @returns {Record<string, number>}
 */
function mapOuraZoneDurationsToSeconds(raw) {
  const out = {};
  for (const key of ZONE_KEYS) out[key] = 0;
  if (raw == null) return out;

  if (Array.isArray(raw)) {
    for (let i = 0; i < ZONE_KEYS.length && i < raw.length; i += 1) {
      const n = Number(raw[i]);
      out[ZONE_KEYS[i]] = Number.isFinite(n) && n > 0 ? Math.round(n) : 0;
    }
    return out;
  }

  if (typeof raw !== 'object') return out;

  const aliases = {
    z0: ['z0', 'zone_0', 'zone0', 'zone_zero', 'zone_zero_milli'],
    z1: ['z1', 'zone_1', 'zone1', 'zone_one', 'zone_one_milli'],
    z2: ['z2', 'zone_2', 'zone2', 'zone_two', 'zone_two_milli'],
    z3: ['z3', 'zone_3', 'zone3', 'zone_three', 'zone_three_milli'],
    z4: ['z4', 'zone_4', 'zone4', 'zone_four', 'zone_four_milli'],
    z5: ['z5', 'zone_5', 'zone5', 'zone_five', 'zone_five_milli'],
  };

  for (const zone of ZONE_KEYS) {
    for (const key of aliases[zone]) {
      if (raw[key] == null) continue;
      const n = Number(raw[key]);
      if (!Number.isFinite(n) || n <= 0) continue;
      // Milli fields are typically large; treat >= 1000 as ms when key says milli.
      out[zone] = key.endsWith('_milli') ? Math.round(n / 1000) : Math.round(n);
      break;
    }
  }
  return out;
}

/**
 * Build a Polar-compatible HR timeline from timestamped BPM samples.
 * Oura public samples are typically ~5 min apart; we keep one point per sample.
 *
 * @param {Array<{ bpm: number, t: number|null }>} used
 * @param {{ workoutStartMs?: number|null }} [opts]
 * @returns {{
 *   hrTimeline: Array<{ t: number, avg: number, min: number, max: number }>,
 *   hrTimelineBucketMinutes: number,
 * }}
 */
function buildHrTimelineFromSamples(used, opts = {}) {
  const empty = { hrTimeline: [], hrTimelineBucketMinutes: 1 };
  if (!Array.isArray(used) || used.length === 0) return empty;

  const dated = used.filter((s) => s.t != null);
  if (dated.length === 0) {
    return {
      hrTimeline: used.map((s, index) => ({
        t: index,
        avg: s.bpm,
        min: s.bpm,
        max: s.bpm,
      })),
      hrTimelineBucketMinutes: 1,
    };
  }

  const startMs =
    Number.isFinite(opts.workoutStartMs) && opts.workoutStartMs > 0
      ? opts.workoutStartMs
      : dated[0].t;

  /** @type {Map<number, number[]>} */
  const byMinute = new Map();
  for (const sample of dated) {
    const offsetMinutes = Math.max(
      0,
      Math.floor((sample.t - startMs) / 60_000),
    );
    const bucket = byMinute.get(offsetMinutes) ?? [];
    bucket.push(sample.bpm);
    byMinute.set(offsetMinutes, bucket);
  }

  const hrTimeline = [...byMinute.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([t, bpms]) => {
      const sum = bpms.reduce((acc, n) => acc + n, 0);
      return {
        t,
        avg: Math.round(sum / bpms.length),
        min: Math.min(...bpms),
        max: Math.max(...bpms),
      };
    });

  // Infer chart bucket from median gap between points (fallback 1 min).
  let hrTimelineBucketMinutes = 1;
  if (hrTimeline.length >= 2) {
    const gaps = [];
    for (let i = 1; i < hrTimeline.length; i += 1) {
      gaps.push(hrTimeline[i].t - hrTimeline[i - 1].t);
    }
    gaps.sort((a, b) => a - b);
    const median = gaps[Math.floor(gaps.length / 2)];
    if (Number.isFinite(median) && median > 0) {
      hrTimelineBucketMinutes = Math.max(1, Math.min(5, median));
    }
  }

  return { hrTimeline, hrTimelineBucketMinutes };
}

/**
 * Bucket BPM samples into zone seconds using %-of-max (or absolute) bands.
 * Each sample contributes the gap until the next sample (capped at 5 min),
 * or an equal share of [workoutDurationSeconds] when only one sample exists.
 *
 * @param {Array<{ bpm?: number, timestamp?: string, source?: string }>} samples
 * @param {{
 *   hrMaxBpm?: number|null,
 *   workoutDurationSeconds?: number|null,
 *   workoutStartMs?: number|null,
 * }} [opts]
 * @returns {{
 *   averageHeartRateBpm: number|null,
 *   maxHeartRateBpm: number|null,
 *   hrZoneSeconds: Record<string, number>,
 *   hrTimeline: Array<{ t: number, avg: number, min: number, max: number }>,
 *   hrTimelineBucketMinutes: number,
 *   samplesUsed: number,
 * }}
 */
function extractMetricsFromHrSamples(samples, opts = {}) {
  const emptyZones = {};
  for (const key of ZONE_KEYS) emptyZones[key] = 0;

  const list = Array.isArray(samples) ? samples : [];
  const parsed = [];
  for (const row of list) {
    const bpm = Number(row?.bpm ?? row?.heart_rate ?? NaN);
    if (!Number.isFinite(bpm) || bpm <= 0) continue;
    const tsRaw = (row?.timestamp ?? row?.datetime ?? '').toString();
    const ts = tsRaw ? Date.parse(tsRaw) : NaN;
    parsed.push({
      bpm: Math.round(bpm),
      t: Number.isFinite(ts) ? ts : null,
      source: (row?.source ?? '').toString().toLowerCase(),
    });
  }

  if (parsed.length === 0) {
    return {
      averageHeartRateBpm: null,
      maxHeartRateBpm: null,
      hrZoneSeconds: emptyZones,
      hrTimeline: [],
      hrTimelineBucketMinutes: 1,
      samplesUsed: 0,
    };
  }

  // Prefer workout-tagged samples when present.
  const workoutOnly = parsed.filter((s) => s.source === 'workout');
  const used = workoutOnly.length > 0 ? workoutOnly : parsed;
  used.sort((a, b) => (a.t ?? 0) - (b.t ?? 0));

  const sum = used.reduce((acc, s) => acc + s.bpm, 0);
  const averageHeartRateBpm = Math.round(sum / used.length);
  const maxHeartRateBpm = used.reduce((m, s) => Math.max(m, s.bpm), 0);

  const bands = ouraHrZoneBandsBpm({ hrMaxBpm: opts.hrMaxBpm });
  const zones = { ...emptyZones };
  const maxGapMs = 5 * 60 * 1000;
  const workoutDurationSeconds =
    Number.isFinite(opts.workoutDurationSeconds) &&
    opts.workoutDurationSeconds > 0
      ? opts.workoutDurationSeconds
      : null;

  if (used.length === 1 || used.every((s) => s.t == null)) {
    const share =
      workoutDurationSeconds != null
        ? Math.round(workoutDurationSeconds / used.length)
        : 0;
    for (const sample of used) {
      const zone = bandForBpm(sample.bpm, bands);
      if (zone) zones[zone] += share;
    }
  } else {
    for (let i = 0; i < used.length; i += 1) {
      const sample = used[i];
      let seconds = 0;
      if (i < used.length - 1 && sample.t != null && used[i + 1].t != null) {
        seconds = Math.round(
          Math.min(maxGapMs, Math.max(0, used[i + 1].t - sample.t)) / 1000,
        );
      } else if (workoutDurationSeconds != null) {
        // Last sample: residual duration so totals ~ workout length.
        const accounted = ZONE_KEYS.reduce((a, k) => a + zones[k], 0);
        seconds = Math.max(0, Math.round(workoutDurationSeconds - accounted));
      }
      const zone = bandForBpm(sample.bpm, bands);
      if (zone) zones[zone] += seconds;
    }
  }

  const timeline = buildHrTimelineFromSamples(used, {
    workoutStartMs: opts.workoutStartMs,
  });

  return {
    averageHeartRateBpm,
    maxHeartRateBpm,
    hrZoneSeconds: zones,
    hrTimeline: timeline.hrTimeline,
    hrTimelineBucketMinutes: timeline.hrTimelineBucketMinutes,
    samplesUsed: used.length,
  };
}

/**
 * @param {number} bpm
 * @param {Array<{ zone: string, y1: number, y2: number }>} bands
 * @returns {string|null}
 */
function bandForBpm(bpm, bands) {
  for (let i = 0; i < bands.length; i += 1) {
    const band = bands[i];
    const last = i === bands.length - 1;
    if (bpm >= band.y1 && (last ? bpm <= band.y2 : bpm < band.y2)) {
      return band.zone;
    }
  }
  if (bpm >= bands[bands.length - 1].y2) return 'z5';
  return 'z0';
}

/**
 * Estimate HRmax from Oura personal_info age (220 − age).
 * @param {unknown} personalInfo
 * @returns {number|null}
 */
function estimateHrMaxFromPersonalInfo(personalInfo) {
  const age = Number(personalInfo?.age ?? NaN);
  if (!Number.isFinite(age) || age < 10 || age > 100) return null;
  return Math.round(220 - age);
}

module.exports = {
  ZONE_KEYS,
  ouraHrZoneBandsBpm,
  mapOuraZoneDurationsToSeconds,
  extractMetricsFromHrSamples,
  buildHrTimelineFromSamples,
  estimateHrMaxFromPersonalInfo,
  bandForBpm,
};
