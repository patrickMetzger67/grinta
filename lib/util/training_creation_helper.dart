import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_deletion_access.dart';

import '../model/grinta_player.dart';
import '../model/season.dart';
import '../model/team.dart';
import '../model/tracker/deviceOwner.dart';
import '../model/training.dart';
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

/// Shows a confirmation dialog before deleting a manually managed training.
Future<bool> confirmDeleteTraining(
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

  return confirmed == true;
}

/// Deletes a training after confirmation and shows a snackbar on the root navigator.
Future<bool> deleteManagedTraining(
  BuildContext context, {
  required Training training,
  VoidCallback? onDeleted,
}) async {
  final String? trainingId = training.docId?.trim();
  if (trainingId == null || trainingId.isEmpty) {
    return false;
  }

  final confirmed = await confirmDeleteTraining(context, training: training);
  if (!confirmed || !context.mounted) {
    return false;
  }

  final String successMessage = context.l10n.trainingDeleted;
  final String errorMessage = context.l10n.trainingDeleteError;

  try {
    await TrainingService().deleteTraining(trainingId);
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
List<PlayerTraining> playerTrainingFromGrintaPlayers(
  List<GrintaPlayer> players, {
  Set<String> managerIds = const <String>{},
  bool withTracker = false,
  Map<String, DeviceOwner>? ownerDevicesByDocId,
}) {
  final rows = <PlayerTraining>[];
  final devicesAffected = <String>{};
  final ownerDevices = ownerDevicesByDocId ?? const <String, DeviceOwner>{};

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

    final playerTraining = PlayerTraining(
      playerId: playerId,
      presenceType: PresenceType.present,
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
}) {
  if (!isRecurrent) {
    return <Training>[
      buildTrainingForCreation(
        date: startDate,
        time: time,
        durationMinutes: durationMinutes,
        team: team,
        season: season,
        playerTraining: playerTraining,
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
          playerTraining: playerTraining,
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
    isReccurent: existing.isReccurent,
    reccurentCode: existing.reccurentCode,
    reccurentDay: existing.reccurentDay,
    reccurentStart: existing.reccurentStart,
    reccurentEnd: existing.reccurentEnd,
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

/// Firestore collection name for [Training] (avoids circular import with service).
const String kTrainingCollectionName = 'training';
