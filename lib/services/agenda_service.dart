import 'dart:async' show StreamController, StreamSubscription, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/non_sport_event.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/non_sport_event_service.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/util/buildTimestampFromDateAndTime.dart';
import 'package:grinta/util/intense_live_eligibility.dart';

class AgendaService {
  final TrainingService _trainingService;
  final MatchService _matchService;
  final TeamWorkloadSummaryService _teamWorkloadSummaryService;
  final NonSportEventService _nonSportEventService;

  /// In-memory cache so tracker enrichment does not re-hit Firestore on every
  /// progressive stream emission (match phases, team merges, range refreshes).
  final Map<String, TeamWorkloadSummary?> _workloadSummaryCache =
      <String, TeamWorkloadSummary?>{};

  /// Event ids that must re-hit Firestore even if a cache entry already exists
  /// (e.g. after Intense re-sync). Keeps the previous summary painted until the
  /// fresh doc arrives.
  final Set<String> _workloadSummaryForceRefetchIds = <String>{};

  /// Broadcast when [invalidateWorkloadSummaryCache] runs so active
  /// [watchAgendaItems] listeners re-enrich without a full resubscribe.
  final StreamController<String?> _workloadCacheInvalidations =
      StreamController<String?>.broadcast();

  AgendaService({
    TrainingService? trainingService,
    MatchService? matchService,
    TeamWorkloadSummaryService? teamWorkloadSummaryService,
    NonSportEventService? nonSportEventService,
  })  : _trainingService = trainingService ?? TrainingService(),
        _matchService = matchService ?? MatchService(),
        _teamWorkloadSummaryService =
            teamWorkloadSummaryService ?? TeamWorkloadSummaryService(),
        _nonSportEventService =
            nonSportEventService ?? NonSportEventService();

  /// Marks team workload for [eventId] (or all events) stale and notifies
  /// active agenda streams to re-fetch [TRACKER_TeamAnalysis].
  void invalidateWorkloadSummaryCache([String? eventId]) {
    final String? trimmed = eventId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _workloadSummaryForceRefetchIds
        ..addAll(_workloadSummaryCache.keys);
    } else {
      _workloadSummaryForceRefetchIds.add(trimmed);
    }
    if (!_workloadCacheInvalidations.isClosed) {
      _workloadCacheInvalidations.add(trimmed);
    }
  }

  Stream<List<AgendaItem>> watchAgendaItems({
    required List<Team> teams,
    required String? seasonId,
    required DateTime start,
    required DateTime end,
    String? memberId,
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
      int enrichmentGeneration = 0;
      bool isCancelled = false;

      void emitMerged() {
        final List<AgendaItem> merged =
            _dedupeAndSort(partialItems.values.expand((items) => items));

        // Paint immediately with cached summaries when available, then enrich
        // any missing tracker docs without blocking later progressive emits.
        controller.add(_applyCachedWorkloadSummaries(merged));

        final int generation = ++enrichmentGeneration;
        unawaited(() async {
          final List<AgendaItem> enriched =
              await _enrichWithTeamWorkloadSummaries(merged);
          if (isCancelled || generation != enrichmentGeneration) {
            return;
          }
          controller.add(enriched);
        }());
      }

      if (kDebugMode) {
        debugPrint(
          'Agenda stream: seasonId=$seasonId teams=${teams.length} '
          'memberId=$memberId range=$start → $end',
        );
      }

      final String? trimmedMemberId = memberId?.trim();
      if (trimmedMemberId != null && trimmedMemberId.isNotEmpty) {
        subscriptions.add(
          _nonSportEventService
              .watchEventsForMemberBetweenDates(
                memberId: trimmedMemberId,
                start: start,
                end: end,
              )
              .listen(
            (List<NonSportEvent> events) {
              partialItems['non_sport'] = events
                  .map(_nonSportEventToAgendaItem)
                  .whereType<AgendaItem>()
                  .toList();
              emitMerged();
            },
            onError: controller.addError,
          ),
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
                  .map((grinta_match.Match match) => matchToAgendaItem(
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

      subscriptions.add(
        _workloadCacheInvalidations.stream.listen((_) {
          if (!isCancelled) {
            emitMerged();
          }
        }),
      );

      final bool hasAgendaSources = teams.any((Team team) {
            final String? teamId = team.keyTeam?.trim();
            return teamId != null && teamId.isNotEmpty;
          }) ||
          (trimmedMemberId != null && trimmedMemberId.isNotEmpty);
      if (!hasAgendaSources) {
        controller.add(const <AgendaItem>[]);
      }

      controller.onCancel = () {
        isCancelled = true;
        enrichmentGeneration++;
        for (final StreamSubscription<dynamic> subscription in subscriptions) {
          unawaited(subscription.cancel());
        }
      };
    });
  }

  /// Loads agenda items using the same Firestore sources as [watchAgendaItems].
  ///
  /// Uses explicit one-shot queries instead of [watchAgendaItems] because match
  /// streams emit in phases (fallback → engagements → per-engagement queries).
  /// A timed "settle" on that stream often completes after the first phases and
  /// cancels before competition matches arrive; the agenda screen keeps listening
  /// and eventually shows them, but chat would send an empty partial snapshot.
  Future<List<AgendaItem>> loadAgendaItems({
    required List<Team> teams,
    required String? seasonId,
    required DateTime start,
    required DateTime end,
    String? memberId,
  }) async {
    final Timestamp timestampStart = Timestamp.fromDate(start);
    final Timestamp timestampEnd = Timestamp.fromDate(end);

    final List<Future<List<AgendaItem>>> teamLoads =
        <Future<List<AgendaItem>>>[];

    for (final Team team in teams) {
      final String? teamId = team.keyTeam?.trim();
      if (teamId == null || teamId.isEmpty) {
        continue;
      }

      teamLoads.add(
        _loadAgendaItemsForTeam(
          team: team,
          teamId: teamId,
          seasonId: seasonId,
          start: timestampStart,
          end: timestampEnd,
        ),
      );
    }

    final String? trimmedMemberId = memberId?.trim();
    if (trimmedMemberId != null && trimmedMemberId.isNotEmpty) {
      teamLoads.add(
        _nonSportEventService
            .watchEventsForMemberBetweenDates(
              memberId: trimmedMemberId,
              start: start,
              end: end,
            )
            .first
            .then(
              (List<NonSportEvent> events) => events
                  .map(_nonSportEventToAgendaItem)
                  .whereType<AgendaItem>()
                  .toList(),
            ),
      );
    }

    if (teamLoads.isEmpty) {
      return const <AgendaItem>[];
    }

    if (kDebugMode) {
      debugPrint(
        'Agenda load: seasonId=$seasonId teams=${teams.length} '
        'memberId=$memberId range=$start → $end',
      );
    }

    final List<List<AgendaItem>> results = await Future.wait(teamLoads);
    final List<AgendaItem> merged =
        _dedupeAndSort(results.expand((List<AgendaItem> items) => items));

    if (kDebugMode) {
      debugPrint('Agenda load: itemCount=${merged.length}');
    }

    return _enrichWithTeamWorkloadSummaries(merged);
  }

  List<AgendaItem> _applyCachedWorkloadSummaries(List<AgendaItem> items) {
    if (items.isEmpty || _workloadSummaryCache.isEmpty) {
      return items;
    }

    return items.map((AgendaItem item) {
      if (item.withTracker != true ||
          item.id.isEmpty ||
          item.teamWorkloadSummary != null) {
        return item;
      }

      final TeamWorkloadSummary? cached = _workloadSummaryCache[item.id];
      if (cached == null) {
        return item;
      }

      return _withTeamWorkloadSummary(item, cached);
    }).toList();
  }

  Future<List<AgendaItem>> _enrichWithTeamWorkloadSummaries(
    List<AgendaItem> items,
  ) async {
    if (items.isEmpty) {
      return items;
    }

    final List<AgendaItem> enriched = await Future.wait(
      items.map((AgendaItem item) async {
        if (item.withTracker != true || item.id.isEmpty) {
          return item;
        }

        if (item.teamWorkloadSummary != null) {
          _workloadSummaryCache[item.id] = item.teamWorkloadSummary;
          return item;
        }

        final bool forceRefetch =
            _workloadSummaryForceRefetchIds.contains(item.id);

        if (!forceRefetch && _workloadSummaryCache.containsKey(item.id)) {
          final TeamWorkloadSummary? cached = _workloadSummaryCache[item.id];
          if (cached != null) {
            return _withTeamWorkloadSummary(item, cached);
          }
          // Cached miss: retry once trackers are synced / session is done so
          // finish+upload is not stuck on a pre-sync null entry.
          final bool shouldRetryNullCache = item.areTrackersSynchronized ||
              item.isDone ||
              item.training?.isFinish == true ||
              item.training?.isTrackerDataUploaded == true ||
              item.match?.isTrackerDataUploaded == true;
          if (!shouldRetryNullCache) {
            return item;
          }
        }

        final TeamWorkloadSummary? summary =
            await _teamWorkloadSummaryService.getByEventId(item.id);
        _workloadSummaryCache[item.id] = summary;
        _workloadSummaryForceRefetchIds.remove(item.id);
        if (summary == null) {
          return item;
        }

        return _withTeamWorkloadSummary(item, summary);
      }),
    );

    return enriched;
  }

  static AgendaItem _withTeamWorkloadSummary(
    AgendaItem item,
    TeamWorkloadSummary summary,
  ) {
    return AgendaItem(
      id: item.id,
      startAt: item.startAt,
      endAt: item.endAt,
      title: item.title,
      subtitle: item.subtitle,
      type: item.type,
      isDone: item.isDone,
      allDay: item.allDay,
      match: item.match,
      training: item.training,
      nonSportEvent: item.nonSportEvent,
      activityMetrics: item.activityMetrics,
      withTracker: item.withTracker,
      areTrackersSynchronized: item.areTrackersSynchronized,
      teamWorkloadSummary: summary,
    );
  }

  Future<List<AgendaItem>> _loadAgendaItemsForTeam({
    required Team team,
    required String teamId,
    required String? seasonId,
    required Timestamp start,
    required Timestamp end,
  }) async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      _matchService.getMatchesForTeamEngagementsBetweenDates(
        teamId: teamId,
        clubId: team.clubId ?? '',
        seasonId: seasonId,
        start: start,
        end: end,
      ),
      _trainingService.getTrainingsByTeamIdBetweenDates(
        teamId: teamId,
        start: start,
        end: Timestamp.fromMillisecondsSinceEpoch(
          end.millisecondsSinceEpoch + 1,
        ),
      ),
    ]);

    final List<grinta_match.Match> matches =
        results[0] as List<grinta_match.Match>;
    final List<Training> trainings = results[1] as List<Training>;

    final List<AgendaItem> items = <AgendaItem>[
      ...matches
          .map(
            (grinta_match.Match match) => matchToAgendaItem(
              match: match,
              team: team,
            ),
          )
          .whereType<AgendaItem>(),
      ...trainings
          .map(
            (Training training) => _trainingToAgendaItem(
              training: training,
              team: team,
            ),
          )
          .whereType<AgendaItem>(),
    ];

    return items;
  }

  static List<AgendaItem> _dedupeAndSort(Iterable<AgendaItem> items) {
    final Map<String, AgendaItem> unique = <String, AgendaItem>{};
    for (final AgendaItem item in items) {
      unique['${item.type.name}_${item.id}'] = item;
    }

    return unique.values.toList()
      ..sort((AgendaItem a, AgendaItem b) {
        if (a.allDay != b.allDay) {
          return a.allDay ? -1 : 1;
        }
        return a.startAt.compareTo(b.startAt);
      });
  }

  static AgendaItem? _nonSportEventToAgendaItem(NonSportEvent event) {
    final String? eventId = event.id?.trim();
    if (eventId == null || eventId.isEmpty || event.title.trim().isEmpty) {
      return null;
    }

    final String? location = event.location?.trim();
    return AgendaItem(
      id: eventId,
      startAt: event.startAt,
      endAt: event.endAt,
      title: event.title,
      subtitle: location,
      type: AgendaItemType.nonSport,
      allDay: event.allDay,
      isDone: event.endAt.isBefore(DateTime.now()),
      nonSportEvent: event,
    );
  }

  static AgendaItem? matchToAgendaItem({
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

    final int durationMinutes = match.duration ?? 90;
    final DateTime endAt = startAt.add(Duration(minutes: durationMinutes));
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
    final int durationMinutes = training.duration ?? 90;
    final DateTime endAt = startAt.add(
      Duration(minutes: durationMinutes > 0 ? durationMinutes : 90),
    );
    final Timestamp timestampNow = Timestamp.now();

    return AgendaItem(
      id: trainingId,
      startAt: startAt,
      endAt: endAt,
      title: '${team.name ?? ''}: Entraînement',
      type: AgendaItemType.entrainement,
      training: training,
      isDone: training.isFinish == true ||
          Timestamp.fromDate(endAt).millisecondsSinceEpoch <
              timestampNow.millisecondsSinceEpoch,
      withTracker: training.withTracker,
      areTrackersSynchronized: training.isTrackerDataUploaded,
    );
  }
}
