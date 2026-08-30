import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/services/session_personal_data_service.dart';
import 'package:grinta/util/match_usb_sync_window.dart';

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
    test('finished match uses lead 15 + slot + trail 60 for individual live GPS',
        () {
      final kickOff = DateTime(2026, 8, 1, 15);
      final item = AgendaItem(
        id: 'm1',
        startAt: kickOff,
        endAt: kickOff.add(const Duration(minutes: 90)),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: false, duration: 90),
        withTracker: false,
      );
      // Slot end = kickOff + 90 + 15 half-time = 16:45; +60 trail = 17:45.
      final window = SessionPersonalDataService.resolveWindow(
        item: item,
        now: kickOff.add(const Duration(hours: 4)),
      );
      expect(
        window.start,
        kickOff.subtract(const Duration(minutes: kPersonalMatchGpsLeadMinutes)),
      );
      expect(
        window.stop,
        kickOff.add(
          Duration(
            minutes: 90 +
                kMatchUsbSyncHalftimeBreakMinutes +
                kPersonalMatchGpsTrailMinutes,
          ),
        ),
      );
    });

    test('in-progress match caps stop at now but keeps lead-in', () {
      final kickOff = DateTime(2026, 8, 1, 15);
      final now = kickOff.add(const Duration(minutes: 30));
      final item = AgendaItem(
        id: 'm1',
        startAt: kickOff,
        endAt: kickOff.add(const Duration(minutes: 90)),
        title: 'Match',
        type: AgendaItemType.match,
        match: models.Match(withTracker: false, duration: 90),
        withTracker: false,
      );
      final window = SessionPersonalDataService.resolveWindow(
        item: item,
        now: now,
      );
      expect(
        window.start,
        kickOff.subtract(const Duration(minutes: kPersonalMatchGpsLeadMinutes)),
      );
      expect(window.stop, now);
    });
  });
}
