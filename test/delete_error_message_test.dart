import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/delete_error_message.dart';

void main() {
  group('DeleteErrorMessage.isPermissionDenied', () {
    test('detects Firestore permission-denied codes', () {
      expect(
        DeleteErrorMessage.isPermissionDenied(
          Exception(
            '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
          ),
        ),
        isTrue,
      );
    });

    test('detects the insufficient-permissions phrase', () {
      expect(
        DeleteErrorMessage.isPermissionDenied(
          Exception('Missing or insufficient permissions.'),
        ),
        isTrue,
      );
    });

    test('ignores unrelated failures', () {
      expect(
        DeleteErrorMessage.isPermissionDenied(Exception('network-request-failed')),
        isFalse,
      );
    });
  });
}
