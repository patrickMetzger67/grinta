import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/search_options.dart';

void main() {
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
  });
}
