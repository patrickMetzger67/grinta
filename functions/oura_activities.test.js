const test = require('node:test');
const assert = require('node:assert/strict');
const { mapOuraSport, mapWorkoutSummary } = require('./oura_activities');

test('mapOuraSport maps common activities', () => {
  assert.equal(mapOuraSport('running'), 'course');
  assert.equal(mapOuraSport('cycling'), 'velo');
  assert.equal(mapOuraSport('swimming'), 'natation');
  assert.equal(mapOuraSport('yoga'), 'recuperation');
  assert.equal(mapOuraSport('strength_training'), 'entrainement');
});

test('mapWorkoutSummary maps Oura workout fields', () => {
  const summary = mapWorkoutSummary({
    id: '2-abc',
    activity: 'running',
    calories: 412.4,
    distance: 5200,
    start_datetime: '2026-01-01T10:00:00+00:00',
    end_datetime: '2026-01-01T10:40:00+00:00',
    intensity: 'moderate',
    source: 'manual',
    day: '2026-01-01',
    label: null,
  });
  assert.equal(summary.externalId, '2-abc');
  assert.equal(summary.typeId, 'course');
  assert.equal(summary.durationSeconds, 2400);
  assert.equal(summary.distanceMeters, 5200);
  assert.equal(summary.caloriesKcal, 412);
  assert.equal(summary.intensity, 'moderate');
  assert.ok(summary.startDate);
});
