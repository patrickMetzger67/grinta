import 'dart:async' show StreamSubscription, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';

class AgendaService {
  final TrainingService _trainingService;
  final MatchService _matchService;

  AgendaService({
    TrainingService? trainingService,
    MatchService? matchService,
  })  : _trainingService = trainingService ?? TrainingService(),
        _matchService = matchService ?? MatchService();

  Stream<List<AgendaItem>> watchAgendaItems({
    required List<Team> teams,
    required String? seasonId,
    required DateTime start,
    required DateTime end,
  }) {
    final Timestamp timestampStart = Timestamp.fromDate(start);
    final Timestamp timestampEnd = Timestamp.fromDate(end);
    final Timestamp trainingStreamEnd =
        Timestamp.fromMillisecondsSinceEpoch(timestampEnd.millisecondsSinceEpoch + 1);

    return Stream<List<AgendaItem>>.multi((controller) {
      final Map<String, List<AgendaItem>> partialItems =
          <String, List<AgendaItem>>{};
      final List<StreamSubscription<dynamic>> subscriptions =
          <StreamSubscription<dynamic>>[];

      void emitMerged() {
        controller.add(_dedupeAndSort(partialItems.values.expand((items) => items)));
      }

      if (kDebugMode) {
        debugPrint(
          'Agenda stream: seasonId=$seasonId teams=${teams.length} '
          'range=$start → $end',
        );
      }

      for (final Team team in teams) {
        final String? teamId = team.keyTeam?.trim();
        if (teamId == null || teamId.isEmpty) {
          continue;
        }

        final String matchKey = 'match_$teamId';
        final String trainingKey = 'training_$teamId';

        subscriptions.add(
          _matchService
              .streamMatchesForTeamEngagementsBetweenDates(
                teamId: teamId,
                clubId: team.clubId ?? '',
                seasonId: seasonId,
                start: timestampStart,
                end: timestampEnd,
              )
              .listen(
            (List<grinta_match.Match> matches) {
              partialItems[matchKey] = matches
                  .map((grinta_match.Match match) => _matchToAgendaItem(
                        match: match,
                        team: team,
                      ))
                  .whereType<AgendaItem>()
                  .toList();
              emitMerged();
            },
            onError: controller.addError,
          ),
        );

        subscriptions.add(
          _trainingService
              .streamTrainingsByTeamIdBetweenDates(
                teamId: teamId,
                start: timestampStart,
                end: trainingStreamEnd,
              )
              .listen(
            (List<Training> trainings) {
              partialItems[trainingKey] = trainings
                  .map((Training training) => _trainingToAgendaItem(
                        training: training,
                        team: team,
                      ))
                  .whereType<AgendaItem>()
                  .toList();
              emitMerged();
            },
            onError: controller.addError,
          ),
        );
      }

      if (subscriptions.isEmpty) {
        controller.add(const <AgendaItem>[]);
      }

      controller.onCancel = () {
        for (final StreamSubscription<dynamic> subscription in subscriptions) {
          unawaited(subscription.cancel());
        }
      };
    });
  }

  static List<AgendaItem> _dedupeAndSort(Iterable<AgendaItem> items) {
    final Map<String, AgendaItem> unique = <String, AgendaItem>{};
    for (final AgendaItem item in items) {
      unique['${item.type.name}_${item.id}'] = item;
    }

    return unique.values.toList()
      ..sort((AgendaItem a, AgendaItem b) => a.startAt.compareTo(b.startAt));
  }

  static AgendaItem? _matchToAgendaItem({
    required grinta_match.Match match,
    required Team team,
  }) {
    final String? matchId = match.id?.trim();
    if (matchId == null || matchId.isEmpty) {
      return null;
    }

    DateTime? startAt;
    if (match.timestamp != null) {
      startAt = match.timestamp!.toDate();
    } else if (match.dateCh != null && match.timeCh != null) {
      startAt = buildTimestampFromDateAndTime(
        date: match.dateCh!,
        time: match.timeCh!,
      ).toDate();
    }

    if (startAt == null) {
      return null;
    }

    final DateTime endAt = startAt.add(const Duration(minutes: 90));
    final Timestamp timestampNow = Timestamp.now();

    return AgendaItem(
      id: matchId,
      startAt: startAt,
      endAt: endAt,
      title: team.name ?? '',
      type: AgendaItemType.match,
      match: match,
      isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
          timestampNow.millisecondsSinceEpoch,
      withTracker: match.withTracker,
      areTrackersSynchronized: match.isTrackerDataUploaded ?? false,
    );
  }

  static AgendaItem? _trainingToAgendaItem({
    required Training training,
    required Team team,
  }) {
    if (training.dateTime == null) {
      return null;
    }

    final String? trainingId = training.ref?.id.trim();
    if (trainingId == null || trainingId.isEmpty) {
      return null;
    }

    final DateTime startAt = training.dateTime!.toDate();
    final DateTime endAt = startAt.add(const Duration(minutes: 90));
    final Timestamp timestampNow = Timestamp.now();

    return AgendaItem(
      id: trainingId,
      startAt: startAt,
      endAt: endAt,
      title: '${team.name ?? ''}: Entraînement',
      type: AgendaItemType.entrainement,
      training: training,
      isDone: Timestamp.fromDate(endAt).millisecondsSinceEpoch <
          timestampNow.millisecondsSinceEpoch,
      withTracker: training.withTracker,
      areTrackersSynchronized: training.isTrackerDataUploaded,
    );
  }
}
