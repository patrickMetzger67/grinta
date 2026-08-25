/**
 * Match Insiders window — same rules as the Grinta app
 * (`resolveMatchIntenseFetchWindow` / `resolveMatchSensorSyncPeriods`).
 *
 * - Kick-off = `Match.timestamp` only (never dateCh / timeCh).
 * - With usable Temps forts (`kickOff` + `end`): those wall times, split
 *   into halves when mi-temps / reprise are present.
 * - Otherwise: two scheduled halves + 15' break from timestamp
 *   (`[T, T+45]` then `[T+60, T+105]` for a 90' match).
 */

const HALFTIME_BREAK_MINUTES = 15;
const MIN_PLAUSIBLE_MATCH_MINUTES = 5;
const MAX_PLAUSIBLE_MATCH_HOURS = 4;
const DEFAULT_DURATION_MINUTES = 90;

const TIME_EVENT_ACTION = 'ActionType.timeEvent';
const TIME_TYPE = {
  kickOff: 'kickOff',
  halfTime: 'halTime',
  secondHalf: 'secondHalf',
  startExtraTime: 'startExtraTime',
  end: 'end',
};

function tsToDate(value) {
  if (!value) return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value.toDate === 'function') {
    try {
      const date = value.toDate();
      return date instanceof Date && !Number.isNaN(date.getTime()) ? date : null;
    } catch (_) {
      return null;
    }
  }
  if (typeof value === 'number' && Number.isFinite(value)) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (typeof value === 'string' && value.trim()) {
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
  const value = String(raw ?? '').trim();
  if (!value) return null;
  const name = value.includes('.') ? value.split('.').pop() : value;
  if (name === TIME_TYPE.kickOff) return TIME_TYPE.kickOff;
  if (name === TIME_TYPE.halfTime || name === 'halfTime') return TIME_TYPE.halfTime;
  if (name === TIME_TYPE.secondHalf) return TIME_TYPE.secondHalf;
  if (name === TIME_TYPE.startExtraTime) return TIME_TYPE.startExtraTime;
  if (name === TIME_TYPE.end) return TIME_TYPE.end;
  return null;
}

function isTimeEventHighlight(data) {
  const action = String(data?.action ?? '');
  return action === TIME_EVENT_ACTION || action.endsWith('timeEvent');
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
  if (candidateEnd.getTime() <= startAt.getTime() + MIN_PLAUSIBLE_MATCH_MINUTES * 60 * 1000) {
    return false;
  }
  if (candidateEnd.getTime() > startAt.getTime() + MAX_PLAUSIBLE_MATCH_HOURS * 60 * 60 * 1000) {
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

/**
 * Play periods excluding the half-time break when halves are known.
 */
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

/**
 * Full-time used for eligibility: Temps fort `end` if present, else
 * timestamp + duration + 15' break.
 */
function matchIntenseEnd(matchData, highlights, { scheduledEnd = null } = {}) {
  const endHighlight = findTimeEventDate(highlights, TIME_TYPE.end);
  if (endHighlight) return endHighlight;
  if (scheduledEnd) return scheduledEnd;

  const start = matchLiveStart(matchData, highlights) ??
    matchSessionStart(matchData, highlights);
  if (start) {
    return matchScheduledSlotEnd(start, matchDurationMinutes(matchData));
  }
  return null;
}

/**
 * Insiders fetch window: first play-period start → last play-period end
 * (includes the half-time gap so samples can be fetched; filter afterwards).
 */
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
  if (!sample || typeof sample !== 'object') return null;
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

module.exports = {
  HALFTIME_BREAK_MINUTES,
  TIME_TYPE,
  tsToDate,
  matchDurationMinutes,
  matchTimestampKickoff,
  matchScheduledSlotEnd,
  findTimeEventDate,
  resolveMatchSensorSyncPeriods,
  matchLiveStart,
  matchIntenseEnd,
  resolveMatchIntenseFetchWindow,
  filterSamplesToMatchPeriods,
  isEligibleForAutoSync,
};
