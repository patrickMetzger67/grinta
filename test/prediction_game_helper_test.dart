import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/engagement.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/pred_game_day.dart';
import 'package:grinta/services/pred_game_day_service.dart';
import 'package:grinta/util/prediction_game_helper.dart';

void main() {
  final engagement = Engagement(
    competitionId: 'COMP1',
    group: 'A',
    stage: 'championnat',
    seasonId: 'S26',
    clubId: 'CLUB1',
    name: 'U18 R1',
  );

  Match datedMatch({
    required String id,
    required int day,
    required DateTime kickoff,
    bool played = false,
    String competitionID = 'COMP1',
    String poule = 'A',
    String stage = 'championnat',
  }) {
    return Match(
      id: id,
      day: day,
      dateCh:
          '${kickoff.day.toString().padLeft(2, '0')}/${kickoff.month.toString().padLeft(2, '0')}/${kickoff.year}',
      timeCh:
          '${kickoff.hour.toString().padLeft(2, '0')}:${kickoff.minute.toString().padLeft(2, '0')}',
      isMatchPlayed: played,
      competitionID: competitionID,
      poule: poule,
      stage: stage,
      team1: 'Home $id',
      team2: 'Away $id',
      timestamp: Timestamp.fromDate(kickoff),
    );
  }

  group('predGameDayDocumentId', () {
    test('joins trimmed team, engagement and day', () {
      expect(
        predGameDayDocumentId(
          teamId: ' T1 ',
          engagementId: ' E1 ',
          day: 4,
        ),
        'T1_E1_4',
      );
    });
  });

  group('predictionGameEngagementLabel', () {
    test('prefers engagement name', () {
      expect(predictionGameEngagementLabel(engagement), 'U18 R1');
    });

    test('falls back to competition / group / stage', () {
      expect(
        predictionGameEngagementLabel(
          Engagement(competitionId: 'COMP1', group: 'A', stage: '1'),
        ),
        'COMP1 · A · 1',
      );
    });
  });

  group('matchBelongsToPredictionEngagement', () {
    test('filters on competition, poule and stage', () {
      final match = datedMatch(
        id: 'm1',
        day: 1,
        kickoff: DateTime(2026, 9, 6, 15),
      );
      expect(matchBelongsToPredictionEngagement(match, engagement), isTrue);
      expect(
        matchBelongsToPredictionEngagement(
          datedMatch(
            id: 'm2',
            day: 1,
            kickoff: DateTime(2026, 9, 6, 15),
            poule: 'B',
          ),
          engagement,
        ),
        isFalse,
      );
    });
  });

  group('selectNextPredictionMatchday', () {
    final now = DateTime(2026, 9, 3, 8);

    test('picks the earliest still-open journée', () {
      final selection = selectNextPredictionMatchday(
        matches: [
          datedMatch(id: 'm1', day: 4, kickoff: DateTime(2026, 8, 30, 15)),
          datedMatch(id: 'm2', day: 5, kickoff: DateTime(2026, 9, 6, 15)),
          datedMatch(id: 'm3', day: 5, kickoff: DateTime(2026, 9, 6, 17)),
          datedMatch(id: 'm4', day: 6, kickoff: DateTime(2026, 9, 13, 15)),
        ],
        engagement: engagement,
        now: now,
      );

      expect(selection, isNotNull);
      expect(selection!.day, 5);
      expect(selection.matches.map((m) => m.id), ['m2', 'm3']);
      expect(selection.firstKickoff, DateTime(2026, 9, 6, 15));
      expect(selection.closesAt, DateTime(2026, 9, 6, 3));
    });

    test('skips played matches and days whose deadline has passed', () {
      final selection = selectNextPredictionMatchday(
        matches: [
          datedMatch(
            id: 'played',
            day: 5,
            kickoff: DateTime(2026, 9, 6, 15),
            played: true,
          ),
          datedMatch(
            id: 'locked',
            day: 5,
            kickoff: DateTime(2026, 9, 3, 10),
          ),
          datedMatch(id: 'next', day: 6, kickoff: DateTime(2026, 9, 13, 15)),
        ],
        engagement: engagement,
        now: now,
      );

      expect(selection!.day, 6);
      expect(selection.matches.single.id, 'next');
    });
  });

  group('PredGameDay', () {
    test('serializes fixtures and entries', () {
      final contest = PredGameDay(
        id: 'T1_E1_5',
        teamId: 'T1',
        engagementId: 'E1',
        competitionId: 'COMP1',
        day: 5,
        matchIds: const ['m2'],
        fixtures: [
          PredGameDayFixture(
            matchId: 'm2',
            team1: 'Home',
            team2: 'Away',
            kickoffAt: DateTime(2026, 9, 6, 15),
            day: 5,
          ),
        ],
        firstKickoffAt: DateTime(2026, 9, 6, 15),
        closesAt: DateTime(2026, 9, 6, 3),
        entries: {
          'p1': PredGameDayEntry(
            userId: 'u1',
            playerId: 'p1',
            picks: const {'m2': predGameDayPickHome},
            submittedAt: DateTime(2026, 9, 3, 12),
          ),
        },
      );

      final parsed = PredGameDay.fromMap(contest.toMap(), id: contest.id);
      expect(parsed.teamId, 'T1');
      expect(parsed.fixtures.single.team1, 'Home');
      expect(parsed.entries['p1']!.picks['m2'], predGameDayPickHome);
      expect(parsed.isOpenAt(DateTime(2026, 9, 5, 12)), isTrue);
      expect(parsed.isOpenAt(DateTime(2026, 9, 6, 4)), isFalse);
    });
  });

  group('PredGameDayService.pickPreferredContest', () {
    test('prefers the open contest with the soonest deadline', () {
      final open = PredGameDay(
        id: 'open',
        day: 5,
        closesAt: DateTime(2026, 9, 6, 3),
      );
      final later = PredGameDay(
        id: 'later',
        day: 6,
        closesAt: DateTime(2026, 9, 13, 3),
      );
      final closed = PredGameDay(
        id: 'closed',
        day: 4,
        closesAt: DateTime(2026, 8, 30, 3),
      );

      expect(
        PredGameDayService.pickPreferredContest(
          [later, closed, open],
          DateTime(2026, 9, 3, 8),
        )?.id,
        'open',
      );
    });

    test('falls back to the latest day when all are closed', () {
      expect(
        PredGameDayService.pickPreferredContest(
          [
            PredGameDay(id: 'd4', day: 4, closesAt: DateTime(2026, 8, 20)),
            PredGameDay(id: 'd5', day: 5, closesAt: DateTime(2026, 8, 27)),
          ],
          DateTime(2026, 9, 3, 8),
        )?.id,
        'd5',
      );
    });
  });

  group('isValidPredictionPick', () {
    test('accepts only 1, 2 and 3', () {
      expect(isValidPredictionPick(1), isTrue);
      expect(isValidPredictionPick(2), isTrue);
      expect(isValidPredictionPick(3), isTrue);
      expect(isValidPredictionPick(0), isFalse);
      expect(isValidPredictionPick(null), isFalse);
    });
  });
}
