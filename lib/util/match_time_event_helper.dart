import 'package:flutter/foundation.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/session_feeling_notification_service.dart';
import 'package:grinta/util/intense_live_eligibility.dart';
import 'package:grinta/util/training_finish_helper.dart';

/// After a full-time ([TimeType.end]) highlight is saved, marks the match as
/// played. Intense cloud owners keep [isTrackerDataUploaded] false until the
/// Insiders finish/resync dialog succeeds.
Future<void> updateMatchAfterEndTimeEventHighlight({
  required models.Match match,
  AppLocalizations? l10n,
}) async {
  final matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    return;
  }

  var markTrackerDataUploaded = false;

  // Intense cloud: do not mark uploaded yet — finish dialog fetches GNSS first.
  final isIntenseCloud = await isIntenseTrackerOwner(match.ownerId);
  if (match.isTrackerDataUploaded == true) {
    markTrackerDataUploaded = true;
  } else if (!isIntenseCloud && match.withTracker != true) {
    markTrackerDataUploaded = false;
  }

  await MatchService().markMatchPlayedAfterEndEvent(
    matchId: matchId,
    markTrackerDataUploaded: markTrackerDataUploaded,
  );

  match.isMatchPlayed = true;
  if (markTrackerDataUploaded) {
    match.isTrackerDataUploaded = true;
  }

  if (!markTrackerDataUploaded) return;

  final resolvedL10n = l10n ??
      (appNavigatorKey.currentContext != null
          ? AppLocalizations.of(appNavigatorKey.currentContext!)
          : null);
  if (resolvedL10n == null) return;

  try {
    await SessionFeelingNotificationService().maybeNotifyAfterMatchSynced(
      match: match,
      l10n: resolvedL10n,
    );
  } catch (e, st) {
    debugPrint('updateMatchAfterEndTimeEventHighlight feeling notif: $e\n$st');
  }
}

/// True when the match calendar slot is over: [Match.timestamp] + [Match.duration]
/// minutes (default 90). Used after Intense re-sync (`withSyncing == false`) to
/// decide whether [isTrackerDataUploaded] can be set.
bool isMatchTheoreticallyFinishedByTimestamp(
  models.Match match, {
  DateTime? now,
}) {
  final start = match.timestamp?.toDate();
  if (start == null) return false;

  final minutes = match.duration ?? 90;
  final end = start.add(Duration(minutes: minutes > 0 ? minutes : 90));
  final clock = now ?? DateTime.now();
  return !clock.isBefore(end);
}

/// After a successful Intense match re-sync: always refresh workload; mark
/// [isTrackerDataUploaded] when the calendar slot ([timestamp]+[duration]) is over.
Future<void> finalizeMatchIntenseResyncSuccess({
  required models.Match match,
  DateTime? now,
}) async {
  final matchId = match.id?.trim() ?? '';
  if (matchId.isEmpty) return;

  if (isMatchTheoreticallyFinishedByTimestamp(match, now: now)) {
    await markMatchTrackerDataUploadedAfterIntenseSync(match: match);
    return;
  }

  await computeTeamWorkloadSummaryForEvent(eventId: matchId);
}

/// Marks tracker data uploaded after a successful Intense match sync.
Future<void> markMatchTrackerDataUploadedAfterIntenseSync({
  required models.Match match,
}) async {
  final matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) return;

  await MatchService().updateTrackerStatus(
    matchId: matchId,
    isTrackerDataUploaded: true,
  );
  match.isTrackerDataUploaded = true;
  match.isMatchPlayed = true;

  await computeTeamWorkloadSummaryForEvent(eventId: matchId);

  final ctx = appNavigatorKey.currentContext;
  if (ctx == null) return;
  final resolvedL10n = AppLocalizations.of(ctx);
  if (resolvedL10n == null) return;

  try {
    await SessionFeelingNotificationService().maybeNotifyAfterMatchSynced(
      match: match,
      l10n: resolvedL10n,
    );
  } catch (e, st) {
    debugPrint('markMatchTrackerDataUploadedAfterIntenseSync: $e\n$st');
  }
}
