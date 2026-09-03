import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/fcm_token.dart';

void main() {
  group('isLikelyApnsDeviceToken', () {
    test('detects 64-char hex APNs tokens', () {
      expect(isLikelyApnsDeviceToken('a' * 64), isTrue);
      expect(isLikelyApnsDeviceToken('0123456789ABCDEFabcdef0123456789ABCDEF0123456789abcdef0123456789'), isTrue);
    });

    test('accepts FCM registration tokens', () {
      expect(
        isSendableFcmRegistrationToken(
          'dXyZtoken:APA91bFakeFcmRegistrationTokenValueForTests',
        ),
        isTrue,
      );
      expect(isSendableFcmRegistrationToken('a' * 64), isFalse);
      expect(isSendableFcmRegistrationToken(''), isFalse);
    });
  });

  group('fcmTokenFromFirestoreDoc', () {
    test('prefers data.token over the document id', () {
      expect(
        fcmTokenFromFirestoreDoc(
          id: 'legacy-id',
          data: {'token': ' real-fcm-token '},
        ),
        'real-fcm-token',
      );
    });

    test('falls back to the document id', () {
      expect(
        fcmTokenFromFirestoreDoc(id: ' doc-token ', data: const {}),
        'doc-token',
      );
    });
  });

  group('collectGrintaFcmTokens', () {
    test('keeps unbranded iOS tokens when another device is already branded', () {
      final tokens = collectGrintaFcmTokens([
        (
          id: 'android-tok',
          data: {'app': 'grinta', 'platform': 'android'},
        ),
        (
          id: 'ios-legacy-tok',
          data: {'platform': 'ios'},
        ),
        (
          id: 'aser-tok',
          data: {'app': 'aserstein'},
        ),
        (
          id: 'a' * 64,
          data: {'app': 'grinta', 'platform': 'ios'},
        ),
      ]);

      expect(tokens, containsAll(['android-tok', 'ios-legacy-tok']));
      expect(tokens, isNot(contains('aser-tok')));
      expect(tokens, isNot(contains('a' * 64)));
    });

    test('reads token from the document field', () {
      expect(
        collectGrintaFcmTokens([
          (
            id: 'hashed-id',
            data: {'app': 'grinta', 'token': 'ios-fcm-tok'},
          ),
        ]),
        ['ios-fcm-tok'],
      );
    });
  });

  group('shouldCallChatPushCloudFunction', () {
    test('sends when peers exist even if the client has no tokens yet', () {
      expect(
        shouldCallChatPushCloudFunction(peerUserIds: [' peer-1 ', '']),
        isTrue,
      );
      expect(shouldCallChatPushCloudFunction(peerUserIds: const []), isFalse);
      expect(shouldCallChatPushCloudFunction(peerUserIds: ['  ']), isFalse);
    });
  });
}
