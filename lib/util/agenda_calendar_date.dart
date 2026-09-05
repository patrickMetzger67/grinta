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

/// Page index for [month] relative to [anchorMonth] at [initialPage].
///
/// Used so week→month / date-picker jumps land on the focused month instead
/// of leaving the PageController on the initial (today) page.
int agendaMonthPageIndex({
  required DateTime anchorMonth,
  required DateTime month,
  required int initialPage,
}) {
  final DateTime from = DateTime(anchorMonth.year, anchorMonth.month, 1);
  final DateTime to = DateTime(month.year, month.month, 1);
  final int diff =
      (to.year - from.year) * 12 + to.month - from.month;
  return initialPage + diff;
}

/// Calendar month shown at [page] for a pager anchored on [anchorMonth].
DateTime agendaMonthForPageIndex({
  required DateTime anchorMonth,
  required int page,
  required int initialPage,
}) {
  final int offset = page - initialPage;
  return DateTime(anchorMonth.year, anchorMonth.month + offset, 1);
}

/// Focus after picking [pickedDate] (e.g. in week mode) then opening month.
///
/// The month pager must sync to this month — not stay on the initial today
/// page — otherwise the grid still shows August while selection is December.
AgendaMonthSwipeFocus focusAfterDatePickForMonth({
  required DateTime pickedDate,
}) {
  final DateTime day = DateUtils.dateOnly(pickedDate);
  return AgendaMonthSwipeFocus(
    displayedMonth: DateTime(day.year, day.month, 1),
    selectedDate: day,
    preferredDayOfMonth: day.day,
  );
}

/// Previous-month page derived from [displayedMonth], never from a stale
/// PageController index (e.g. still on August after a far date-picker jump).
int agendaAdjacentMonthPageFromFocus({
  required DateTime displayedMonth,
  required DateTime anchorMonth,
  required int initialPage,
  required int monthDelta,
}) {
  final DateTime target =
      DateTime(displayedMonth.year, displayedMonth.month + monthDelta, 1);
  return agendaMonthPageIndex(
    anchorMonth: anchorMonth,
    month: target,
    initialPage: initialPage,
  );
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

/// Calendar-day shift that uses date fields, not [Duration] (DST-safe).
DateTime addDaysKeepingDate(DateTime date, int days) {
  final DateTime normalized = DateUtils.dateOnly(date);
  return DateTime(normalized.year, normalized.month, normalized.day + days);
}

/// Advances [date] by full weeks, preserving the weekday.
DateTime addWeeksKeepingWeekday(DateTime date, int weeks) {
  return addDaysKeepingDate(date, 7 * weeks);
}

/// Period used by the agenda header chevrons (and matching swipes).
enum AgendaHeaderPeriod {
  /// No 7-day strip (unused by the current 3 icons).
  day,
  /// 7-day strip is visible — list/3-bar icon or week icon.
  week,
  month,
}

/// Maps the 3 header view icons to a chevron step.
///
/// The first icon (list / 3 horizontal bars) still paints a LUN–DIM week
/// strip under the date — same strip as the week icon. Chevrons must move
/// by a full week there, not by one day. Only the month grid steps by month.
AgendaHeaderPeriod agendaChevronPeriodForView({
  required bool listWithWeekStrip,
  required bool weekView,
  required bool monthView,
}) {
  if (monthView) return AgendaHeaderPeriod.month;
  if (listWithWeekStrip || weekView) return AgendaHeaderPeriod.week;
  return AgendaHeaderPeriod.day;
}

/// Focused date after one header chevron (or equivalent swipe).
///
/// * [AgendaHeaderPeriod.day] — ±1 calendar day (no week strip)
/// * [AgendaHeaderPeriod.week] — ±7 days (same weekday), never ±1
/// * [AgendaHeaderPeriod.month] — ±1 month, keeping day-of-month when possible
DateTime agendaHeaderChevronDate({
  required DateTime focusedDate,
  required AgendaHeaderPeriod period,
  required int direction,
}) {
  switch (period) {
    case AgendaHeaderPeriod.day:
      return addDaysKeepingDate(focusedDate, direction);
    case AgendaHeaderPeriod.week:
      return addWeeksKeepingWeekday(focusedDate, direction);
    case AgendaHeaderPeriod.month:
      return addMonthsKeepingDay(focusedDate, direction);
  }
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

/// Focus after a month PageView landing (preferred day is never overwritten).
@immutable
class AgendaMonthSwipeFocus {
  const AgendaMonthSwipeFocus({
    required this.displayedMonth,
    required this.selectedDate,
    required this.preferredDayOfMonth,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final int preferredDayOfMonth;
}

/// Applies one month-pager landing without mutating [preferredDayOfMonth].
///
/// Used by the UI and by burst-swipe regression tests so Aug 31 → … → Aug
/// still restores day 31 even when intermediate months clamp to 30.
AgendaMonthSwipeFocus applyMonthPageLanding({
  required DateTime targetMonth,
  required int preferredDayOfMonth,
}) {
  final DateTime month = DateTime(targetMonth.year, targetMonth.month, 1);
  return AgendaMonthSwipeFocus(
    displayedMonth: month,
    selectedDate: monthPageSelectedDate(
      targetMonth: month,
      preferredDayOfMonth: preferredDayOfMonth,
    ),
    preferredDayOfMonth: preferredDayOfMonth,
  );
}

/// Pure burst simulator: rapid month landings + deferred latest-wins hydrate.
///
/// Mimics PageView `onPageChanged` storms where only the final settle may
/// hydrate; intermediate generations must be ignored.
class AgendaMonthSwipeBurstSimulator {
  AgendaMonthSwipeBurstSimulator({
    required DateTime initialMonth,
    required this.preferredDayOfMonth,
  })  : displayedMonth = DateTime(initialMonth.year, initialMonth.month, 1),
        selectedDate = monthPageSelectedDate(
          targetMonth: initialMonth,
          preferredDayOfMonth: preferredDayOfMonth,
        );

  int preferredDayOfMonth;
  DateTime displayedMonth;
  DateTime selectedDate;

  final LatestWinsGate hydrationGate = LatestWinsGate();
  LatestWinsToken? pendingHydrateToken;
  final List<int> appliedHydrationIds = <int>[];
  final List<int> ignoredStaleHydrationIds = <int>[];

  /// One PageView landing: update focus immediately, bump latest-wins.
  LatestWinsToken landOnMonth(DateTime targetMonth) {
    final AgendaMonthSwipeFocus focus = applyMonthPageLanding(
      targetMonth: targetMonth,
      preferredDayOfMonth: preferredDayOfMonth,
    );
    displayedMonth = focus.displayedMonth;
    selectedDate = focus.selectedDate;
    // Preferred day stays sticky across clamps (do not take selectedDate.day).
    preferredDayOfMonth = focus.preferredDayOfMonth;

    final LatestWinsToken token = hydrationGate.begin();
    pendingHydrateToken = token;
    return token;
  }

  /// Attempts to apply a deferred hydrate for [token] (no-op if superseded).
  bool tryApplyHydration(LatestWinsToken token) {
    if (!token.isCurrent) {
      ignoredStaleHydrationIds.add(token.id);
      return false;
    }
    appliedHydrationIds.add(token.id);
    return true;
  }

  /// Runs a burst of landings then hydrates every token in order (stale drop).
  void runBurstAndFlush(List<DateTime> months) {
    final List<LatestWinsToken> tokens = <LatestWinsToken>[
      for (final DateTime m in months) landOnMonth(m),
    ];
    for (final LatestWinsToken token in tokens) {
      tryApplyHydration(token);
    }
  }
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
