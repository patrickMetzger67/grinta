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
  });
}
