import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/util/match_creation_helper.dart';

/// Minimum allowed match minute (kick-off is minute 1, never 0).
const int kHighlightMinuteMin = 1;

/// Suggested minute and optional stoppage time for a new highlight.
class HighlightMinuteSuggestion {
  const HighlightMinuteSuggestion({
    required this.minute,
    this.extraTime = 0,
  });

  final int minute;
  final int extraTime;
}

/// Regulation match length in minutes (defaults to 90).
int regulationMatchDuration(models.Match match) => match.duration ?? 90;

/// First-half length in minutes.
int halfMatchDuration(models.Match match) =>
    regulationMatchDuration(match) ~/ 2;

/// Scheduled kick-off as local [DateTime], when [Match.dateCh] and [timeCh] are set.
DateTime? matchKickoffDateTime(models.Match match) {
  final matchDate = parseMatchDateCh(match.dateCh);
  final matchTime = parseMatchTimeCh(match.timeCh);
  if (matchDate == null || matchTime == null) {
    return null;
  }
  return DateTime(
    matchDate.year,
    matchDate.month,
    matchDate.day,
    matchTime.hour,
    matchTime.minute,
  );
}

/// Most recent period-start time event among [highlights].
Highlights? findLastTimeAnchor(List<Highlights> highlights) {
  Highlights? best;
  int bestMs = -1;

  for (final highlight in highlights) {
    if (highlight.actionType != ActionType.timeEvent) {
      continue;
    }
    final timeEvent = highlight.value as TimeEvent?;
    final type = timeEvent?.type;
    if (type != TimeType.kickOff &&
        type != TimeType.secondHalf &&
        type != TimeType.startExtraTime) {
      continue;
    }
    final ms = highlight.dateTime?.millisecondsSinceEpoch ?? 0;
    if (ms >= bestMs) {
      bestMs = ms;
      best = highlight;
    }
  }

  return best;
}

Highlights? findTimeEventHighlight(
  List<Highlights> highlights,
  TimeType timeType,
) {
  for (final highlight in highlights) {
    if (highlight.actionType != ActionType.timeEvent) {
      continue;
    }
    final timeEvent = highlight.value as TimeEvent?;
    if (timeEvent?.type == timeType) {
      return highlight;
    }
  }
  return null;
}

/// [TimeType] values already recorded as time-event highlights.
Set<TimeType> recordedTimeTypes(List<Highlights> highlights) {
  final recorded = <TimeType>{};
  for (final highlight in highlights) {
    if (highlight.actionType != ActionType.timeEvent) {
      continue;
    }
    final timeEvent = highlight.value as TimeEvent?;
    final type = timeEvent?.type;
    if (type != null) {
      recorded.add(type);
    }
  }
  return recorded;
}

/// Time-event types that can still be added for this match.
List<TimeType> availableTimeTypes(List<Highlights> highlights) {
  final recorded = recordedTimeTypes(highlights);
  return TimeType.values.where((type) => !recorded.contains(type)).toList();
}

int _clampMinute(int minute) => minute.clamp(kHighlightMinuteMin, 999);

/// Elapsed match minutes since the last period anchor or scheduled kick-off.
int minuteFromElapsed({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? now,
}) {
  now ??= DateTime.now();

  final anchor = findLastTimeAnchor(highlights);
  if (anchor?.dateTime != null) {
    final elapsed =
        now.difference(anchor!.dateTime!.toDate()).inMinutes;
    final base = _clampMinute(anchor.minute ?? kHighlightMinuteMin);
    return _clampMinute(base + elapsed);
  }

  final kickoff = matchKickoffDateTime(match);
  if (kickoff != null) {
    final elapsed = now.difference(kickoff).inMinutes;
    return _clampMinute(kHighlightMinuteMin + elapsed);
  }

  if (highlights.isNotEmpty) {
    final last = highlights.last;
    final lastMinute = _clampMinute(last.minute ?? kHighlightMinuteMin);
    return _clampMinute(lastMinute + 1);
  }

  return kHighlightMinuteMin;
}

/// Match minute elapsed since the kick-off highlight timestamp (minute 1 at whistle).
int minuteElapsedSinceKickOff({
  required List<Highlights> highlights,
  DateTime? now,
}) {
  now ??= DateTime.now();

  final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
  if (kickOff?.dateTime != null) {
    final base = _clampMinute(kickOff!.minute ?? kHighlightMinuteMin);
    final elapsed = now.difference(kickOff.dateTime!.toDate()).inMinutes;
    return _clampMinute(base + elapsed);
  }

  return kHighlightMinuteMin;
}

/// Default minute for a new [TimeType] period event.
HighlightMinuteSuggestion suggestedMinuteForTimeEvent({
  required models.Match match,
  required List<Highlights> highlights,
  required TimeType timeType,
  DateTime? now,
}) {
  now ??= DateTime.now();
  final half = halfMatchDuration(match);

  switch (timeType) {
    case TimeType.kickOff:
      return const HighlightMinuteSuggestion(minute: kHighlightMinuteMin);

    case TimeType.halTime:
      final kickOff = findTimeEventHighlight(highlights, TimeType.kickOff);
      if (kickOff?.dateTime != null) {
        return HighlightMinuteSuggestion(
          minute: minuteElapsedSinceKickOff(
            highlights: highlights,
            now: now,
          ),
        );
      }
      return HighlightMinuteSuggestion(
        minute: minuteFromElapsed(
          match: match,
          highlights: highlights,
          now: now,
        ),
      );

    case TimeType.secondHalf:
      final halTimeHighlight =
          findTimeEventHighlight(highlights, TimeType.halTime);
      if (halTimeHighlight?.minute != null) {
        return HighlightMinuteSuggestion(
          minute: _clampMinute(halTimeHighlight!.minute! + 1),
        );
      }
      return HighlightMinuteSuggestion(
        minute: _clampMinute(half + 1),
      );

    case TimeType.startExtraTime:
    case TimeType.end:
      return HighlightMinuteSuggestion(
        minute: minuteFromElapsed(
          match: match,
          highlights: highlights,
          now: now,
        ),
      );
  }
}

/// Default minute for a new action highlight (goal, card, substitution, …).
HighlightMinuteSuggestion suggestedMinuteForAction({
  required models.Match match,
  required List<Highlights> highlights,
  DateTime? now,
}) {
  return HighlightMinuteSuggestion(
    minute: minuteFromElapsed(
      match: match,
      highlights: highlights,
      now: now,
    ),
  );
}

/// Parses user-entered minute text; returns null when invalid or below [kHighlightMinuteMin].
int? parseHighlightMinute(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final value = int.tryParse(trimmed);
  if (value == null || value < kHighlightMinuteMin) {
    return null;
  }
  return value;
}
