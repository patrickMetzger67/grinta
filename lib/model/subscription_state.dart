import 'package:grinta/config/subscription_config.dart';

/// Highest active coach tier; `pro` > `elite` > `basic`.
enum CoachTier {
  basic,
  elite,
  pro;

  static CoachTier? fromEntitlementId(String id) {
    switch (id) {
      case SubscriptionEntitlementIds.coachBasic:
        return CoachTier.basic;
      case SubscriptionEntitlementIds.coachElite:
        return CoachTier.elite;
      case SubscriptionEntitlementIds.coachPro:
        return CoachTier.pro;
      default:
        return null;
    }
  }

  String get entitlementId {
    switch (this) {
      case CoachTier.basic:
        return SubscriptionEntitlementIds.coachBasic;
      case CoachTier.elite:
        return SubscriptionEntitlementIds.coachElite;
      case CoachTier.pro:
        return SubscriptionEntitlementIds.coachPro;
    }
  }

  int get rank {
    switch (this) {
      case CoachTier.basic:
        return 1;
      case CoachTier.elite:
        return 2;
      case CoachTier.pro:
        return 3;
    }
  }

  bool satisfies(CoachTier required) => rank >= required.rank;
}

/// Immutable snapshot of the user's subscription status from RevenueCat.
class SubscriptionState {
  const SubscriptionState({
    this.isLoading = false,
    this.isInitialized = false,
    this.activeEntitlements = const <String>{},
    this.coachTier,
    this.hasPlayerSubscription = false,
    this.activeProductId,
    this.billingPeriod,
    this.subscriptionExpiresAt,
    this.managementUrl,
    this.lastError,
  });

  final bool isLoading;
  final bool isInitialized;
  final Set<String> activeEntitlements;
  final CoachTier? coachTier;
  final bool hasPlayerSubscription;
  final String? activeProductId;
  final SubscriptionBillingPeriod? billingPeriod;
  final DateTime? subscriptionExpiresAt;
  final String? managementUrl;
  final String? lastError;

  bool get isSubscribed => activeEntitlements.isNotEmpty;

  bool hasEntitlement(String entitlementId) =>
      activeEntitlements.contains(entitlementId);

  factory SubscriptionState.initial() => const SubscriptionState(isLoading: true);

  factory SubscriptionState.unavailable({String? error}) => SubscriptionState(
        isLoading: false,
        isInitialized: true,
        lastError: error,
      );

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isInitialized,
    Set<String>? activeEntitlements,
    CoachTier? coachTier,
    bool clearCoachTier = false,
    bool? hasPlayerSubscription,
    String? activeProductId,
    bool clearActiveProductId = false,
    SubscriptionBillingPeriod? billingPeriod,
    bool clearBillingPeriod = false,
    DateTime? subscriptionExpiresAt,
    bool clearExpiresAt = false,
    String? managementUrl,
    bool clearManagementUrl = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      activeEntitlements: activeEntitlements ?? this.activeEntitlements,
      coachTier: clearCoachTier ? null : (coachTier ?? this.coachTier),
      hasPlayerSubscription:
          hasPlayerSubscription ?? this.hasPlayerSubscription,
      activeProductId: clearActiveProductId
          ? null
          : (activeProductId ?? this.activeProductId),
      billingPeriod: clearBillingPeriod
          ? null
          : (billingPeriod ?? this.billingPeriod),
      subscriptionExpiresAt: clearExpiresAt
          ? null
          : (subscriptionExpiresAt ?? this.subscriptionExpiresAt),
      managementUrl:
          clearManagementUrl ? null : (managementUrl ?? this.managementUrl),
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}
