import '../../model/answer.dart';
import '../../model/effectives.dart';
import '../../model/player.dart';
import '../../model/training.dart';
import '../../services/answerService.dart';
import '../../services/effectivesService.dart';
import '../../services/playerService.dart';
import '../../services/teamService.dart';
import 'training_team_players_presence.dart';

class TrainingPlayerRowVm {
  const TrainingPlayerRowVm({
    required this.player,
    required this.playerTraining,
    this.effectives,
    this.answer,
  });

  final Player player;
  final PlayerTraining playerTraining;
  final Effectives? effectives;
  final Answer? answer;
}

class TrainingPresenceCounts {
  const TrainingPresenceCounts({
    this.present = 0,
    this.injured = 0,
    this.excused = 0,
    this.absent = 0,
    this.late = 0,
  });

  final int present;
  final int injured;
  final int excused;
  final int absent;
  final int late;

  int get total => present + injured + excused + absent + late;
}

class TrainingTeamPlayersLoader {
  TrainingTeamPlayersLoader({
    PlayerService? playerService,
    TeamService? teamService,
    EffectivesService? effectivesService,
    AnswerService? answerService,
  })  : _playerService = playerService ?? PlayerService(),
        _teamService = teamService ?? TeamService(),
        _effectivesService = effectivesService ?? EffectivesService(),
        _answerService = answerService ?? AnswerService();

  final PlayerService _playerService;
  final TeamService _teamService;
  final EffectivesService _effectivesService;
  final AnswerService _answerService;

  Future<List<TrainingPlayerRowVm>> load({
    required Training training,
    String? seasonId,
  }) async {
    final teamId = training.teamId?.trim();
    if (teamId == null || teamId.isEmpty) {
      return <TrainingPlayerRowVm>[];
    }

    final team = await _teamService.getTeamById(teamId);
    if (team?.players == null || team!.players!.isEmpty) {
      return _fallbackFromTrainingOnly(training, seasonId: seasonId);
    }

    final trainingDate = training.dateTime?.toDate();
    final objectId = _trainingObjectId(training);

    final answersByPlayerId = <String, Answer>{};
    if (objectId != null && objectId.isNotEmpty) {
      final answers = await _answerService.getAnswersByObjectId(objectId);
      for (final answer in answers) {
        final playerId = answer.userId ?? answer.playerTraining?.playerId;
        if (playerId != null && playerId.isNotEmpty) {
          answersByPlayerId[playerId] = answer;
        }
      }
    }

    final playerTrainingById = <String, PlayerTraining>{};
    for (final pt in training.playerTraining) {
      final id = pt.playerId?.trim();
      if (id != null && id.isNotEmpty) {
        playerTrainingById[id] = pt;
      }
    }

    final registeredIds = playerTrainingById.keys.toSet();
    final listOnlyRegistered = registeredIds.isNotEmpty;

    final rows = <TrainingPlayerRowVm>[];

    for (final rawId in team.players!) {
      final playerId = rawId?.toString().trim() ?? '';
      if (playerId.isEmpty) continue;

      final player = await _playerService.getPlayerById(playerId);
      if (player == null) continue;
      if (player.statut != null && player.statut != 1) continue;

      final effectives = await _resolveEffectives(
        playerId: playerId,
        teamId: teamId,
        seasonId: seasonId,
      );

      if (effectives != null && (effectives.type == 1 || effectives.type == 2)) {
        continue;
      }

      if (listOnlyRegistered && !registeredIds.contains(playerId)) {
        continue;
      }

      final answer = answersByPlayerId[playerId];
      // Default absent when unavailable only for brand-new rows. Never overwrite
      // a presence already saved by the manager (including during unavailability).
      final playerTraining = answer?.playerTraining ??
          playerTrainingById[playerId] ??
          PlayerTraining(
            playerId: playerId,
            presenceType: defaultPresenceForPlayer(
              player,
              trainingDate,
              seasonId: seasonId,
            ),
          );

      rows.add(
        TrainingPlayerRowVm(
          player: player,
          playerTraining: playerTraining,
          effectives: effectives,
          answer: answer,
        ),
      );
    }

    rows.sort((a, b) {
      final last = (a.player.lastName ?? '').toLowerCase().compareTo(
        (b.player.lastName ?? '').toLowerCase(),
      );
      if (last != 0) return last;
      return (a.player.firstName ?? '').toLowerCase().compareTo(
        (b.player.firstName ?? '').toLowerCase(),
      );
    });

    return rows;
  }

  /// Joueurs de l'équipe pas encore dans [training.playerTraining].
  Future<List<Player>> loadCandidatesToAdd({
    required Training training,
    String? seasonId,
  }) async {
    final teamId = training.teamId?.trim();
    if (teamId == null || teamId.isEmpty) return [];

    final team = await _teamService.getTeamById(teamId);
    if (team?.players == null) return [];

    final registered = <String>{};
    for (final pt in training.playerTraining) {
      final id = pt.playerId?.trim();
      if (id != null && id.isNotEmpty) registered.add(id);
    }

    final candidates = <Player>[];

    for (final rawId in team!.players!) {
      final playerId = rawId?.toString().trim() ?? '';
      if (playerId.isEmpty || registered.contains(playerId)) continue;

      final player = await _playerService.getPlayerById(playerId);
      if (player == null) continue;
      if (player.statut != null && player.statut != 1) continue;

      final effectives = await _resolveEffectives(
        playerId: playerId,
        teamId: teamId,
        seasonId: seasonId,
      );
      if (effectives != null && (effectives.type == 1 || effectives.type == 2)) {
        continue;
      }

      candidates.add(player);
    }

    candidates.sort((a, b) {
      final last = (a.lastName ?? '').toLowerCase().compareTo(
        (b.lastName ?? '').toLowerCase(),
      );
      if (last != 0) return last;
      return (a.firstName ?? '').toLowerCase().compareTo(
        (b.firstName ?? '').toLowerCase(),
      );
    });

    return candidates;
  }

  TrainingPresenceCounts countPresence(List<TrainingPlayerRowVm> rows) {
    var present = 0;
    var injured = 0;
    var excused = 0;
    var absent = 0;
    var late = 0;

    for (final row in rows) {
      switch (row.playerTraining.presenceType) {
        case PresenceType.present:
          present++;
        case PresenceType.blesse:
          injured++;
        case PresenceType.excuse:
          excused++;
        case PresenceType.absent:
          absent++;
        case PresenceType.late:
          late++;
        case null:
          present++;
      }
    }

    return TrainingPresenceCounts(
      present: present,
      injured: injured,
      excused: excused,
      absent: absent,
      late: late,
    );
  }

  Future<Effectives?> _resolveEffectives({
    required String playerId,
    required String teamId,
    String? seasonId,
  }) async {
    final byTeam = await _effectivesService.getEffectivesByMemberIdAndTeamId(
      playerId,
      teamId,
    );
    if (byTeam != null) return byTeam;

    if (seasonId != null && seasonId.isNotEmpty) {
      return _effectivesService.getEffectivesByMemberAndSeason(
        memberId: playerId,
        seasonId: seasonId,
      );
    }

    return null;
  }

  String? _trainingObjectId(Training training) {
    final trainingId = training.trainingId?.trim();
    if (trainingId != null && trainingId.isNotEmpty) return trainingId;
    final docId = training.docId?.trim();
    if (docId != null && docId.isNotEmpty) return docId;
    return training.ref?.id;
  }

  Future<List<TrainingPlayerRowVm>> _fallbackFromTrainingOnly(
    Training training, {
    String? seasonId,
  }) async {
    final rows = <TrainingPlayerRowVm>[];

    for (final pt in training.playerTraining) {
      final playerId = pt.playerId?.trim();
      if (playerId == null || playerId.isEmpty) continue;

      final player = await _playerService.getPlayerById(playerId);
      if (player == null) continue;

      rows.add(
        TrainingPlayerRowVm(
          player: player,
          playerTraining: pt,
          effectives: null,
          answer: null,
        ),
      );
    }

    return rows;
  }
}
