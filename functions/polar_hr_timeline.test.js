const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  extractPolarHrSamples,
  aggregateHrTimeline,
  mapPolarHeartRateZones,
  buildPolarCardioExtras,
  parseIsoDurationSeconds,
} = require('./polar_hr_timeline');

describe('parseIsoDurationSeconds', () => {
  it('parses hours and minutes', () => {
    assert.equal(parseIsoDurationSeconds('PT2H44M'), 2 * 3600 + 44 * 60);
  });

  it('parses seconds', () => {
    assert.equal(parseIsoDurationSeconds('PT1H38M13S'), 3600 + 38 * 60 + 13);
  });
});

describe('extractPolarHrSamples', () => {
  it('prefers sample-type 0 (heart rate)', () => {
    const extracted = extractPolarHrSamples([
      {
        'sample-type': '1',
        'recording-rate': 1,
        data: '10,11,12,13,14,15',
      },
      {
        'sample-type': '0',
        'recording-rate': 5,
        data: '0,100,102,140,160',
      },
    ]);
    assert.ok(extracted);
    assert.equal(extracted.intervalSeconds, 5);
    assert.deepEqual(extracted.samples, [0, 100, 102, 140, 160]);
  });

  it('falls back to BPM-looking series when type 0 is missing', () => {
    const extracted = extractPolarHrSamples([
      {
        'sample-type': '1',
        'recording-rate': 5,
        data: '100,102,97,101,103,106,96,89,88',
      },
    ]);
    assert.ok(extracted);
    assert.equal(extracted.samples.length, 9);
    assert.equal(extracted.intervalSeconds, 5);
  });
});

describe('aggregateHrTimeline', () => {
  it('averages into 5-minute buckets', () => {
    const samples = Array.from({ length: 12 }, (_, i) => 100 + i);
    const timeline = aggregateHrTimeline({
      samples,
      intervalSeconds: 60,
    });
    assert.equal(timeline.length, 3);
    assert.equal(timeline[0].t, 0);
    assert.equal(timeline[0].avg, 102);
    assert.equal(timeline[1].t, 5);
    assert.equal(timeline[1].avg, 107);
    assert.equal(timeline[2].t, 10);
    assert.equal(timeline[2].avg, 111);
  });
});

describe('mapPolarHeartRateZones', () => {
  it('maps in-zone durations to z1…z5', () => {
    const zones = mapPolarHeartRateZones([
      { index: 1, 'in-zone': 'PT1M' },
      { index: 3, 'in-zone': 'PT2M30S' },
      { index: 5, 'in-zone': 'PT10S' },
    ]);
    assert.equal(zones.z1, 60);
    assert.equal(zones.z2, 0);
    assert.equal(zones.z3, 150);
    assert.equal(zones.z5, 10);
  });
});

describe('buildPolarCardioExtras', () => {
  it('builds timeline and zones from samples', () => {
    const extras = buildPolarCardioExtras({
      heart_rate: { average: 130, maximum: 170 },
      samples: [
        {
          'sample-type': '0',
          'recording-rate': 60,
          data: '100,110,120,130,140,150,160,170,180,190,100,110',
        },
      ],
    });
    assert.equal(extras.hrTimelineBucketMinutes, 5);
    assert.ok(extras.hrTimeline.length >= 2);
    assert.equal(extras.maxHeartRateBpm, 170);
    assert.equal(extras.minHeartRateBpm, 100);
    assert.ok(extras.hrSamplesCount > 0);
    assert.ok(extras.hrZoneSeconds.z5 > 0);
  });

  it('uses API heart_rate_zones when present', () => {
    const extras = buildPolarCardioExtras({
      heart_rate: { average: 120, maximum: 150 },
      heart_rate_zones: [
        { index: 2, 'in-zone': 'PT10M' },
        { index: 3, 'in-zone': 'PT5M' },
      ],
      samples: [
        {
          'sample-type': '0',
          'recording-rate': 60,
          data: '100,110,120,130,140',
        },
      ],
    });
    assert.equal(extras.hrZoneSeconds.z2, 600);
    assert.equal(extras.hrZoneSeconds.z3, 300);
  });
});
