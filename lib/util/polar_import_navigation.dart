import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as match_model;
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/screen/polar_import/polar_import_hub_page.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/polar_session_device_map.dart';
import 'package:grinta/util/polar_tracker_eligibility.dart';

/// Opens the Polar end-of-session import hub for a finished training.
///
/// Returns `true` when the hub was pushed.
Future<bool> openPolarImportHubForTraining(
  BuildContext context, {
  required Training training,
  String? seasonId,
  String source = 'unknown',
}) async {
  final eventId = training.docId?.trim() ?? training.trainingId?.trim() ?? '';
  final ownerId = training.ownerId?.trim() ?? '';
  if (eventId.isEmpty || ownerId.isEmpty) return false;

  final owner = await OwnerService().getOwnerById(ownerId);
  if (owner == null || !ownerUsesPolarTeamKit(owner)) return false;
  if (!context.mounted) return false;

  if (!await _ensureEventSyncNotFullyClosed(context, eventId)) {
    return false;
  }
  if (!context.mounted) return false;

  final resolvedSeasonId = (seasonId ?? training.seasonId)?.trim() ?? '';
  if (resolvedSeasonId.isEmpty) {
    AppSnackbar.show(context, context.l10n.polarImportMissingSeason);
    return false;
  }

  final ownerDevices = await DeviceOwnerService().getByOwnerId(owner.id);
  final ownerDevicesByDocId = {
    for (final od in ownerDevices) od.id: od,
  };

  final devicePlayerMap = await buildPolarTrainingDevicePlayerMap(
    training: training,
    ownerDevicesByDocId: ownerDevicesByDocId,
    seasonId: resolvedSeasonId,
  );
  final trackerIds = devicePlayerMap.keys.toList()
    ..sort((a, b) => a.compareTo(b));

  if (!context.mounted) return false;

  if (trackerIds.isEmpty) {
    AppSnackbar.show(context, context.l10n.syncNoDeviceForTraining);
    return false;
  }

  AnalyticsInteractions.logFeature(
    AnalyticsFeatures.syncTrackerHub,
    parameters: <String, Object>{
      'is_match': false,
      'kit': 'polar',
      'source': source,
    },
  );

  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.polarImportHub,
      builder: (_) => PolarImportHubPage(
        trackerIds: trackerIds,
        eventId: eventId,
        isMatch: false,
        devicePlayerMap: devicePlayerMap,
        ownerId: ownerId,
        eventAt: training.dateTime?.toDate() ?? DateTime.now(),
      ),
    ),
  );
  return true;
}

/// Opens the Polar import hub for a match.
Future<bool> openPolarImportHubForMatch(
  BuildContext context, {
  required match_model.Match match,
  String? seasonId,
  String source = 'unknown',
}) async {
  final eventId = match.id?.trim() ?? '';
  final ownerId = match.ownerId?.trim() ?? '';
  if (eventId.isEmpty || ownerId.isEmpty) return false;

  final owner = await OwnerService().getOwnerById(ownerId);
  if (owner == null || !TrackerOwner.isPolarType(owner.typeTracker)) {
    return false;
  }
  if (!context.mounted) return false;

  if (!await _ensureEventSyncNotFullyClosed(context, eventId)) {
    return false;
  }
  if (!context.mounted) return false;

  final matchCompo =
      await MatchCompoService().getFirstMatchCompoByMatchId(eventId);
  if (matchCompo == null) {
    if (context.mounted) {
      AppSnackbar.show(context, context.l10n.syncNoDeviceForMatch);
    }
    return false;
  }

  final ownerDevices = await DeviceOwnerService().getByOwnerId(owner.id);
  final ownerDevicesByDocId = {
    for (final od in ownerDevices) od.id: od,
  };

  final devicePlayerMap = await buildPolarMatchDevicePlayerMap(
    matchCompo: matchCompo,
    ownerDevicesByDocId: ownerDevicesByDocId,
    seasonId: seasonId ?? match.seasonID,
  );
  final trackerIds = devicePlayerMap.keys.toList()
    ..sort((a, b) => a.compareTo(b));

  if (!context.mounted) return false;
  if (trackerIds.isEmpty) {
    AppSnackbar.show(context, context.l10n.syncNoDeviceForMatch);
    return false;
  }

  AnalyticsInteractions.logFeature(
    AnalyticsFeatures.syncTrackerHub,
    parameters: <String, Object>{
      'is_match': true,
      'kit': 'polar',
      'source': source,
    },
  );

  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.polarImportHub,
      builder: (_) => PolarImportHubPage(
        trackerIds: trackerIds,
        eventId: eventId,
        isMatch: true,
        devicePlayerMap: devicePlayerMap,
        ownerId: ownerId,
        eventAt: match.timestamp?.toDate() ?? DateTime.now(),
      ),
    ),
  );
  return true;
}

Future<bool> _ensureEventSyncNotFullyClosed(
  BuildContext context,
  String eventId,
) async {
  final existing = await EventSyncService().getEventSync(eventId);
  if (existing?.isFullySynced != true) return true;
  if (!context.mounted) return false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.trackerAlreadySyncedTitle),
      content: Text(dialogContext.l10n.trackerAllSensorsSynced),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(dialogContext.l10n.actionOk),
        ),
      ],
    ),
  );
  return false;
}

/// Whether [training] is a Polar kit session still waiting for cardio import.
Future<bool> trainingNeedsPolarImport(Training training) async {
  if (training.withTracker != true) return false;
  if (training.isTrackerDataUploaded == true) return false;
  final finished =
      training.isFinish == true || training.trainingEndAt != null;
  if (!finished) return false;
  return isPolarTrackerOwner(training.ownerId);
}
