import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';

MatchStatPlayer _player({
  required String name,
  required String shirt,
  String team = 'Adversaire FC',
}) {
  return MatchStatPlayer(team: team, player: name, shirt: shirt);
}

TypicalTeamMatchInput _matchInput({
  required List<MatchStatPlayer> titulars,
  List<MatchStatPlayer> substitutes = const [],
}) {
  return TypicalTeamMatchInput(
    match: models.Match(),
    opponentTeamName: 'Adversaire FC',
    matchStats: MatchStats(
      matchId: 'm1',
      titulars: titulars,
      substitutes: substitutes,
      highlights: const [],
    ),
  );
}

void main() {
  group('normalizeTypicalTeamPlayerIdentity', () {
    test('uses first and last name tokens', () {
      expect(
        normalizeTypicalTeamPlayerIdentity('Jean Pierre Dupont'),
        'jean dupont',
      );
      expect(normalizeTypicalTeamPlayerIdentity('Marie Martin'), 'marie martin');
    });
  });

  group('computeTypicalTeamFromMatchStats uniqueness', () {
    test('never selects the same first+last name twice in starters', () {
      // Same person under two shirts across matches → two accumulator keys.
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '10'),
              _player(name: 'Paul Martin', shirt: '9'),
            ],
          ),
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '7'),
              _player(name: 'Paul Martin', shirt: '9'),
              _player(name: 'Alex Bernard', shirt: '8'),
            ],
          ),
          // Boost Jean#10 and Jean#7 titular counts so both would enter top XI
          // without name dedupe.
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '10'),
              _player(name: 'Alex Bernard', shirt: '8'),
            ],
          ),
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '7'),
              _player(name: 'Hugo Leroy', shirt: '6'),
            ],
          ),
        ],
        maxStarters: 11,
        maxSubstitutes: 7,
      );

      final starterNames = result.probableStarters
          .map((player) => normalizeTypicalTeamPlayerIdentity(player.displayName))
          .toList();

      expect(starterNames.toSet().length, starterNames.length);
      expect(
        starterNames.where((name) => name == 'jean dupont').length,
        1,
      );
      expect(starterNames, contains('paul martin'));
      expect(starterNames, contains('alex bernard'));
      expect(starterNames, contains('hugo leroy'));
    });

    test('skips duplicate name and takes the next ranked starter', () {
      // Ranked by titularCount: Dupont#10 (3), Other (2), Dupont#7 (2), Fill (1)
      // Without dedupe top 3 would include Dupont twice; with dedupe Fill enters.
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          for (var i = 0; i < 3; i++)
            _matchInput(
              titulars: [
                _player(name: 'Jean Dupont', shirt: '10'),
                if (i < 2) _player(name: 'Paul Martin', shirt: '9'),
                if (i < 2) _player(name: 'Jean Dupont', shirt: '7'),
                if (i < 1) _player(name: 'Alex Bernard', shirt: '8'),
              ],
            ),
        ],
        maxStarters: 3,
        maxSubstitutes: 0,
      );

      final identities = result.probableStarters
          .map((player) => normalizeTypicalTeamPlayerIdentity(player.displayName))
          .toSet();

      expect(result.probableStarters, hasLength(3));
      expect(identities, containsAll(['jean dupont', 'paul martin', 'alex bernard']));
      expect(identities.length, 3);
    });

    test('excludes a starter identity from the bench even with another shirt', () {
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '10'),
            ],
            substitutes: [
              _player(name: 'Jean Dupont', shirt: '7'),
              _player(name: 'Paul Martin', shirt: '12'),
            ],
          ),
          _matchInput(
            titulars: [
              _player(name: 'Jean Dupont', shirt: '10'),
            ],
            substitutes: [
              _player(name: 'Jean Dupont', shirt: '7'),
              _player(name: 'Paul Martin', shirt: '12'),
            ],
          ),
        ],
        maxStarters: 11,
        maxSubstitutes: 7,
      );

      final starterIds = result.probableStarters
          .map((player) => normalizeTypicalTeamPlayerIdentity(player.displayName))
          .toSet();
      final subIds = result.probableSubstitutes
          .map((player) => normalizeTypicalTeamPlayerIdentity(player.displayName))
          .toSet();

      expect(starterIds, contains('jean dupont'));
      expect(subIds, isNot(contains('jean dupont')));
      expect(subIds, contains('paul martin'));
    });

    test('merges shirt usages for the same player across numbers', () {
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          for (var i = 0; i < 8; i++)
            _matchInput(
              titulars: [
                _player(name: 'Mohamed Ali', shirt: '6'),
                _player(name: 'Paul Martin', shirt: '9'),
              ],
            ),
          for (var i = 0; i < 3; i++)
            _matchInput(
              titulars: [
                _player(name: 'Mohamed Ali', shirt: '5'),
                _player(name: 'Paul Martin', shirt: '9'),
              ],
            ),
        ],
        maxStarters: 11,
        maxSubstitutes: 0,
      );

      final mohamed = result.probableStarters.singleWhere(
        (player) =>
            normalizeTypicalTeamPlayerIdentity(player.displayName) ==
            'mohamed ali',
      );

      expect(mohamed.titularCount, 11);
      expect(mohamed.shirtNumber, 6);
      expect(mohamed.shirtUsages, hasLength(2));
      expect(mohamed.shirtUsages[0].shirtNumber, 6);
      expect(mohamed.shirtUsages[0].titularCount, 8);
      expect(mohamed.shirtUsages[1].shirtNumber, 5);
      expect(mohamed.shirtUsages[1].titularCount, 3);
      expect(
        mohamed.shirtBreakdownLabel(useTitularCounts: true),
        '#6 - 8/11 - #5 - 3/11',
      );
    });

    test('omits shirt breakdown when only one number was used', () {
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          _matchInput(
            titulars: [
              _player(name: 'Paul Martin', shirt: '9'),
            ],
          ),
        ],
        maxStarters: 11,
        maxSubstitutes: 0,
      );

      final paul = result.probableStarters.single;
      expect(paul.shirtUsages, hasLength(1));
      expect(paul.shirtBreakdownLabel(useTitularCounts: true), isNull);
    });

    test('omits zero-count shirts from breakdown label', () {
      final result = computeTypicalTeamFromMatchStats(
        matches: [
          for (var i = 0; i < 9; i++)
            _matchInput(
              titulars: [
                _player(name: 'Jean Philippe', shirt: '6'),
              ],
            ),
          for (var i = 0; i < 9; i++)
            _matchInput(
              titulars: [
                _player(name: 'Jean Philippe', shirt: '8'),
              ],
            ),
          for (var i = 0; i < 2; i++)
            _matchInput(
              titulars: [
                _player(name: 'Paul Martin', shirt: '9'),
              ],
              substitutes: [
                _player(name: 'Jean Philippe', shirt: '13'),
              ],
            ),
          _matchInput(
            titulars: [
              _player(name: 'Paul Martin', shirt: '9'),
            ],
            substitutes: [
              _player(name: 'Jean Philippe', shirt: '14'),
            ],
          ),
        ],
        maxStarters: 11,
        maxSubstitutes: 0,
      );

      final jean = result.probableStarters.singleWhere(
        (player) =>
            normalizeTypicalTeamPlayerIdentity(player.displayName) ==
            'jean philippe',
      );

      expect(jean.shirtUsages.length, greaterThanOrEqualTo(2));
      expect(
        jean.shirtBreakdownLabel(useTitularCounts: true),
        '#6 - 9/21 - #8 - 9/21',
      );
      expect(
        jean.shirtBreakdownLabel(useTitularCounts: true),
        isNot(contains('#13')),
      );
      expect(
        jean.shirtBreakdownLabel(useTitularCounts: true),
        isNot(contains('#14')),
      );
    });
  });
}
