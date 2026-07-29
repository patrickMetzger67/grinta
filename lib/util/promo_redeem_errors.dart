/// Pure classification of Firebase Callable errors for promo redemption.
///
/// Kept free of Flutter/Firebase types so unit tests can lock the demo-critical
/// rule: a missing Cloud Function must never surface as "code promo introuvable".
abstract final class PromoRedeemErrors {
  PromoRedeemErrors._();

  /// True when Firebase could not reach [redeemPromoCode] (undeployed / wrong region).
  ///
  /// Must not be shown as "promo code not found" — that message is reserved for
  /// an explicit [PROMO_NOT_FOUND] from the callable itself.
  static bool isCallableMissing({
    required String httpsCode,
    String? message,
    Object? details,
  }) {
    final msg = (message ?? '').trim().toLowerCase();
    final detailsText = details?.toString().toLowerCase() ?? '';
    final combined = '$msg $detailsText';

    if (combined.contains('promo code') && combined.contains('not found')) {
      return false;
    }

    final looksLikeMissingFunction = combined.contains('function') ||
        combined.contains('callable') ||
        combined.contains('does not exist') ||
        combined.contains('was not found') ||
        combined.contains('not been deployed') ||
        combined.contains('404');

    if (httpsCode == 'not-found' && looksLikeMissingFunction) {
      return true;
    }
    if (httpsCode == 'not-found' && !_hasExplicitPromoErrorCode(details)) {
      // Generic Firebase "not-found" without our errorCode usually means the
      // Cloud Function endpoint itself is missing — not the promo document.
      return true;
    }
    return false;
  }

  /// Stable promo error code from callable [details.errorCode], or inferred
  /// from known English server messages.
  static String? extractErrorCode({
    required String httpsCode,
    String? message,
    Object? details,
  }) {
    if (isCallableMissing(
      httpsCode: httpsCode,
      message: message,
      details: details,
    )) {
      return 'PROMO_CALLABLE_MISSING';
    }

    if (details is Map) {
      final raw = details['errorCode']?.toString().trim();
      if (raw != null && raw.isNotEmpty) {
        return raw.toUpperCase();
      }
    }

    final msg = (message ?? '').trim().toLowerCase();
    if (msg.contains('already redeemed')) {
      return 'ALREADY_REDEEMED';
    }
    // Only treat as missing promo when the server message mentions a promo code.
    if (msg.contains('promo code') && msg.contains('not found')) {
      return 'PROMO_NOT_FOUND';
    }
    if (msg.contains('inactive')) {
      return 'PROMO_INACTIVE';
    }
    if (msg.contains('expired')) {
      return 'PROMO_EXPIRED';
    }
    if (msg.contains('exhausted')) {
      return 'PROMO_EXHAUSTED';
    }
    if (msg.contains('restricted to a specific club') ||
        msg.contains('reserved for another club')) {
      return 'PROMO_TEAM_MISMATCH';
    }
    if (msg.contains('authentication required') || msg.contains('signed in')) {
      return 'PROMO_UNAUTHENTICATED';
    }
    if (msg.contains('code is required') || msg.contains('empty')) {
      return 'PROMO_EMPTY';
    }
    if (msg.contains('invalid promo')) {
      return 'PROMO_INVALID';
    }
    // RevenueCat grant failures historically used bare failed-precondition.
    // Never treat those as PROMO_INVALID — the promo code itself may be fine.
    if (msg.contains('revenuecat')) {
      if (msg.contains('not configured') || msg.contains('api_key secret')) {
        return 'PROMO_RC_NOT_CONFIGURED';
      }
      if (msg.contains('api key rejected')) {
        return 'PROMO_RC_KEY_REJECTED';
      }
      if (msg.contains('entitlement') && msg.contains('not found')) {
        return 'PROMO_RC_ENTITLEMENT_MISSING';
      }
      if (msg.contains('grant')) {
        return 'PROMO_GRANT_FAILED';
      }
      return 'PROMO_GRANT_FAILED';
    }
    return null;
  }

  /// UI key: only show "introuvable" when the callable confirmed [PROMO_NOT_FOUND].
  static bool shouldShowNotFoundMessage({
    required String httpsCode,
    String? message,
    Object? details,
  }) {
    return extractErrorCode(
          httpsCode: httpsCode,
          message: message,
          details: details,
        ) ==
        'PROMO_NOT_FOUND';
  }

  /// UI key: only show "n'est plus valide" for an explicit invalid promo payload.
  ///
  /// Bare `failed-precondition` (e.g. RevenueCat secret missing) must never
  /// surface as an invalid code — that repeatedly breaks live demos.
  static bool shouldShowInvalidMessage({
    required String httpsCode,
    String? message,
    Object? details,
  }) {
    return extractErrorCode(
          httpsCode: httpsCode,
          message: message,
          details: details,
        ) ==
        'PROMO_INVALID';
  }

  /// True when the failure is a RevenueCat grant / config issue, not the promo.
  static bool isGrantFailure({
    required String httpsCode,
    String? message,
    Object? details,
  }) {
    final code = extractErrorCode(
      httpsCode: httpsCode,
      message: message,
      details: details,
    );
    return code == 'PROMO_RC_NOT_CONFIGURED' ||
        code == 'PROMO_RC_KEY_REJECTED' ||
        code == 'PROMO_RC_ENTITLEMENT_MISSING' ||
        code == 'PROMO_GRANT_FAILED';
  }

  static bool _hasExplicitPromoErrorCode(Object? details) {
    if (details is! Map) return false;
    final raw = details['errorCode']?.toString().trim() ?? '';
    return raw.isNotEmpty;
  }
}
