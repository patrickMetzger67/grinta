import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/util/team_stats_goals_detail_helper.dart';

void main() {
  Match homeMatch() {
    return Match(
      id: 'm1',
      team1: 'A.S. ERSTEIN',
      team2: 'RACING HOLTZWIR',
      affiliationTeam1: 'aff-erstein',
      affiliationTeam2: 'aff-racing',
      teams: const ['team-erstein'],
      teamID: 'team-erstein',
      isOwnClub: true,
      isMatchPlayed: true,
      homeScore: 2,
      outSideScore: 1,
      timestamp: Timestamp.fromDate(DateTime(2025, 9, 1, 15)),
    );
  }

  Highlights goalAt({
    required String affiliation,
    required int minute,
    int extraTime = 0,
    String? playerId,
    String? playerName,
    int? playerNumber,
  }) {
    return Highlights(
      matchCalendarId: 'm1',
      teamId: 'team-erstein',
      minute: minute,
      extraTime: extraTime,
      actionType: ActionType.goal,
      value: Goal(
        affiliationTeam: affiliation,
        playerId: playerId,
        playerName: playerName,
      )..playerNumber = playerNumber,
    );
  }

  group('teamGoalDetailsFromHighlights', () {
    test('keeps scored goals for our side and sorts by minute', () {
      final match = homeMatch();
      final details = teamGoalDetailsFromHighlights(
        match: match,
        highlights: [
          goalAt(
            affiliation: 'aff-erstein',
            minute: 67,
            playerId: 'p2',
            playerName: 'Martin',
          ),
          goalAt(
            affiliation: 'aff-racing',
            minute: 12,
            playerName: 'Opponent',
            playerNumber: 9,
          ),
          goalAt(
            affiliation: 'aff-erstein',
            minute: 10,
            playerId: 'p1',
            playerName: 'Dupont',
          ),
        ],
        kind: TeamStatsGoalBarKind.scored,
        teamId: 'team-erstein',
        clubAffiliation: 'aff-erstein',
      );

      expect(details, hasLength(2));
      expect(details[0].minute, 10);
      expect(details[0].scorerLabel(unknownLabel: '?'), 'Dupont');
      expect(details[1].minute, 67);
      expect(details[1].matchLabel(), 'A.S. ERSTEIN 2-1 RACING HOLTZWIR');
    });

    test('keeps conceded goals with opponent name/number fallback', () {
      final match = homeMatch();
      final details = teamGoalDetailsFromHighlights(
        match: match,
        highlights: [
          goalAt(
            affiliation: 'aff-racing',
            minute: 45,
            extraTime: 2,
            playerNumber: 11,
          ),
          goalAt(
            affiliation: 'aff-erstein',
            minute: 20,
            playerName: 'Ours',
          ),
        ],
        kind: TeamStatsGoalBarKind.conceded,
        teamId: 'team-erstein',
        clubAffiliation: 'aff-erstein',
      );

      expect(details, hasLength(1));
      expect(details.single.minuteLabel, "45'+2");
      expect(details.single.scorerLabel(unknownLabel: 'Unknown'), '#11');
    });

    test('uses unknown fallback when scorer fields are empty', () {
      final match = homeMatch();
      final details = teamGoalDetailsFromHighlights(
        match: match,
        highlights: [
          goalAt(affiliation: 'aff-racing', minute: 8),
        ],
        kind: TeamStatsGoalBarKind.conceded,
        teamId: 'team-erstein',
        clubAffiliation: 'aff-erstein',
      );

      expect(details, hasLength(1));
      expect(
        details.single.scorerLabel(unknownLabel: 'Unknown scorer'),
        'Unknown scorer',
      );
    });
  });

  group('sortTeamGoalDetails', () {
    test('orders by match date then minute', () {
      final earlier = Match(
        id: 'm-early',
        team1: 'A',
        team2: 'B',
        homeScore: 1,
        outSideScore: 0,
        timestamp: Timestamp.fromDate(DateTime(2025, 8, 1)),
      );
      final later = Match(
        id: 'm-late',
        team1: 'A',
        team2: 'C',
        homeScore: 0,
        outSideScore: 1,
        timestamp: Timestamp.fromDate(DateTime(2025, 9, 1)),
      );
      final goal = Goal(affiliationTeam: 'x', playerName: 'Z');

      final sorted = sortTeamGoalDetails([
        TeamStatsGoalDetail(
          match: later,
          kind: TeamStatsGoalBarKind.scored,
          minute: 5,
          extraTime: 0,
          goal: goal,
        ),
        TeamStatsGoalDetail(
          match: earlier,
          kind: TeamStatsGoalBarKind.scored,
          minute: 80,
          extraTime: 0,
          goal: goal,
        ),
        TeamStatsGoalDetail(
          match: earlier,
          kind: TeamStatsGoalBarKind.scored,
          minute: 12,
          extraTime: 0,
          goal: goal,
        ),
      ]);

      expect(sorted.map((g) => g.minute).toList(), [12, 80, 5]);
    });
  });

  group('aggregateTeamGoalScorers', () {
    TeamStatsGoalDetail detail({
      String? playerId,
      String? playerName,
      int? playerNumber,
    }) {
      return TeamStatsGoalDetail(
        match: homeMatch(),
        kind: TeamStatsGoalBarKind.scored,
        minute: 10,
        extraTime: 0,
        goal: Goal(
          affiliationTeam: 'aff-erstein',
          playerId: playerId,
          playerName: playerName,
        )..playerNumber = playerNumber,
      );
    }

    test('aggregates by playerId and sorts by goal count descending', () {
      final ranks = aggregateTeamGoalScorers(
        [
          detail(playerId: 'p1', playerName: 'Alexandre DELEAU'),
          detail(playerId: 'p2', playerName: 'Vincent DESTENAY'),
          detail(playerId: 'p1', playerName: 'Alexandre DELEAU'),
          detail(playerId: 'p1', playerName: 'A. DELEAU'),
          detail(playerId: 'p3', playerName: 'Ludovic ZINCK'),
          detail(playerId: 'p2', playerName: 'Vincent DESTENAY'),
        ],
        unknownLabel: 'Unknown',
      );

      expect(ranks.map((r) => r.goalCount).toList(), [3, 2, 1]);
      expect(ranks[0].displayName, 'Alexandre DELEAU');
      expect(ranks[0].identityKey, 'id:p1');
      expect(ranks[1].displayName, 'Vincent DESTENAY');
      expect(ranks[2].displayName, 'Ludovic ZINCK');
    });

    test('falls back to display name when playerId is missing', () {
      final ranks = aggregateTeamGoalScorers(
        [
          detail(playerName: 'Dupont'),
          detail(playerName: 'dupont'),
          detail(playerName: 'Martin'),
          detail(playerNumber: 9),
        ],
        unknownLabel: 'Unknown',
      );

      expect(ranks, hasLength(3));
      expect(ranks[0].goalCount, 2);
      expect(ranks[0].displayName.toLowerCase(), 'dupont');
      expect(ranks[0].identityKey, 'name:dupont');
      expect(ranks.map((r) => r.goalCount).toList(), [2, 1, 1]);
    });

    test('merges unknown scorers under the unknown label', () {
      final ranks = aggregateTeamGoalScorers(
        [
          detail(),
          detail(),
          detail(playerName: 'Only Name'),
        ],
        unknownLabel: 'Unknown scorer',
      );

      expect(ranks, hasLength(2));
      expect(ranks[0].displayName, 'Unknown scorer');
      expect(ranks[0].goalCount, 2);
      expect(ranks[1].displayName, 'Only Name');
      expect(ranks[1].goalCount, 1);
    });
  });
}
