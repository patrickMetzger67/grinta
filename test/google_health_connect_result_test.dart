import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/google_health_sync_service.dart';

void main() {
  group('GoogleHealthConnectResultX.isAuthorized', () {
    test('is true for success and successNoRecentWorkouts', () {
      expect(GoogleHealthConnectResult.success.isAuthorized, isTrue);
      expect(
        GoogleHealthConnectResult.successNoRecentWorkouts.isAuthorized,
        isTrue,
      );
    });

    test('is false for denied / failed / android-only / unauthenticated', () {
      expect(GoogleHealthConnectResult.denied.isAuthorized, isFalse);
      expect(GoogleHealthConnectResult.failed.isAuthorized, isFalse);
      expect(GoogleHealthConnectResult.androidOnly.isAuthorized, isFalse);
      expect(GoogleHealthConnectResult.unauthenticated.isAuthorized, isFalse);
    });
  });
}
