import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

void main() {
  group('monthPageSelectedDate / preferred day', () {
    test('Aug 31 → Sep keeps preferred 31 as Sep 30', () {
      final result = monthPageSelectedDate(
        targetMonth: DateTime(2026, 9, 1),
        preferredDayOfMonth: 31,
      );
      expect(result, DateTime(2026, 9, 30));
    });

    test('Sep 30 → Aug restores preferred 31 (not 30)', () {
      // After clamping on Sep, preferred day must still be 31 so back nav
      // returns to "today" (31 Aug) instead of drifting to 30 Aug.
      final result = monthPageSelectedDate(
        targetMonth: DateTime(2026, 8, 1),
        preferredDayOfMonth: 31,
      );
      expect(result, DateTime(2026, 8, 31));
    });

    test('preferred 15 stays stable across months', () {
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 9, 1),
          preferredDayOfMonth: 15,
        ),
        DateTime(2026, 9, 15),
      );
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 8, 1),
          preferredDayOfMonth: 15,
        ),
        DateTime(2026, 8, 15),
      );
    });

    test('Jan 31 → Feb non-leap clamps to 28, back restores 31', () {
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 2, 1),
          preferredDayOfMonth: 31,
        ),
        DateTime(2026, 2, 28),
      );
      expect(
        monthPageSelectedDate(
          targetMonth: DateTime(2026, 1, 1),
          preferredDayOfMonth: 31,
        ),
        DateTime(2026, 1, 31),
      );
    });
  });

  group('weekOverlapsMonth', () {
    test('week fully inside month overlaps', () {
      expect(weekOverlapsMonth(DateTime(2026, 8, 10), DateTime(2026, 8, 1)), isTrue);
    });

    test('week spanning Aug/Sep overlaps both months', () {
      final weekStart = DateTime(2026, 8, 31);
      expect(weekOverlapsMonth(weekStart, DateTime(2026, 8, 1)), isTrue);
      expect(weekOverlapsMonth(weekStart, DateTime(2026, 9, 1)), isTrue);
    });

    test('week in August does not overlap October', () {
      expect(
        weekOverlapsMonth(DateTime(2026, 8, 10), DateTime(2026, 10, 1)),
        isFalse,
      );
    });
  });

  group('LatestWinsGate', () {
    test('newer begin() makes previous token stale', () {
      final gate = LatestWinsGate();
      final first = gate.begin();
      expect(first.isCurrent, isTrue);

      final second = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isTrue);
    });
  });

  group('planAgendaWindowHydration', () {
    test('returns alreadyFullyCovered when M±1 is loaded', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 8, 1),
        currentRangeStart: DateTime(2026, 7, 1),
        currentRangeEnd: DateTime(2026, 9, 30),
      );
      expect(plan.alreadyFullyCovered, isTrue);
      expect(plan.needsReload, isFalse);
    });

    test('plans reload when focus month is outside range', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 11, 1),
        currentRangeStart: DateTime(2026, 7, 1),
        currentRangeEnd: DateTime(2026, 9, 30),
      );
      expect(plan.needsReload, isTrue);
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.rangeStart, DateTime(2026, 10, 1));
      expect(plan.rangeEnd, DateTime(2026, 12, 31));
    });
  });
}
