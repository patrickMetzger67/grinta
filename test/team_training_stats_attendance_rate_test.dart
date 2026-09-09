import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/team_training_stats_service.dart';

void main() {
  group('playerTrainingAttendanceRate', () {
    test('returns null when nothing is marked', () {
      expect(
        playerTrainingAttendanceRate(presentCount: 0, absentCount: 0),
        isNull,
      );
    });

    test('present only is 100%', () {
      expect(
        playerTrainingAttendanceRate(presentCount: 4, absentCount: 0),
        100,
      );
    });

    test('classic present/absent split', () {
      expect(
        playerTrainingAttendanceRate(presentCount: 3, absentCount: 1),
        75,
      );
    });

    test('late counts as attended', () {
      expect(
        playerTrainingAttendanceRate(
          presentCount: 2,
          absentCount: 0,
          lateCount: 2,
        ),
        100,
      );
    });

    test('excused counts as absent and lowers the rate', () {
      // (2 present + 0 late) / (2 + 0 absent + 2 excused) = 50%
      expect(
        playerTrainingAttendanceRate(
          presentCount: 2,
          absentCount: 0,
          excusedCount: 2,
        ),
        50,
      );
    });

    test('late attended and excused absent together', () {
      // (1 present + 1 late) / (1 + 1 late + 1 absent + 1 excused) = 50%
      expect(
        playerTrainingAttendanceRate(
          presentCount: 1,
          absentCount: 1,
          excusedCount: 1,
          lateCount: 1,
        ),
        50,
      );
    });

    test('only excused yields 0%', () {
      expect(
        playerTrainingAttendanceRate(
          presentCount: 0,
          absentCount: 0,
          excusedCount: 3,
        ),
        0,
      );
    });

    test('only late yields 100%', () {
      expect(
        playerTrainingAttendanceRate(
          presentCount: 0,
          absentCount: 0,
          lateCount: 3,
        ),
        100,
      );
    });
  });

  group('TeamTrainingPlayerStats.attendedCount', () {
    test('includes late as present', () {
      const stats = TeamTrainingPlayerStats(
        playerId: 'p1',
        player: null,
        presentCount: 1,
        absentCount: 0,
        excusedCount: 0,
        lateCount: 2,
        attendanceRate: 100,
        trends: TeamTrainingPlayerTrends(),
      );
      expect(stats.attendedCount, 3);
    });
  });
}
