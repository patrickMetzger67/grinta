import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/user.dart';
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
    test('on dual-app accounts sends nothing if the Grinta token is missing', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'aser-tok', data: {'app': 'aserstein'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
      ]);
      expect(tokens, isEmpty);
    });

    test('on dual-app accounts keeps only explicit Grinta tokens', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-tok', data: {'app': 'grinta', 'platform': 'android'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
        (id: 'aser-tok', data: {'app': 'aserstein'}),
        (id: 'a' * 64, data: {'app': 'grinta', 'platform': 'ios'}),
      ]);
      expect(tokens, ['android-tok']);
    });

    test('drops unbranded iOS even on Grinta-only accounts', () {
      final tokens = collectGrintaFcmTokens([
        (id: 'android-tok', data: {'app': 'grinta', 'platform': 'android'}),
        (id: 'ios-legacy-tok', data: {'platform': 'ios'}),
        (id: 'a' * 64, data: {'app': 'grinta', 'platform': 'ios'}),
      ]);
      expect(tokens, ['android-tok']);
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

    test('collectAsersteinFcmTokens keeps only AS Erstein devices', () {
      expect(
        collectAsersteinFcmTokens([
          (id: 'g', data: {'app': 'grinta'}),
          (id: 'a', data: {'app': 'aserstein'}),
          (
            id: 'pkg',
            data: {'packageName': 'com.tome4.asersteinv2'},
          ),
        ]),
        ['a', 'pkg'],
      );
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

  group('User.grintaTokens', () {
    test('round-trips a token list through fromMap / toMap', () {
      const fcm = 'dXyZtoken:APA91bFakeFcmRegistrationTokenValueForTests';
      final user = User(
        uid: 'uid-1',
        grintaTokens: <dynamic>[fcm, '  $fcm  '],
      );
      final encoded = user.toMap();
      expect(encoded[keyUserGrintaTokens], [fcm, '  $fcm  ']);

      final parsed = User.fromMap(encoded, uid: 'uid-1');
      expect(parsed.uid, 'uid-1');
      expect(parsed.grintaTokens, [fcm, '  $fcm  ']);
      expect(User.fromMap(const {}).grintaTokens, isNull);
      expect(User(uid: 'x').toMap()[keyUserGrintaTokens], <dynamic>[]);
    });
  });

  group('grintaTokensFromUserMap / resolveGrintaSendTokens', () {
    test('parses sendable tokens and drops APNs hex', () {
      const fcm = 'dXyZtoken:APA91bFakeFcmRegistrationTokenValueForTests';
      expect(
        grintaTokensFromUserMap({
          keyUserGrintaTokens: <dynamic>[fcm, fcm, 'a' * 64, ''],
        }),
        [fcm],
      );
      expect(grintaTokensFromUserMap(const {}), isEmpty);
    });

    test('prefers user.grintaTokens over the subcollection fallback', () {
      expect(
        resolveGrintaSendTokens(
          grintaTokens: <dynamic>[' user-tok ', 'user-tok'],
          subcollectionTokens: const ['sub-tok'],
        ),
        ['user-tok'],
      );
    });

    test('falls back to subcollection tokens when the field is empty', () {
      expect(
        resolveGrintaSendTokens(
          grintaTokens: null,
          subcollectionTokens: const ['grinta-sub'],
        ),
        ['grinta-sub'],
      );
      expect(
        resolveGrintaSendTokens(
          grintaTokens: const <dynamic>[],
          subcollectionTokens: const ['grinta-sub'],
        ),
        ['grinta-sub'],
      );
    });
  });
}
