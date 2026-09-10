import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/admin_player_session_item.dart';

void main() {
  group('AdminPlayerSensorFlags', () {
    test('none has no indicators', () {
      expect(AdminPlayerSensorFlags.none.hasAny, isFalse);
      expect(AdminPlayerSensorFlags.none.hasTeamKitSensor, isFalse);
      expect(AdminPlayerSensorFlags.none.hasConnectedDevices, isFalse);
    });

    test('hasAny is true when either flag is set', () {
      expect(
        const AdminPlayerSensorFlags(
          hasTeamKitSensor: true,
          hasConnectedDevices: false,
        ).hasAny,
        isTrue,
      );
      expect(
        const AdminPlayerSensorFlags(
          hasTeamKitSensor: false,
          hasConnectedDevices: true,
        ).hasAny,
        isTrue,
      );
    });
  });

  group('AdminPlayerSessionItem sort', () {
    test('descending by sessionDate', () {
      final older = AdminPlayerSessionItem(
        kind: AdminPlayerSessionKind.gps,
        sessionDate: DateTime(2025, 1, 1),
        eventId: 'a',
      );
      final newer = AdminPlayerSessionItem(
        kind: AdminPlayerSessionKind.polar,
        sessionDate: DateTime(2025, 6, 1),
        eventId: 'b',
      );
      final items = [older, newer]..sort(
          (a, b) => b.sessionDate.compareTo(a.sessionDate),
        );
      expect(items.first.eventId, 'b');
      expect(items.last.eventId, 'a');
    });
  });
}
