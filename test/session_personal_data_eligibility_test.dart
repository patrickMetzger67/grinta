import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/services/session_personal_data_service.dart';

void main() {
  group('SessionPersonalDataService.isEligibleAgendaItem', () {
    test('allows match without team tracker kit', () {
      final item = AgendaItem(
        id: 'm1',
        startAt: DateTime(2026, 8, 9, 15),
        endAt: DateTime(2026, 8, 9, 16, 30),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: false),
        withTracker: false,
      );
      expect(SessionPersonalDataService.isEligibleAgendaItem(item), isTrue);
    });

    test('blocks match with team tracker kit + owner', () {
      final item = AgendaItem(
        id: 'm1',
        startAt: DateTime(2026, 8, 9, 15),
        endAt: DateTime(2026, 8, 9, 16, 30),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: true, ownerId: 'owner1'),
        withTracker: true,
      );
      expect(SessionPersonalDataService.isEligibleAgendaItem(item), isFalse);
    });
  });

  group('SessionPersonalDataService.resolveMatchGpsWindow', () {
    test('uses 45 + 15 + 45 + 10 minutes from kick-off when finished', () {
      final kickOff = DateTime(2026, 8, 1, 15);
      final window = SessionPersonalDataService.resolveMatchGpsWindow(
        kickOff: kickOff,
        now: kickOff.add(const Duration(hours: 4)),
      );
      expect(window.start, kickOff);
      expect(
        window.stop,
        kickOff.add(
          const Duration(minutes: kPersonalMatchGpsTotalSpanMinutes),
        ),
      );
    });

    test('caps stop at now when match is still in progress', () {
      final kickOff = DateTime(2026, 8, 1, 15);
      final now = kickOff.add(const Duration(minutes: 30));
      final window = SessionPersonalDataService.resolveMatchGpsWindow(
        kickOff: kickOff,
        now: now,
      );
      expect(window.start, kickOff);
      expect(window.stop, now);
    });

    test('uses delayed kick-off when provided via resolveWindow', () {
      final scheduledKickOff = DateTime(2026, 8, 1, 15);
      final actualKickOff = DateTime(2026, 8, 1, 15, 20);
      final item = AgendaItem(
        id: 'm1',
        startAt: scheduledKickOff,
        endAt: scheduledKickOff.add(const Duration(minutes: 90)),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: false, duration: 90),
        withTracker: false,
      );
      final window = SessionPersonalDataService.resolveWindow(
        item: item,
        matchKickOff: actualKickOff,
        now: actualKickOff.add(const Duration(hours: 3)),
      );
      expect(window.start, actualKickOff);
      expect(
        window.stop,
        actualKickOff.add(
          const Duration(minutes: kPersonalMatchGpsTotalSpanMinutes),
        ),
      );
    });
  });
}
