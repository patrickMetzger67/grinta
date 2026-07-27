import 'package:grinta/model/tracker/owner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/ownerService.dart';

/// Whether [owner] is a Polar **team kit** owner (`typeTracker == polar`).
///
/// Distinct from Polar AccessLink wearables (`users/{uid}/polarSync/...`).
bool ownerUsesPolarTeamKit(Owner owner) =>
    TrackerOwner.isPolarType(owner.typeTracker);

/// Async check used by agenda / session UI (same pattern as Intense).
Future<bool> isPolarTrackerOwner(String? ownerId) async {
  final id = ownerId?.trim();
  if (id == null || id.isEmpty) return false;

  try {
    final owner = await OwnerService().getOwnerById(id);
    if (owner == null || !owner.isActive) return false;
    return ownerUsesPolarTeamKit(owner);
  } catch (_) {
    return false;
  }
}
