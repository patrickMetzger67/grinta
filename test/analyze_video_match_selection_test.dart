import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/analyze_player_detection.dart';
import 'package:grinta/services/analyze_video_match_selection.dart';
import 'package:grinta/services/analyze_video_storage_service.dart';

void main() {
  group('parseDebugVideoDate', () {
    test('parses day/month/year', () {
      expect(parseDebugVideoDate('17/08/2026'), DateTime(2026, 8, 17));
      expect(parseDebugVideoDate('7/8/2026'), DateTime(2026, 8, 7));
    });

    test('parses ISO dates', () {
      expect(parseDebugVideoDate('2026-08-17'), DateTime(2026, 8, 17));
    });

    test('rejects impossible dates', () {
      expect(parseDebugVideoDate('32/01/2026'), isNull);
      expect(parseDebugVideoDate('not-a-date'), isNull);
    });
  });

  group('debugVideoMatchLabel', () {
    test('joins time and teams', () {
      final match = Match(
        team1: 'Grinta FC',
        team2: 'Adversaire',
        timeCh: '15:00',
      );
      expect(debugVideoMatchLabel(match), '15:00  Grinta FC – Adversaire');
    });
  });

  group('debugVideoRosterFromCompo', () {
    test('lists starters and substitutes with jersey numbers', () {
      final compo = MatchCompo(
        teamID: 'team-a',
        stricker: [
          PlayerCompo(
            playerID: 'p1',
            number: 9,
            playerNameDisplayed: 'Dupont',
          ),
        ],
        substitute: [
          PlayerCompo(
            playerID: 'p2',
            number: 12,
            playerNameDisplayed: 'Martin',
          ),
        ],
      );
      final roster = debugVideoRosterFromCompo(compo);
      expect(roster, hasLength(2));
      expect(roster.first.number, 9);
      expect(roster.first.isSubstitute, isFalse);
      expect(roster.last.number, 12);
      expect(roster.last.isSubstitute, isTrue);
    });
  });

  group('debugVideoMatchMetadata', () {
    test('omits empty values', () {
      expect(
        debugVideoMatchMetadata(
          matchId: ' m1 ',
          teamId: '',
          team1KitColor: '#1E4DB7',
        ),
        {'matchId': 'm1', 'team1KitColor': '#1E4DB7'},
      );
    });
  });

  group('debugVideoItemWithMetadata', () {
    test('reads match fields from storage metadata', () {
      final item = debugVideoItemWithMetadata(
        name: 'clip.mp4',
        storagePath: 'video/u/clip.mp4',
        downloadUrl: 'https://example.com/clip.mp4',
        customMetadata: {
          'matchId': 'match-1',
          'teamId': 'team-a',
          'matchLabel': '15:00  A – B',
        },
      );
      expect(item.matchId, 'match-1');
      expect(item.teamId, 'team-a');
      expect(item.matchLabel, '15:00  A – B');
    });
  });

  group('associateUniqueRosterPlayers', () {
    test('locks a unique jersey to the sheet player once', () {
      const boxes = [
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
          teamId: 'home',
        ),
      ];
      const roster = [
        DebugVideoRosterPlayer(
          teamId: 'home',
          playerId: 'p10',
          number: 10,
          displayName: 'Ada',
          isSubstitute: false,
        ),
        DebugVideoRosterPlayer(
          teamId: 'away',
          playerId: 'p9',
          number: 9,
          displayName: 'Bea',
          isSubstitute: false,
        ),
      ];
      final associated = associateUniqueRosterPlayers(
        boxes: boxes,
        roster: roster,
      );
      expect(associated.single.playerId, 'p10');
      expect(associated.single.teamId, 'home');
    });

    test('does not overwrite an existing player association', () {
      const boxes = [
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
          playerId: 'already',
          teamId: 'home',
        ),
      ];
      const roster = [
        DebugVideoRosterPlayer(
          teamId: 'home',
          playerId: 'p10',
          number: 10,
          displayName: 'Ada',
          isSubstitute: false,
        ),
      ];
      final associated = associateUniqueRosterPlayers(
        boxes: boxes,
        roster: roster,
      );
      expect(associated.single.playerId, 'already');
    });

    test('does not guess when the same number exists on both teams', () {
      const boxes = [
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
        ),
      ];
      const roster = [
        DebugVideoRosterPlayer(
          teamId: 'home',
          playerId: 'h10',
          number: 10,
          displayName: 'Ada',
          isSubstitute: false,
        ),
        DebugVideoRosterPlayer(
          teamId: 'away',
          playerId: 'a10',
          number: 10,
          displayName: 'Bea',
          isSubstitute: false,
        ),
      ];
      final associated = associateUniqueRosterPlayers(
        boxes: boxes,
        roster: roster,
      );
      expect(associated.single.playerId, isNull);
    });

    test('does not lock a blue-sheet number onto a white-kit box', () {
      const boxes = [
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
          teamId: 'away',
        ),
      ];
      const roster = [
        DebugVideoRosterPlayer(
          teamId: 'home',
          playerId: 'p10',
          number: 10,
          displayName: 'Ada',
          isSubstitute: false,
        ),
      ];
      final associated = associateUniqueRosterPlayers(
        boxes: boxes,
        roster: roster,
      );
      expect(associated.single.playerId, isNull);
    });

    test('does not lock a jersey when the kit team is unknown', () {
      const boxes = [
        PlayerDetectionBox(
          left: 0.2,
          top: 0.2,
          width: 0.1,
          height: 0.2,
          jerseyNumber: 10,
        ),
      ];
      const roster = [
        DebugVideoRosterPlayer(
          teamId: 'home',
          playerId: 'p10',
          number: 10,
          displayName: 'Ada',
          isSubstitute: false,
        ),
      ];
      final associated = associateUniqueRosterPlayers(
        boxes: boxes,
        roster: roster,
      );
      expect(associated.single.playerId, isNull);
    });
  });
}
