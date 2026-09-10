import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/admin_player_session_item.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/services/wearable_devices_repository.dart';

class _HangingWearable extends WearableDevicesRepository {
  @override
  Future<bool> hasAnyConnected(String uid, String playerId) {
    return Completer<bool>().future;
  }
}

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

  group('playerHasAssignedTeamKit / loadFlags', () {
    test('detects a roster tracker without a full team scan', () {
      final player = Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        keyMember: 'mohamed-player',
        userID: 'mohamed-uid',
      );
      final teams = [
        Team(
          keyTeam: 't1',
          isGrinta: true,
          grintaPlayers: [
            GrintaPlayer(playerId: 'mohamed-player', trackers: ['trk-1']),
          ],
        ),
      ];
      expect(
        playerHasAssignedTeamKit(player: player, teams: teams),
        isTrue,
      );
    });

    test('returns team-kit flags without waiting on hung wearables', () async {
      final player = Player(
        firstName: 'Mohamed-Amine',
        lastName: 'ABDESSAMAD',
        keyMember: 'mohamed-player',
        userID: 'mohamed-uid',
      );
      final service = AdminPlayerSensorService(
        timeout: const Duration(milliseconds: 40),
        loadGrintaTeams: (_) async => [
          Team(
            keyTeam: 't1',
            isGrinta: true,
            grintaPlayers: [
              GrintaPlayer(playerId: 'mohamed-player', trackers: ['trk-1']),
            ],
          ),
        ],
        wearableRepository: _HangingWearable(),
      );

      final flags = await service.loadFlags(player).timeout(
            const Duration(seconds: 2),
          );
      expect(flags.hasTeamKitSensor, isTrue);
      expect(flags.hasConnectedDevices, isFalse);
    });

    test('times out hung team lookups instead of hanging forever', () async {
      final service = AdminPlayerSensorService(
        timeout: const Duration(milliseconds: 30),
        loadGrintaTeams: (_) => Completer<List<Team>>().future,
        wearableRepository: _HangingWearable(),
      );
      final flags = await service.loadFlags(
        Player(keyMember: 'p1', userID: 'u1'),
      ).timeout(const Duration(seconds: 2));
      expect(flags.hasAny, isFalse);
    });
  });
}
