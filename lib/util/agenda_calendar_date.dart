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
