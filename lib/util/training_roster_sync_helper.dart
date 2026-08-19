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
    this.trackersUpdated = 0,
  });

  final int trainingsScanned;
  final int trainingsUpdated;
  final int playersAdded;
  final int playersRemoved;
  final int trackersUpdated;

  bool get hasChanges =>
      trainingsUpdated > 0 ||
      playersAdded > 0 ||
      playersRemoved > 0 ||
      trackersUpdated > 0;
}

/// GPS assigned to a roster player (`PlayerTraining.deviceId` = DeviceOwner doc id).
class TrainingTrackerAssignment {
  const TrainingTrackerAssignment({
    required this.deviceOwnerDocId,
    required this.customName,
  });

  final String deviceOwnerDocId;
  final String customName;
}

/// Field-player member ids currently on [team] (staff excluded).
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

String _trimmedOrEmpty(String? value) => value?.trim() ?? '';

bool _hasTracker(PlayerTraining row) {
  return _trimmedOrEmpty(row.deviceId).isNotEmpty ||
      _trimmedOrEmpty(row.customName).isNotEmpty;
}

void _clearTracker(PlayerTraining row) {
  row.deviceId = '';
  row.customName = '';
}

void _setTracker(PlayerTraining row, TrainingTrackerAssignment assignment) {
  row.deviceId = assignment.deviceOwnerDocId;
  row.customName = assignment.customName;
}

/// Assigns [assignment] to [playerId] and frees that GPS from any other row.
@visibleForTesting
({
  List<PlayerTraining> next,
  bool changed,
  bool addedPlayer,
}) assignTrackerOnPlayerTraining({
  required List<PlayerTraining> current,
  required String playerId,
  required TrainingTrackerAssignment assignment,
}) {
  final String memberId = playerId.trim();
  final String deviceId = assignment.deviceOwnerDocId.trim();
  if (memberId.isEmpty || deviceId.isEmpty) {
    return (next: current, changed: false, addedPlayer: false);
  }

  final List<PlayerTraining> next = List<PlayerTraining>.from(current);
  var changed = false;
  var addedPlayer = false;

  PlayerTraining? target;
  for (final PlayerTraining row in next) {
    if (_trimmedOrEmpty(row.playerId) == memberId) {
      target = row;
      break;
    }
  }
  if (target == null) {
    target = PlayerTraining(
      playerId: memberId,
      presenceType: PresenceType.present,
    );
    next.add(target);
    addedPlayer = true;
    changed = true;
  }

  if (_trimmedOrEmpty(target.deviceId) != deviceId ||
      _trimmedOrEmpty(target.customName) != assignment.customName.trim()) {
    _setTracker(target, assignment);
    changed = true;
  }

  for (final PlayerTraining row in next) {
    if (identical(row, target)) continue;
    if (_trimmedOrEmpty(row.deviceId) != deviceId) continue;
    _clearTracker(row);
    changed = true;
  }

  return (next: next, changed: changed, addedPlayer: addedPlayer);
}

/// Clears [deviceOwnerDocId] from [playerId] when that GPS is still assigned.
@visibleForTesting
({
  List<PlayerTraining> next,
  bool changed,
}) clearTrackerOnPlayerTraining({
  required List<PlayerTraining> current,
  required String playerId,
  required String deviceOwnerDocId,
}) {
  final String memberId = playerId.trim();
  final String deviceId = deviceOwnerDocId.trim();
  if (memberId.isEmpty || deviceId.isEmpty) {
    return (next: current, changed: false);
  }

  var changed = false;
  for (final PlayerTraining row in current) {
    if (_trimmedOrEmpty(row.playerId) != memberId) continue;
    if (_trimmedOrEmpty(row.deviceId) != deviceId) continue;
    _clearTracker(row);
    changed = true;
  }
  return (next: current, changed: changed);
}

/// Aligns each training row's GPS with [rosterTrackers] (null = no GPS).
@visibleForTesting
({
  List<PlayerTraining> next,
  bool changed,
}) alignTrackersWithRoster({
  required List<PlayerTraining> current,
  required Map<String, TrainingTrackerAssignment?> rosterTrackers,
}) {
  if (rosterTrackers.isEmpty) {
    return (next: current, changed: false);
  }

  var changed = false;
  final Set<String> claimed = <String>{};

  for (final PlayerTraining row in current) {
    final String id = _trimmedOrEmpty(row.playerId);
    if (id.isEmpty || !rosterTrackers.containsKey(id)) continue;

    final TrainingTrackerAssignment? assignment = rosterTrackers[id];
    if (assignment == null || assignment.deviceOwnerDocId.trim().isEmpty) {
      if (_hasTracker(row)) {
        _clearTracker(row);
        changed = true;
      }
      continue;
    }

    final String deviceId = assignment.deviceOwnerDocId.trim();
    if (claimed.contains(deviceId)) {
      if (_trimmedOrEmpty(row.deviceId) == deviceId || _hasTracker(row)) {
        _clearTracker(row);
        changed = true;
      }
      continue;
    }

    claimed.add(deviceId);
    if (_trimmedOrEmpty(row.deviceId) != deviceId ||
        _trimmedOrEmpty(row.customName) != assignment.customName.trim()) {
      _setTracker(row, assignment);
      changed = true;
    }
  }

  for (final PlayerTraining row in current) {
    final String id = _trimmedOrEmpty(row.playerId);
    final String device = _trimmedOrEmpty(row.deviceId);
    if (device.isEmpty) continue;
    final TrainingTrackerAssignment? assignment = rosterTrackers[id];
    if (assignment != null && assignment.deviceOwnerDocId.trim() == device) {
      continue;
    }
    if (claimed.contains(device)) {
      _clearTracker(row);
      changed = true;
    }
  }

  return (next: current, changed: changed);
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

  /// Full align: add/remove roster players and apply GPS assignments.
  Future<TrainingRosterSyncResult> syncUpcomingTrainingsWithRoster({
    required Team team,
    Map<String, TrainingTrackerAssignment?>? rosterTrackers,
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
    var trackersUpdated = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final diff = syncPlayerTrainingWithRoster(
        current: List<PlayerTraining>.from(training.playerTraining),
        rosterIds: rosterIds,
      );
      var next = diff.next;
      var trackerChanged = false;
      if (rosterTrackers != null && rosterTrackers.isNotEmpty) {
        final aligned = alignTrackersWithRoster(
          current: next,
          rosterTrackers: rosterTrackers,
        );
        next = aligned.next;
        trackerChanged = aligned.changed;
      }
      if (diff.added == 0 && diff.removed == 0 && !trackerChanged) continue;

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
        playerTraining: next,
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
      if (trackerChanged) trackersUpdated++;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      playersAdded: playersAdded,
      playersRemoved: playersRemoved,
      trackersUpdated: trackersUpdated,
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

  /// Copies [assignment] onto [playerId] for every upcoming unfinished training.
  Future<TrainingRosterSyncResult> assignTrackerToUpcomingTrainings({
    required Team team,
    required String playerId,
    required TrainingTrackerAssignment assignment,
  }) async {
    final String memberId = playerId.trim();
    final String? teamId = team.keyTeam?.trim();
    if (memberId.isEmpty ||
        teamId == null ||
        teamId.isEmpty ||
        assignment.deviceOwnerDocId.trim().isEmpty) {
      return const TrainingRosterSyncResult();
    }

    final List<Training> trainings = await _loadUpcomingTrainings(teamId);
    var trainingsUpdated = 0;
    var playersAdded = 0;
    var trackersUpdated = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final result = assignTrackerOnPlayerTraining(
        current: List<PlayerTraining>.from(training.playerTraining),
        playerId: memberId,
        assignment: assignment,
      );
      if (!result.changed) continue;

      await _trainingService.updatePlayerTraining(
        trainingId: docId,
        playerTraining: result.next,
      );
      trainingsUpdated++;
      trackersUpdated++;
      if (result.addedPlayer) playersAdded++;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      playersAdded: playersAdded,
      trackersUpdated: trackersUpdated,
    );
  }

  /// Removes [deviceOwnerDocId] from [playerId] on upcoming unfinished trainings.
  Future<TrainingRosterSyncResult> removeTrackerFromUpcomingTrainings({
    required Team team,
    required String playerId,
    required String deviceOwnerDocId,
  }) async {
    final String memberId = playerId.trim();
    final String deviceId = deviceOwnerDocId.trim();
    final String? teamId = team.keyTeam?.trim();
    if (memberId.isEmpty || deviceId.isEmpty || teamId == null || teamId.isEmpty) {
      return const TrainingRosterSyncResult();
    }

    final List<Training> trainings = await _loadUpcomingTrainings(teamId);
    var trainingsUpdated = 0;
    var trackersUpdated = 0;

    for (final Training training in trainings) {
      final String? docId = _trainingDocId(training);
      if (docId == null) continue;

      final result = clearTrackerOnPlayerTraining(
        current: List<PlayerTraining>.from(training.playerTraining),
        playerId: memberId,
        deviceOwnerDocId: deviceId,
      );
      if (!result.changed) continue;

      await _trainingService.updatePlayerTraining(
        trainingId: docId,
        playerTraining: result.next,
      );
      trainingsUpdated++;
      trackersUpdated++;
    }

    return TrainingRosterSyncResult(
      trainingsScanned: trainings.length,
      trainingsUpdated: trainingsUpdated,
      trackersUpdated: trackersUpdated,
    );
  }
}
