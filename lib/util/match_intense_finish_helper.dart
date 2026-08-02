import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/intense_live_eligibility.dart';
import 'package:grinta/widget/match_intense_finish_dialog.dart';

/// True when the match owner streams via Intense cloud (no USB sync).
Future<bool> shouldUseIntenseMatchFinishFlow(models.Match match) async {
  if (match.withTracker != true) return false;
  return isIntenseTrackerOwner(match.ownerId);
}

/// Runs the Intense Insiders sync dialog after full-time, then marks uploaded.
Future<bool> finishMatchIntenseSync(
  BuildContext context, {
  required models.Match match,
  required List<Highlights> highlights,
}) async {
  final useIntense = await shouldUseIntenseMatchFinishFlow(match);
  if (!useIntense || !context.mounted) return false;

  final synced = await MatchIntenseFinishDialog.show(
    context,
    match: match,
    highlights: highlights,
  );
  if (synced != true || !context.mounted) {
    return false;
  }

  final rootContext = appNavigatorKey.currentContext;
  if (rootContext != null && rootContext.mounted) {
    AppSnackbar.show(
      rootContext,
      context.l10n.trainingIntenseResyncSuccess,
      isError: false,
    );
  }
  return true;
}

/// Re-syncs Intense match tracker data within 48h after full-time.
Future<bool> resyncManagedMatchIntense(
  BuildContext context, {
  required models.Match match,
  required List<Highlights> highlights,
}) async {
  if (!canResyncMatchIntense(match: match, highlights: highlights)) {
    return false;
  }

  final useIntense = await shouldUseIntenseMatchFinishFlow(match);
  if (!useIntense || !context.mounted) return false;

  final synced = await MatchIntenseFinishDialog.show(
    context,
    match: match,
    highlights: highlights,
    resync: true,
  );
  if (synced != true || !context.mounted) {
    return false;
  }

  final rootContext = appNavigatorKey.currentContext;
  if (rootContext != null && rootContext.mounted) {
    AppSnackbar.show(
      rootContext,
      context.l10n.trainingIntenseResyncSuccess,
      isError: false,
    );
  }
  return true;
}
