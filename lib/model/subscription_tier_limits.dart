import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';

/// Identifies which limit profile applies (RevenueCat entitlements + trial).
enum SubscriptionLimitsTier {
  coachBasic,
  coachElite,
  coachPro,
  player,
  trial,
}

/// Remote-adjustable caps for a subscription profile.
class SubscriptionTierLimits {
  const SubscriptionTierLimits({
    required this.maxTeams,
    required this.maxPlayersPerTeam,
    this.maxProfiles = 1,
    this.allowOnlySelfAsPlayer = false,
  });

  final int maxTeams;
  final int maxPlayersPerTeam;

  /// Maximum member profiles linked to one Firebase account.
  final int maxProfiles;

  /// When true, roster additions are limited to the subscriber's own player profile.
  final bool allowOnlySelfAsPlayer;

  factory SubscriptionTierLimits.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      throw ArgumentError('empty map');
    }
    return SubscriptionTierLimits(
      maxTeams: _readInt(map['maxTeams'], fallback: 0),
      maxPlayersPerTeam: _readInt(map['maxPlayersPerTeam'], fallback: 0),
      maxProfiles: _readInt(map['maxProfiles'], fallback: 1),
      allowOnlySelfAsPlayer: map['allowOnlySelfAsPlayer'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'maxTeams': maxTeams,
        'maxPlayersPerTeam': maxPlayersPerTeam,
        'maxProfiles': maxProfiles,
        if (allowOnlySelfAsPlayer) 'allowOnlySelfAsPlayer': true,
      };

  static int _readInt(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }
}

/// Built-in defaults matching product specs (used when Firestore doc is missing).
abstract final class SubscriptionTierLimitsDefaults {
  static const coachBasic = SubscriptionTierLimits(
    maxTeams: 1,
    maxPlayersPerTeam: 20,
    maxProfiles: 1,
  );

  static const coachElite = SubscriptionTierLimits(
    maxTeams: 3,
    maxPlayersPerTeam: 22,
    maxProfiles: 3,
  );

  static const coachPro = SubscriptionTierLimits(
    maxTeams: 5,
    maxPlayersPerTeam: 25,
    maxProfiles: 3,
  );

  static const player = SubscriptionTierLimits(
    maxTeams: 3,
    maxPlayersPerTeam: 1,
    maxProfiles: 3,
    allowOnlySelfAsPlayer: true,
  );

  /// Free accounts without a paid subscription (implicit first profile only).
  static const int maxProfilesFreePlayer = 1;

  /// Free player accounts without a paid subscription (one owned team).
  static const int maxTeamsFreePlayer = 1;

  /// Trial users get Basic coach caps.
  static const trial = coachBasic;

  static Map<SubscriptionLimitsTier, SubscriptionTierLimits> all() => {
        SubscriptionLimitsTier.coachBasic: coachBasic,
        SubscriptionLimitsTier.coachElite: coachElite,
        SubscriptionLimitsTier.coachPro: coachPro,
        SubscriptionLimitsTier.player: player,
        SubscriptionLimitsTier.trial: trial,
      };

  static String firestoreKeyFor(SubscriptionLimitsTier tier) {
    switch (tier) {
      case SubscriptionLimitsTier.coachBasic:
        return SubscriptionEntitlementIds.coachBasic;
      case SubscriptionLimitsTier.coachElite:
        return SubscriptionEntitlementIds.coachElite;
      case SubscriptionLimitsTier.coachPro:
        return SubscriptionEntitlementIds.coachPro;
      case SubscriptionLimitsTier.player:
        return SubscriptionEntitlementIds.player;
      case SubscriptionLimitsTier.trial:
        return 'trial';
    }
  }

  static SubscriptionLimitsTier? tierFromFirestoreKey(String key) {
    switch (key) {
      case SubscriptionEntitlementIds.coachBasic:
        return SubscriptionLimitsTier.coachBasic;
      case SubscriptionEntitlementIds.coachElite:
        return SubscriptionLimitsTier.coachElite;
      case SubscriptionEntitlementIds.coachPro:
        return SubscriptionLimitsTier.coachPro;
      case SubscriptionEntitlementIds.player:
        return SubscriptionLimitsTier.player;
      case 'trial':
        return SubscriptionLimitsTier.trial;
      default:
        return null;
    }
  }

  static SubscriptionLimitsTier fromCoachTier(CoachTier tier) {
    switch (tier) {
      case CoachTier.basic:
        return SubscriptionLimitsTier.coachBasic;
      case CoachTier.elite:
        return SubscriptionLimitsTier.coachElite;
      case CoachTier.pro:
        return SubscriptionLimitsTier.coachPro;
    }
  }
}

enum SubscriptionLimitViolation {
  maxTeams,
  maxPlayersPerTeam,
  maxProfiles,
  playerTierOnlySelf,
}

/// Whether the user can create another team right now.
enum TeamCreationGate {
  /// Under the tier cap — open the create-team flow.
  allowed,

  /// At cap but a paid subscription unlocks more teams.
  needsUpgrade,

  /// At the maximum allowed for the current subscription tier.
  atMaxLimit,
}

/// Whether the user can create another member profile right now.
enum ProfileCreationGate {
  /// Under the tier cap — open the create-profile flow.
  allowed,

  /// At cap but a higher subscription unlocks more profiles.
  needsUpgrade,

  /// At the maximum allowed for the current subscription tier.
  atMaxLimit,
}

/// Thrown when a subscription cap blocks team or roster changes.
class SubscriptionLimitExceeded implements Exception {
  const SubscriptionLimitExceeded({
    required this.violation,
    required this.tier,
    this.limit,
    this.requiresUpgrade = false,
  });

  final SubscriptionLimitViolation violation;
  final SubscriptionLimitsTier tier;
  final int? limit;
  final bool requiresUpgrade;

  @override
  String toString() =>
      'SubscriptionLimitExceeded(violation=$violation, tier=$tier, limit=$limit)';
}
