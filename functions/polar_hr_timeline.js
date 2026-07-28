/**
 * Pure helpers for Polar AccessLink HR samples → 5-min timeline + zones.
 * Kept free of Firebase so unit tests can run with `node --test`.
 */

const HR_TIMELINE_BUCKET_SECONDS = 5 * 60;

/** Official AccessLink sample-type key for heart rate (bpm). */
const SAMPLE_TYPE_HEART_RATE = '0';

/**
 * Parse ISO-8601 duration like PT2H44M / PT1H38M13S → seconds.
 * @param {unknown} iso
 * @returns {number|null}
 */
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

/**
 * Extract BPM samples + recording interval from AccessLink `samples[]`.
 * Prefers sample-type "0" (HR). Falls back to another series whose values
 * look like BPM when Polar omits/mislabels the type.
 *
 * @param {unknown} samples
 * @returns {{ samples: number[], intervalSeconds: number } | null}
 */
function extractPolarHrSamples(samples) {
  if (!Array.isArray(samples) || samples.length === 0) return null;

  const parsed = [];
  for (const entry of samples) {
    if (!entry || typeof entry !== 'object') continue;
    const type = String(entry['sample-type'] ?? entry.sample_type ?? '').trim();
    const rateRaw = Number(entry['recording-rate'] ?? entry.recording_rate);
    const intervalSeconds =
      Number.isFinite(rateRaw) && rateRaw > 0 ? Math.round(rateRaw) : 1;
    const dataRaw = entry.data ?? entry.Data ?? '';
    const values = String(dataRaw)
      .split(',')
      .map((part) => Number(String(part).trim()))
      .filter((n) => Number.isFinite(n));
    if (values.length === 0) continue;
    parsed.push({ type, intervalSeconds, values });
  }
  if (parsed.length === 0) return null;

  const hrTyped = parsed.find((p) => p.type === SAMPLE_TYPE_HEART_RATE);
  if (hrTyped) {
    return {
      samples: hrTyped.values.map((n) => Math.round(n)),
      intervalSeconds: hrTyped.intervalSeconds,
    };
  }

  // Fallback: pick the series whose valid values look like BPM (40–230).
  let best = null;
  let bestScore = -1;
  for (const series of parsed) {
    const plausible = series.values.filter((v) => v >= 40 && v <= 230);
    const score = plausible.length / series.values.length;
    if (score > bestScore && plausible.length >= 3) {
      bestScore = score;
      best = series;
    }
  }
  if (!best || bestScore < 0.6) return null;
  return {
    samples: best.values.map((n) => Math.round(n)),
    intervalSeconds: best.intervalSeconds,
  };
}

/**
 * Average HR samples into fixed buckets (default 5 minutes).
 * @param {{ samples: number[], intervalSeconds: number, bucketSeconds?: number }} args
 * @returns {Array<{ t: number, avg: number, min: number, max: number }>}
 */
function aggregateHrTimeline({
  samples,
  intervalSeconds,
  bucketSeconds = HR_TIMELINE_BUCKET_SECONDS,
}) {
  if (!Array.isArray(samples) || samples.length === 0) return [];
  const interval =
    Number.isFinite(intervalSeconds) && intervalSeconds > 0
      ? Math.round(intervalSeconds)
      : 1;
  const bucket =
    Number.isFinite(bucketSeconds) && bucketSeconds > 0
      ? Math.round(bucketSeconds)
      : HR_TIMELINE_BUCKET_SECONDS;
  const samplesPerBucket = Math.max(1, Math.ceil(bucket / interval));

  const points = [];
  for (let start = 0; start < samples.length; start += samplesPerBucket) {
    const end = Math.min(start + samplesPerBucket, samples.length);
    const chunk = [];
    for (let i = start; i < end; i += 1) {
      const bpm = samples[i];
      if (Number.isFinite(bpm) && bpm > 0) chunk.push(bpm);
    }
    if (chunk.length === 0) continue;
    let sum = 0;
    let min = chunk[0];
    let max = chunk[0];
    for (const bpm of chunk) {
      sum += bpm;
      if (bpm < min) min = bpm;
      if (bpm > max) max = bpm;
    }
    points.push({
      t: Math.floor((start * interval) / 60),
      avg: Math.round(sum / chunk.length),
      min: Math.round(min),
      max: Math.round(max),
    });
  }
  return points;
}

/**
 * Absolute BPM zone seconds (Grinta defaults when no HRmax).
 * z1 <120 · z2 120–139 · z3 140–159 · z4 160–179 · z5 ≥180
 */
function computeAbsoluteZoneSeconds(samples, intervalSeconds) {
  const interval =
    Number.isFinite(intervalSeconds) && intervalSeconds > 0
      ? Math.round(intervalSeconds)
      : 1;
  const zones = { z1: 0, z2: 0, z3: 0, z4: 0, z5: 0 };
  for (const bpm of samples) {
    if (!Number.isFinite(bpm) || bpm <= 0) continue;
    let key = 'z5';
    if (bpm < 120) key = 'z1';
    else if (bpm < 140) key = 'z2';
    else if (bpm < 160) key = 'z3';
    else if (bpm < 180) key = 'z4';
    zones[key] += interval;
  }
  return zones;
}

/**
 * Map AccessLink `heart_rate_zones[]` → { z1…z5 → seconds }.
 * @param {unknown} zones
 * @returns {Record<string, number>}
 */
function mapPolarHeartRateZones(zones) {
  const out = { z1: 0, z2: 0, z3: 0, z4: 0, z5: 0 };
  if (!Array.isArray(zones)) return out;
  for (const zone of zones) {
    if (!zone || typeof zone !== 'object') continue;
    const index = Number(zone.index ?? zone.Index);
    if (!Number.isFinite(index) || index < 1 || index > 5) continue;
    const seconds = parseIsoDurationSeconds(
      zone['in-zone'] ?? zone.in_zone ?? zone.inZone,
    );
    if (seconds == null || seconds < 0) continue;
    out[`z${Math.round(index)}`] = seconds;
  }
  return out;
}

/**
 * Build cardio extras to store on personalSportActivities from an exercise
 * detail payload (with samples=true&zones=true).
 *
 * @param {object} exercise
 * @returns {{
 *   hrTimeline: Array<{t:number,avg:number,min?:number,max?:number}>,
 *   hrTimelineBucketMinutes: number,
 *   hrZoneSeconds: Record<string, number>,
 *   maxHeartRateBpm: number|null,
 *   minHeartRateBpm: number|null,
 *   hrSamplesCount: number,
 * }}
 */
function buildPolarCardioExtras(exercise) {
  const empty = {
    hrTimeline: [],
    hrTimelineBucketMinutes: 5,
    hrZoneSeconds: { z1: 0, z2: 0, z3: 0, z4: 0, z5: 0 },
    maxHeartRateBpm: null,
    minHeartRateBpm: null,
    hrSamplesCount: 0,
  };
  if (!exercise || typeof exercise !== 'object') return empty;

  const extracted = extractPolarHrSamples(exercise.samples);
  const apiZones = mapPolarHeartRateZones(
    exercise.heart_rate_zones ?? exercise.heartRateZones,
  );
  const maxFromApi = Number(exercise.heart_rate?.maximum ?? NaN);
  const maxHeartRateBpm = Number.isFinite(maxFromApi)
    ? Math.round(maxFromApi)
    : null;

  if (!extracted) {
    const hasZones = Object.values(apiZones).some((s) => s > 0);
    return {
      ...empty,
      hrZoneSeconds: hasZones ? apiZones : empty.hrZoneSeconds,
      maxHeartRateBpm,
    };
  }

  const timeline = aggregateHrTimeline({
    samples: extracted.samples,
    intervalSeconds: extracted.intervalSeconds,
  });
  const valid = extracted.samples.filter((b) => b > 0);
  let minHeartRateBpm = null;
  let maxFromSamples = null;
  if (valid.length > 0) {
    minHeartRateBpm = Math.min(...valid);
    maxFromSamples = Math.max(...valid);
  }

  const sampleZones = computeAbsoluteZoneSeconds(
    extracted.samples,
    extracted.intervalSeconds,
  );
  const hasApiZones = Object.values(apiZones).some((s) => s > 0);

  return {
    hrTimeline: timeline,
    hrTimelineBucketMinutes: 5,
    hrZoneSeconds: hasApiZones ? apiZones : sampleZones,
    maxHeartRateBpm: maxHeartRateBpm ?? maxFromSamples,
    minHeartRateBpm,
    hrSamplesCount: valid.length,
  };
}

module.exports = {
  HR_TIMELINE_BUCKET_SECONDS,
  SAMPLE_TYPE_HEART_RATE,
  parseIsoDurationSeconds,
  extractPolarHrSamples,
  aggregateHrTimeline,
  computeAbsoluteZoneSeconds,
  mapPolarHeartRateZones,
  buildPolarCardioExtras,
};
