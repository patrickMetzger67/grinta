import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/agenda_calendar_date.dart';

void main() {
  group('LatestWinsGate', () {
    test('only the newest token stays current (switchMap)', () {
      final gate = LatestWinsGate();
      final first = gate.begin();
      expect(first.isCurrent, isTrue);

      final second = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isTrue);

      final third = gate.begin();
      expect(first.isCurrent, isFalse);
      expect(second.isCurrent, isFalse);
      expect(third.isCurrent, isTrue);
    });
  });

  group('planAgendaWindowHydration', () {
    final aug = DateTime(2026, 8, 1);
    final julStart = DateTime(2026, 7, 1);
    final sepEnd = DateTime(2026, 9, 30);

    test('already covered window needs no reload', () {
      final plan = planAgendaWindowHydration(
        focusMonth: aug,
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isTrue);
      expect(plan.needsReload, isFalse);
      expect(plan.rangeStart, julStart);
      expect(plan.rangeEnd, sepEnd);
    });

    test('uncovered month replaces range with M±1 window', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 12, 1),
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, DateTime(2026, 11, 1));
      expect(plan.rangeEnd, DateTime(2027, 1, 31));
    });

    test('partial cover expands range without jumping focus', () {
      // Range covers Sep but not the full Sep±1 window (missing Oct).
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 9, 1),
        currentRangeStart: julStart,
        currentRangeEnd: sepEnd,
      );
      expect(plan.alreadyFullyCovered, isFalse);
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, julStart);
      expect(plan.rangeEnd, DateTime(2026, 10, 31));
    });

    test('oversized span collapses to focus M±1', () {
      final plan = planAgendaWindowHydration(
        focusMonth: DateTime(2026, 10, 1),
        currentRangeStart: DateTime(2026, 1, 1),
        currentRangeEnd: DateTime(2026, 10, 31),
        maxLoadedMonths: 4,
      );
      expect(plan.needsReload, isTrue);
      expect(plan.rangeStart, DateTime(2026, 9, 1));
      expect(plan.rangeEnd, DateTime(2026, 11, 30));
    });
  });
}
