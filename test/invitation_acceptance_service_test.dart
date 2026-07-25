import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/invitation_acceptance_service.dart';

void main() {
  group('InvitationLookupResult', () {
    test('failure is not success', () {
      final result = InvitationLookupResult.failure(
        InvitationLookupError.notFound,
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, InvitationLookupError.notFound);
      expect(result.invitation, isNull);
      expect(result.member, isNull);
    });
  });
}
