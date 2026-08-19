import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/member_unsubscribe.dart';

void main() {
  group('canManageLinkedProfiles', () {
    test('false with a single profile', () {
      expect(canManageLinkedProfiles(1), isFalse);
      expect(canManageLinkedProfiles(0), isFalse);
    });

    test('true when several profiles are linked', () {
      expect(canManageLinkedProfiles(2), isTrue);
      expect(canManageLinkedProfiles(3), isTrue);
    });
  });

  group('planMemberUnsubscribe', () {
    test('returns null when uid is not in users', () {
      expect(
        planMemberUnsubscribe(
          users: const ['other'],
          userID: 'other',
          uid: 'me',
        ),
        isNull,
      );
    });

    test('returns null for a blank uid', () {
      expect(
        planMemberUnsubscribe(
          users: const ['me'],
          userID: 'me',
          uid: '  ',
        ),
        isNull,
      );
    });

    test('removes uid and keeps userID when it belongs to someone else', () {
      final plan = planMemberUnsubscribe(
        users: const ['parent', 'child'],
        userID: 'child',
        uid: 'parent',
      );

      expect(plan, isNotNull);
      expect(plan!.remainingUsers, ['child']);
      expect(plan.userIdAction, MemberUserIdUnsubscribeAction.keep);
      expect(plan.nextUserId, isNull);
    });

    test('reassigns userID to another remaining user', () {
      final plan = planMemberUnsubscribe(
        users: const ['parent', 'child'],
        userID: 'parent',
        uid: 'parent',
      );

      expect(plan, isNotNull);
      expect(plan!.remainingUsers, ['child']);
      expect(plan.userIdAction, MemberUserIdUnsubscribeAction.reassign);
      expect(plan.nextUserId, 'child');
    });

    test('clears userID when no other users remain', () {
      final plan = planMemberUnsubscribe(
        users: const ['only'],
        userID: 'only',
        uid: 'only',
      );

      expect(plan, isNotNull);
      expect(plan!.remainingUsers, isEmpty);
      expect(plan.userIdAction, MemberUserIdUnsubscribeAction.clear);
    });

    test('deduplicates and ignores empty users entries', () {
      final plan = planMemberUnsubscribe(
        users: const ['me', '', 'me', 'other'],
        userID: 'other',
        uid: 'me',
      );

      expect(plan, isNotNull);
      expect(plan!.remainingUsers, ['other']);
      expect(plan.userIdAction, MemberUserIdUnsubscribeAction.keep);
    });
  });
}
