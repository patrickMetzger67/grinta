import 'dart:math';

import 'package:grinta/model/shop_ad.dart';
import 'package:grinta/model/team.dart';

/// Resolved targeting flags for the signed-in user / selected member.
///
/// Heuristic (conservative when the data model is ambiguous):
///
/// **Coach** — selected member [Player.isEducatorOrCoach] OR the user
/// manages/owns at least one team (`TRACKER_Owner` kit managers, team
/// `managers` / `owners` / `uid`).
///
/// **Player** — selected member is not a coach-only profile: they are not
/// an educator/coach, **or** they appear on a team roster / Grinta player
/// list (`teamsAsPlayer` / `teamsAsGrintaPlayer`).
///
/// **Team has a tracker kit** when [teamHasTrackerKit] is true:
/// `owners` has any TRACKER_Owner entry ([Team.hasAnyTrackerOwners]) or
/// `withTracker == true`. Empty owners + `withTracker != true` ⇒ no kit.
///
/// **coachWithoutTracker** — coach/manager of **at least one** team that
/// has no tracker kit.
///
/// **playerWithoutTracker** — player on a team without a kit, **or** the
/// player has no individual tracker (wearable connection or individual
/// Intense GPS / TRACKER_Owner claim).
class ShopAdAudience {
  const ShopAdAudience({
    required this.isCoach,
    required this.isPlayer,
    required this.hasManagedTeamWithoutTracker,
    required this.isPlayerOnTeamWithoutTracker,
    required this.hasIndividualTracker,
  });

  final bool isCoach;
  final bool isPlayer;
  final bool hasManagedTeamWithoutTracker;
  final bool isPlayerOnTeamWithoutTracker;
  final bool hasIndividualTracker;

  bool get matchesCoachWithoutTracker =>
      isCoach && hasManagedTeamWithoutTracker;

  bool get matchesPlayerWithoutTracker =>
      isPlayer && (isPlayerOnTeamWithoutTracker || !hasIndividualTracker);
}

/// Builds [ShopAdAudience] from already-resolved session flags.
///
/// [managedTeamsHaveKit] / [memberTeamsHaveKit] are parallel kit flags
/// for each managed / roster team (any season in session cache).
ShopAdAudience resolveShopAdAudience({
  required bool isEducatorOrCoach,
  required List<bool> managedTeamsHaveKit,
  required List<bool> memberTeamsHaveKit,
  required bool hasIndividualTracker,
}) {
  final isCoach = isEducatorOrCoach || managedTeamsHaveKit.isNotEmpty;
  final isPlayer = !isEducatorOrCoach || memberTeamsHaveKit.isNotEmpty;
  return ShopAdAudience(
    isCoach: isCoach,
    isPlayer: isPlayer,
    hasManagedTeamWithoutTracker: managedTeamsHaveKit.any((hasKit) => !hasKit),
    isPlayerOnTeamWithoutTracker: memberTeamsHaveKit.any((hasKit) => !hasKit),
    hasIndividualTracker: hasIndividualTracker,
  );
}

/// Whether [team] is treated as having a GPS / Polar / Intense team kit.
///
/// Conservative: unknown/empty `owners` and `withTracker != true` ⇒ no kit.
/// Raw unparsed owner entries still count via [Team.hasRawOwners].
bool teamHasTrackerKit(Team team) {
  return team.hasAnyTrackerOwners || team.withTracker == true;
}

/// Whether [ad.target] applies to [audience].
///
/// Invalid/unknown targets are not stored on [ShopAd] (they fall back to
/// [ShopAdTarget.all] at parse time).
bool shopAdMatchesTarget(ShopAdTarget target, ShopAdAudience audience) {
  switch (target) {
    case ShopAdTarget.all:
      return true;
    case ShopAdTarget.coach:
      return audience.isCoach;
    case ShopAdTarget.player:
      return audience.isPlayer;
    case ShopAdTarget.coachWithoutTracker:
      return audience.matchesCoachWithoutTracker;
    case ShopAdTarget.playerWithoutTracker:
      return audience.matchesPlayerWithoutTracker;
  }
}

/// Inclusive window: [now] is current when it is on or after [startDate]
/// and on or before [endDate]. A missing bound is open-ended.
bool shopAdIsCurrent({
  DateTime? startDate,
  DateTime? endDate,
  required DateTime now,
}) {
  if (startDate != null && now.isBefore(startDate)) return false;
  if (endDate != null && now.isAfter(endDate)) return false;
  return true;
}

/// Local calendar day as `YYYY-MM-DD`.
String formatShopAdLocalDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? parseShopAdLocalDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

/// True when an ad was already shown on [nowLocal]'s calendar day.
///
/// Prefers `eshopAdsLastShownDate` (`YYYY-MM-DD`). Falls back to the
/// local calendar day of `eshopAdsLastShownAt`.
bool shopAdAlreadyShownOnLocalDay({
  String? lastShownDate,
  DateTime? lastShownAt,
  required DateTime nowLocal,
}) {
  final today = formatShopAdLocalDate(nowLocal);
  final stored = lastShownDate?.trim() ?? '';
  if (stored.isNotEmpty) {
    return stored == today;
  }
  if (lastShownAt != null) {
    return formatShopAdLocalDate(lastShownAt) == today;
  }
  return false;
}

/// Current ads whose [ShopAd.target] matches [audience].
List<ShopAd> selectEligibleShopAds({
  required Iterable<ShopAd> ads,
  required ShopAdAudience audience,
  required DateTime now,
}) {
  return ads.where((ad) {
    if (ad.name.trim().isEmpty || ad.url.trim().isEmpty) return false;
    if (!shopAdIsCurrent(
      startDate: ad.startDate,
      endDate: ad.endDate,
      now: now,
    )) {
      return false;
    }
    return shopAdMatchesTarget(ad.target, audience);
  }).toList(growable: false);
}

/// Picks one element uniformly at random. Null when [items] is empty.
T? pickRandomItem<T>(List<T> items, {Random? random}) {
  if (items.isEmpty) return null;
  final rng = random ?? Random();
  return items[rng.nextInt(items.length)];
}
