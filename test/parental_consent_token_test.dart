import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/parental_consent_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('newParentalConsentToken does not throw (web-safe entropy)', () {
    // Regression: Random.nextInt(1 << 32) → RangeError on web.
    expect(
      () => newParentalConsentToken(random: Random(1), uuid: const Uuid()),
      returnsNormally,
    );
    final token = newParentalConsentToken(random: Random(1), uuid: const Uuid());
    expect(token.length, greaterThan(32));
    expect(token.contains('-'), isFalse);
  });
}
