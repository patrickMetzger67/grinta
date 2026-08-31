import 'package:flutter/material.dart';

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

/// Places [date]'s day-of-month onto [month], clamping when needed.
///
/// Example: date=31 Aug 2026, month=Sep 2026 → 30 Sep 2026.
DateTime clampDateToMonth(DateTime date, DateTime month) {
  final DateTime normalized = DateUtils.dateOnly(date);
  final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final int safeDay =
      normalized.day > daysInMonth ? daysInMonth : normalized.day;
  return DateTime(month.year, month.month, safeDay);
}

/// Advances [date] by full weeks, preserving the weekday.
DateTime addWeeksKeepingWeekday(DateTime date, int weeks) {
  return DateUtils.dateOnly(date).add(Duration(days: 7 * weeks));
}
