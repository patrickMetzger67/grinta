import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/fff_competition_url.dart';

void main() {
  group('parseFffCompetitionUrl', () {
    test('parses coupe du grand est futsal u18 URL', () {
      const url =
          'https://epreuves.fff.fr/competition/engagement/'
          '445878-coupe-du-grand-est-futsal-u18/phase/1/1';

      final info = parseFffCompetitionUrl(url);

      expect(info, isNotNull);
      expect(info!.rawUrl, url);
      expect(info.engagementId, '445878');
      expect(info.slug, 'coupe-du-grand-est-futsal-u18');
      expect(info.name, 'Coupe du Grand Est Futsal');
      expect(info.phase, 1);
      expect(info.groupe, 1);
    });

    test('parses u18 regional 1 URL', () {
      const url =
          'https://epreuves.fff.fr/competition/engagement/'
          '436278-u18-regional-1/phase/1/2';

      final info = parseFffCompetitionUrl(url);

      expect(info, isNotNull);
      expect(info!.engagementId, '436278');
      expect(info.slug, 'u18-regional-1');
      expect(info.name, 'U18 Régional 1');
      expect(info.phase, 1);
      expect(info.groupe, 2);
    });

    test('accepts path-only URLs', () {
      const url =
          '/competition/engagement/436278-u18-regional-1/phase/2/3';

      final info = parseFffCompetitionUrl(url);

      expect(info, isNotNull);
      expect(info!.phase, 2);
      expect(info.groupe, 3);
    });

    test('returns null for invalid URLs', () {
      expect(parseFffCompetitionUrl(''), isNull);
      expect(parseFffCompetitionUrl('https://example.com'), isNull);
      expect(
        parseFffCompetitionUrl(
          'https://epreuves.fff.fr/competition/engagement/abc-slug/phase/1/1',
        ),
        isNull,
      );
      expect(
        parseFffCompetitionUrl(
          'https://epreuves.fff.fr/competition/engagement/123-slug/phase/a/b',
        ),
        isNull,
      );
    });
  });

  group('parseFffCompetitionUrls', () {
    test('keeps only valid URLs in order', () {
      const valid =
          'https://epreuves.fff.fr/competition/engagement/'
          '436278-u18-regional-1/phase/1/2';
      const invalid = 'not-a-url';

      final infos = parseFffCompetitionUrls(<String>[invalid, valid, '']);

      expect(infos, hasLength(1));
      expect(infos.first.name, 'U18 Régional 1');
    });
  });

  group('buildEngagementDocumentId', () {
    test('builds club-competition-group-stage id', () {
      expect(
        buildEngagementDocumentId(
          clubId: '500200',
          competitionId: '436278',
          group: '2',
          stage: '1',
        ),
        '500200-436278-2-1',
      );
    });
  });

  group('isFriendlyCompetitionUrl', () {
    test('detects matchs amicaux FFF engagement URLs', () {
      expect(
        isFriendlyCompetitionUrl(
          'https://epreuves.fff.fr/competition/engagement/'
          '440556-matchs-amicaux-seniors/phase/1/1',
        ),
        isTrue,
      );
      expect(
        isFriendlyCompetitionUrl(
          'https://epreuves.fff.fr/competition/engagement/'
          '444915-matches-amicaux-seniors/phase/1/1',
        ),
        isTrue,
      );
    });

    test('returns false for regular competitions', () {
      expect(
        isFriendlyCompetitionUrl(
          'https://epreuves.fff.fr/competition/engagement/'
          '436278-u18-regional-1/phase/1/2',
        ),
        isFalse,
      );
    });
  });

  group('slugToCompetitionName', () {
    test('applies French accents and title casing', () {
      expect(
        slugToCompetitionName('coupe-feminine-departementale'),
        'Coupe Féminine Départementale',
      );
    });

    test('keeps leading age category and strips trailing age category', () {
      expect(slugToCompetitionName('u18-regional-1'), 'U18 Régional 1');
      expect(
        slugToCompetitionName('coupe-du-grand-est-futsal-u18'),
        'Coupe du Grand Est Futsal',
      );
    });
  });
}
