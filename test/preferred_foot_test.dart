import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/preferred_foot.dart';

void main() {
  group('normalizePreferredFoot', () {
    test('maps canonical and legacy values', () {
      expect(normalizePreferredFoot('left'), PreferredFootCodes.left);
      expect(normalizePreferredFoot('Gauche'), PreferredFootCodes.left);
      expect(normalizePreferredFoot('droit'), PreferredFootCodes.right);
      expect(normalizePreferredFoot('both'), PreferredFootCodes.both);
      expect(normalizePreferredFoot('ambidextre'), PreferredFootCodes.both);
      expect(normalizePreferredFoot(''), isNull);
      expect(normalizePreferredFoot(null), isNull);
    });
  });
}
