import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/match_creation_helper.dart';

void main() {
  Match scrapedFriendly({
    String competitionID = '',
    String poule = '',
    String stage = '',
  }) {
    return Match(
      id: '56007396',
      affiliationTeam1: '500554',
      affiliationTeam2: '520346',
      team1: 'ERSTEIN AS',
      team2: 'MENORA AS',
      teams: const <dynamic>[],
      chType: 'MATCHS AMICAUX',
      competitionID: competitionID,
      poule: poule,
      stage: stage,
    );
  }

  Team ersteinTeam({
    required String key,
    String? managerUid,
    List<Competition>? competitions,
  }) {
    return Team(
      keyTeam: key,
      name: 'Séniors 2',
      clubId: '500554',
    )
      ..managers =
          managerUid == null ? <dynamic>[] : <dynamic>[managerUid]
      ..competitions = competitions;
  }

  Competition friendlyEngagement() {
    return Competition(
      name: 'Matchs Amicaux',
      competitionID: '452004',
      poule: '1',
      urlCalendar:
          'https://marne.fff.fr/competition/engagement/452004-matchs-amicaux-seniors/phase/1/1',
    );
  }

  test('matchAffiliationMatchesClubId checks both sides', () {
    final match = scrapedFriendly();
    expect(matchAffiliationMatchesClubId(match, '500554'), isTrue);
    expect(matchAffiliationMatchesClubId(match, '520346'), isTrue);
    expect(matchAffiliationMatchesClubId(match, '999999'), isFalse);
    expect(matchAffiliationMatchesClubId(match, ''), isFalse);
  });

  test('scraped match without competitionID is editable via affiliation', () {
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

  test('requires competitionID/poule/stage to match team competitions', () {
    const uid = 'manager-1';
    final match = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '1',
    );

    final withoutCompetition = ersteinTeam(
      key: 'team-test',
      managerUid: uid,
    );
    final withCompetition = ersteinTeam(
      key: 'team-erstein',
      managerUid: uid,
      competitions: <Competition>[friendlyEngagement()],
    );

    final managed = resolveManagedMatchTeamIds(
      match: match,
      seasonTeams: <Team>[withoutCompetition, withCompetition],
      currentUserUid: uid,
      managedTeamsIdsForSelectedSeason: const <String>[
        'team-test',
        'team-erstein',
      ],
    );

    expect(managed, <String>['team-erstein']);
  });

  test('teamCompetitionsIncludeMatch rejects wrong poule/stage', () {
    final team = ersteinTeam(
      key: 'team-erstein',
      competitions: <Competition>[friendlyEngagement()],
    );
    final wrongPoule = scrapedFriendly(
      competitionID: '452004',
      poule: '2',
      stage: '1',
    );
    final wrongStage = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '2',
    );
    final ok = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '1',
    );

    expect(teamCompetitionsIncludeMatch(team, wrongPoule), isFalse);
    expect(teamCompetitionsIncludeMatch(team, wrongStage), isFalse);
    expect(teamCompetitionsIncludeMatch(team, ok), isTrue);
  });
}
