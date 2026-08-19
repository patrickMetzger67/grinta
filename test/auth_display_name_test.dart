import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/auth_display_name.dart';

void main() {
  group('composeAuthDisplayName', () {
    test('joins first and last name', () {
      expect(
        composeAuthDisplayName(firstName: '2', lastName: 'Test'),
        '2 Test',
      );
    });

    test('keeps a first name only', () {
      expect(composeAuthDisplayName(firstName: '2'), '2');
    });
  });

  group('shouldWriteAuthDisplayName', () {
    test('writes a person name over an empty or email Auth name', () {
      expect(shouldWriteAuthDisplayName(null, '2 Test'), isTrue);
      expect(shouldWriteAuthDisplayName('ase@tome4.com', '2 Test'), isTrue);
    });

    test('does not write an email as displayName', () {
      expect(shouldWriteAuthDisplayName(null, 'ase@tome4.com'), isFalse);
    });

    test('writes when the Grinta name changed', () {
      expect(shouldWriteAuthDisplayName('Patrick Metzger', '2 Test'), isTrue);
    });
  });

  group('resolveAuthDisplayName', () {
    test('prefers the Grinta member name over Google/Apple displayName', () {
      final resolved = resolveAuthDisplayName(
        memberFirstName: '2',
        memberLastName: 'Test',
        authDisplayName: 'Patrick Metzger',
        email: 'ase@tome4.com',
      );
      expect(resolved.name, '2 Test');
      expect(resolved.firstName, '2');
      expect(resolved.lastName, 'Test');
      expect(resolved.email, 'ase@tome4.com');
    });

    test('does not mix member first name with account last name', () {
      final resolved = resolveAuthDisplayName(
        memberFirstName: '2',
        accountFirstName: 'Patrick',
        accountLastName: 'Metzger',
        email: 'ase@tome4.com',
      );
      expect(resolved.name, '2');
      expect(resolved.firstName, '2');
      expect(resolved.lastName, '');
    });

    test('falls back to users/{uid} names then Auth then email', () {
      expect(
        resolveAuthDisplayName(
          accountFirstName: 'Alice',
          accountLastName: 'Serre',
          authDisplayName: 'Google Name',
        ).name,
        'Alice Serre',
      );
      expect(
        resolveAuthDisplayName(
          authDisplayName: 'Patrick Metzger',
          email: 'p@example.com',
        ).name,
        'Patrick Metzger',
      );
      expect(
        resolveAuthDisplayName(email: 'ase@tome4.com').name,
        'ase@tome4.com',
      );
    });
  });
}
