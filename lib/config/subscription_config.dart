/// RevenueCat and store product configuration for Grinta subscriptions.
///
/// ## RevenueCat dashboard setup
/// 1. Create a project at https://app.revenuecat.com
/// 2. Add iOS app (bundle id: `io.grinta.app`) and Android app (same package)
/// 3. Connect App Store Connect and Google Play Console
/// 4. Create entitlements (exact identifiers):
///    - `coach_basic`, `coach_elite`, `coach_pro`, `player`
/// 5. Attach store products to each entitlement:
///    - `io.grinta.app.coach.basic.monthly` → coach_basic
///    - `io.grinta.app.coach.elite.monthly` → coach_elite
///    - `io.grinta.app.coach.pro.monthly` → coach_pro
///    - `io.grinta.app.player.monthly` → player
/// 6. Create an Offering (e.g. `default`) with packages mapped to products
/// 7. Copy the public API keys into `--dart-define` at build time (never commit):
///    - `REVENUECAT_IOS_API_KEY`
///    - `REVENUECAT_ANDROID_API_KEY`
///
/// ## Web / Stripe (future)
/// RevenueCat supports Stripe for web. Wire a separate web key when ready;
/// mobile remains the source of truth via CustomerInfo sync on login.
library;

/// App Store / Play Store bundle identifier.
const String kSubscriptionBundleId = 'io.grinta.app';

/// RevenueCat public API keys — pass via `--dart-define`, empty in dev without IAP.
const String kRevenueCatIosApiKey = String.fromEnvironment(
  'REVENUECAT_IOS_API_KEY',
  defaultValue: '',
);

const String kRevenueCatAndroidApiKey = String.fromEnvironment(
  'REVENUECAT_ANDROID_API_KEY',
  defaultValue: '',
);

/// Store product identifiers (must match App Store Connect / Play Console).
abstract final class SubscriptionProductIds {
  static const coachBasicMonthly = 'io.grinta.app.coach.basic.monthly';
  static const coachEliteMonthly = 'io.grinta.app.coach.elite.monthly';
  static const coachProMonthly = 'io.grinta.app.coach.pro.monthly';
  static const playerMonthly = 'io.grinta.app.player.monthly';

  static const all = <String>[
    coachBasicMonthly,
    coachEliteMonthly,
    coachProMonthly,
    playerMonthly,
  ];
}

/// RevenueCat entitlement identifiers (must match dashboard).
abstract final class SubscriptionEntitlementIds {
  static const coachBasic = 'coach_basic';
  static const coachElite = 'coach_elite';
  static const coachPro = 'coach_pro';
  static const player = 'player';

  static const coachTiersOrdered = <String>[
    coachPro,
    coachElite,
    coachBasic,
  ];
}

/// Fallback display prices when RevenueCat offerings are unavailable (dev / web).
abstract final class SubscriptionFallbackPrices {
  static const coachBasic = '9,99 €';
  static const coachElite = '14,99 €';
  static const coachPro = '24,99 €';
  static const player = '2,49 €';
}
