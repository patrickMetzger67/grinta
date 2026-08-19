import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/util/training_roster_sync_helper.dart';

void main() {
  test('fieldPlayerIdsFromTeam excludes staff', () {
    final team = Team(
      keyTeam: 't1',
      isGrinta: true,
    )..grintaPlayers = <GrintaPlayer>[
        GrintaPlayer(playerId: 'p1', positions: <int>[1]),
        GrintaPlayer(playerId: 'coach1', positions: <int>[], fonction: 1),
      ]
      ..managers = <dynamic>['coach1'];

    final ids = fieldPlayerIdsFromTeam(team);
    expect(ids, <String>{'p1'});
  });

  test('syncPlayerTrainingWithRoster adds and removes', () {
    final current = <PlayerTraining>[
      PlayerTraining(playerId: 'keep', presenceType: PresenceType.present),
      PlayerTraining(playerId: 'gone', presenceType: PresenceType.excuse),
    ];

    final diff = syncPlayerTrainingWithRoster(
      current: current,
      rosterIds: <String>{'keep', 'new'},
    );

    expect(diff.added, 1);
    expect(diff.removed, 1);
    expect(
      diff.next.map((PlayerTraining p) => p.playerId).toSet(),
      <String>{'keep', 'new'},
    );
    // Existing presence preserved for kept players.
    expect(
      diff.next
          .firstWhere((PlayerTraining p) => p.playerId == 'keep')
          .presenceType,
      PresenceType.present,
    );
  });

  test('prunePlayerFromTrainingGroups removes id', () {
    final groups = <TrainingGroup>[
      TrainingGroup(id: 'g1', groupName: 'A', players: <String>['a', 'b']),
    ];
    final next = prunePlayerFromTrainingGroups(groups: groups, playerId: 'a');
    expect(next.single.players, <String>['b']);
  });

  test('assignTrackerOnPlayerTraining sets GPS and frees it from the other row', () {
    final current = <PlayerTraining>[
      PlayerTraining(playerId: 'p1', presenceType: PresenceType.present)
        ..deviceId = 'old'
        ..customName = '1',
      PlayerTraining(playerId: 'p2', presenceType: PresenceType.present)
        ..deviceId = 'gps-7'
        ..customName = '7',
    ];

    final result = assignTrackerOnPlayerTraining(
      current: current,
      playerId: 'p1',
      assignment: const TrainingTrackerAssignment(
        deviceOwnerDocId: 'gps-7',
        customName: '7',
      ),
    );

    expect(result.changed, isTrue);
    expect(result.addedPlayer, isFalse);
    expect(
      result.next.firstWhere((PlayerTraining p) => p.playerId == 'p1').deviceId,
      'gps-7',
    );
    expect(
      result.next.firstWhere((PlayerTraining p) => p.playerId == 'p2').deviceId,
      '',
    );
  });

  test('assignTrackerOnPlayerTraining adds a missing player', () {
    final result = assignTrackerOnPlayerTraining(
      current: <PlayerTraining>[],
      playerId: 'p1',
      assignment: const TrainingTrackerAssignment(
        deviceOwnerDocId: 'gps-3',
        customName: '3',
      ),
    );

    expect(result.addedPlayer, isTrue);
    expect(result.next.single.playerId, 'p1');
    expect(result.next.single.deviceId, 'gps-3');
    expect(result.next.single.customName, '3');
  });

  test('clearTrackerOnPlayerTraining removes only that GPS', () {
    final current = <PlayerTraining>[
      PlayerTraining(playerId: 'p1', presenceType: PresenceType.present)
        ..deviceId = 'gps-7'
        ..customName = '7',
    ];

    final result = clearTrackerOnPlayerTraining(
      current: current,
      playerId: 'p1',
      deviceOwnerDocId: 'gps-7',
    );

    expect(result.changed, isTrue);
    expect(result.next.single.deviceId, '');
    expect(result.next.single.customName, '');
  });

  test('alignTrackersWithRoster applies, clears, and keeps GPS unique', () {
    final current = <PlayerTraining>[
      PlayerTraining(playerId: 'keep', presenceType: PresenceType.present)
        ..deviceId = 'stale'
        ..customName = '9',
      PlayerTraining(playerId: 'clear', presenceType: PresenceType.present)
        ..deviceId = 'gps-2'
        ..customName = '2',
    ];

    final result = alignTrackersWithRoster(
      current: current,
      rosterTrackers: <String, TrainingTrackerAssignment?>{
        'keep': const TrainingTrackerAssignment(
          deviceOwnerDocId: 'gps-1',
          customName: '1',
        ),
        'clear': null,
      },
    );

    expect(result.changed, isTrue);
    expect(
      result.next.firstWhere((PlayerTraining p) => p.playerId == 'keep').deviceId,
      'gps-1',
    );
    expect(
      result.next.firstWhere((PlayerTraining p) => p.playerId == 'clear').deviceId,
      '',
    );
  });
}
