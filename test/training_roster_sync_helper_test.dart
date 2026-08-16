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
}
