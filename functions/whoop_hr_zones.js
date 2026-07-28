/**
 * Pure helpers for Whoop workout score → HR zone seconds + BPM bands.
 * Kept free of Firebase so unit tests can run with `node --test`.
 */

const ZONE_KEYS = ['z0', 'z1', 'z2', 'z3', 'z4', 'z5'];

const ZONE_MILLI_FIELDS = {
  z0: 'zone_zero_milli',
  z1: 'zone_one_milli',
  z2: 'zone_two_milli',
  z3: 'zone_three_milli',
  z4: 'zone_four_milli',
  z5: 'zone_five_milli',
};

/** Whoop zone bounds as fractions of HRmax (Locker / training zones). */
const ZONE_FRACTIONS = [
  { zone: 'z0', min: 0.0, max: 0.5 },
  { zone: 'z1', min: 0.5, max: 0.6 },
  { zone: 'z2', min: 0.6, max: 0.7 },
  { zone: 'z3', min: 0.7, max: 0.8 },
  { zone: 'z4', min: 0.8, max: 0.9 },
  { zone: 'z5', min: 0.9, max: 1.0 },
];

/**
 * @param {unknown} ms
 * @returns {number}
 */
function milliToSeconds(ms) {
  const raw = Number(ms);
  if (!Number.isFinite(raw) || raw <= 0) return 0;
  return Math.round(raw / 1000);
}

/**
 * Map Whoop `score.zone_durations` (ms) → `{ z0…z5: seconds }`.
 * @param {unknown} zoneDurations
 * @returns {Record<string, number>}
 */
function mapZoneDurationsToSeconds(zoneDurations) {
  const out = {};
  for (const key of ZONE_KEYS) out[key] = 0;
  if (!zoneDurations || typeof zoneDurations !== 'object') return out;

  for (const zone of ZONE_KEYS) {
    const field = ZONE_MILLI_FIELDS[zone];
    out[zone] = milliToSeconds(zoneDurations[field]);
  }
  return out;
}

/**
 * Absolute BPM bands from HRmax (Whoop %-based zones).
 * @param {{ hrMaxBpm?: number|null }} [args]
 * @returns {Array<{ zone: string, y1: number, y2: number }>}
 */
function whoopHrZoneBandsBpm({ hrMaxBpm } = {}) {
  const max =
    Number.isFinite(hrMaxBpm) && hrMaxBpm > 0 ? Math.round(hrMaxBpm) : null;
  if (max == null) {
    // Fallback absolute bands when HRmax is unknown (aligned with Polar defaults).
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
 * Extract scored metrics from a Whoop workout payload.
 * @param {unknown} workout
 * @returns {{
 *   strain: number|null,
 *   averageHeartRateBpm: number|null,
 *   maxHeartRateBpm: number|null,
 *   altitudeGainMeters: number|null,
 *   hrZoneSeconds: Record<string, number>,
 * }}
 */
function extractWhoopScoreMetrics(workout) {
  const score =
    (workout?.score_state ?? '').toString().toUpperCase() === 'SCORED'
      ? workout?.score ?? null
      : workout?.score ?? null;

  const strainRaw = Number(score?.strain ?? NaN);
  const avgHrRaw = Number(score?.average_heart_rate ?? NaN);
  const maxHrRaw = Number(score?.max_heart_rate ?? NaN);
  const altRaw = Number(score?.altitude_gain_meter ?? NaN);

  return {
    strain: Number.isFinite(strainRaw) ? strainRaw : null,
    averageHeartRateBpm: Number.isFinite(avgHrRaw)
      ? Math.round(avgHrRaw)
      : null,
    maxHeartRateBpm: Number.isFinite(maxHrRaw) ? Math.round(maxHrRaw) : null,
    altitudeGainMeters: Number.isFinite(altRaw) && altRaw > 0 ? altRaw : null,
    hrZoneSeconds: mapZoneDurationsToSeconds(score?.zone_durations),
  };
}

module.exports = {
  ZONE_KEYS,
  mapZoneDurationsToSeconds,
  whoopHrZoneBandsBpm,
  extractWhoopScoreMetrics,
  milliToSeconds,
};
