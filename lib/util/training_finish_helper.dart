import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/session_feeling_notification_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/training_intense_finish_dialog.dart';

import '../model/training.dart';

bool isPresentOrDefaultPresence(PresenceType? presenceType) {
  return presenceType == null || presenceType == PresenceType.present;
}

bool isTrainingFinished(Training training) {
  return training.isFinish == true || training.trainingEndAt != null;
}

/// Aggregates per-player [TRACKER_Analysis] docs into [TRACKER_TeamAnalysis].
///
/// Mirrors [TrackerHubPage._confirmCloseSync] after manual USB sync.
Future<void> computeTeamWorkloadSummaryForEvent({
  required String eventId,
  Training? training,
}) async {
  final analyses =
      await TrackerAnalysisService.getAnalysesByEvent(eventId);
  if (analyses.isEmpty) return;

  Duration? sessionDuration;
  if (training != null) {
    final durationMinutes = training.duration;
    if (durationMinutes != null && durationMinutes > 0) {
      sessionDuration = Duration(minutes: durationMinutes);
    } else if (training.trainingStartAt != null &&
        training.trainingEndAt != null) {
      sessionDuration = training.trainingEndAt!
          .toDate()
          .difference(training.trainingStartAt!.toDate());
    }
  }

  await TeamWorkloadSummaryService().computeAndSave(
    eventId: eventId,
    playerResults: analyses,
    sessionDuration: sessionDuration,
  );
}

/// Post-finish processing (feeling notifications when sync is already done).
Future<void> onTrainingFinishedProcessing({
  required Training training,
  AppLocalizations? l10n,
}) async {
  final resolvedL10n = l10n ??
      (appNavigatorKey.currentContext != null
          ? AppLocalizations.of(appNavigatorKey.currentContext!)
          : null);
  if (resolvedL10n == null) {
    debugPrint(
      'onTrainingFinishedProcessing: missing l10n, skip feeling notifications',
    );
    return;
  }

  try {
    await SessionFeelingNotificationService().maybeNotifyAfterTrainingSynced(
      training: training,
      l10n: resolvedL10n,
    );
  } catch (e, st) {
    debugPrint('onTrainingFinishedProcessing feeling notif failed: $e\n$st');
  }
}

/// After a manager finishes a training, sets [trainingEndAt] and optionally
/// marks tracker data as uploaded when the linked owner does not sync
/// externally.
///
/// Presence choices (including during an unavailability window) are kept as
/// set by the manager — finish does not force unavailable players to absent.
Future<void> finishTrainingAfterConfirm({
  required Training training,
  bool? markTrackerDataUploaded,
  bool aggregateTeamWorkload = false,
}) async {
  final trainingId = training.docId?.trim() ?? training.trainingId?.trim();
  if (trainingId == null || trainingId.isEmpty) {
    return;
  }

  final fresh = await TrainingService().getTrainingById(trainingId);
  if (fresh == null) {
    throw StateError('Training not found');
  }

  final updatedPlayerTraining =
      List<PlayerTraining>.from(fresh.playerTraining);

  var trackerDataUploaded = markTrackerDataUploaded;
  if (trackerDataUploaded == null && fresh.withTracker) {
    final ownerId = fresh.ownerId?.trim() ?? '';
    if (ownerId.isNotEmpty) {
      final owner = await OwnerService().getOwnerById(ownerId);
      if (owner != null && !owner.withSyncing) {
        trackerDataUploaded = true;
      }
    }
  }

  if (aggregateTeamWorkload) {
    await computeTeamWorkloadSummaryForEvent(
      eventId: trainingId,
      training: fresh,
    );
  }

  await TrainingService().markTrainingFinished(
    trainingId: trainingId,
    playerTraining: updatedPlayerTraining,
    trainingEndAt: Timestamp.now(),
    markTrackerDataUploaded: trackerDataUploaded == true,
  );

  fresh.isFinish = true;
  fresh.trainingEndAt = Timestamp.now();
  fresh.playerTraining = updatedPlayerTraining;
  if (trackerDataUploaded == true) {
    fresh.isTrackerDataUploaded = true;
  }
  await onTrainingFinishedProcessing(training: fresh);
}

/// Shows a confirmation dialog before finishing a training session.
Future<bool> confirmFinishTraining(
  BuildContext context, {
  required Training training,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.trainingFinishConfirmTitle),
        content: Text(l10n.trainingFinishConfirmMessage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true)
                .pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(
              l10n.finishTrainingTitle,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

/// Returns true when the training owner uses Intense/SIM cloud sync (no USB).
Future<bool> shouldUseIntenseFinishFlow(Training training) async {
  if (training.withTracker != true) return false;

  final ownerId = training.ownerId?.trim() ?? '';
  if (ownerId.isEmpty) return false;

  final owner = await OwnerService().getOwnerById(ownerId);
  return owner != null && !owner.withSyncing;
}

/// Re-syncs Intense tracker data for a finished training using
/// [Training.dateTime] → [Training.trainingEndAt] (available 48h after end).
Future<bool> resyncManagedTrainingIntense(
  BuildContext context, {
  required Training training,
}) async {
  if (!canResyncTrainingIntense(training)) {
    return false;
  }

  final useIntenseFlow = await shouldUseIntenseFinishFlow(training);
  if (!useIntenseFlow || !context.mounted) {
    return false;
  }

  final synced = await TrainingIntenseFinishDialog.show(
    context,
    training: training,
    resync: true,
  );
  if (synced != true || !context.mounted) {
    return false;
  }

  final BuildContext? rootContext = appNavigatorKey.currentContext;
  if (rootContext != null && rootContext.mounted) {
    AppSnackbar.show(
      rootContext,
      context.l10n.trainingIntenseResyncSuccess,
      isError: false,
    );
  }
  return true;
}

/// Finishes a training after confirmation and shows a snackbar on the root
/// navigator.
Future<bool> finishManagedTraining(
  BuildContext context, {
  required Training training,
  VoidCallback? onFinished,
}) async {
  if (isTrainingFinished(training)) {
    return false;
  }

  final useIntenseFlow = await shouldUseIntenseFinishFlow(training);
  if (!context.mounted) return false;

  if (useIntenseFlow) {
    final finished = await TrainingIntenseFinishDialog.show(
      context,
      training: training,
    );
    if (finished != true || !context.mounted) {
      return false;
    }

    onFinished?.call();
    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      AppSnackbar.show(rootContext, context.l10n.trainingFinished, isError: false);
    }
    return true;
  }

  final confirmed = await confirmFinishTraining(context, training: training);
  if (!confirmed || !context.mounted) {
    return false;
  }

  final String successMessage = context.l10n.trainingFinished;
  final String errorMessage = context.l10n.trainingFinishError;

  try {
    await finishTrainingAfterConfirm(training: training);
    onFinished?.call();

    final BuildContext? rootContext = appNavigatorKey.currentContext;
    if (rootContext != null && rootContext.mounted) {
      AppSnackbar.show(rootContext, successMessage, isError: false);
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      AppSnackbar.show(context, errorMessage);
    }
    return false;
  }
}
