const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const {
  TIME_TYPE,
  matchScheduledSlotEnd,
  matchTimestampKickoff,
  resolveMatchSensorSyncPeriods,
  resolveMatchIntenseFetchWindow,
  matchIntenseEnd,
  filterSamplesToMatchPeriods,
  isEligibleForAutoSync,
} = require('./intense_match_window');

function timeEvent(type, at) {
  return {
    action: 'ActionType.timeEvent',
    value: { type: `TimeType.${type}` },
    dateTime: at,
  };
}

describe('matchTimestampKickoff', () => {
  it('uses Match.timestamp only (never dateCh/timeCh)', () => {
    const kickOff = new Date(2026, 7, 2, 15, 0);
    assert.deepEqual(
      matchTimestampKickoff({
        timestamp: kickOff,
        dateCh: '02/08/2026',
        timeCh: '18:00',
      }),
      kickOff,
    );
    assert.equal(
      matchTimestampKickoff({ dateCh: '02/08/2026', timeCh: '15:00' }),
      null,
    );
  });
});

describe('matchScheduledSlotEnd', () => {
  it('adds duration plus 15 min half-time break', () => {
    const start = new Date(2026, 7, 2, 15, 0);
    assert.deepEqual(
      matchScheduledSlotEnd(start, 90),
      new Date(2026, 7, 2, 16, 45),
    );
  });
});

describe('resolveMatchSensorSyncPeriods', () => {
  const kickOffTs = new Date(2026, 7, 2, 15, 0);

  it('without temps forts builds two halves + 15 min break from timestamp', () => {
    const periods = resolveMatchSensorSyncPeriods({
      matchData: { timestamp: kickOffTs, duration: 90 },
      highlights: [],
    });

    assert.equal(periods.length, 2);
    assert.deepEqual(periods[0].start, kickOffTs);
    assert.deepEqual(periods[0].end, new Date(2026, 7, 2, 15, 45));
    assert.deepEqual(periods[1].start, new Date(2026, 7, 2, 16, 0));
    assert.deepEqual(periods[1].end, new Date(2026, 7, 2, 16, 45));
  });

  it('uses kickOff + end as a single period', () => {
    const end = new Date(2026, 7, 2, 16, 50);
    const periods = resolveMatchSensorSyncPeriods({
      matchData: { timestamp: kickOffTs, duration: 90 },
      highlights: [
        timeEvent(TIME_TYPE.kickOff, kickOffTs),
        timeEvent(TIME_TYPE.end, end),
      ],
    });

    assert.equal(periods.length, 1);
    assert.deepEqual(periods[0].start, kickOffTs);
    assert.deepEqual(periods[0].end, end);
  });

  it('splits halves when mi-temps and reprise are present', () => {
    const half = new Date(2026, 7, 2, 15, 48);
    const second = new Date(2026, 7, 2, 16, 3);
    const end = new Date(2026, 7, 2, 16, 52);
    const periods = resolveMatchSensorSyncPeriods({
      matchData: { timestamp: kickOffTs, duration: 90 },
      highlights: [
        timeEvent(TIME_TYPE.kickOff, kickOffTs),
        timeEvent(TIME_TYPE.halfTime, half),
        timeEvent(TIME_TYPE.secondHalf, second),
        timeEvent(TIME_TYPE.end, end),
      ],
    });

    assert.equal(periods.length, 2);
    assert.deepEqual(periods[0], { start: kickOffTs, end: half });
    assert.deepEqual(periods[1], { start: second, end });
  });

  it('incomplete temps forts fall back to timestamp halves', () => {
    const lateKickOff = new Date(2026, 7, 2, 15, 46, 48);
    const periods = resolveMatchSensorSyncPeriods({
      matchData: { timestamp: kickOffTs, duration: 90 },
      highlights: [timeEvent(TIME_TYPE.kickOff, lateKickOff)],
      fallbackStart: kickOffTs,
    });

    assert.equal(periods.length, 2);
    assert.deepEqual(periods[0].start, kickOffTs);
    assert.deepEqual(periods[1].end, new Date(2026, 7, 2, 16, 45));
  });
});

describe('resolveMatchIntenseFetchWindow', () => {
  const kickOffTs = new Date(2026, 7, 2, 15, 0);

  it('uses kick-off and full-time Temps forts when both present', () => {
    const end = new Date(2026, 7, 2, 16, 50);
    const window = resolveMatchIntenseFetchWindow(
      { timestamp: kickOffTs, duration: 90 },
      [
        timeEvent(TIME_TYPE.kickOff, kickOffTs),
        timeEvent(TIME_TYPE.end, end),
      ],
    );

    assert.ok(window);
    assert.deepEqual(window.start, kickOffTs);
    assert.deepEqual(window.stop, end);
  });

  it('builds halves + 15 min break from Match.timestamp when no temps forts', () => {
    const window = resolveMatchIntenseFetchWindow(
      {
        timestamp: kickOffTs,
        duration: 90,
        dateCh: '02/08/2026',
        timeCh: '18:00',
      },
      [],
    );

    assert.ok(window);
    assert.deepEqual(window.start, kickOffTs);
    assert.deepEqual(window.stop, new Date(2026, 7, 2, 16, 45));
    assert.equal(window.playPeriods.length, 2);
  });

  it('ignores late-tapped kick-off and keeps Match.timestamp window', () => {
    const window = resolveMatchIntenseFetchWindow(
      { timestamp: kickOffTs, duration: 90 },
      [timeEvent(TIME_TYPE.kickOff, new Date(Date.UTC(2026, 7, 2, 15, 46, 48)))],
    );

    assert.ok(window);
    assert.deepEqual(window.start, kickOffTs);
    assert.deepEqual(window.stop, new Date(2026, 7, 2, 16, 45));
    assert.ok(window.stop.getTime() > window.start.getTime());
  });

  it('never returns a zero-width window', () => {
    const late = new Date(2026, 7, 2, 15, 46, 48);
    const window = resolveMatchIntenseFetchWindow(
      { timestamp: kickOffTs, duration: 90 },
      [timeEvent(TIME_TYPE.kickOff, late), timeEvent(TIME_TYPE.end, late)],
    );

    assert.ok(window);
    assert.equal(
      window.stop.getTime() - window.start.getTime(),
      105 * 60 * 1000,
    );
    assert.deepEqual(window.start, kickOffTs);
  });

  it('returns null when Match.timestamp is missing and no usable temps forts', () => {
    const window = resolveMatchIntenseFetchWindow(
      { dateCh: '02/08/2026', timeCh: '15:00', duration: 90 },
      [],
    );
    assert.equal(window, null);
  });
});

describe('matchIntenseEnd', () => {
  const kickOffTs = new Date(2026, 7, 2, 15, 0);

  it('prefers the full-time Temps fort', () => {
    const end = new Date(2026, 7, 2, 16, 50);
    assert.deepEqual(
      matchIntenseEnd(
        { timestamp: kickOffTs, duration: 90 },
        [timeEvent(TIME_TYPE.end, end)],
      ),
      end,
    );
  });

  it('falls back to timestamp + duration + 15 min without temps forts', () => {
    assert.deepEqual(
      matchIntenseEnd({ timestamp: kickOffTs, duration: 90 }, []),
      new Date(2026, 7, 2, 16, 45),
    );
  });
});

describe('filterSamplesToMatchPeriods', () => {
  it('drops samples that fall in the half-time break', () => {
    const start = new Date(Date.UTC(2026, 7, 2, 15, 0));
    const periods = resolveMatchSensorSyncPeriods({
      matchData: { timestamp: start, duration: 90 },
      highlights: [],
    });
    const samples = [10, 50, 70, 110].map((minutes) => ({
      timeMs: start.getTime() + minutes * 60 * 1000,
    }));

    const kept = filterSamplesToMatchPeriods(samples, periods);
    assert.deepEqual(
      kept.map((s) => (s.timeMs - start.getTime()) / 60000),
      [10, 70],
    );
  });
});

describe('isEligibleForAutoSync', () => {
  const config = { graceMinutes: 10, insidersRetentionHours: 48 };
  const end = new Date(2026, 7, 2, 16, 45);

  it('is false during the grace period after full-time', () => {
    assert.equal(
      isEligibleForAutoSync(end, new Date(2026, 7, 2, 16, 50), config),
      false,
    );
  });

  it('is true after grace and within retention', () => {
    assert.equal(
      isEligibleForAutoSync(end, new Date(2026, 7, 2, 17, 0), config),
      true,
    );
  });

  it('is false after the retention window', () => {
    assert.equal(
      isEligibleForAutoSync(end, new Date(2026, 7, 5, 17, 0), config),
      false,
    );
  });
});
