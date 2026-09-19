import 'package:flutter/foundation.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/gemini_chat_service.dart';
import 'package:grinta/services/gio_session_opinion.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/player_chat_stats_service.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/model/chat_action.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/season_period_ranges.dart';

/// Loads same-type recent sessions and asks Gio to comment the open sheet.
class GioSessionOpinionService {
  GioSessionOpinionService({
    TeamService? teamService,
    TrainingService? trainingService,
    TeamCompetitionStatsService? competitionStatsService,
    MatchService? matchService,
    PolarSessionAnalysisService? polarService,
    GeminiChatService? chatService,
  }) : _teamService = teamService ?? TeamService(),
       _trainingService = trainingService ?? TrainingService(),
       _competitionStatsService =
           competitionStatsService ?? TeamCompetitionStatsService(),
       _matchService = matchService ?? MatchService(),
       _polarService = polarService ?? PolarSessionAnalysisService(),
       _chatService = chatService ?? GeminiChatService.instance;

  final TeamService _teamService;
  final TrainingService _trainingService;
  final TeamCompetitionStatsService _competitionStatsService;
  final MatchService _matchService;
  final PolarSessionAnalysisService _polarService;
  final GeminiChatService _chatService;

  Future<String> requestOpinion({
    required AppSession session,
    required String localeCode,
    required bool isMatch,
    required GioSessionOpinionSource source,
    required String eventId,
    required String playerId,
    required Map<String, num> currentMetrics,
    Player? player,
    String? teamId,
    String? playerName,
  }) async {
    final sessionType = gioSessionType(isMatch: isMatch);
    final prepared = await _prepare(
      session: session,
      isMatch: isMatch,
      source: source,
      eventId: eventId,
      playerId: playerId,
      player: player,
      teamId: teamId,
    );

    final metrics = currentMetrics.isNotEmpty
        ? currentMetrics
        : (prepared.currentMetrics ?? const <String, num>{});

    final context = buildGioSessionOpinionContext(
      sessionType: sessionType,
      source: source,
      playerName: playerName,
      current: GioOpinionSessionRecord(
        eventId: eventId.trim(),
        sessionType: sessionType,
        metrics: metrics,
        date: prepared.currentDate,
        label: prepared.currentLabel,
      ),
      history: prepared.history,
    );

    final actions = await _chatService.sendMessage(
      message: gioSessionOpinionUserMessage(isMatch: isMatch),
      context: <String, dynamic>{
        'locale': localeCode,
        'sessionPerformanceOpinion': context,
      },
      localeCode: localeCode,
    );

    final text = _firstAnswer(actions);
    if (text == null) {
      throw StateError('Gio returned an empty opinion');
    }
    return text;
  }

  Future<_PreparedOpinion> _prepare({
    required AppSession session,
    required bool isMatch,
    required GioSessionOpinionSource source,
    required String eventId,
    required String playerId,
    required Player? player,
    required String? teamId,
  }) async {
    try {
      final teams = await _resolveTeams(session, teamId);
      final catalog = await _loadCatalog(
        session: session,
        teams: teams,
        isMatch: isMatch,
      );
      final currentId = eventId.trim();
      var currentMeta = catalog[currentId];
      currentMeta ??= await _lookupCurrentEvent(
        eventId: currentId,
        isMatch: isMatch,
        teams: teams,
      );

      final sessions = await _loadPlayerSessions(
        source: source,
        playerIds: _playerIds(playerId, player),
        catalog: catalog,
        isMatch: isMatch,
      );

      Map<String, num>? currentMetrics;
      for (final sessionRecord in sessions) {
        if (sessionRecord.eventId == currentId &&
            sessionRecord.metrics.isNotEmpty) {
          currentMetrics = sessionRecord.metrics;
          break;
        }
      }

      return _PreparedOpinion(
        currentDate: currentMeta?.date,
        currentLabel: currentMeta?.label,
        currentMetrics: currentMetrics,
        history: sessions,
      );
    } catch (e, st) {
      debugPrint('GioSessionOpinionService prepare failed: $e\n$st');
      return const _PreparedOpinion();
    }
  }

  Future<List<Team>> _resolveTeams(AppSession session, String? teamId) async {
    final id = teamId?.trim() ?? '';
    if (id.isNotEmpty) {
      final cached = _findTeam(session, id);
      if (cached != null) return <Team>[cached];
      try {
        final loaded = await _teamService.getTeamById(id);
        if (loaded != null) return <Team>[loaded];
      } catch (e, st) {
        debugPrint('GioSessionOpinionService team $id: $e\n$st');
      }
      return const <Team>[];
    }
    return PlayerChatStatsService.resolveTeamsForPlayerStats(session);
  }

  Team? _findTeam(AppSession session, String teamId) {
    for (final seasons in session.teams.values) {
      for (final teams in seasons.values) {
        final team = teams[teamId];
        if (team != null) return team;
      }
    }
    return null;
  }

  Future<Map<String, _EventMeta>> _loadCatalog({
    required AppSession session,
    required List<Team> teams,
    required bool isMatch,
  }) async {
    final season = session.selectedSeason;
    final seasonId = season?.ref?.id.trim() ?? '';
    if (seasonId.isEmpty || teams.isEmpty) {
      return const <String, _EventMeta>{};
    }

    final period = resolveSeasonPeriodRanges(
      seasonId: seasonId,
      season: season,
    ).fullSeason;
    final catalog = <String, _EventMeta>{};

    await Future.wait(
      teams.map((Team team) async {
        final teamId = team.keyTeam?.trim() ?? '';
        if (teamId.isEmpty) return;
        try {
          if (isMatch) {
            final matches = await _competitionStatsService
                .loadPlayedSeasonMatches(team: team, seasonId: seasonId);
            for (final match in matches) {
              final id = match.id?.trim() ?? '';
              if (id.isEmpty) continue;
              catalog[id] = _EventMeta(
                date: matchDateForTeamStats(match),
                label: _matchLabel(match, team),
              );
            }
            return;
          }

          final trainings = await loadPastTrainingsForTeamSeason(
            trainingService: _trainingService,
            teamId: teamId,
            seasonId: seasonId,
            period: period,
          );
          for (final training in trainings) {
            final meta = _EventMeta(date: trainingDateForStats(training));
            for (final id in _trainingIds(training)) {
              catalog[id] = meta;
            }
          }
        } catch (e, st) {
          debugPrint('GioSessionOpinionService catalog team=$teamId: $e\n$st');
        }
      }),
    );

    return catalog;
  }

  Future<_EventMeta?> _lookupCurrentEvent({
    required String eventId,
    required bool isMatch,
    required List<Team> teams,
  }) async {
    if (eventId.isEmpty) return null;
    try {
      if (isMatch) {
        final match = await _matchService.getMatchById(eventId);
        if (match == null) return null;
        final team = teams.isEmpty ? null : teams.first;
        return _EventMeta(
          date: matchDateForTeamStats(match),
          label: team == null ? _matchNames(match) : _matchLabel(match, team),
        );
      }

      final training = await _trainingService.getTrainingByDocId(eventId);
      if (training == null) return null;
      return _EventMeta(date: trainingDateForStats(training));
    } catch (e, st) {
      debugPrint('GioSessionOpinionService current event: $e\n$st');
      return null;
    }
  }

  Future<List<GioOpinionSessionRecord>> _loadPlayerSessions({
    required GioSessionOpinionSource source,
    required Set<String> playerIds,
    required Map<String, _EventMeta> catalog,
    required bool isMatch,
  }) async {
    if (playerIds.isEmpty || catalog.isEmpty) {
      return const <GioOpinionSessionRecord>[];
    }

    final sessionType = gioSessionType(isMatch: isMatch);
    if (source == GioSessionOpinionSource.polar) {
      return _polarRecords(
        playerIds: playerIds,
        catalog: catalog,
        sessionType: sessionType,
      );
    }
    return _gpsRecords(
      playerIds: playerIds,
      catalog: catalog,
      sessionType: sessionType,
    );
  }

  Future<List<GioOpinionSessionRecord>> _gpsRecords({
    required Set<String> playerIds,
    required Map<String, _EventMeta> catalog,
    required String sessionType,
  }) async {
    final batches = await Future.wait(
      playerIds.map(TrackerAnalysisService.getAnalysisDocsByPlayer),
    );
    final newest = <String, TrackerAnalysisDoc>{};
    for (final doc in batches.expand((docs) => docs)) {
      final eventId = doc.analysis.eventId.trim();
      if (eventId.isEmpty || !catalog.containsKey(eventId)) continue;
      final existing = newest[eventId];
      if (existing == null || _docIsNewer(doc, existing)) {
        newest[eventId] = doc;
      }
    }

    return newest.entries
        .map((entry) {
          final meta = catalog[entry.key];
          return GioOpinionSessionRecord(
            eventId: entry.key,
            sessionType: sessionType,
            metrics: gioMetricsFromTrackerAnalysis(entry.value.analysis),
            date: meta?.date ?? entry.value.createdAt,
            label: meta?.label,
          );
        })
        .toList(growable: false);
  }

  Future<List<GioOpinionSessionRecord>> _polarRecords({
    required Set<String> playerIds,
    required Map<String, _EventMeta> catalog,
    required String sessionType,
  }) async {
    final batches = await Future.wait(
      playerIds.map((String id) => _polarService.listByPlayerId(id)),
    );
    final newest = <String, PolarSessionAnalysis>{};
    for (final analysis in batches.expand((items) => items)) {
      final eventId = analysis.eventId.trim();
      if (eventId.isEmpty || !catalog.containsKey(eventId)) continue;
      final existing = newest[eventId];
      if (existing == null || _polarIsNewer(analysis, existing)) {
        newest[eventId] = analysis;
      }
    }

    return newest.entries
        .map((entry) {
          final meta = catalog[entry.key];
          return GioOpinionSessionRecord(
            eventId: entry.key,
            sessionType: sessionType,
            metrics: gioMetricsFromPolarAnalysis(entry.value),
            date: meta?.date ?? entry.value.startedAt ?? entry.value.createdAt,
            label: meta?.label,
          );
        })
        .toList(growable: false);
  }

  Set<String> _playerIds(String playerId, Player? player) {
    final ids = <String>{};
    final id = playerId.trim();
    if (id.isNotEmpty) ids.add(id);
    if (player != null) ids.addAll(playerMemberLookupIds(player));
    return ids;
  }

  Set<String> _trainingIds(Training training) {
    final ids = <String>{};
    final docId = training.docId?.trim() ?? '';
    final trainingId = training.trainingId?.trim() ?? '';
    if (docId.isNotEmpty) ids.add(docId);
    if (trainingId.isNotEmpty) ids.add(trainingId);
    return ids;
  }

  String? _matchLabel(Match match, Team team) {
    final teamName = (team.name ?? '').trim().toLowerCase();
    final team1 = (match.team1 ?? '').trim();
    final team2 = (match.team2 ?? '').trim();
    if (teamName.isNotEmpty) {
      if (team1.toLowerCase() == teamName && team2.isNotEmpty) return team2;
      if (team2.toLowerCase() == teamName && team1.isNotEmpty) return team1;
    }
    return _matchNames(match);
  }

  String? _matchNames(Match match) {
    final team1 = (match.team1 ?? '').trim();
    final team2 = (match.team2 ?? '').trim();
    if (team1.isNotEmpty && team2.isNotEmpty) return '$team1 – $team2';
    if (team2.isNotEmpty) return team2;
    if (team1.isNotEmpty) return team1;
    return null;
  }

  bool _docIsNewer(TrackerAnalysisDoc candidate, TrackerAnalysisDoc existing) {
    final candidateDate =
        candidate.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final existingDate =
        existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return candidateDate.isAfter(existingDate);
  }

  bool _polarIsNewer(
    PolarSessionAnalysis candidate,
    PolarSessionAnalysis existing,
  ) {
    DateTime dateOf(PolarSessionAnalysis analysis) {
      return analysis.startedAt ??
          analysis.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return dateOf(candidate).isAfter(dateOf(existing));
  }

  String? _firstAnswer(List<ChatAction> actions) {
    for (final action in actions) {
      if (action is! ChatAnswerAction) continue;
      final text = action.text.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}

class _EventMeta {
  const _EventMeta({this.date, this.label});

  final DateTime? date;
  final String? label;
}

class _PreparedOpinion {
  const _PreparedOpinion({
    this.currentDate,
    this.currentLabel,
    this.currentMetrics,
    this.history = const <GioOpinionSessionRecord>[],
  });

  final DateTime? currentDate;
  final String? currentLabel;
  final Map<String, num>? currentMetrics;
  final List<GioOpinionSessionRecord> history;
}
