import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_deletion_access.dart';

import '../model/grinta_player.dart';
import '../model/player.dart';
import '../model/season.dart';
import '../model/team.dart';
import '../model/tracker/deviceOwner.dart';
import '../model/training.dart';
import '../screen/team_players/training_team_players_presence.dart';
import 'player_positions.dart';

/// Formats a date as `dd/MM/yyyy` for [Training.dateTg].
String formatTrainingDateTg(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Formats a [DateTime] as `HH:mm` for [Training.startTime] / [Training.endTime].
String formatTrainingTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Parses [Training.dateTg] (`dd/MM/yyyy`) into a local date.
DateTime? parseTrainingDateTg(String? dateTg) {
  final String raw = dateTg?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parts = raw.split('/');
  if (parts.length != 3) return null;

  try {
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  } catch (_) {
    return null;
  }
}

/// Parses [Training.startTime] (`HH:mm`) into a [TimeOfDay].
TimeOfDay? parseTrainingTime(String? startTime) {
  final String raw = startTime?.trim() ?? '';
  if (raw.isEmpty) return null;

  final parts = raw.split(':');
  if (parts.length != 2) return null;

  try {
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  } catch (_) {
    return null;
  }
}

/// Returns the team id when [Training.teamId] is set.
String? managedTrainingTeamId(Training training) {
  final String teamId = training.teamId?.trim() ?? '';
  if (teamId.isEmpty) {
    return null;
  }
  return teamId;
}

/// True when the training belongs to one team and the user can manage that team.
bool canManageTraining(Training training, AppSession session) {
  final String? teamId = managedTrainingTeamId(training);
  if (teamId == null) {
    return false;
  }

  Team? team;
  for (final Team candidate in session.teamsForAgendaSelectedSeason) {
    if (candidate.keyTeam?.trim() == teamId) {
      team = candidate;
      break;
    }
  }
  if (team == null) {
    return false;
  }

  return canManageTeam(
    team,
    session.user?.uid,
    isManager: session.managedTeamsIdsForSelectedSeason.contains(teamId),
  );
}

/// True when [training] belongs to a recurring series.
bool isTrainingRecurrent(Training training) {
  if (training.isReccurent != true) return false;
  final String code = training.reccurentCode?.trim() ?? '';
  return code.isNotEmpty;
}

/// Weekdays stored on [training] ([DateTime.weekday] values).
Set<int> recurrentWeekdaysFromTraining(Training training) {
  final Set<int> days = <int>{};
  for (final dynamic raw in training.reccurentDay ?? const <dynamic>[]) {
    if (raw is int) {
      days.add(raw);
    } else if (raw is num) {
      days.add(raw.toInt());
    }
  }
  return days;
}

/// Scope chosen when deleting a training (possibly recurring).
enum DeleteTrainingScope {
  cancelled,
  thisOccurrence,
  allOccurrences,
}

/// Shows a confirmation dialog before deleting a manually managed training.
///
/// For recurring trainings, offers deleting this occurrence only or the whole series.
Future<DeleteTrainingScope> confirmDeleteTraining(
  BuildContext context, {
  required Training training,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;

  if (isTrainingRecurrent(training)) {
    final DeleteTrainingScope? scope = await showDialog<DeleteTrainingScope>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        final NavigatorState nav =
            Navigator.of(dialogContext, rootNavigator: true);
        return AlertDialog(
          title: Text(l10n.trainingDeleteRecurrentTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.trainingDeleteRecurrentMessage),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => nav.pop(DeleteTrainingScope.allOccurrences),
                child: Text(l10n.trainingDeleteAllOccurrences),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => nav.pop(DeleteTrainingScope.thisOccurrence),
                child: Text(l10n.trainingDeleteThisOccurrence),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => nav.pop(DeleteTrainingScope.cancelled),
                child: Text(l10n.actionCancel),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.border),
          ),
        );
      },
    );
    return scope ?? DeleteTrainingScope.cancelled;
  }

  final bool? confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.trainingDeleteConfirmTitle),
        content: Text(l10n.trainingDeleteConfirmMessage),
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
              l10n.actionDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true
      ? DeleteTrainingScope.thisOccurrence
      : DeleteTrainingScope.cancelled;
}

/// Deletes a training after confirmation and shows a snackbar on the root navigator.
///
/// When the training is recurring and the user chooses to delete all occurrences,
/// every training sharing the same [Training.reccurentCode] is removed.
Future<bool> deleteManagedTraining(
  BuildContext context, {
  required Training training,
  VoidCallback? onDeleted,
}) async {
  final String? trainingId = training.docId?.trim();
  if (trainingId == null || trainingId.isEmpty) {
    return false;
  }

  final DeleteTrainingScope scope =
      await confirmDeleteTraining(context, training: training);
  if (scope == DeleteTrainingScope.cancelled || !context.mounted) {
    return false;
  }

  final String successMessage = context.l10n.trainingDeleted;
  final String errorMessage = context.l10n.trainingDeleteError;

  try {
    final TrainingService service = TrainingService();
    if (scope == DeleteTrainingScope.allOccurrences) {
      final String code = training.reccurentCode!.trim();
      final List<Training> series =
          await service.getTrainingsByReccurentCode(code);
      final List<String> ids = series
          .map((Training t) => t.docId?.trim() ?? '')
          .where((String id) => id.isNotEmpty)
          .toList(growable: true);
      if (ids.isEmpty) {
        ids.add(trainingId);
      }
      await service.deleteTrainings(ids);
    } else {
      await service.deleteTraining(trainingId);
    }
    onDeleted?.call();

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

/// Assigns the first available tracker from [trackers] (DeviceOwner doc ids) to
/// [playerTraining], mirroring [TrainingTrackerContext.applyDefaultFromEffectives].
///
/// [PlayerTraining.deviceId] stores the DeviceOwner Firestore doc id (for lookup).
/// [PlayerTraining.customName] stores the display label (e.g. "7").
/// Insiders API calls must use [DeviceOwner.deviceId] (TRACKER_Device UUID), never
/// [PlayerTraining.customName].
void applyTrackerToPlayerTraining({
  required PlayerTraining playerTraining,
  required List<String> trackers,
  required Map<String, DeviceOwner> ownerDevicesByDocId,
  required Set<String> devicesAffected,
}) {
  if (playerTraining.deviceId != null && playerTraining.deviceId!.isNotEmpty) {
    devicesAffected.add(playerTraining.deviceId!);
    return;
  }

  if (trackers.isEmpty || ownerDevicesByDocId.isEmpty) return;

  for (final trackerDocId in trackers) {
    final String id = trackerDocId.trim();
    if (id.isEmpty) continue;

    final device = ownerDevicesByDocId[id];
    if (device == null) continue;
    if (devicesAffected.contains(device.id)) continue;

    playerTraining.deviceId = device.id;
    final name = device.customName?.trim();
    playerTraining.customName =
        (name != null && name.isNotEmpty) ? name : device.deviceId;
    devicesAffected.add(device.id);
    break;
  }
}

/// Builds [PlayerTraining] rows for field players only (present by default).
///
/// Staff members ([hasExplicitGrintaStaffFonction] / [isGrintaRosterStaff]) are
/// excluded from attendance tracking.
///
/// When [withTracker] is true and [ownerDevicesByDocId] is provided, each player's
/// assigned tracker from [GrintaPlayer.trackers] is copied to [PlayerTraining.deviceId]
/// (DeviceOwner doc id), using the same resolution rules as the training players screen.
///
/// When [playersById] + [trainingDate] are provided, unavailable players default
/// to [PresenceType.absent] (managers can still change presence later).
List<PlayerTraining> playerTrainingFromGrintaPlayers(
  List<GrintaPlayer> players, {
  Set<String> managerIds = const <String>{},
  bool withTracker = false,
  Map<String, DeviceOwner>? ownerDevicesByDocId,
  Map<String, Player>? playersById,
  DateTime? trainingDate,
  String? seasonId,
}) {
  final rows = <PlayerTraining>[];
  final devicesAffected = <String>{};
  final ownerDevices = ownerDevicesByDocId ?? const <String, DeviceOwner>{};
  final playersMap = playersById ?? const <String, Player>{};

  for (final GrintaPlayer player in players) {
    final String playerId = player.playerId.trim();
    if (playerId.isEmpty) continue;

    if (isGrintaRosterStaff(
      positions: player.positions,
      fonction: player.fonction,
      listedInManagers: managerIds.contains(playerId),
    )) {
      continue;
    }

    final fullPlayer = playersMap[playerId];
    final presence = fullPlayer == null
        ? PresenceType.present
        : defaultPresenceForPlayer(
            fullPlayer,
            trainingDate,
            seasonId: seasonId,
          );

    final playerTraining = PlayerTraining(
      playerId: playerId,
      presenceType: presence,
    );

    if (withTracker && ownerDevices.isNotEmpty) {
      applyTrackerToPlayerTraining(
        playerTraining: playerTraining,
        trackers: player.trackers,
        ownerDevicesByDocId: ownerDevices,
        devicesAffected: devicesAffected,
      );
    }

    rows.add(playerTraining);
  }
  return rows;
}

/// Clones [template] for [date], recomputing default presence from unavailability.
List<PlayerTraining> clonePlayerTrainingForDate({
  required List<PlayerTraining> template,
  required DateTime date,
  required Map<String, Player> playersById,
  String? seasonId,
}) {
  return template.map((PlayerTraining p) {
    final playerId = p.playerId?.trim() ?? '';
    final fullPlayer = playersById[playerId];
    final presence = fullPlayer == null
        ? (p.presenceType ?? PresenceType.present)
        : defaultPresenceForPlayer(
            fullPlayer,
            date,
            seasonId: seasonId,
          );
    return PlayerTraining(
      playerId: p.playerId,
      presenceType: presence,
    )
      ..deviceId = p.deviceId
      ..customName = p.customName;
  }).toList(growable: false);
}

/// Normalizes [Team.managers] into a set of member ids.
Set<String> managerIdsFromTeam(Team team) {
  final Set<String> ids = <String>{};
  for (final dynamic raw in team.managers ?? const <dynamic>[]) {
    if (raw is! String) continue;
    final String id = raw.trim();
    if (id.isNotEmpty) {
      ids.add(id);
    }
  }
  return ids;
}

/// All calendar dates between [start] and [end] (inclusive) whose weekday is in [weekdays].
///
/// Weekdays follow [DateTime.weekday] (Monday = 1, Sunday = 7).
/// Dates whose weekday is not selected are never included — including [start]
/// itself when it falls on a non-selected day.
List<DateTime> generateRecurrentTrainingDates({
  required DateTime start,
  required DateTime end,
  required Set<int> weekdays,
}) {
  if (weekdays.isEmpty) return const <DateTime>[];

  final DateTime rangeStart = DateUtils.dateOnly(start);
  final DateTime rangeEnd = DateUtils.dateOnly(end);
  if (rangeEnd.isBefore(rangeStart)) return const <DateTime>[];

  final dates = <DateTime>[];
  var current = rangeStart;
  while (!current.isAfter(rangeEnd)) {
    if (weekdays.contains(current.weekday)) {
      dates.add(current);
    }
    current = current.add(const Duration(days: 1));
  }
  return dates;
}

/// Builds one [Training] document for creation.
Training buildTrainingForCreation({
  required DateTime date,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required List<PlayerTraining> playerTraining,
  required bool isRecurrent,
  required String recurrentCode,
  required List<int> recurrentWeekdays,
  required DateTime recurrentStart,
  required DateTime recurrentEnd,
  required bool withTracker,
  String? ownerId,
}) {
  final DateTime dateTime = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  final DateTime endDateTime =
      dateTime.add(Duration(minutes: durationMinutes));

  return Training(
    seasonId: season.ref?.id,
    clubId: team.clubId,
    teamId: team.keyTeam,
    dateTime: Timestamp.fromDate(dateTime),
    dateTg: formatTrainingDateTg(date),
    duration: durationMinutes,
    startTime: formatTrainingTime(dateTime),
    endTime: formatTrainingTime(endDateTime),
    playerTraining: playerTraining,
    isFinish: false,
    withRPE: false,
    withVICP: false,
    isReccurent: isRecurrent,
    reccurentCode: isRecurrent ? recurrentCode : '',
    reccurentDay: isRecurrent ? recurrentWeekdays : const <int>[],
    reccurentStart:
        isRecurrent ? Timestamp.fromDate(DateUtils.dateOnly(recurrentStart)) : null,
    reccurentEnd:
        isRecurrent ? Timestamp.fromDate(DateUtils.dateOnly(recurrentEnd)) : null,
    withTracker: withTracker,
    ownerId: withTracker ? (ownerId ?? '') : '',
    isTrackerDataUploaded: false,
    version: '2',
  );
}

/// Builds all [Training] instances for a single or recurrent creation request.
///
/// When [playersById] is provided, each occurrence gets its own playerTraining
/// copy with presence defaulted from unavailability on that date.
List<Training> buildTrainingsForCreation({
  required DateTime startDate,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required List<PlayerTraining> playerTraining,
  required bool isRecurrent,
  required Set<int> recurrentWeekdays,
  required bool withTracker,
  String? ownerId,
  DateTime? recurrentFrom,
  DateTime? recurrentTo,
  Map<String, Player>? playersById,
}) {
  final seasonId = season.ref?.id;
  final playersMap = playersById ?? const <String, Player>{};

  List<PlayerTraining> rosterFor(DateTime date) {
    if (playersMap.isEmpty) {
      // Defensive copy so recurrent docs do not share one mutable list.
      return playerTraining
          .map(
            (p) => PlayerTraining(
              playerId: p.playerId,
              presenceType: p.presenceType ?? PresenceType.present,
            )
              ..deviceId = p.deviceId
              ..customName = p.customName,
          )
          .toList(growable: false);
    }
    return clonePlayerTrainingForDate(
      template: playerTraining,
      date: date,
      playersById: playersMap,
      seasonId: seasonId,
    );
  }

  if (!isRecurrent) {
    return <Training>[
      buildTrainingForCreation(
        date: startDate,
        time: time,
        durationMinutes: durationMinutes,
        team: team,
        season: season,
        playerTraining: rosterFor(startDate),
        isRecurrent: false,
        recurrentCode: '',
        recurrentWeekdays: const <int>[],
        recurrentStart: startDate,
        recurrentEnd: startDate,
        withTracker: withTracker,
        ownerId: ownerId,
      ),
    ];
  }

  final String recurrentCode =
      FirebaseFirestore.instance.collection(kTrainingCollectionName).doc().id;
  final DateTime rangeStart = DateUtils.dateOnly(recurrentFrom ?? startDate);
  final DateTime rangeEnd = DateUtils.dateOnly(recurrentTo ?? startDate);
  // Only selected weekdays — do not force-include [startDate] when its weekday
  // is outside [recurrentWeekdays] (first occurrence is the next match).
  final List<DateTime> dates = generateRecurrentTrainingDates(
    start: rangeStart,
    end: rangeEnd,
    weekdays: recurrentWeekdays,
  );
  final List<int> weekdayList = recurrentWeekdays.toList()..sort();

  return dates
      .map(
        (DateTime date) => buildTrainingForCreation(
          date: date,
          time: time,
          durationMinutes: durationMinutes,
          team: team,
          season: season,
          playerTraining: rosterFor(date),
          isRecurrent: true,
          recurrentCode: recurrentCode,
          recurrentWeekdays: weekdayList,
          recurrentStart: rangeStart,
          recurrentEnd: rangeEnd,
          withTracker: withTracker,
          ownerId: ownerId,
        ),
      )
      .toList();
}

/// Applies agenda form values to an existing training while preserving unrelated fields.
Training buildTrainingForUpdate({
  required Training existing,
  required DateTime date,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required bool withTracker,
  String? ownerId,
  bool? isRecurrent,
  String? recurrentCode,
  List<int>? recurrentWeekdays,
  DateTime? recurrentStart,
  DateTime? recurrentEnd,
}) {
  final DateTime dateTime = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  final DateTime endDateTime =
      dateTime.add(Duration(minutes: durationMinutes));

  final bool recurrent = isRecurrent ?? (existing.isReccurent == true);
  final String code = recurrent
      ? (recurrentCode?.trim().isNotEmpty == true
          ? recurrentCode!.trim()
          : (existing.reccurentCode?.trim() ?? ''))
      : '';
  final List<int> weekdays;
  if (recurrent) {
    weekdays = List<int>.from(
      recurrentWeekdays ?? recurrentWeekdaysFromTraining(existing),
    )..sort();
  } else {
    weekdays = const <int>[];
  }

  final Training updated = Training(
    docId: existing.docId,
    trainingId: existing.trainingId,
    seasonId: season.ref?.id,
    clubId: team.clubId ?? existing.clubId,
    teamId: team.keyTeam ?? existing.teamId,
    dateTime: Timestamp.fromDate(dateTime),
    dateTg: formatTrainingDateTg(date),
    duration: durationMinutes,
    startTime: formatTrainingTime(dateTime),
    endTime: formatTrainingTime(endDateTime),
    playerTraining: existing.playerTraining,
    isFinish: existing.isFinish,
    withRPE: existing.withRPE,
    withVICP: existing.withVICP,
    isNotifBeforeSended: existing.isNotifBeforeSended,
    dateTimeNotifBeforeSended: existing.dateTimeNotifBeforeSended,
    isNotifAfterSended: existing.isNotifAfterSended,
    dateTimeNotifAfterSended: existing.dateTimeNotifAfterSended,
    sessionType: existing.sessionType,
    gameState: existing.gameState,
    fieldPosition: existing.fieldPosition,
    gamePhases: existing.gamePhases,
    gamePrinciple: existing.gamePrinciple,
    mentalDominant: existing.mentalDominant,
    associatedTechnicalMeans: existing.associatedTechnicalMeans,
    athleticDominant: existing.athleticDominant,
    tacticalPrinciple: existing.tacticalPrinciple,
    version: existing.version ?? '2',
    isReccurent: recurrent,
    reccurentCode: code,
    reccurentDay: weekdays,
    reccurentStart: recurrent && recurrentStart != null
        ? Timestamp.fromDate(DateUtils.dateOnly(recurrentStart))
        : (recurrent ? existing.reccurentStart : null),
    reccurentEnd: recurrent && recurrentEnd != null
        ? Timestamp.fromDate(DateUtils.dateOnly(recurrentEnd))
        : (recurrent ? existing.reccurentEnd : null),
    withTracker: withTracker,
    ownerId: withTracker ? (ownerId ?? '') : '',
    isTrackerDataUploaded: existing.isTrackerDataUploaded,
    trainingStartAt: existing.trainingStartAt,
    trainingEndAt: existing.trainingEndAt,
    trainingGroup: existing.trainingGroup,
    trainingWorkshop: existing.trainingWorkshop,
    trainingWorkshopCompleted: existing.trainingWorkshopCompleted,
    ref: existing.ref,
  );

  return updated;
}

String _dateKey(DateTime date) {
  final DateTime d = DateUtils.dateOnly(date);
  return '${d.year}-${d.month}-${d.day}';
}

DateTime? _trainingDateOnly(Training training) {
  return training.dateTime?.toDate() != null
      ? DateUtils.dateOnly(training.dateTime!.toDate())
      : parseTrainingDateTg(training.dateTg);
}

/// Saves an edited training; when recurrence is enabled, syncs the whole series.
Future<void> saveTrainingEdit({
  required TrainingService service,
  required Training existing,
  required DateTime date,
  required TimeOfDay time,
  required int durationMinutes,
  required Team team,
  required Season season,
  required bool withTracker,
  String? ownerId,
  required bool isRecurrent,
  required Set<int> recurrentWeekdays,
  DateTime? recurrentFrom,
  DateTime? recurrentTo,
  List<PlayerTraining>? playerTrainingForNewOccurrences,
}) async {
  if (!isRecurrent) {
    final Training updated = buildTrainingForUpdate(
      existing: existing,
      date: date,
      time: time,
      durationMinutes: durationMinutes,
      team: team,
      season: season,
      withTracker: withTracker,
      ownerId: ownerId,
      isRecurrent: false,
      recurrentCode: '',
      recurrentWeekdays: const <int>[],
    );
    await service.updateTraining(updated);
    return;
  }

  final List<int> weekdayList = recurrentWeekdays.toList()..sort();
  final DateTime rangeStart = DateUtils.dateOnly(recurrentFrom ?? date);
  final DateTime rangeEnd = DateUtils.dateOnly(recurrentTo ?? date);
  final String recurrentCode =
      (existing.reccurentCode?.trim().isNotEmpty == true)
          ? existing.reccurentCode!.trim()
          : FirebaseFirestore.instance.collection(kTrainingCollectionName).doc().id;

  final List<DateTime> desiredDates = generateRecurrentTrainingDates(
    start: rangeStart,
    end: rangeEnd,
    weekdays: recurrentWeekdays,
  );
  final Set<String> desiredKeys = desiredDates.map(_dateKey).toSet();

  final List<Training> series =
      await service.getTrainingsByReccurentCode(recurrentCode);
  final Map<String, Training> byDate = <String, Training>{};
  for (final Training sibling in series) {
    final DateTime? siblingDate = _trainingDateOnly(sibling);
    if (siblingDate == null) continue;
    byDate[_dateKey(siblingDate)] = sibling;
  }

  // Keep the edited doc in the map even when it is not yet under the code
  // (first time enabling recurrence). Use the form date as the key so a date
  // change does not leave the same doc under two keys (old + new).
  final DateTime editedDate = DateUtils.dateOnly(date);
  final String editedKey = _dateKey(editedDate);
  final String? currentId = existing.docId?.trim();
  if (currentId != null && currentId.isNotEmpty) {
    byDate.removeWhere(
      (_, Training t) => t.docId?.trim() == currentId,
    );
    byDate[editedKey] = existing;
  }

  final List<PlayerTraining> templatePlayers =
      playerTrainingForNewOccurrences ?? existing.playerTraining;

  final templatePlayerIds = templatePlayers
      .map((p) => p.playerId?.trim() ?? '')
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  final loadedPlayers = await Future.wait(
    templatePlayerIds.map(PlayerService().getPlayerById),
  );
  final playersById = <String, Player>{
    for (var i = 0; i < templatePlayerIds.length; i++)
      if (loadedPlayers[i] != null) templatePlayerIds[i]: loadedPlayers[i]!,
  };

  // Update / create only desired weekdays — never keep an edited date whose
  // weekday is outside the selected set.
  final List<Training> toCreate = <Training>[];
  for (final DateTime desired in desiredDates) {
    final String key = _dateKey(desired);
    final Training? existingOnDate = byDate[key];
    if (existingOnDate != null &&
        (existingOnDate.docId?.trim().isNotEmpty ?? false)) {
      await service.updateTraining(
        buildTrainingForUpdate(
          existing: existingOnDate,
          date: desired,
          time: time,
          durationMinutes: durationMinutes,
          team: team,
          season: season,
          withTracker: withTracker,
          ownerId: ownerId,
          isRecurrent: true,
          recurrentCode: recurrentCode,
          recurrentWeekdays: weekdayList,
          recurrentStart: rangeStart,
          recurrentEnd: rangeEnd,
        ),
      );
      continue;
    }
    toCreate.add(
      buildTrainingForCreation(
        date: desired,
        time: time,
        durationMinutes: durationMinutes,
        team: team,
        season: season,
        playerTraining: clonePlayerTrainingForDate(
          template: templatePlayers,
          date: desired,
          playersById: playersById,
          seasonId: season.ref?.id,
        ),
        isRecurrent: true,
        recurrentCode: recurrentCode,
        recurrentWeekdays: weekdayList,
        recurrentStart: rangeStart,
        recurrentEnd: rangeEnd,
        withTracker: withTracker,
        ownerId: ownerId,
      ),
    );
  }
  if (toCreate.isNotEmpty) {
    await service.createTrainings(toCreate);
  }

  final List<String> idsToDelete = <String>[];
  for (final MapEntry<String, Training> entry in byDate.entries) {
    if (desiredKeys.contains(entry.key)) continue;
    final String? siblingId = entry.value.docId?.trim();
    if (siblingId == null || siblingId.isEmpty) continue;
    idsToDelete.add(siblingId);
  }
  if (idsToDelete.isNotEmpty) {
    await service.deleteTrainings(idsToDelete);
  }
}

/// Firestore collection name for [Training] (avoids circular import with service).
const String kTrainingCollectionName = 'training';
