import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/intense_live_data_service.dart';

void main() {
  group('Intense live Insiders rate-limit helpers', () {
    test('detects HTTP 429 / throttled Firebase errors', () {
      final error = FirebaseFunctionsException(
        code: 'internal',
        message:
            'Insiders HTTP 429 Too Many Requests (Retry-After: 1s): '
            '{"detail":"Request was throttled"}',
      );
      expect(IntenseLiveDataService.debugIsInsidersRateLimited(error), isTrue);
    });

    test('parses Retry-After delay', () {
      final error = FirebaseFunctionsException(
        code: 'internal',
        message: 'Insiders HTTP 429 Too Many Requests (Retry-After: 2s)',
      );
      final delay = IntenseLiveDataService.debugRetryDelayForRateLimit(error, 0);
      expect(delay.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(3000));
    });
  });
}
