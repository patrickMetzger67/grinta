import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/fcm_token.dart';

void main() {
  group('isLikelyApnsDeviceToken', () {
    test('detects 64-char hex APNs tokens', () {
      expect(isLikelyApnsDeviceToken('a' * 64), isTrue);
    });

    test('rejects FCM registration tokens', () {
      expect(
        isLikelyApnsDeviceToken('dXyz:APA91bExampleFcmRegistrationToken'),
        isFalse,
      );
    });
  });

  group('collectGrintaFcmTokens', () {
    test('keeps unbranded iOS next to branded Android and drops aserstein', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-tok', data: {'app': 'grinta', 'platform': 'android'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
        (id: 'aser-tok', data: {'app': 'aserstein'}),
      ]);
      expect(tokens.toSet(), {'android-tok', 'ios-legacy-tok'});
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
    test('is true when any peer uid is present', () {
      expect(
        shouldCallChatPushCloudFunction(peerUserIds: [' u1 ', '']),
        isTrue,
      );
    });

    test('is false when peers are empty', () {
      expect(shouldCallChatPushCloudFunction(peerUserIds: ['', '  ']), isFalse);
    });
  });
}
