import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/opponent_typical_team_chat_context.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';

void main() {
  group('OpponentTypicalTeamChatContext intent', () {
    test('detects équipe type phrasing', () {
      expect(
        OpponentTypicalTeamChatContext.detectsTypicalTeamIntent(
          "Peux-tu me donner l'équipe type de Geispolsheim ?",
        ),
        isTrue,
      );
    });

    test('detects composition adversaire phrasing', () {
      expect(
        OpponentTypicalTeamChatContext.detectsTypicalTeamIntent(
          'Composition probable de notre prochain adversaire',
        ),
        isTrue,
      );
    });

    test('ignores unrelated agenda questions', () {
      expect(
        OpponentTypicalTeamChatContext.detectsTypicalTeamIntent(
          'Quel est mon prochain match ?',
        ),
        isFalse,
      );
    });
  });

  group('OpponentTypicalTeamChatContext opponent matching', () {
    late AgendaOpponentCandidate geispolsheimCandidate;

    setUp(() {
      geispolsheimCandidate = AgendaOpponentCandidate(
        team: Team(name: 'Mon équipe', keyTeam: 'team-1'),
        match: Match(id: 'match-1', teamID: 'team-1'),
        opponentName: 'Geispolsheim',
        opponent: const TeamStatsOpponent(
          key: 'name:geispolsheim',
          displayName: 'Geispolsheim',
        ),
      );
    });

    test('finds opponent name embedded in message', () {
      expect(
        OpponentTypicalTeamChatContext.findOpponentMentionInMessage(
          message: "Peux-tu me donner l'équipe type de Geispolsheim",
          candidates: <AgendaOpponentCandidate>[geispolsheimCandidate],
        )?.opponentName,
        'Geispolsheim',
      );
    });

    test('extracts named opponent query after équipe type de', () {
      expect(
        OpponentTypicalTeamChatContext.extractNamedOpponentQuery(
          "Peux-tu me donner l'équipe type de Geispolsheim ?",
        ),
        'Geispolsheim',
      );
    });

    test('normalizes diacritics for search', () {
      expect(
        OpponentTypicalTeamChatContext.normalizeOpponentSearchText('Équipe Type'),
        'equipe type',
      );
    });
  });
}
