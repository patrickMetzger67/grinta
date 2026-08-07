import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/util/training_creation_helper.dart';

/// Result of aligning upcoming trainings with a team roster.
class TrainingRosterSyncResult {
  const TrainingRosterSyncResult({
    this.trainingsScanned = 0,
    this.trainingsUpdated = 0,
    this.playersAdded = 0,
    this.playersRemoved = 0,
  });

  final int trainingsScanned;
  final int trainingsUpdated;
  final int playersAdded;
  final int playersRemoved;

  bool get hasChanges =>
      trainingsUpdated > 0 || playersAdded > 0 || playersRemoved > 0;
}

/// Field-player member ids currently on [team] (staff excluded).
@visibleForTesting
Set<String> fieldPlayerIdsFromTeam(Team team) {
  final Set<String> managerIds = managerIdsFromTeam(team);
  final Set<String> ids = <String>{};

  final List<GrintaPlayer> grinta =
      team.grintaPlayers ?? const <GrintaPlayer>[];
  final bool useGrinta = team.isGrinta == true || grinta.isNotEmpty;

  if (useGrinta) {
    for (final GrintaPlayer player in grinta) {
      final String playerId = player.playerId.trim();
      if (playerId.isEmpty) continue;
      if (isGrintaRosterStaff(
        positions: player.positions,
        fonction: player.fonction,
        listedInManagers: managerIds.contains(playerId),
      )) {
        continue;
      }
      ids.add(playerId);
    }
    return ids;
  }

  for (final dynamic raw in team.players ?? const <dynamic>[]) {
    final String id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty) ids.add(id);
  }
  return ids;
}

/// Diff one training's [PlayerTraining] list against [rosterIds].
@visibleForTesting
({
  List<PlayerTraining> next,
  int added,
  int removed,
}) syncPlayerTrainingWithRoster({
  required List<PlayerTraining> current,
  required Set<String> rosterIds,
}) {
  final List<PlayerTraining> kept = <PlayerTraining>[];
  var removed = 0;

  for (final PlayerTraining row in current) {
    final String id = row.playerId?.trim() ?? '';
    if (id.isEmpty) continue;
    if (rosterIds.contains(id)) {
      kept.add(row);
    } else {
      removed++;
    }
  }

  final Set<String> present = kept
      .map((PlayerTraining row) => row.playerId?.trim() ?? '')
      .where((String id) => id.isNotEmpty)
      .toSet();

  var added = 0;
  for (final String playerId in rosterIds) {
    if (present.contains(playerId)) continue;
    // Tracker assignment needs DeviceOwner lookup — left empty so managers
    // can assign on the training players screen.
    kept.add(
      PlayerTraining(
        playerId: playerId,
        presenceType: PresenceType.present,
      ),
    );
    added++;
  }

  return (next: kept, added: added, removed: removed);
}

/// Removes [playerId] from [training.trainingGroup] player lists.
@visibleForTesting
List<TrainingGroup> prunePlayerFromTrainingGroups({
  required List<TrainingGroup> groups,
  required String playerId,
}) {
  final String id = playerId.trim();
  if (id.isEmpty) return groups;
  return groups
      .map(
        (TrainingGroup group) => group.copyWith(
          players: group.players.where((String p) => p.trim() != id).toList(),
        ),
      )
      .toList();
}

class TrainingRosterSyncHelper {
  TrainingRosterSyncHelper({
    TrainingService? trainingService,
  }) : _trainingService = trainingService ?? TrainingService();

  final TrainingService _trainingService;

  static const Duration _upcomingHorizon = Duration(days: 400);

  Future<List<Training>> _loadUpcomingTrainings(String teamId) async {
    final String trimmed = teamId.trim();
    if (trimmed.isEmpty) return const <Training>[];

    final DateTime now = DateTime.now();
    final List<Training> trainings =
        await _trainingService.getTrainingsByTeamIdBetweenDates(
      teamId: trimmed,
      start: Timestamp.fromDate(now),
      end: Timestamp.fromDate(now.add(_upcomingHorizon)),
    );

    return trainings.where((Training t) {
      if (t.isFinish == true) return false;
      return _trainingDocId(t) != null;
    }).toList();
  }

  String? _trainingDocId(Training training) {
    final String? fromRef = training.ref?.id.trim();
    if (fromRef != null && fromRef.isNotEmpty) return fromRef;
    final String? fromDoc = training.docId?.trim();
    if (fromDoc != null && fromDoc.isNotEmpty) return fromDoc;
    final String? fromTrainingId = training.trainingId?.trim();
    if (fromTrainingId != null && fromTrainingId.isNotEmpty) {
      return fromTrainingId;
    }
    return null;
  }

  /// Full align: add missing roster players, remove players no longer on roster.
  Future<TrainingRosterSyncResult> syncUpcomingTrainingsWithRoster({
    required Team team,
  }) async {
    final String? teamId = team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      return const TrainingRosterSyncResult();
    }

    final Set<String> rosterIds = fieldPlayerIdsFromTeam(team);
    final List<Training> trainings = await _loadUpcomingTrainings(teamId);

    var trainingsUpdated = 0;
    var playersAdded = 0;
    var playersRemoved = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final diff = syncPlayerTrainingWithRoster(
        current: List<PlayerTraining>.from(training.playerTraining),
        rosterIds: rosterIds,
      );
      if (diff.added == 0 && diff.removed == 0) continue;

      List<TrainingGroup> groups = training.trainingGroup;
      if (diff.removed > 0) {
        final Set<String> removedIds = <String>{};
        for (final PlayerTraining row in training.playerTraining) {
          final String id = row.playerId?.trim() ?? '';
          if (id.isNotEmpty && !rosterIds.contains(id)) {
            removedIds.add(id);
          }
        }
        for (final String removedId in removedIds) {
          groups = prunePlayerFromTrainingGroups(
            groups: groups,
            playerId: removedId,
          );
        }
      }

      await _trainingService.updatePlayerTraining(
        trainingId: docId,
        playerTraining: diff.next,
      );
      if (diff.removed > 0) {
        await _trainingService.updateTrainingGroups(
          trainingId: docId,
          groups: groups,
        );
      }

      trainingsUpdated++;
      playersAdded += diff.added;
      playersRemoved += diff.removed;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      playersAdded: playersAdded,
      playersRemoved: playersRemoved,
    );
  }

  /// Adds [playerId] to all upcoming unfinished trainings missing that player.
  Future<TrainingRosterSyncResult> addPlayerToUpcomingTrainings({
    required Team team,
    required String playerId,
  }) async {
    final String memberId = playerId.trim();
    final String? teamId = team.keyTeam?.trim();
    if (memberId.isEmpty || teamId == null || teamId.isEmpty) {
      return const TrainingRosterSyncResult();
    }

    // Staff must not appear on training attendance.
    final Set<String> rosterIds = fieldPlayerIdsFromTeam(team);
    if (!rosterIds.contains(memberId)) {
      return const TrainingRosterSyncResult();
    }

    final List<Training> trainings = await _loadUpcomingTrainings(teamId);
    var trainingsUpdated = 0;
    var playersAdded = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final bool already = training.playerTraining.any(
        (PlayerTraining row) => row.playerId?.trim() == memberId,
      );
      if (already) continue;

      final List<PlayerTraining> next =
          List<PlayerTraining>.from(training.playerTraining)
            ..add(
              PlayerTraining(
                playerId: memberId,
                presenceType: PresenceType.present,
              ),
            );

      await _trainingService.updatePlayerTraining(
        trainingId: docId,
        playerTraining: next,
      );
      trainingsUpdated++;
      playersAdded++;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      playersAdded: playersAdded,
    );
  }

  /// Removes [playerId] from all upcoming unfinished trainings.
  Future<TrainingRosterSyncResult> removePlayerFromUpcomingTrainings({
    required Team team,
    required String playerId,
  }) async {
    final String memberId = playerId.trim();
    final String? teamId = team.keyTeam?.trim();
    if (memberId.isEmpty || teamId == null || teamId.isEmpty) {
      return const TrainingRosterSyncResult();
    }

    final List<Training> trainings = await _loadUpcomingTrainings(teamId);
    var trainingsUpdated = 0;
    var playersRemoved = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final bool present = training.playerTraining.any(
        (PlayerTraining row) => row.playerId?.trim() == memberId,
      );
      if (!present) continue;

      final List<PlayerTraining> next =
          List<PlayerTraining>.from(training.playerTraining)
            ..removeWhere((PlayerTraining row) => row.playerId?.trim() == memberId);

      final List<TrainingGroup> groups = prunePlayerFromTrainingGroups(
        groups: training.trainingGroup,
        playerId: memberId,
      );

      await _trainingService.updatePlayerTraining(
        trainingId: docId,
        playerTraining: next,
      );
      await _trainingService.updateTrainingGroups(
        trainingId: docId,
        groups: groups,
      );
      trainingsUpdated++;
      playersRemoved++;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      playersRemoved: playersRemoved,
    );
  }
}
