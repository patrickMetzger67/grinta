import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/screen/session_player_feeling_screen.dart';
import 'package:grinta/services/apple_health_platform.dart';
import 'package:grinta/services/apple_health_sync_service.dart';
import 'package:grinta/services/event_sync_service.dart';
import 'package:grinta/services/google_health_platform.dart';
import 'package:grinta/services/google_health_sync_service.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/highlight_minute_helper.dart';

enum SessionHealthExportTarget { appleForme, googleFit }

/// Offers / writes session distance+duration into Apple Health or Health Connect.
class SessionHealthExportService {
  SessionHealthExportService._();

  static final SessionHealthExportService instance =
      SessionHealthExportService._();

  final EventSyncService _eventSync = EventSyncService();

  /// Call after the session recap screen has loaded rings / event type.
  /// Feeling is optional and independent.
  Future<void> maybeOfferExport({
    required BuildContext context,
    required String eventId,
    required String playerId,
    required SessionFeelingScreenEventType eventType,
  }) async {
    if (kIsWeb) return;

    final target = _targetForPlatform();
    if (target == null) return;

    final event = eventId.trim();
    final player = playerId.trim();
    if (event.isEmpty || player.isEmpty) return;

    final status = await _eventSync.getHealthExportStatus(
      eventId: event,
      playerId: player,
    );
    if (status == 'exported' || status == 'declined') return;

    final analysis =
        await TrackerDataAnalysisService.getAnalysisByEventAndPlayerId(
      event,
      player,
    );
    if (analysis == null) return;

    final distanceMeters = (analysis.distanceKm * 1000).round();
    if (distanceMeters <= 0 && analysis.duration.inSeconds <= 0) return;

    final window = await _resolveTimeWindow(
      eventId: event,
      eventType: eventType,
      analysis: analysis,
    );
    if (window == null) return;
    final start = window.$1;
    final end = window.$2;
    if (!end.isAfter(start)) return;

    if (!context.mounted) return;
    final l10n = context.l10n;
    final connected = await _isConnected(playerId: player, target: target);

    if (connected) {
      final ok = await _writeWorkout(
        target: target,
        eventType: eventType,
        start: start,
        end: end,
        distanceMeters: distanceMeters > 0 ? distanceMeters : null,
        title: eventType == SessionFeelingScreenEventType.match
            ? l10n.sessionHealthExportTitleMatch
            : l10n.sessionHealthExportTitleTraining,
      );
      if (!context.mounted) return;
      if (ok) {
        await _eventSync.setHealthExportStatus(
          eventId: event,
          playerId: player,
          status: 'exported',
        );
        AppSnackbar.show(
          context,
          target == SessionHealthExportTarget.appleForme
              ? l10n.sessionHealthExportSuccessApple
              : l10n.sessionHealthExportSuccessGoogle,
          isError: false,
        );
      } else {
        AppSnackbar.show(context, l10n.sessionHealthExportFailed);
      }
      return;
    }

    final wants = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sessionHealthExportPromptTitle),
        content: Text(
          target == SessionHealthExportTarget.appleForme
              ? l10n.sessionHealthExportPromptApple
              : l10n.sessionHealthExportPromptGoogle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.actionNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.actionYes),
          ),
        ],
      ),
    );

    if (wants != true) {
      await _eventSync.setHealthExportStatus(
        eventId: event,
        playerId: player,
        status: 'declined',
      );
      return;
    }

    final connectOk = await _connect(playerId: player, target: target);
    if (!connectOk) {
      if (context.mounted) {
        AppSnackbar.show(context, l10n.sessionHealthExportConnectFailed);
      }
      return;
    }

    final ok = await _writeWorkout(
      target: target,
      eventType: eventType,
      start: start,
      end: end,
      distanceMeters: distanceMeters > 0 ? distanceMeters : null,
      title: eventType == SessionFeelingScreenEventType.match
          ? l10n.sessionHealthExportTitleMatch
          : l10n.sessionHealthExportTitleTraining,
    );
    if (!context.mounted) return;
    if (ok) {
      await _eventSync.setHealthExportStatus(
        eventId: event,
        playerId: player,
        status: 'exported',
      );
      AppSnackbar.show(
        context,
        target == SessionHealthExportTarget.appleForme
            ? l10n.sessionHealthExportSuccessApple
            : l10n.sessionHealthExportSuccessGoogle,
        isError: false,
      );
    } else {
      AppSnackbar.show(context, l10n.sessionHealthExportFailed);
    }
  }

  SessionHealthExportTarget? _targetForPlatform() {
    if (isAppleHealthSupported) return SessionHealthExportTarget.appleForme;
    if (isGoogleHealthConnectSupported) {
      return SessionHealthExportTarget.googleFit;
    }
    return null;
  }

  Future<bool> _isConnected({
    required String playerId,
    required SessionHealthExportTarget target,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (target == SessionHealthExportTarget.appleForme) {
      final config = await AppleHealthSyncService.instance.repository
          .getConfig(uid, playerId);
      return config?.connected == true;
    }
    final config = await GoogleHealthSyncService.instance.repository
        .getConfig(uid, playerId);
    return config?.connected == true;
  }

  Future<bool> _connect({
    required String playerId,
    required SessionHealthExportTarget target,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (target == SessionHealthExportTarget.appleForme) {
      final result = await AppleHealthSyncService.instance.connect(
        playerId: playerId,
        initiatedBy: uid,
      );
      if (result != AppleHealthConnectResult.success) return false;
      return ensureAppleWorkoutWriteAuthorized();
    }
    final result = await GoogleHealthSyncService.instance.connect(
      playerId: playerId,
      initiatedBy: uid,
    );
    if (result != GoogleHealthConnectResult.success) return false;
    return ensureGoogleWorkoutWriteAuthorized();
  }

  Future<bool> _writeWorkout({
    required SessionHealthExportTarget target,
    required SessionFeelingScreenEventType eventType,
    required DateTime start,
    required DateTime end,
    required int? distanceMeters,
    required String title,
  }) async {
    final activityTypeName =
        eventType == SessionFeelingScreenEventType.match ? 'SOCCER' : 'OTHER';
    if (target == SessionHealthExportTarget.appleForme) {
      return writeAppleHealthWorkout(
        activityTypeName: activityTypeName,
        start: start,
        end: end,
        distanceMeters: distanceMeters,
        title: title,
      );
    }
    return writeGoogleHealthWorkout(
      activityTypeName: activityTypeName,
      start: start,
      end: end,
      distanceMeters: distanceMeters,
      title: title,
    );
  }

  Future<(DateTime, DateTime)?> _resolveTimeWindow({
    required String eventId,
    required SessionFeelingScreenEventType eventType,
    required TrackerAnalysisResult analysis,
  }) async {
    if (eventType == SessionFeelingScreenEventType.training) {
      final training = await TrainingService().getTrainingById(eventId);
      final start = training?.trainingStartAt?.toDate() ??
          training?.dateTime?.toDate();
      if (start == null) return null;
      final endFromDoc = training?.trainingEndAt?.toDate();
      if (endFromDoc != null && endFromDoc.isAfter(start)) {
        return (start, endFromDoc);
      }
      final minutes = training?.duration ?? 0;
      if (minutes > 0) {
        return (start, start.add(Duration(minutes: minutes)));
      }
      if (analysis.duration.inSeconds > 0) {
        return (start, start.add(analysis.duration));
      }
      return (start, start.add(const Duration(minutes: 1)));
    }

    final match = await MatchService().getMatchById(eventId);
    if (match == null) return null;
    final start = matchKickoffDateTime(match);
    if (start == null) return null;
    if (analysis.duration.inSeconds > 0) {
      return (start, start.add(analysis.duration));
    }
    final minutes = regulationMatchDuration(match);
    return (start, start.add(Duration(minutes: minutes)));
  }
}
