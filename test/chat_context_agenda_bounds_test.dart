import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/chat_context_service.dart';

void main() {
  group('resolveAgendaQueryRange', () {
    test('extends past seasonEnd when today is after season document end', () {
      // Season 2025-2026 ends Jun 30; user on Jul 6 still sees Jul events on agenda.
      final range = ChatContextService.resolveAgendaQueryRange(
        seasonStart: DateTime(2025, 7, 1),
        seasonEnd: DateTime(2026, 6, 30),
        today: DateTime(2026, 7, 6),
      );

      expect(range.start, DateTime(2025, 7, 1));
      expect(range.end.isAfter(DateTime(2026, 7, 3)), isTrue);
      expect(range.end.isAfter(DateTime(2026, 6, 30, 23, 59, 59)), isTrue);
    });

    test('includes last week when today is Monday Jul 6 2026', () {
      final today = DateTime(2026, 7, 6);
      final range = ChatContextService.resolveAgendaQueryRange(
        seasonStart: DateTime(2026, 7, 1),
        seasonEnd: DateTime(2027, 6, 30),
        today: today,
      );

      final lastWeekStart = DateTime(2026, 6, 29);
      final lastWeekEnd = DateTime(2026, 7, 5);

      expect(range.start.isBefore(lastWeekStart) || range.start == lastWeekStart,
          isTrue);
      expect(range.end.isAfter(lastWeekEnd), isTrue);
    });

    test('past anchor extends before last week even when season starts mid-year', () {
      final today = DateTime(2026, 7, 6);
      final range = ChatContextService.resolveAgendaQueryRange(
        seasonStart: DateTime(2026, 7, 1),
        seasonEnd: DateTime(2027, 6, 30),
        today: today,
      );

      expect(range.start.isBefore(DateTime(2026, 6, 29)), isTrue);
    });
  });

  group('last week boundaries', () {
    test('Jul 6 2026 → last week Jun 29 to Jul 5', () {
      final today = DateUtils.dateOnly(DateTime(2026, 7, 6));
      final weekStart = _startOfWeek(today);
      final lastWeekStart = weekStart.subtract(const Duration(days: 7));
      final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));

      expect(weekStart, DateTime(2026, 7, 6));
      expect(lastWeekStart, DateTime(2026, 6, 29));
      expect(lastWeekEnd, DateTime(2026, 7, 5));
    });
  });
}

DateTime _startOfWeek(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return local.subtract(Duration(days: local.weekday - DateTime.monday));
}
