import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/match_creation_helper.dart';

void main() {
  Match scrapedFriendly() {
    return Match(
      id: '56007396',
      affiliationTeam1: '500554',
      affiliationTeam2: '520346',
      team1: 'ERSTEIN AS',
      team2: 'MENORA AS',
      teams: const <dynamic>[],
      chType: 'MATCHS AMICAUX',
    );
  }

  Team ersteinTeam({required String key, String? managerUid}) {
    return Team(
      keyTeam: key,
      name: 'Séniors 2',
      clubId: '500554',
    )..managers =
        managerUid == null ? <dynamic>[] : <dynamic>[managerUid];
  }

  test('matchAffiliationMatchesClubId checks both sides', () {
    final match = scrapedFriendly();
    expect(matchAffiliationMatchesClubId(match, '500554'), isTrue);
    expect(matchAffiliationMatchesClubId(match, '520346'), isTrue);
    expect(matchAffiliationMatchesClubId(match, '999999'), isFalse);
    expect(matchAffiliationMatchesClubId(match, ''), isFalse);
  });

  test('scraped match with empty teams is editable via club affiliation', () {
    const uid = 'manager-1';
    final team = ersteinTeam(key: 'team-erstein', managerUid: uid);

    final managed = resolveManagedMatchTeamIds(
      match: scrapedFriendly(),
      seasonTeams: <Team>[team],
      currentUserUid: uid,
      managedTeamsIdsForSelectedSeason: const <String>['team-erstein'],
    );

    expect(managed, <String>['team-erstein']);
  });

  test('affiliation alone is not enough without manager rights', () {
    final team = ersteinTeam(key: 'team-erstein');

    final managed = resolveManagedMatchTeamIds(
      match: scrapedFriendly(),
      seasonTeams: <Team>[team],
      currentUserUid: 'someone-else',
      managedTeamsIdsForSelectedSeason: const <String>[],
    );

    expect(managed, isEmpty);
  });

  test('still resolves teams listed on the match document', () {
    const uid = 'manager-1';
    final team = ersteinTeam(key: 'team-erstein', managerUid: uid);
    final match = scrapedFriendly()..teams = <dynamic>['team-erstein'];

    final managed = resolveManagedMatchTeamIds(
      match: match,
      seasonTeams: <Team>[team],
      currentUserUid: uid,
      managedTeamsIdsForSelectedSeason: const <String>['team-erstein'],
    );

    expect(managed, <String>['team-erstein']);
  });
}
