import 'package:flutter/material.dart';

/// Shared Semaine / Mois / Personnalisé for Dashboard and Analyse charge.
enum CoachFilterPeriod {
  week,
  month,
  custom,
}

/// Calendar-aligned date windows so both screens show the same data.
abstract final class CoachFilterPeriodRange {
  /// Inclusive start/end calendar days (UI + Analyse charge queries after +1 day).
  static DateTimeRange inclusive({
    required CoachFilterPeriod period,
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final DateTime n = now ?? DateTime.now();
    final DateTime today = DateTime(n.year, n.month, n.day);

    switch (period) {
      case CoachFilterPeriod.week:
        final DateTime start =
            today.subtract(Duration(days: today.weekday - 1));
        final DateTime end = start.add(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case CoachFilterPeriod.month:
        final DateTime start = DateTime(today.year, today.month, 1);
        final DateTime end = DateTime(today.year, today.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case CoachFilterPeriod.custom:
        final DateTimeRange range = customRange ??
            DateTimeRange(
              start: DateTime(today.year, today.month, 1),
              end: today,
            );
        return DateTimeRange(
          start: DateTime(
            range.start.year,
            range.start.month,
            range.start.day,
          ),
          end: DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
          ),
        );
    }
  }

  /// End-exclusive range for Dashboard activity filters / Firestore queries.
  static DateTimeRange queryExclusive({
    required CoachFilterPeriod period,
    DateTimeRange? customRange,
    DateTime? now,
  }) {
    final DateTimeRange range = inclusive(
      period: period,
      customRange: customRange,
      now: now,
    );
    return DateTimeRange(
      start: range.start,
      end: DateTime(
        range.end.year,
        range.end.month,
        range.end.day + 1,
      ),
    );
  }
}
