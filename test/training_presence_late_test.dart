import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/team_players/training_team_players_loader.dart';
import 'package:grinta/util/training_finish_helper.dart';

void main() {
  group('TrainingPresenceCounts', () {
    test('attended includes late as present', () {
      const counts = TrainingPresenceCounts(
        present: 17,
        late: 1,
        excused: 2,
        absent: 0,
      );
      expect(counts.attended, 18);
      expect(counts.total, 20);
    });
  });

  group('TrainingTeamPlayersLoader.countPresence', () {
    test('counts late separately and rolls it into attended', () {
      final loader = TrainingTeamPlayersLoader();
      final rows = [
        _row(PresenceType.present),
        _row(PresenceType.present),
        _row(PresenceType.late),
        _row(PresenceType.excuse),
        _row(PresenceType.absent),
        _row(null),
      ];

      final counts = loader.countPresence(rows);
      expect(counts.present, 3); // 2 explicit + 1 null default
      expect(counts.late, 1);
      expect(counts.excused, 1);
      expect(counts.absent, 1);
      expect(counts.attended, 4);
    });
  });

  group('isPresentOrDefaultPresence', () {
    test('treats late as attended', () {
      expect(isPresentOrDefaultPresence(null), isTrue);
      expect(isPresentOrDefaultPresence(PresenceType.present), isTrue);
      expect(isPresentOrDefaultPresence(PresenceType.late), isTrue);
      expect(isPresentOrDefaultPresence(PresenceType.absent), isFalse);
      expect(isPresentOrDefaultPresence(PresenceType.excuse), isFalse);
    });
  });
}

TrainingPlayerRowVm _row(PresenceType? presence) {
  return TrainingPlayerRowVm(
    player: Player()..firstName = 'Test',
    playerTraining: PlayerTraining()..presenceType = presence,
  );
}
