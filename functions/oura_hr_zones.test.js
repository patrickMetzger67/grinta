const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  mapOuraZoneDurationsToSeconds,
  extractMetricsFromHrSamples,
  estimateHrMaxFromPersonalInfo,
  ouraHrZoneBandsBpm,
} = require('./oura_hr_zones');

describe('mapOuraZoneDurationsToSeconds', () => {
  it('maps array of seconds', () => {
    const zones = mapOuraZoneDurationsToSeconds([10, 20, 30, 40, 50, 60]);
    assert.equal(zones.z0, 10);
    assert.equal(zones.z5, 60);
  });

  it('maps zone_N object keys', () => {
    const zones = mapOuraZoneDurationsToSeconds({
      zone_1: 120,
      zone_3: 45,
    });
    assert.equal(zones.z1, 120);
    assert.equal(zones.z3, 45);
    assert.equal(zones.z0, 0);
  });
});

describe('extractMetricsFromHrSamples', () => {
  it('computes avg/max and zone seconds from samples', () => {
    const start = Date.parse('2026-08-11T10:00:00.000Z');
    const samples = [
      { bpm: 90, timestamp: new Date(start).toISOString(), source: 'workout' },
      {
        bpm: 130,
        timestamp: new Date(start + 60_000).toISOString(),
        source: 'workout',
      },
      {
        bpm: 170,
        timestamp: new Date(start + 120_000).toISOString(),
        source: 'workout',
      },
    ];
    const metrics = extractMetricsFromHrSamples(samples, {
      hrMaxBpm: 200,
      workoutDurationSeconds: 180,
    });
    assert.equal(metrics.averageHeartRateBpm, 130);
    assert.equal(metrics.maxHeartRateBpm, 170);
    assert.equal(metrics.samplesUsed, 3);
    const total = Object.values(metrics.hrZoneSeconds).reduce((a, b) => a + b, 0);
    assert.ok(total > 0);
    assert.ok(metrics.hrZoneSeconds.z4 > 0 || metrics.hrZoneSeconds.z5 > 0);
  });

  it('prefers workout-tagged samples', () => {
    const samples = [
      { bpm: 60, timestamp: '2026-08-11T10:00:00.000Z', source: 'awake' },
      { bpm: 150, timestamp: '2026-08-11T10:01:00.000Z', source: 'workout' },
    ];
    const metrics = extractMetricsFromHrSamples(samples, {
      workoutDurationSeconds: 60,
    });
    assert.equal(metrics.samplesUsed, 1);
    assert.equal(metrics.averageHeartRateBpm, 150);
  });
});

describe('estimateHrMaxFromPersonalInfo', () => {
  it('returns 220 - age', () => {
    assert.equal(estimateHrMaxFromPersonalInfo({ age: 30 }), 190);
  });

  it('rejects invalid ages', () => {
    assert.equal(estimateHrMaxFromPersonalInfo({ age: 5 }), null);
    assert.equal(estimateHrMaxFromPersonalInfo({}), null);
  });
});

describe('ouraHrZoneBandsBpm', () => {
  it('uses absolute fallbacks without HRmax', () => {
    const bands = ouraHrZoneBandsBpm({});
    assert.equal(bands[0].zone, 'z0');
    assert.equal(bands[5].y2, 200);
  });
});
