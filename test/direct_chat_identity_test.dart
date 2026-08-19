import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/direct_chat_identity.dart';

void main() {
  group('isDirectMessageChannel', () {
    test('is true for a 2-member channel without a Stream name', () {
      expect(
        isDirectMessageChannel(
          memberCount: 2,
          channelName: null,
          otherMemberCount: 1,
        ),
        isTrue,
      );
    });

    test('is false when the channel has a team/group name', () {
      expect(
        isDirectMessageChannel(
          memberCount: 2,
          channelName: 'myTeam 1',
          otherMemberCount: 1,
        ),
        isFalse,
      );
    });

    test('is false for a group with more than two members', () {
      expect(
        isDirectMessageChannel(
          memberCount: 8,
          channelName: '',
          otherMemberCount: 7,
        ),
        isFalse,
      );
    });
  });

  group('resolveDirectChatIdentity', () {
    test('uses first + last name and puts email underneath', () {
      final identity = resolveDirectChatIdentity(
        firstName: '2',
        lastName: 'Test',
        email: 'ase@tome4.com',
        streamName: 'ase@tome4.com',
      );
      expect(identity.title, '2 Test');
      expect(identity.email, 'ase@tome4.com');
    });

    test('keeps a real Stream name when Grinta names are missing', () {
      final identity = resolveDirectChatIdentity(
        streamName: 'Patrick Metzger',
        email: 'patrick@example.com',
      );
      expect(identity.title, 'Patrick Metzger');
      expect(identity.email, 'patrick@example.com');
    });

    test('does not repeat the email when it is the only label', () {
      final identity = resolveDirectChatIdentity(
        streamName: 'ase@tome4.com',
        email: 'ase@tome4.com',
      );
      expect(identity.title, 'ase@tome4.com');
      expect(identity.email, isNull);
    });

    test('shows email under a first name only', () {
      final identity = resolveDirectChatIdentity(
        firstName: '2',
        email: 'ase@tome4.com',
      );
      expect(identity.title, '2');
      expect(identity.email, 'ase@tome4.com');
    });
  });

  group('mergeDirectChatIdentity', () {
    test('replaces an email Stream title with the Grinta profile name', () {
      final merged = mergeDirectChatIdentity(
        streamIdentity: resolveDirectChatIdentity(
          streamName: 'ase@tome4.com',
          email: 'ase@tome4.com',
        ),
        profileFirstName: 'Alice',
        profileLastName: 'Serre',
        profileEmail: 'ase@tome4.com',
      );
      expect(merged.title, 'Alice Serre');
      expect(merged.email, 'ase@tome4.com');
    });

    test('keeps the Stream identity when the profile is empty', () {
      final stream = resolveDirectChatIdentity(
        streamName: 'Patrick Metzger',
        email: 'patrick@example.com',
      );
      final merged = mergeDirectChatIdentity(streamIdentity: stream);
      expect(merged.title, stream.title);
      expect(merged.email, stream.email);
    });
  });
}
