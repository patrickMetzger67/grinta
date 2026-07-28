const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  mapZoneDurationsToSeconds,
  whoopHrZoneBandsBpm,
  extractWhoopScoreMetrics,
} = require('./whoop_hr_zones');

describe('mapZoneDurationsToSeconds', () => {
  it('converts milli fields to rounded seconds', () => {
    const result = mapZoneDurationsToSeconds({
      zone_zero_milli: 300000,
      zone_one_milli: 600000,
      zone_two_milli: 900000,
      zone_three_milli: 900000,
      zone_four_milli: 600000,
      zone_five_milli: 300000,
    });
    assert.deepEqual(result, {
      z0: 300,
      z1: 600,
      z2: 900,
      z3: 900,
      z4: 600,
      z5: 300,
    });
  });

  it('returns zeros for missing / invalid payloads', () => {
    assert.deepEqual(mapZoneDurationsToSeconds(null), {
      z0: 0,
      z1: 0,
      z2: 0,
      z3: 0,
      z4: 0,
      z5: 0,
    });
    assert.deepEqual(mapZoneDurationsToSeconds({ zone_five_milli: -1 }), {
      z0: 0,
      z1: 0,
      z2: 0,
      z3: 0,
      z4: 0,
      z5: 0,
    });
  });
});

describe('whoopHrZoneBandsBpm', () => {
  it('builds %-of-max bands when HRmax is known', () => {
    const bands = whoopHrZoneBandsBpm({ hrMaxBpm: 200 });
    assert.equal(bands.length, 6);
    assert.deepEqual(bands[0], { zone: 'z0', y1: 0, y2: 100 });
    assert.deepEqual(bands[5], { zone: 'z5', y1: 180, y2: 200 });
  });

  it('falls back to absolute bands without HRmax', () => {
    const bands = whoopHrZoneBandsBpm({});
    assert.equal(bands[5].zone, 'z5');
    assert.equal(bands[5].y1, 180);
  });
});

describe('extractWhoopScoreMetrics', () => {
  it('reads strain, HR, altitude and zones from a scored workout', () => {
    const metrics = extractWhoopScoreMetrics({
      score_state: 'SCORED',
      score: {
        strain: 14.6,
        average_heart_rate: 152,
        max_heart_rate: 189,
        altitude_gain_meter: 42.5,
        zone_durations: {
          zone_zero_milli: 1000,
          zone_one_milli: 2000,
          zone_two_milli: 3000,
          zone_three_milli: 4000,
          zone_four_milli: 5000,
          zone_five_milli: 6000,
        },
      },
    });
    assert.equal(metrics.strain, 14.6);
    assert.equal(metrics.averageHeartRateBpm, 152);
    assert.equal(metrics.maxHeartRateBpm, 189);
    assert.equal(metrics.altitudeGainMeters, 42.5);
    assert.equal(metrics.hrZoneSeconds.z5, 6);
  });
});
