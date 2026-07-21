import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/staff_session_access.dart';

void main() {
  group('isRosterStaffOnTeam', () {
    Player player({required String id}) {
      return Player(keyMember: id);
    }

    Team teamWith({
      required String memberId,
      int? fonction,
      List<int> positions = const <int>[],
    }) {
      return Team(
        keyTeam: 'TEAM1',
        grintaPlayers: <GrintaPlayer>[
          GrintaPlayer(
            playerId: memberId,
            positions: positions,
            fonction: fonction,
          ),
        ],
      );
    }

    test('true when member has explicit staff fonction', () {
      final Team team = teamWith(
        memberId: 'm1',
        fonction: positionCodeEducator,
      );
      expect(isRosterStaffOnTeam(team, player(id: 'm1')), isTrue);
    });

    test('false when member is a field player', () {
      final Team team = teamWith(
        memberId: 'm1',
        positions: const <int>[10],
      );
      expect(isRosterStaffOnTeam(team, player(id: 'm1')), isFalse);
    });

    test('false when member is not on roster', () {
      final Team team = teamWith(
        memberId: 'other',
        fonction: positionCodeExecutive,
      );
      expect(isRosterStaffOnTeam(team, player(id: 'm1')), isFalse);
    });

    test('true for medical staff via positions code 24', () {
      final Team team = teamWith(
        memberId: 'm1',
        positions: const <int>[positionCodeMedical],
      );
      expect(isRosterStaffOnTeam(team, player(id: 'm1')), isTrue);
    });
  });
}
