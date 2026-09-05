import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/util/fff_competition_url.dart';
import 'package:grinta/util/team_stats_competition_filter.dart';

void main() {
  Match match56174440() {
    return Match(
      id: '56174440',
      competitionID: '450652',
      poule: '3',
      stage: '1',
      url:
          'https://alsace.fff.fr/competitions?competition_id=450652&poule=1&match_id=56174440',
    );
  }

  group('parseFffCompetitionUrl query', () {
    test('reads competition_id and poule from a district match URL', () {
      final info = parseFffCompetitionUrl(
        'https://alsace.fff.fr/competitions?competition_id=450652&poule=1&match_id=56174440',
      );

      expect(info, isNotNull);
      expect(info!.engagementId, '450652');
      expect(info.groupe, 1);
    });
  });

  group('competitionIdentityFromMatch', () {
    test('56174440 uses poule 3 from the document, not URL poule 1', () {
      final identity = competitionIdentityFromMatch(match56174440());

      expect(identity?.competitionId, '450652');
      expect(identity?.poule, '3');
      expect(identity?.stage, '1');
      expect(
        urlMatchesCompetitionIdentity(
          'https://alsace.fff.fr/competitions?competition_id=450652&poule=1',
          identity!,
        ),
        isFalse,
      );
      expect(
        urlMatchesCompetitionIdentity(
          'https://epreuves.fff.fr/competition/engagement/'
          '450652-district-1-alsace/phase/1/3',
          identity,
        ),
        isTrue,
      );
    });
  });

  group('matchMatchesCompetitionFilter', () {
    test('rejects the home-club poule 1 URL for match 56174440', () {
      final filter = competitionFilterFromUrl(
        'https://alsace.fff.fr/competitions?competition_id=450652&poule=1',
      );
      expect(filter, isNotNull);
      expect(matchMatchesCompetitionFilter(match56174440(), filter!), isFalse);
    });

    test('accepts poule 3 for match 56174440', () {
      final filter = competitionFilterFromUrl(
        'https://epreuves.fff.fr/competition/engagement/'
        '450652-district-1-alsace/phase/1/3',
      );
      expect(filter, isNotNull);
      expect(matchMatchesCompetitionFilter(match56174440(), filter!), isTrue);
    });
  });

  group('resolveTeamStatsSelectedCompetitionValue', () {
    const poule1 = TeamStatsCompetitionOption(
      value:
          'https://epreuves.fff.fr/competition/engagement/'
          '450652-district-1-alsace/phase/1/1',
      label: 'District 1 poule 1',
    );
    const poule3 = TeamStatsCompetitionOption(
      value:
          'https://epreuves.fff.fr/competition/engagement/'
          '450652-district-1-alsace/phase/1/3',
      label: 'District 1 poule 3',
    );

    test('selects poule 3 even if the initial URL is poule 1', () {
      final selected = resolveTeamStatsSelectedCompetitionValue(
        options: const [poule1, poule3],
        initialUrl:
            'https://alsace.fff.fr/competitions?competition_id=450652&poule=1',
        matchIdentity: competitionIdentityFromMatch(match56174440()),
      );

      expect(selected, poule3.value);
    });

    test('does not fall back to poule 1 when poule 3 is missing', () {
      final selected = resolveTeamStatsSelectedCompetitionValue(
        options: const [poule1],
        initialUrl:
            'https://alsace.fff.fr/competitions?competition_id=450652&poule=1',
        matchIdentity: competitionIdentityFromMatch(match56174440()),
        fallback: kTeamStatsAllCompetitionsValue,
      );

      expect(selected, kTeamStatsAllCompetitionsValue);
    });
  });
}
