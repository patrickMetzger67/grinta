import 'dart:async';

import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';

/// Counts matches and trainings pending tracker upload across managed teams.
class SyncPendingCountService {
  const SyncPendingCountService();

  /// Matches where `withTracker == true`, `isMatchPlayed == true`, and
  /// `isTrackerDataUploaded == false`. Trainings where `withTracker == true`
  /// and `isTrackerDataUploaded == false`. Match and training ids are
  /// deduplicated when aggregating multiple teams.
  Stream<int> watchPendingEventsCount(List<String> teamIds) {
    final normalizedIds = teamIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (normalizedIds.isEmpty) {
      return Stream.value(0);
    }

    final matchService = MatchService();
    final trainingService = TrainingService();

    return Stream.multi((controller) {
      final matchIdsByTeam = <String, Set<String>>{
        for (final teamId in normalizedIds) teamId: <String>{},
      };
      final trainingIdsByTeam = <String, Set<String>>{
        for (final teamId in normalizedIds) teamId: <String>{},
      };
      final subscriptions = <StreamSubscription<List<dynamic>>>[];

      void emitCount() {
        final matchIds =
            matchIdsByTeam.values.expand((ids) => ids).toSet();
        final trainingIds =
            trainingIdsByTeam.values.expand((ids) => ids).toSet();
        controller.add(matchIds.length + trainingIds.length);
      }

      for (final teamId in normalizedIds) {
        subscriptions.add(
          matchService.streamMatchesToUploadTrackerData(teamId).listen(
            (matches) {
              matchIdsByTeam[teamId] = {
                for (final match in matches)
                  if (match.id?.trim().isNotEmpty == true) match.id!.trim(),
              };
              emitCount();
            },
            onError: (_) => emitCount(),
          ),
        );
        subscriptions.add(
          trainingService.streamTrainingsToUploadTrackerData(teamId).listen(
            (trainings) {
              trainingIdsByTeam[teamId] = {
                for (final training in trainings)
                  if (training.docId?.trim().isNotEmpty == true)
                    training.docId!.trim(),
              };
              emitCount();
            },
            onError: (_) => emitCount(),
          ),
        );
      }

      controller.onCancel = () {
        for (final subscription in subscriptions) {
          subscription.cancel();
        }
      };
    });
  }
}
