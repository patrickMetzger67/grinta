import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/search_options.dart';

void main() {
  group('searchTokenCaseVariants', () {
    test('includes lowercase, uppercase, and title-case variants', () {
      expect(
        searchTokenCaseVariants('etienne').toList(),
        containsAll(<String>['etienne', 'ETIENNE', 'Etienne']),
      );
    });

    test('keeps single-character tokens', () {
      expect(
        searchTokenCaseVariants('e').toList(),
        containsAll(<String>['e', 'E']),
      );
    });

    test('strips accents so Raëd queries raed', () {
      expect(
        searchTokenCaseVariants('Raëd').toList(),
        containsAll(<String>['raed', 'RAED', 'Raed']),
      );
    });
  });

  group('normalizeSearchToken', () {
    test('lowercases and strips accents', () {
      expect(normalizeSearchToken('Jérou'), 'jerou');
      expect(normalizeSearchToken('  Raëd '), 'raed');
    });
  });

  group('phoneSearchE164Variants', () {
    test('covers 06 and legacy +3306 forms', () {
      final variants = phoneSearchE164Variants('06 41 26 57 56');
      expect(variants, contains('+33641265756'));
      expect(variants, contains('+330641265756'));
    });
  });

  group('buildPlayerSearchOptions', () {
    test('indexes first name and last name prefixes', () {
      final options = buildPlayerSearchOptions(
        firstName: 'Jean',
        lastName: 'Dupont',
      );

      expect(options, containsAll(<String>['j', 'je', 'jean', 'd', 'du', 'dupont']));
    });

    test('indexes email and local-part prefixes', () {
      final options = buildPlayerSearchOptions(
        firstName: 'Jean',
        lastName: 'Dupont',
        email: 'Jean.Dupont@Club.fr',
      );

      expect(options, contains('jean.dupont@club.fr'));
      expect(options, contains('jean.dupont@'));
      expect(options, contains('jean.dupont'));
      expect(options, contains('jean'));
      expect(options, contains('dupont'));
    });

    test('ignores blank email', () {
      final options = buildPlayerSearchOptions(
        firstName: 'Anna',
        lastName: 'Martin',
        email: '   ',
      );

      expect(options.any((token) => token.contains('@')), isFalse);
      expect(options, containsAll(<String>['anna', 'martin']));
    });

    test('indexes accent-stripped prefixes for mobile keyboards', () {
      final options = buildPlayerSearchOptions(
        firstName: 'Raëd',
        lastName: 'Jérou',
      );

      expect(options, containsAll(<String>['raed', 'jerou', 'rae', 'jero']));
    });
  });
}
