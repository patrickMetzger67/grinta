import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/promo_code.dart';
import 'package:grinta/util/promo_redeem_errors.dart';

void main() {
  group('PromoCode.compactCode', () {
    test('strips separators for DEMO-style codes', () {
      expect(PromoCode.compactCode('DEMO-2026'), 'DEMO2026');
      expect(PromoCode.compactCode(' demo_2026 '), 'DEMO2026');
      expect(PromoCode.normalizeCode('demo 2026'), 'DEMO2026');
    });

    test('strips leading hash from tag-icon UX', () {
      expect(PromoCode.normalizeCode('# JOUEURGPS'), 'JOUEURGPS');
      expect(PromoCode.normalizeCode('#JOUEURGPS'), 'JOUEURGPS');
      expect(PromoCode.compactCode('# joueur-gps'), 'JOUEURGPS');
    });
  });

  group('PromoRedeemErrors — demo regression guards', () {
    test('generic not-found (missing CF) is NOT promo-not-found', () {
      expect(
        PromoRedeemErrors.isCallableMissing(
          httpsCode: 'not-found',
          message: 'NOT_FOUND',
        ),
        isTrue,
      );
      expect(
        PromoRedeemErrors.extractErrorCode(
          httpsCode: 'not-found',
          message: 'NOT_FOUND',
        ),
        'PROMO_CALLABLE_MISSING',
      );
      expect(
        PromoRedeemErrors.shouldShowNotFoundMessage(
          httpsCode: 'not-found',
          message: 'NOT_FOUND',
        ),
        isFalse,
      );
    });

    test('explicit PROMO_NOT_FOUND still shows introuvable', () {
      expect(
        PromoRedeemErrors.isCallableMissing(
          httpsCode: 'not-found',
          message: 'Promo code "DEMO2026" not found.',
          details: {'errorCode': 'PROMO_NOT_FOUND'},
        ),
        isFalse,
      );
      expect(
        PromoRedeemErrors.shouldShowNotFoundMessage(
          httpsCode: 'not-found',
          message: 'Promo code "DEMO2026" not found.',
          details: {'errorCode': 'PROMO_NOT_FOUND'},
        ),
        isTrue,
      );
    });

    test('function missing message never maps to introuvable', () {
      expect(
        PromoRedeemErrors.shouldShowNotFoundMessage(
          httpsCode: 'not-found',
          message: 'NOT FOUND: Requested entity was not found.',
          details: 'cloud function does not exist',
        ),
        isFalse,
      );
    });

    test('already redeemed is detected from message', () {
      expect(
        PromoRedeemErrors.extractErrorCode(
          httpsCode: 'failed-precondition',
          message: 'You have already redeemed this promo code.',
        ),
        'ALREADY_REDEEMED',
      );
    });

    test('bare failed-precondition is NOT invalid promo', () {
      expect(
        PromoRedeemErrors.shouldShowInvalidMessage(
          httpsCode: 'failed-precondition',
          message: 'REVENUECAT_API_KEY secret is not configured.',
        ),
        isFalse,
      );
      expect(
        PromoRedeemErrors.isGrantFailure(
          httpsCode: 'failed-precondition',
          message: 'REVENUECAT_API_KEY secret is not configured.',
        ),
        isTrue,
      );
      expect(
        PromoRedeemErrors.extractErrorCode(
          httpsCode: 'failed-precondition',
          message: 'RevenueCat API key rejected (401).',
          details: {'errorCode': 'PROMO_RC_KEY_REJECTED'},
        ),
        'PROMO_RC_KEY_REJECTED',
      );
    });

    test('explicit PROMO_INVALID still shows invalid', () {
      expect(
        PromoRedeemErrors.shouldShowInvalidMessage(
          httpsCode: 'failed-precondition',
          message: 'Invalid promo entitlement.',
          details: {'errorCode': 'PROMO_INVALID'},
        ),
        isTrue,
      );
    });
  });
}
