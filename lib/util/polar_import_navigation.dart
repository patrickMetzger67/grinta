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
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/polar_session_device_map.dart';
import 'package:grinta/util/polar_tracker_eligibility.dart';
import 'package:grinta/widget/session_player_analysis_view.dart';
import 'package:grinta/widget/session_tracker_stats_view.dart';

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

String? trainingEventId(Training training) {
  final id = training.docId?.trim() ?? training.trainingId?.trim() ?? '';
  return id.isEmpty ? null : id;
}

bool _trainingFinished(Training training) =>
    training.isFinish == true || training.trainingEndAt != null;

/// Whether Polar cardio analysis can be opened from the agenda card.
///
/// Polar kits do not write GPS `TRACKER_TeamAnalysis` / workload rings, so the
/// card needs an explicit entry point once at least one analysis exists (or
/// sync was closed with [Training.isTrackerDataUploaded]).
Future<bool> trainingHasPolarAnalysis(Training training) async {
  if (training.withTracker != true) return false;
  if (!_trainingFinished(training)) return false;
  if (!await isPolarTrackerOwner(training.ownerId)) return false;

  final eventId = trainingEventId(training);
  if (eventId == null) return false;

  if (training.isTrackerDataUploaded == true) return true;

  final list =
      await PolarSessionAnalysisService().listByEventId(eventId);
  return list.isNotEmpty;
}

/// Whether [playerId] has imported Polar cardio for [training].
Future<bool> trainingHasPolarAnalysisForPlayer(
  Training training, {
  required String playerId,
}) async {
  final pid = playerId.trim();
  if (pid.isEmpty) return false;
  if (training.withTracker != true) return false;
  if (!_trainingFinished(training)) return false;
  if (!await isPolarTrackerOwner(training.ownerId)) return false;

  final eventId = trainingEventId(training);
  if (eventId == null) return false;

  final analysis = await PolarSessionAnalysisService().getForEventPlayer(
    eventId: eventId,
    playerId: pid,
  );
  return analysis != null;
}

/// Opens team Polar cardio analysis for a training (agenda entry point).
Future<void> showPolarTrainingTeamAnalysis(
  BuildContext context, {
  required Training training,
  required String title,
  String? subtitle,
  DateTime? eventDate,
}) async {
  final eventId = trainingEventId(training);
  if (eventId == null) return;

  AnalyticsInteractions.logFeature(
    AnalyticsFeatures.openTrackerStats,
    parameters: const <String, Object>{
      'source': 'agenda_polar_analysis',
      'is_match': false,
      'kit': 'polar',
    },
  );

  final colors = context.appColors;
  final teamId = training.teamId?.trim() ?? '';

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Material(
        color: colors.background,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SizedBox(
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 96),
                          child: Text(
                            context.l10n.polarAnalysisTeamTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.actionClose,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: colors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SessionTrackerStatsView(
                    eventId: eventId,
                    ownerId: training.ownerId,
                    teamId: teamId.isEmpty ? null : teamId,
                    realtime: true,
                    isMatch: false,
                    reportTitle: title,
                    reportSubtitle: subtitle,
                    reportEventDate: eventDate,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Opens player Polar cardio analysis for a training.
Future<void> showPolarTrainingPlayerAnalysis(
  BuildContext context, {
  required Training training,
  required String playerId,
}) async {
  final eventId = trainingEventId(training);
  final pid = playerId.trim();
  if (eventId == null || pid.isEmpty) return;

  AnalyticsInteractions.logFeature(
    AnalyticsFeatures.openPlayerAnalysis,
    parameters: const <String, Object>{
      'source': 'agenda_polar_analysis',
      'is_match': false,
      'kit': 'polar',
    },
  );

  final player = await PlayerService().getPlayerById(pid);
  if (!context.mounted) return;

  final colors = context.appColors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: colors.background,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.polarAnalysisTeamTitle,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              Expanded(
                child: SessionPlayerAnalysisView(
                  eventId: eventId,
                  ownerId: training.ownerId,
                  playerId: pid,
                  teamId: training.teamId,
                  player: player,
                  isMatch: false,
                  showHeader: false,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
