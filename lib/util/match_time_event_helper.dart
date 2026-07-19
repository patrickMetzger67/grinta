import 'package:flutter/foundation.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/session_feeling_notification_service.dart';

/// After a full-time ([TimeType.end]) highlight is saved, marks the match as
/// played and optionally marks tracker data as uploaded when the linked owner
/// does not sync externally.
Future<void> updateMatchAfterEndTimeEventHighlight({
  required models.Match match,
  AppLocalizations? l10n,
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

  // If USB sync already happened before full-time, keep uploaded = true.
  if (match.isTrackerDataUploaded == true) {
    markTrackerDataUploaded = true;
  }

  await MatchService().markMatchPlayedAfterEndEvent(
    matchId: matchId,
    markTrackerDataUploaded: markTrackerDataUploaded,
  );

  if (!markTrackerDataUploaded) return;

  final resolvedL10n = l10n ??
      (appNavigatorKey.currentContext != null
          ? AppLocalizations.of(appNavigatorKey.currentContext!)
          : null);
  if (resolvedL10n == null) return;

  try {
    match.isMatchPlayed = true;
    match.isTrackerDataUploaded = true;
    await SessionFeelingNotificationService().maybeNotifyAfterMatchSynced(
      match: match,
      l10n: resolvedL10n,
    );
  } catch (e, st) {
    debugPrint('updateMatchAfterEndTimeEventHighlight feeling notif: $e\n$st');
  }
}
