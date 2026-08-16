import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';

// Exercise the private day-key helpers via the same dateOnly + calendar-day
// arithmetic used by agenda month dots.
Map<int, List<AgendaItemType>> headerEventTypesByDayForTest(
  List<AgendaItem> items,
) {
  final result = <int, List<AgendaItemType>>{};
  for (final item in items) {
    DateTime day = DateUtils.dateOnly(item.startAt);
    final DateTime last = DateUtils.dateOnly(item.endAt);
    while (!day.isAfter(last)) {
      final int dayKey = day.millisecondsSinceEpoch;
      final List<AgendaItemType> types =
          result.putIfAbsent(dayKey, () => <AgendaItemType>[]);
      if (!types.contains(item.type)) {
        types.add(item.type);
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
  }
  return result;
}

void main() {
  test('month-dot day keys match DateUtils.dateOnly lookups', () {
    final start = DateTime(2026, 10, 17, 18, 30);
    final item = AgendaItem(
      id: 'm1',
      startAt: start,
      endAt: start.add(const Duration(minutes: 90)),
      title: 'Match',
      type: AgendaItemType.match,
    );

    final byDay = headerEventTypesByDayForTest([item]);
    final key = DateUtils.dateOnly(DateTime(2026, 10, 17)).millisecondsSinceEpoch;

    expect(byDay.containsKey(key), isTrue);
    expect(byDay[key], contains(AgendaItemType.match));
  });

  test('multi-day items mark each calendar day', () {
    final item = AgendaItem(
      id: 'camp',
      startAt: DateTime(2026, 10, 16, 9),
      endAt: DateTime(2026, 10, 18, 18),
      title: 'Camp',
      type: AgendaItemType.nonSport,
    );

    final byDay = headerEventTypesByDayForTest([item]);
    expect(
      byDay[DateUtils.dateOnly(DateTime(2026, 10, 16)).millisecondsSinceEpoch],
      contains(AgendaItemType.nonSport),
    );
    expect(
      byDay[DateUtils.dateOnly(DateTime(2026, 10, 17)).millisecondsSinceEpoch],
      contains(AgendaItemType.nonSport),
    );
    expect(
      byDay[DateUtils.dateOnly(DateTime(2026, 10, 18)).millisecondsSinceEpoch],
      contains(AgendaItemType.nonSport),
    );
  });
}
