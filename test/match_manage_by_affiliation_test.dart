import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/engagement.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/fff_competition_url.dart';
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

  Competition friendlyEngagementCompetition() {
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
  });

  test('manager + affiliation can manage even when Team.competitions empty', () {
    // Agenda source of truth is the engagement collection; sync manage gate
    // only checks manager + affiliation so the edit pencil can appear.
    const uid = 'manager-1';
    final team = ersteinTeam(key: 'team-erstein', managerUid: uid);
    final match = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '1',
    );

    final managed = resolveManagedMatchTeamIds(
      match: match,
      seasonTeams: <Team>[team],
      currentUserUid: uid,
      managedTeamsIdsForSelectedSeason: const <String>['team-erstein'],
    );

    expect(managed, <String>['team-erstein']);
  });

  test('affiliation alone is not enough without manager rights', () {
    final team = ersteinTeam(key: 'team-erstein');

    final managed = resolveManagedMatchTeamIds(
      match: scrapedFriendly(competitionID: '452004', poule: '1', stage: '1'),
      seasonTeams: <Team>[team],
      currentUserUid: 'someone-else',
      managedTeamsIdsForSelectedSeason: const <String>[],
    );

    expect(managed, isEmpty);
  });

  test('teamCompetitionsIncludeMatch uses FFF calendar URL', () {
    final team = ersteinTeam(
      key: 'team-erstein',
      competitions: <Competition>[friendlyEngagementCompetition()],
    );
    final ok = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '1',
    );
    final wrongPoule = scrapedFriendly(
      competitionID: '452004',
      poule: '2',
      stage: '1',
    );

    expect(teamCompetitionsIncludeMatch(team, ok), isTrue);
    expect(teamCompetitionsIncludeMatch(team, wrongPoule), isFalse);
  });

  test('engagementMatchesMatch and engagementIncludesTeam', () {
    final match = scrapedFriendly(
      competitionID: '452004',
      poule: '1',
      stage: '1',
    );
    final engagement = Engagement(
      clubId: '500554',
      competitionId: '452004',
      group: '1',
      stage: '1',
      teamIds: <String>['team-erstein'],
    );

    expect(engagementMatchesMatch(engagement, match), isTrue);
    expect(engagementIncludesTeam(engagement, 'team-erstein'), isTrue);
    expect(engagementIncludesTeam(engagement, 'other'), isFalse);
    expect(
      engagementMatchesMatch(
        Engagement(
          competitionId: '452004',
          group: '2',
          stage: '1',
        ),
        match,
      ),
      isFalse,
    );

    expect(
      buildEngagementDocumentId(
        clubId: '500554',
        competitionId: '452004',
        group: '1',
        stage: '1',
      ),
      '500554-452004-1-1',
    );
  });

  test('preferredEditableMatchTeamId prefers sole editable team', () {
    final match = scrapedFriendly(competitionID: '452004', poule: '1', stage: '1');
    expect(
      preferredEditableMatchTeamId(match, <String>['team-erstein']),
      'team-erstein',
    );
    expect(preferredEditableMatchTeamId(match, const <String>[]), isNull);
  });
}
