import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/screen/match_detail/match_grinta_highlights_tab.dart';

void main() {
  models.Match scrapedMatch() {
    return models.Match(
      id: 'match-1',
      affiliationTeam1: '500554',
      affiliationTeam2: '520346',
      team1: 'ERSTEIN AS',
      team2: 'MENORA AS',
      teams: const <dynamic>[],
      teamID: '',
    );
  }

  test('manager prefers affiliation-managed team over arbitrary profile first',
      () {
    final id = resolveGrintaHighlightTeamId(
      match: scrapedMatch(),
      isManager: true,
      profileTeamIds: const <String>['other-team', 'team-erstein'],
      managedMatchTeamIds: const <String>['team-erstein'],
      preferredManagedTeamId: 'team-erstein',
    );

    expect(id, 'team-erstein');
  });

  test('manager falls back to resolveTeamIdForMatch when no preferred id', () {
    final match = models.Match(
      id: 'match-2',
      teams: const <dynamic>['linked-team'],
      teamID: 'linked-team',
    );

    final id = resolveGrintaHighlightTeamId(
      match: match,
      isManager: true,
      profileTeamIds: const <String>['other-team'],
      managedMatchTeamIds: const <String>['linked-team'],
      preferredManagedTeamId: null,
    );

    expect(id, 'linked-team');
  });

  test('non-manager uses profile team relevant to the match', () {
    final match = models.Match(
      id: 'match-3',
      teams: const <dynamic>['player-team'],
    );

    final id = resolveGrintaHighlightTeamId(
      match: match,
      isManager: false,
      profileTeamIds: const <String>['player-team', 'other-team'],
      managedMatchTeamIds: const <String>[],
      preferredManagedTeamId: null,
    );

    expect(id, 'player-team');
  });

  test('returns null when nothing can be resolved', () {
    final id = resolveGrintaHighlightTeamId(
      match: scrapedMatch(),
      isManager: true,
      profileTeamIds: const <String>[],
      managedMatchTeamIds: const <String>[],
      preferredManagedTeamId: null,
    );

    expect(id, isNull);
  });
}
