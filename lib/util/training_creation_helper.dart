import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/grinta_player.dart';
import '../model/season.dart';
import '../model/team.dart';
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

/// Builds [PlayerTraining] rows for field players only (present by default).
///
/// Staff members ([hasExplicitGrintaStaffFonction] / [isGrintaRosterStaff]) are
/// excluded from attendance tracking.
List<PlayerTraining> playerTrainingFromGrintaPlayers(
  List<GrintaPlayer> players, {
  Set<String> managerIds = const <String>{},
}) {
  final rows = <PlayerTraining>[];
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

    rows.add(
      PlayerTraining(
        playerId: playerId,
        presenceType: PresenceType.present,
      ),
    );
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

/// Firestore collection name for [Training] (avoids circular import with service).
const String kTrainingCollectionName = 'training';
