import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';

void main() {
  group('statsForMatch assists', () {
    test('counts decisive passer from Goal highlight', () {
      final match = models.Match(id: 'm1');
      final highlights = [
        Highlights(
          matchCalendarId: 'm1',
          teamId: 't1',
          minute: 22,
          actionType: ActionType.goal,
          value: Goal(
            affiliationTeam: 'aff-1',
            goalType: GoalType.normal,
            playerId: 'scorer-1',
            decisivePasserPlayerId: 'assister-1',
          ),
        ),
        Highlights(
          matchCalendarId: 'm1',
          teamId: 't1',
          minute: 55,
          actionType: ActionType.goal,
          value: Goal(
            affiliationTeam: 'aff-1',
            goalType: GoalType.normal,
            playerId: 'scorer-1',
          ),
        ),
      ];

      final stats = statsForMatch(
        match: match,
        compo: null,
        highlights: highlights,
      );

      expect(stats['scorer-1']?.goals, 2);
      expect(stats['scorer-1']?.assists, 0);
      expect(stats['assister-1']?.assists, 1);
      expect(stats['assister-1']?.goals, 0);
    });

    test('counts assist even when scorer id is missing', () {
      final match = models.Match(id: 'm1');
      final highlights = [
        Highlights(
          matchCalendarId: 'm1',
          teamId: 't1',
          minute: 10,
          actionType: ActionType.goal,
          value: Goal(
            affiliationTeam: 'aff-1',
            goalType: GoalType.normal,
            decisivePasserPlayerId: 'assister-only',
          ),
        ),
      ];

      final stats = statsForMatch(
        match: match,
        compo: null,
        highlights: highlights,
      );

      expect(stats['assister-only']?.assists, 1);
      expect(stats.containsKey(''), isFalse);
    });
  });

  group('statsForMatchFromMatchStats assists', () {
    test('counts incomingPlayer as assist on goal highlights', () {
      final match = models.Match(id: 'm1');
      final matchStats = MatchStats(
        titulars: [
          MatchStatPlayer(team: 'AS Test', player: 'Dupont Jean', shirt: '9'),
          MatchStatPlayer(team: 'AS Test', player: 'Martin Paul', shirt: '10'),
        ],
        substitutes: const [],
        highlights: [
          MatchStatHighLight(
            team: 'AS Test',
            player: 'Dupont Jean',
            incomingPlayer: 'Martin Paul',
            time: 30,
            type: 'goal',
          ),
        ],
      );

      final stats = statsForMatchFromMatchStats(
        match: match,
        matchStats: matchStats,
        opponentTeamName: 'AS Test',
      );

      final scorerKey = normalizeMatchStatPlayerKey('Dupont Jean');
      final assisterKey = normalizeMatchStatPlayerKey('Martin Paul');

      expect(stats[scorerKey]?.goals, 1);
      expect(stats[assisterKey]?.assists, 1);
    });
  });
}
