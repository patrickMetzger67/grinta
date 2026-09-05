import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/fcm_token.dart';

void main() {
  group('isLikelyApnsDeviceToken', () {
    test('detects 64-char hex APNs tokens', () {
      expect(isLikelyApnsDeviceToken('a' * 64), isTrue);
      expect(
        isLikelyApnsDeviceToken(
          '0123456789ABCDEFabcdef0123456789ABCDEF0123456789abcdef0123456789',
        ),
        isTrue,
      );
    });

    test('rejects FCM registration tokens', () {
      expect(
        isLikelyApnsDeviceToken('dXyz:APA91bExampleFcmRegistrationToken'),
        isFalse,
      );
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
    test('on dual-app accounts keeps only explicit Grinta tokens', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-tok', data: {'app': 'grinta', 'platform': 'android'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
        (id: 'aser-tok', data: {'app': 'aserstein'}),
        (id: 'a' * 64, data: {'app': 'grinta', 'platform': 'ios'}),
      ]);
      expect(tokens, ['android-tok']);
    });

    test('keeps unbranded iOS on Grinta-only accounts', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-tok', data: {'app': 'grinta', 'platform': 'android'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
        (id: 'a' * 64, data: {'app': 'grinta', 'platform': 'ios'}),
      ]);
      expect(tokens, containsAll(['android-tok', 'ios-legacy-tok']));
      expect(tokens, isNot(contains('a' * 64)));
    });

    test('drops naked unbranded Android tokens (Aserstein bleed)', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-legacy', data: {'platform': 'android'}),
        (id: 'grinta-tok', data: {'app': 'grinta'}),
      ]);
      expect(tokens, ['grinta-tok']);
    });

    test('keeps unbranded docs tagged with Grinta packageName', () {
      final tokens = collectGrintaFcmTokens([
        (
          id: 'android-pkg',
          data: {
            'platform': 'android',
            'packageName': 'io.grinta.app',
          },
        ),
        (
          id: 'aser-tok',
          data: {'app': 'aserstein', 'packageName': 'com.tome4.asersteinv2'},
        ),
      ]);
      expect(tokens, ['android-pkg']);
    });

    test('excludes Aserstein packageName even without app field', () {
      final tokens = collectGrintaFcmTokens([
        (
          id: 'bleed-tok',
          data: {'packageName': 'com.tome4.asersteinv2'},
        ),
        (id: 'grinta-tok', data: {'app': 'grinta'}),
      ]);
      expect(tokens, ['grinta-tok']);
    });

    test('prefers data.token and skips raw APNs device tokens', () {
      final apns = 'b' * 64;
      final tokens = collectGrintaFcmTokens([
        (
          id: 'hashed-id',
          data: {'app': 'grinta', 'token': 'ios-fcm-tok'},
        ),
        (id: apns, data: {'app': 'grinta', 'platform': 'ios'}),
      ]);
      expect(tokens, ['ios-fcm-tok']);
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
