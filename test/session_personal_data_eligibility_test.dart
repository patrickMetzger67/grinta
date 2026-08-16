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

  group('SessionPersonalDataService.resolveWindow', () {
    test('finished match includes half-time break (duration + 15)', () {
      final start = DateTime(2026, 8, 1, 15);
      final item = AgendaItem(
        id: 'm1',
        startAt: start,
        endAt: start.add(const Duration(minutes: 90)),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: false, duration: 90),
        withTracker: false,
      );
      final window = SessionPersonalDataService.resolveWindow(
        item: item,
        now: start.add(const Duration(hours: 3)),
      );
      expect(window.start, start);
      expect(window.stop, start.add(const Duration(minutes: 105)));
    });
  });
}
