import 'package:firebase_auth/firebase_auth.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/shop_ad_logic.dart';

/// Builds [ShopAdAudience] from [AppSession] + wearable / Intense GPS docs.
class ShopAdAudienceResolver {
  ShopAdAudienceResolver({
    WearableDevicesRepository? wearableRepository,
  }) : _wearableRepository =
            wearableRepository ?? WearableDevicesRepository();

  final WearableDevicesRepository _wearableRepository;

  Future<ShopAdAudience> resolve(AppSession session) async {
    final player = session.selectedPlayer;
    final isEducatorOrCoach = player?.isEducatorOrCoach == true;
    final managedKits =
        session.allManagedTeams.map(teamHasTrackerKit).toList(growable: false);
    final memberKits =
        session.allMemberTeams.map(teamHasTrackerKit).toList(growable: false);

    final uid = session.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    final playerId = player != null
        ? (effectiveMemberId(player) ?? session.selectedPlayerId)
        : session.selectedPlayerId;
    var hasIndividualTracker = false;
    if (uid != null &&
        uid.isNotEmpty &&
        playerId != null &&
        playerId.isNotEmpty) {
      try {
        hasIndividualTracker =
            await _wearableRepository.hasAnyConnected(uid, playerId);
      } catch (_) {
        hasIndividualTracker = false;
      }
    }

    return resolveShopAdAudience(
      isEducatorOrCoach: isEducatorOrCoach,
      managedTeamsHaveKit: managedKits,
      memberTeamsHaveKit: memberKits,
      hasIndividualTracker: hasIndividualTracker,
    );
  }
}
