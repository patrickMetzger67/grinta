import 'package:flutter/material.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

/// One painted span of a [PlayerTask] on a Monday–Sunday strip.
class PlayerTaskBarSpan {
  const PlayerTaskBarSpan({
    required this.task,
    required this.startColumn,
    required this.endColumn,
    required this.lane,
  });

  final PlayerTask task;

  /// Inclusive 0–6 column (Monday = 0).
  final int startColumn;
  final int endColumn;

  /// Vertical lane, 0 at the top.
  final int lane;

  int get columnSpan => endColumn - startColumn + 1;
}

/// Places overlapping tasks into lanes so a week-long duty becomes one bar.
List<PlayerTaskBarSpan> layoutPlayerTaskBars({
  required List<PlayerTask> tasks,
  required DateTime weekStart,
}) {
  final DateTime monday = DateUtils.dateOnly(agendaWeekStart(weekStart));
  final DateTime sunday = DateUtils.dateOnly(agendaWeekEnd(monday));

  final List<PlayerTask> overlapping = tasks
      .where((PlayerTask task) => task.overlapsRange(monday, sunday))
      .toList()
    ..sort((PlayerTask a, PlayerTask b) {
      final int startCmp = a.startDay.compareTo(b.startDay);
      if (startCmp != 0) {
        return startCmp;
      }
      final int durationCmp = b.endDay.compareTo(a.endDay);
      if (durationCmp != 0) {
        return durationCmp;
      }
      return a.barLabel.toLowerCase().compareTo(b.barLabel.toLowerCase());
    });

  final List<PlayerTaskBarSpan> spans = <PlayerTaskBarSpan>[];
  final List<List<PlayerTaskBarSpan>> lanes = <List<PlayerTaskBarSpan>>[];

  for (final PlayerTask task in overlapping) {
    final int startColumn = _columnForDay(task.startDay, monday);
    final int endColumn = _columnForDay(task.endDay, monday);
    if (endColumn < 0 || startColumn > 6) {
      continue;
    }
    final int clampedStart = startColumn < 0 ? 0 : startColumn;
    final int clampedEnd = endColumn > 6 ? 6 : endColumn;

    int lane = 0;
    while (lane < lanes.length &&
        lanes[lane].any(
          (PlayerTaskBarSpan existing) =>
              existing.startColumn <= clampedEnd &&
              clampedStart <= existing.endColumn,
        )) {
      lane++;
    }
    if (lane == lanes.length) {
      lanes.add(<PlayerTaskBarSpan>[]);
    }

    final PlayerTaskBarSpan span = PlayerTaskBarSpan(
      task: task,
      startColumn: clampedStart,
      endColumn: clampedEnd,
      lane: lane,
    );
    lanes[lane].add(span);
    spans.add(span);
  }

  return spans;
}

int playerTaskBarLaneCount(List<PlayerTaskBarSpan> spans) {
  int maxLane = -1;
  for (final PlayerTaskBarSpan span in spans) {
    if (span.lane > maxLane) {
      maxLane = span.lane;
    }
  }
  return maxLane + 1;
}

int _columnForDay(DateTime day, DateTime monday) {
  final DateTime d = DateUtils.dateOnly(day);
  final DateTime m = DateUtils.dateOnly(monday);
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(m.year, m.month, m.day))
      .inDays;
}
