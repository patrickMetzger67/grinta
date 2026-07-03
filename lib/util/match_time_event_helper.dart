import 'package:grinta/model/match.dart' as models;
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';

/// After a full-time ([TimeType.end]) highlight is saved, marks the match as
/// played and optionally marks tracker data as uploaded when the linked owner
/// does not sync externally.
Future<void> updateMatchAfterEndTimeEventHighlight({
  required models.Match match,
}) async {
  final matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    return;
  }

  var markTrackerDataUploaded = false;

  if (match.withTracker == true) {
    final ownerId = match.ownerId?.trim() ?? '';
    if (ownerId.isNotEmpty) {
      final owner = await OwnerService().getOwnerById(ownerId);
      if (owner != null && !owner.withSyncing) {
        markTrackerDataUploaded = true;
      }
    }
  }

  await MatchService().markMatchPlayedAfterEndEvent(
    matchId: matchId,
    markTrackerDataUploaded: markTrackerDataUploaded,
  );
}
