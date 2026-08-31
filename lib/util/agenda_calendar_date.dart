import 'package:flutter/material.dart';

/// Places [dayOfMonth] onto [month], clamping when the month is shorter.
///
/// Example: dayOfMonth=31, month=Sep 2026 → 30 Sep 2026.
DateTime dateInMonthWithDay(DateTime month, int dayOfMonth) {
  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final int safeDay = dayOfMonth < 1
      ? 1
      : (dayOfMonth > daysInMonth ? daysInMonth : dayOfMonth);
  return DateTime(month.year, month.month, safeDay);
}

/// Places [date]'s day-of-month onto [month], clamping when needed.
///
/// Example: date=31 Aug 2026, month=Sep 2026 → 30 Sep 2026.
DateTime clampDateToMonth(DateTime date, DateTime month) {
  final DateTime normalized = DateUtils.dateOnly(date);
  return dateInMonthWithDay(month, normalized.day);
}

/// Moves [date] by [months], keeping the day-of-month when possible.
///
/// If the target month is shorter (e.g. 31 Aug → September), the day is
/// clamped to the last valid day (30 Sep).
DateTime addMonthsKeepingDay(DateTime date, int months) {
  final DateTime normalized = DateUtils.dateOnly(date);
  final DateTime targetMonth =
      DateTime(normalized.year, normalized.month + months);
  return clampDateToMonth(normalized, targetMonth);
}

/// Month-pager selection that remembers the preferred day-of-month.
///
/// Navigating Aug 31 → Sep yields Sep 30, then back to Aug yields Aug 31
/// (not Aug 30), because [preferredDayOfMonth] stays 31 across clamps.
DateTime monthPageSelectedDate({
  required DateTime targetMonth,
  required int preferredDayOfMonth,
}) {
  return dateInMonthWithDay(targetMonth, preferredDayOfMonth);
}

/// Whether [weekStart] (Mon–Sun) overlaps the calendar month of [month].
bool weekOverlapsMonth(DateTime weekStart, DateTime month) {
  final DateTime monthStart = DateTime(month.year, month.month, 1);
  final DateTime monthEnd = DateTime(month.year, month.month + 1, 0);
  final DateTime weekEnd = DateUtils.dateOnly(weekStart).add(
    const Duration(days: 6),
  );
  final DateTime start = DateUtils.dateOnly(weekStart);
  return !weekEnd.isBefore(monthStart) && !start.isAfter(monthEnd);
}

/// Advances [date] by full weeks, preserving the weekday.
DateTime addWeeksKeepingWeekday(DateTime date, int weeks) {
  return DateUtils.dateOnly(date).add(Duration(days: 7 * weeks));
}

/// SwitchMap-style gate: only the latest [LatestWinsToken] stays current.
///
/// Used so rapid agenda slides cancel/ignore stale window hydrations instead
/// of queuing old loads that snap the UI back when they finish.
class LatestWinsGate {
  int _generation = 0;

  int get generation => _generation;

  LatestWinsToken begin() => LatestWinsToken._(++_generation, this);
}

class LatestWinsToken {
  LatestWinsToken._(this.id, this._gate);

  final int id;
  final LatestWinsGate _gate;

  bool get isCurrent => id == _gate.generation;
}

/// Planned loaded-window update for a focus month (M±[windowRadiusMonths]).
class AgendaWindowHydrationPlan {
  const AgendaWindowHydrationPlan({
    required this.rangeStart,
    required this.rangeEnd,
    required this.needsReload,
    required this.alreadyFullyCovered,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final bool needsReload;
  final bool alreadyFullyCovered;
}

DateTime _agendaMonthStart(DateTime month) =>
    DateTime(month.year, month.month, 1);

DateTime _agendaMonthEnd(DateTime month) =>
    DateTime(month.year, month.month + 1, 0);

DateTime _agendaAddMonths(DateTime month, int months) =>
    DateTime(month.year, month.month + months, 1);

int _agendaMonthSpan(DateTime rangeStart, DateTime rangeEnd) {
  final DateTime start = _agendaMonthStart(rangeStart);
  final DateTime end = _agendaMonthStart(rangeEnd);
  return (end.year - start.year) * 12 + (end.month - start.month) + 1;
}

/// Decides how to expand/shrink the cached agenda range for [focusMonth].
///
/// Pure helper so navigation can update the pager first, then hydrate using
/// only the latest slide's plan (stale plans are dropped by [LatestWinsGate]).
AgendaWindowHydrationPlan planAgendaWindowHydration({
  required DateTime focusMonth,
  required DateTime currentRangeStart,
  required DateTime currentRangeEnd,
  int windowRadiusMonths = 1,
  int maxLoadedMonths = 4,
}) {
  final DateTime focus = _agendaMonthStart(focusMonth);
  final DateTime desiredStart =
      _agendaMonthStart(_agendaAddMonths(focus, -windowRadiusMonths));
  final DateTime desiredEnd =
      _agendaMonthEnd(_agendaAddMonths(focus, windowRadiusMonths));

  bool rangeCovers(DateTime start, DateTime end) {
    return !currentRangeStart.isAfter(start) && !currentRangeEnd.isBefore(end);
  }

  final bool monthCovered =
      rangeCovers(_agendaMonthStart(focus), _agendaMonthEnd(focus));
  final bool windowCovered = rangeCovers(desiredStart, desiredEnd);

  if (monthCovered && windowCovered) {
    return AgendaWindowHydrationPlan(
      rangeStart: currentRangeStart,
      rangeEnd: currentRangeEnd,
      needsReload: false,
      alreadyFullyCovered: true,
    );
  }

  var nextStart = currentRangeStart;
  var nextEnd = currentRangeEnd;
  var needsReload = false;

  if (monthCovered) {
    if (nextStart.isAfter(desiredStart)) {
      nextStart = desiredStart;
      needsReload = true;
    }
    if (nextEnd.isBefore(desiredEnd)) {
      nextEnd = desiredEnd;
      needsReload = true;
    }
    if (_agendaMonthSpan(nextStart, nextEnd) > maxLoadedMonths) {
      nextStart = desiredStart;
      nextEnd = desiredEnd;
      needsReload = true;
    }
  } else {
    nextStart = desiredStart;
    nextEnd = desiredEnd;
    needsReload = true;
  }

  return AgendaWindowHydrationPlan(
    rangeStart: nextStart,
    rangeEnd: nextEnd,
    needsReload: needsReload,
    alreadyFullyCovered: false,
  );
}
