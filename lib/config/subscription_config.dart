/// RevenueCat and store product configuration for Grinta subscriptions.
///
/// ## Environnements (debug vs release)
/// - **Debug / profile** (`kReleaseMode == false`) → [SubscriptionEnvironment.sandbox]
///   (App Store sandbox, Google Play test, RevenueCat Web Billing sandbox `rcb_sb_*`,
///   Stripe test via le dashboard RevenueCat)
/// - **Release** (`kReleaseMode == true`) → [SubscriptionEnvironment.production]
///
/// ## RevenueCat + Stripe (web)
/// Les abonnés web **apparaissent dans RevenueCat** lorsque le checkout passe par
/// **RevenueCat Web Billing** (Stripe connecté dans le dashboard RC). Un même
/// `appUserId` (Firebase UID via `Purchases.logIn`) unifie web et mobile ;
/// les entitlements (`coach_basic`, etc.) sont partagés.
///
/// Pas besoin d'intégrer le SDK Stripe côté Flutter : `purchasePackage` ouvre le
/// checkout hébergé par RevenueCat. Stripe (clés secrètes, webhooks) se configure
/// uniquement dans RevenueCat / Stripe Dashboard.
///
/// ## RevenueCat dashboard — mobile (iOS / Android)
/// 1. Projet sur https://app.revenuecat.com
/// 2. Apps iOS (`io.grinta.app`) et Android (même package)
/// 3. Lier App Store Connect et Google Play Console
/// 4. Entitlements : `coach_basic`, `coach_elite`, `coach_pro`, `player`, `player_gps`
/// 5. Produits store (mensuel / annuel) mappés aux entitlements
/// 6. Offering (ex. `default`) avec packages
/// 7. Clés publiques iOS (`appl_…`) et Android (`goog_…`) → `dart_defines.json`
///
/// Sandbox mobile : **même clé API** que la prod ; le sandbox est géré par les
/// comptes test Apple / Google, pas par une seconde clé RC.
///
/// ## RevenueCat dashboard — web (Stripe)
/// 1. Project Settings → connecter le compte Stripe (test + live)
/// 2. Web → créer une config **Web Billing** (sandbox `rcb_sb_*`, prod `rcb_*`)
/// 3. Produits web + offerings (séparés des produits App Store / Play)
/// 4. Même entitlements que mobile pour l'accès cross-platform
/// 5. Clés Web Billing → `REVENUECAT_WEB_API_KEY_SANDBOX` / `_PROD`
///
/// ## Clés à fournir (dans `dart_defines.json`, jamais commité)
/// | Clé | Où la trouver |
/// |-----|----------------|
/// | `REVENUECAT_IOS_API_KEY_*` | RC → Project → iOS app → API keys |
/// | `REVENUECAT_ANDROID_API_KEY_*` | RC → Project → Android app → API keys (**required for Android builds**; placeholder `goog_xxx` disables RC) |
/// | `REVENUECAT_WEB_API_KEY_*` | RC → Web Billing → API keys (`rcb_sb_` / `rcb_`) |
/// | `STRIPE_PUBLISHABLE_KEY_*` | Optionnel si checkout 100 % RC ; sinon Stripe Dashboard |
///
/// Les clés `*_SANDBOX` / `*_PROD` remplacent les anciennes `REVENUECAT_*_API_KEY`
/// (rétrocompatibles en secours).
///
/// **Lancer mobile avec les clés** : `flutter run --dart-define-from-file=dart_defines.json`
/// ou `./scripts/run_with_defines.sh`. Sans ce flag, les clés sont vides et RevenueCat
/// ne s'initialise pas — les abonnements web (Stripe) ne seront pas détectés sur iOS/Android.
///
/// **Cross-platform** : web (Stripe via RC Web Billing) et mobile partagent les entitlements
/// quand `Purchases.logIn(firebaseUid)` utilise le même UID Firebase et le même projet RC.
/// Le simulateur iOS récupère aussi les entitlements web (pas besoin d'achat App Store local).
library;

import 'package:flutter/foundation.dart';
import 'package:grinta/model/notification.dart';
import 'package:grinta/services/eshop_config_service.dart';

/// Billing period for subscription purchases.
enum SubscriptionBillingPeriod {
  monthly,
  yearly,
}

/// Build-time subscription environment derived from Flutter build mode.
enum SubscriptionEnvironment {
  /// Debug/profile — sandbox stores, Web Billing sandbox, Stripe test.
  sandbox,

  /// Release — production stores, Web Billing live, Stripe live.
  production;

  static SubscriptionEnvironment get current =>
      kReleaseMode ? production : sandbox;

  bool get isSandbox => this == sandbox;
  bool get isProduction => this == production;
}

String _firstNonEmpty(String a, String b, String c) {
  if (a.isNotEmpty) return a;
  if (b.isNotEmpty) return b;
  return c;
}

/// True when [key] looks like a real RevenueCat public API key (not empty/placeholder).
bool isRevenueCatApiKeyConfigured(String key, {required String requiredPrefix}) {
  if (key.isEmpty) return false;
  if (!key.startsWith(requiredPrefix)) return false;
  if (RegExp(r'x{4,}', caseSensitive: false).hasMatch(key)) return false;
  if (key.length < 16) return false;
  return true;
}

/// iOS / macOS RevenueCat public API key present and not a template placeholder.
bool get isRevenueCatIosApiKeyConfigured => isRevenueCatApiKeyConfigured(
      revenueCatIosApiKey,
      requiredPrefix: 'appl_',
    );

/// Android RevenueCat public API key present and not a template placeholder.
bool get isRevenueCatAndroidApiKeyConfigured => isRevenueCatApiKeyConfigured(
      revenueCatAndroidApiKey,
      requiredPrefix: 'goog_',
    );

/// Web Billing public API key present (`rcb_sb_*` sandbox or `rcb_*` production).
bool get isRevenueCatWebApiKeyConfigured {
  final key = revenueCatWebApiKey;
  if (key.isEmpty) return false;
  if (!key.startsWith('rcb_')) return false;
  if (RegExp(r'x{4,}', caseSensitive: false).hasMatch(key)) return false;
  return key.length >= 16;
}

/// RevenueCat iOS public API key for the current [SubscriptionEnvironment].
String get revenueCatIosApiKey {
  const sandbox = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY_SANDBOX',
    defaultValue: '',
  );
  const prod = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY_PROD',
    defaultValue: '',
  );
  const legacy = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );
  return SubscriptionEnvironment.current.isSandbox
      ? _firstNonEmpty(sandbox, legacy, prod)
      : _firstNonEmpty(prod, legacy, sandbox);
}

/// RevenueCat Android public API key for the current [SubscriptionEnvironment].
String get revenueCatAndroidApiKey {
  const sandbox = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY_SANDBOX',
    defaultValue: '',
  );
  const prod = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY_PROD',
    defaultValue: '',
  );
  const legacy = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );
  return SubscriptionEnvironment.current.isSandbox
      ? _firstNonEmpty(sandbox, legacy, prod)
      : _firstNonEmpty(prod, legacy, sandbox);
}

/// RevenueCat Web Billing public API key for the current [SubscriptionEnvironment].
///
/// Sandbox keys start with `rcb_sb_`, production with `rcb_`.
String get revenueCatWebApiKey {
  const sandbox = String.fromEnvironment(
    'REVENUECAT_WEB_API_KEY_SANDBOX',
    defaultValue: '',
  );
  const prod = String.fromEnvironment(
    'REVENUECAT_WEB_API_KEY_PROD',
    defaultValue: '',
  );
  const legacy = String.fromEnvironment(
    'REVENUECAT_WEB_API_KEY',
    defaultValue: '',
  );
  return SubscriptionEnvironment.current.isSandbox
      ? _firstNonEmpty(sandbox, legacy, prod)
      : _firstNonEmpty(prod, legacy, sandbox);
}

/// Stripe publishable key — only needed for a custom Stripe Checkout outside RC.
///
/// With RevenueCat Web Billing, leave empty; Stripe is configured in RC dashboard.
String get stripePublishableKey {
  if (SubscriptionEnvironment.current.isSandbox) {
    return const String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY_TEST',
      defaultValue: '',
    );
  }
  return const String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY_LIVE',
    defaultValue: '',
  );
}

@Deprecated('Use revenueCatIosApiKey')
const String kRevenueCatIosApiKey = String.fromEnvironment(
  'REVENUECAT_IOS_API_KEY',
  defaultValue: '',
);

@Deprecated('Use revenueCatAndroidApiKey')
const String kRevenueCatAndroidApiKey = String.fromEnvironment(
  'REVENUECAT_ANDROID_API_KEY',
  defaultValue: '',
);

/// App Store / Play Store bundle identifier.
const String kSubscriptionBundleId = 'io.grinta.app';

/// Store product identifiers (must match App Store Connect / Play Console).
abstract final class SubscriptionProductIds {
  static const coachBasicMonthly = 'io.grinta.app.coach.basic.monthly';
  static const coachEliteMonthly = 'io.grinta.app.coach.elite.monthly';
  static const coachProMonthly = 'io.grinta.app.coach.pro.monthly';
  static const playerMonthly = 'io.grinta.app.player.monthly';
  static const playerGpsMonthly = 'io.grinta.app.playerGPS.monthly';

  static const coachBasicYearly = 'io.grinta.app.coach.basic.yearly';
  static const coachEliteYearly = 'io.grinta.app.coach.elite.yearly';
  static const coachProYearly = 'io.grinta.app.coach.pro.yearly';
  static const playerYearly = 'io.grinta.app.player.yearly';
  static const playerGpsYearly = 'io.grinta.app.playerGPS.yearly';

  static const monthly = <String>[
    coachBasicMonthly,
    coachEliteMonthly,
    coachProMonthly,
    playerMonthly,
    playerGpsMonthly,
  ];

  static const yearly = <String>[
    coachBasicYearly,
    coachEliteYearly,
    coachProYearly,
    playerYearly,
    playerGpsYearly,
  ];

  static const all = <String>[
    ...monthly,
    ...yearly,
  ];
}

/// Cross-platform product lookup helpers (App Store / Play vs RevenueCat Web Billing).
abstract final class SubscriptionProductLookup {
  static String normalizeProductId(String id) {
    return id
        .toLowerCase()
        .replaceAll(RegExp(r'^prod_'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Whether [configuredId] (from [SubscriptionProductIds]) matches a RevenueCat
  /// [storeId] from offerings (exact, normalized, or semantic tier + period).
  static bool identifiersMatch(String configuredId, String storeId) {
    if (configuredId == storeId) return true;
    if (normalizeProductId(configuredId) == normalizeProductId(storeId)) {
      return true;
    }
    final configuredKey = semanticKey(configuredId);
    final storeKey = semanticKey(storeId);
    return configuredKey != null &&
        storeKey != null &&
        configuredKey == storeKey;
  }

  /// Stable key for tier + billing period, independent of store / Stripe naming.
  static String? semanticKey(String productId) {
    final normalized = normalizeProductId(productId);
    final tier = _tierFromNormalized(normalized);
    if (tier == null) return null;
    final yearly = normalized.contains('yearly') ||
        normalized.contains('annual') ||
        normalized.contains('year');
    final monthly = normalized.contains('monthly') || normalized.contains('month');
    if (yearly) return '${tier}_yearly';
    if (monthly) return '${tier}_monthly';
    return null;
  }

  static String? _tierFromNormalized(String normalized) {
    if (normalized.contains('coachpro') || normalized.contains('procoach')) {
      return 'coach_pro';
    }
    if (normalized.contains('coachelite') || normalized.contains('elitecoach')) {
      return 'coach_elite';
    }
    if (normalized.contains('coachbasic') || normalized.contains('basiccoach')) {
      return 'coach_basic';
    }
    // Check player GPS before generic `player` — `playergps` contains `player`.
    if (normalized.contains('playergps') || normalized.contains('gpsplayer')) {
      return 'player_gps';
    }
    if (normalized.contains('player')) return 'player';
    return null;
  }

  static String? entitlementIdForProduct(String productId) {
    return switch (semanticKey(productId)) {
      'coach_basic_monthly' || 'coach_basic_yearly' =>
        SubscriptionEntitlementIds.coachBasic,
      'coach_elite_monthly' || 'coach_elite_yearly' =>
        SubscriptionEntitlementIds.coachElite,
      'coach_pro_monthly' || 'coach_pro_yearly' =>
        SubscriptionEntitlementIds.coachPro,
      'player_monthly' || 'player_yearly' => SubscriptionEntitlementIds.player,
      'player_gps_monthly' || 'player_gps_yearly' =>
        SubscriptionEntitlementIds.playerGps,
      _ => null,
    };
  }

  static bool isYearlyProduct(String productId) {
    final key = semanticKey(productId);
    return key != null && key.endsWith('_yearly');
  }

  static bool isMonthlyProduct(String productId) {
    final key = semanticKey(productId);
    return key != null && key.endsWith('_monthly');
  }
}

/// RevenueCat entitlement identifiers (must match dashboard).
abstract final class SubscriptionEntitlementIds {
  static const coachBasic = 'coach_basic';
  static const coachElite = 'coach_elite';
  static const coachPro = 'coach_pro';
  static const player = 'player';
  static const playerGps = 'player_gps';

  static const coachTiersOrdered = <String>[
    coachPro,
    coachElite,
    coachBasic,
  ];

  static const all = <String>[
    ...coachTiersOrdered,
    playerGps,
    player,
  ];

  /// RevenueCat dashboard IDs that should unlock Joueur GPS.
  static const playerGpsAliases = <String>{
    playerGps,
    'playerGPS',
    'playerGps',
  };

  static bool isKnown(String entitlementId) => all.contains(entitlementId);

  static bool hasPlayerGpsEntitlement(Set<String> entitlements) =>
      entitlements.any(playerGpsAliases.contains);

  static Set<String> canonicalize(Set<String> entitlements) {
    if (!hasPlayerGpsEntitlement(entitlements) ||
        entitlements.contains(playerGps)) {
      return entitlements;
    }
    return {...entitlements, playerGps};
  }

  static bool grantsPlayerAccess(Set<String> entitlements) =>
      entitlements.contains(player) || hasPlayerGpsEntitlement(entitlements);

  /// Whether [entitlements] allow using own Intense GPS after sensor setup.
  ///
  /// Coach-initiated flows stay available. Players need `player_gps` (or root)
  /// when syncing personal GPS — claiming a serial in settings does not use this.
  static bool grantsOwnIntenseGpsAccess({
    required Set<String> entitlements,
    required bool isRoot,
    String initiatedBy = 'player',
  }) {
    if (isRoot) return true;
    if (initiatedBy == 'coach') return true;
    return hasPlayerGpsEntitlement(entitlements);
  }
}

/// FCM / local reminder payload `type` values gated by
/// [EshopConfigService.commerceNotificationsEnabled].
bool isCommerceNotificationPayloadType(String? type) {
  if (type == null || type.isEmpty) return false;
  switch (type) {
    case 'payment':
    case 'shop':
    case 'shopPromo':
    case 'boutique':
    case 'commerce':
    case 'subscription':
    case 'subscriptionPromo':
    case 'trialReminder':
    case 'trialExpiring':
    case 'paywall':
      return true;
    default:
      return false;
  }
}

/// In-app [NotifType] values gated by
/// [EshopConfigService.commerceNotificationsEnabled].
bool isCommerceNotifType(NotifType type) => type == NotifType.payment;

/// Hides commerce in-app notifications when commerce notifications are disabled.
List<NotificationApp> filterCommerceNotifications(
  List<NotificationApp> notifications,
) {
  if (EshopConfigService.instance.commerceNotificationsEnabled) {
    return notifications;
  }
  return notifications
      .where(
        (notification) =>
            notification.type == null ||
            !isCommerceNotifType(notification.type!),
      )
      .toList();
}

/// Fallback display prices when RevenueCat offerings are unavailable (dev / web).
abstract final class SubscriptionFallbackPrices {
  static const coachBasic = '9,99 €';
  static const coachElite = '14,99 €';
  static const coachPro = '24,99 €';
  static const player = '2,49 €';
  static const playerGps = '19,99 €';

  /// Annual list prices (marketing: 2 months free vs monthly × 12).
  static const coachBasicYearly = '99,99 €';
  static const coachEliteYearly = '149,99 €';
  static const coachProYearly = '249,99 €';
  static const playerYearly = '24,99 €';
  static const playerGpsYearly = '199,99 €';
}
