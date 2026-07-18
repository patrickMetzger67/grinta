import 'package:flutter/foundation.dart';
import 'package:grinta/model/compoType.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/teamParam.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/compoTypeService.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/matchStatsService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamParamService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trackerSvgService.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/svg_rasterizer.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:grinta/widget/half_pitch_compo_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Builds [SessionStatsReport] from tracker team analysis (Stats tab data).
///
/// Match heatmaps use the **same** inputs as `#player_analysis` Heatmap:
/// `TeamWorkloadSummary.playerScores[].trackerId` →
/// `TRACKER_Analysis/{eventId}_{trackerId}` →
/// `TrackerSvgService.getSvgForTrackerPeriod(...)`.
class SessionStatsReportService {
  SessionStatsReportService({
    TeamWorkloadSummaryService? summaryService,
    PlayerService? playerService,
    MatchService? matchService,
    MatchCompoService? matchCompoService,
    CompoTypeService? compoTypeService,
    MatchStatsService? matchStatsService,
    HighlightsService? highlightsService,
    TrackerSvgService? svgService,
    http.Client? httpClient,
  })  : _summaryService = summaryService ?? TeamWorkloadSummaryService(),
        _playerService = playerService ?? PlayerService(),
        _matchService = matchService ?? MatchService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _compoTypeService = compoTypeService ?? CompoTypeService(),
        _matchStatsService = matchStatsService ?? MatchStatsService(),
        _highlightsService = highlightsService ?? HighlightsService(),
        _svgService = svgService ?? TrackerSvgService(),
        _httpClient = httpClient ?? http.Client();

  final TeamWorkloadSummaryService _summaryService;
  final PlayerService _playerService;
  final MatchService _matchService;
  final MatchCompoService _matchCompoService;
  final CompoTypeService _compoTypeService;
  final MatchStatsService _matchStatsService;
  final HighlightsService _highlightsService;
  final TrackerSvgService _svgService;
  final http.Client _httpClient;

  static const List<({String key, String label})> _heatmapPeriods =
      <({String key, String label})>[
    (key: 'firstHalf', label: '1ere mi-temps'),
    (key: 'secondHalf', label: '2e mi-temps'),
    (key: 'fullMatch', label: 'Match complet'),
  ];

  static const Map<String, String> _fieldZoneLabels = <String, String>{
    'ATT_LEFT': 'Attaque gauche',
    'ATT_RIGHT': 'Attaque droite',
    'MID_LEFT': 'Milieu gauche',
    'MID_RIGHT': 'Milieu droite',
    'DEF_LEFT': 'Defense gauche',
    'DEF_RIGHT': 'Defense droite',
  };

  /// Loads team analysis for [eventId] and resolves player display names,
  /// per-player analysis tabs, and (for matches) heatmaps / field zones.
  Future<SessionStatsReport?> buildReport({
    required String eventId,
    required bool isMatch,
    String? title,
    String? subtitle,
    String? teamName,
    String? teamId,
    DateTime? eventDate,
    String localeCode = 'fr',
    String unknownPlayerLabel = 'Joueur',
    DateTime? generatedAt,
    TeamWorkloadSummary? summary,
    grinta_match.Match? match,
  }) async {
    final safeEventId = eventId.trim();
    if (safeEventId.isEmpty) {
      return null;
    }

    final resolvedSummary =
        summary ?? await _summaryService.getByEventId(safeEventId);
    if (resolvedSummary == null || resolvedSummary.playerScores.isEmpty) {
      return null;
    }

    final String? safeTeamId = teamId?.trim().isNotEmpty == true
        ? teamId!.trim()
        : null;

    final TeamParam teamParam = safeTeamId == null
        ? TeamParam.defaultConfig()
        : await TeamParamService.getEffectiveTeamParam(safeTeamId);

    final List<TrackerAnalysisResult> analyses =
        await TrackerAnalysisService.getAnalysesByEvent(safeEventId);
    final Map<String, TrackerAnalysisResult> analysisByPlayerId =
        <String, TrackerAnalysisResult>{};
    final Map<String, TrackerAnalysisResult> analysisByTrackerId =
        <String, TrackerAnalysisResult>{};
    for (final TrackerAnalysisResult analysis in analyses) {
      final String pid = analysis.playerId.trim();
      final String tid = analysis.trackerId.trim();
      if (pid.isNotEmpty) {
        analysisByPlayerId[pid] = analysis;
      }
      for (final String candidate
          in TrackerSvgService.trackerIdCandidates(tid)) {
        analysisByTrackerId[candidate] = analysis;
      }
    }

    grinta_match.Match? resolvedMatch = match;
    if (isMatch && resolvedMatch == null) {
      resolvedMatch = await _matchService.getMatchById(safeEventId);
    }

    final SessionStatsReportMatchHeader? matchHeader = isMatch
        ? await _buildMatchHeader(
            match: resolvedMatch,
            teamId: safeTeamId,
          )
        : null;

    final Future<SessionStatsReportTacticalSchema?> tacticalFuture = isMatch
        ? _loadTacticalSchema(
            matchId: safeEventId,
            teamId: safeTeamId,
            unknownPlayerLabel: unknownPlayerLabel,
          )
        : Future<SessionStatsReportTacticalSchema?>.value(null);

    final Future<List<SessionStatsReportHighlightEvent>> highlightsFuture =
        isMatch
            ? _loadHighlightEvents(
                matchId: safeEventId,
                match: resolvedMatch,
                teamId: safeTeamId,
              )
            : Future<List<SessionStatsReportHighlightEvent>>.value(
                const <SessionStatsReportHighlightEvent>[],
              );

    // Same player list / trackerIds as match_tracker_stats_table → player_analysis.
    final playerRows = <SessionStatsReportPlayerRow>[];
    final playerDetails = <SessionStatsReportPlayerDetail>[];

    for (final score in resolvedSummary.playerScores) {
      final Player? player = await _playerService
          .getPlayerById(score.playerId)
          .catchError((_) => null);
      final displayName = player != null
          ? playerDisplayName(player, unknownLabel: unknownPlayerLabel)
          : (score.playerId.trim().isEmpty
              ? unknownPlayerLabel
              : score.playerId.trim());

      final metrics = <String, double>{};
      final zScores = <String, double>{};
      for (final metric in kSessionStatsReportMetrics) {
        final playerMetric = score.getMetric(metric.key);
        metrics[metric.key] = playerMetric?.value ?? 0;
        if (playerMetric != null) {
          zScores[metric.key] = playerMetric.zScore;
        }
      }

      playerRows.add(
        SessionStatsReportPlayerRow(
          playerId: score.playerId,
          displayName: displayName,
          trackerId: score.trackerId,
          metrics: metrics,
          zScores: zScores,
        ),
      );

      final TrackerAnalysisResult? analysis = _resolveAnalysisForScore(
        score: score,
        eventId: safeEventId,
        analysisByPlayerId: analysisByPlayerId,
        analysisByTrackerId: analysisByTrackerId,
      );

      final Uint8List? photoBytes =
          player == null ? null : await _loadPlayerPhotoBytes(player);

      playerDetails.add(
        await _buildPlayerDetail(
          score: score,
          displayName: displayName,
          analysis: analysis,
          photoBytes: photoBytes,
          teamParam: teamParam,
          isMatch: isMatch,
          // TRACKER_Svg key uses TeamWorkloadSummary.eventId + score.trackerId.
          eventId: resolvedSummary.eventId.trim().isNotEmpty
              ? resolvedSummary.eventId.trim()
              : safeEventId,
        ),
      );
    }

    playerRows.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );
    playerDetails.sort(
      (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
    );

    final teamAverages = <String, double>{};
    for (final metric in kSessionStatsReportMetrics) {
      teamAverages[metric.key] =
          resolvedSummary.metricStats[metric.key]?.mean ?? 0;
    }

    final String resolvedTitle;
    if ((title ?? '').trim().isNotEmpty) {
      resolvedTitle = title!.trim();
    } else if (matchHeader?.opponentName?.trim().isNotEmpty == true) {
      resolvedTitle = 'vs ${matchHeader!.opponentName!.trim()}';
    } else if (isMatch &&
        resolvedMatch != null &&
        (resolvedMatch.team1 ?? '').trim().isNotEmpty &&
        (resolvedMatch.team2 ?? '').trim().isNotEmpty) {
      resolvedTitle =
          '${resolvedMatch.team1!.trim()} - ${resolvedMatch.team2!.trim()}';
    } else {
      resolvedTitle = isMatch ? 'Match' : 'Entrainement';
    }

    String? dateLabel;
    String? timeLabel;
    final DateTime? effectiveDate = eventDate ??
        (resolvedMatch == null ? null : matchKickoffDateTime(resolvedMatch));
    if (effectiveDate != null) {
      dateLabel = DateFormat.yMMMMd(localeCode).format(effectiveDate);
      timeLabel = DateFormat.Hm(localeCode).format(effectiveDate);
    }

    String? resolvedTeamName = teamName?.trim().isNotEmpty == true
        ? teamName!.trim()
        : null;
    if (resolvedTeamName == null &&
        safeTeamId != null &&
        resolvedMatch != null) {
      final MatchSide? side = teamSideForMatch(
        match: resolvedMatch,
        teamId: safeTeamId,
      );
      if (side == MatchSide.team1) {
        resolvedTeamName = resolvedMatch.team1?.trim();
      } else if (side == MatchSide.team2) {
        resolvedTeamName = resolvedMatch.team2?.trim();
      }
    }

    final SessionStatsReportTacticalSchema? tacticalSchema =
        await tacticalFuture;
    final List<SessionStatsReportHighlightEvent> highlightEvents =
        await highlightsFuture;

    return SessionStatsReport(
      eventId: safeEventId,
      title: resolvedTitle,
      subtitle: subtitle?.trim().isNotEmpty == true ? subtitle!.trim() : null,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      teamName: resolvedTeamName,
      isMatch: isMatch,
      generatedAt: generatedAt ?? DateTime.now(),
      playersCount: playerRows.isNotEmpty
          ? playerRows.length
          : resolvedSummary.playersCount,
      averageWorkloadScore: resolvedSummary.averageWorkloadScore,
      sessionDuration: resolvedSummary.sessionDuration,
      teamAverages: teamAverages,
      playerRows: playerRows,
      matchHeader: matchHeader,
      tacticalSchema: tacticalSchema,
      highlightEvents: highlightEvents,
      playerDetails: playerDetails,
    );
  }

  Future<SessionStatsReportPlayerDetail> _buildPlayerDetail({
    required TeamPlayerMetricScores score,
    required String displayName,
    required TrackerAnalysisResult? analysis,
    required Uint8List? photoBytes,
    required TeamParam teamParam,
    required bool isMatch,
    required String eventId,
  }) async {
    final List<SessionStatsReportSpeedZoneRow> speedZones =
        <SessionStatsReportSpeedZoneRow>[];
    if (analysis != null) {
      for (final TeamSpeedZone zone in teamParam.orderedSpeedZones) {
        final SpeedZoneStat? stat = _findSpeedZone(analysis.speedZones, zone.zoneId);
        speedZones.add(
          SessionStatsReportSpeedZoneRow(
            zoneId: zone.zoneId,
            label: zone.label,
            rangeLabel: _speedZoneRange(zone),
            duration: stat?.duration ?? Duration.zero,
            percent: stat?.percentOfSession ?? 0,
          ),
        );
      }
    }

    final List<SessionStatsReportTimelineBucket> timeline =
        <SessionStatsReportTimelineBucket>[];
    if (analysis != null) {
      final sorted = [...analysis.distanceTimeline]
        ..sort((a, b) => a.bucketStartMs.compareTo(b.bucketStartMs));
      for (final DistanceTimelineStat bucket in sorted) {
        timeline.add(
          SessionStatsReportTimelineBucket(
            label: bucket.label,
            walkingMeters: bucket.walkingMeters,
            joggingMeters: bucket.joggingMeters,
            runningMeters: bucket.runningMeters,
            highIntensityMeters: bucket.highIntensityMeters,
          ),
        );
      }
    }

    final List<SessionStatsReportFieldZoneCell> fieldZones =
        <SessionStatsReportFieldZoneCell>[];
    if (isMatch && analysis != null) {
      for (final String zoneId in _fieldZoneLabels.keys) {
        final FieldZoneStats? zone = _findFieldZone(
          analysis.distanceByZones,
          zoneId,
        );
        fieldZones.add(
          SessionStatsReportFieldZoneCell(
            zoneId: zoneId,
            label: _fieldZoneLabels[zoneId]!,
            distanceKm: (zone?.distanceMeters ?? 0) / 1000.0,
            occupancyPercent: zone?.occupancyPercent ?? 0,
          ),
        );
      }
    }

    // Heatmap key from TeamWorkloadSummary only:
    // TRACKER_Svg/{playerScores.trackerId}-{summary.eventId}_{period}
    final List<SessionStatsReportHeatmapImage> heatmaps = isMatch
        ? await _loadHeatmapsFromPlayerScoreTrackerId(
            eventId: eventId,
            trackerId: score.trackerId.trim(),
          )
        : const <SessionStatsReportHeatmapImage>[];

    return SessionStatsReportPlayerDetail(
      playerId: score.playerId,
      displayName: displayName,
      trackerId: score.trackerId,
      photoBytes: photoBytes,
      distanceKm: analysis?.distanceKm ??
          score.getMetric(TeamWorkloadMetricKeys.distanceKm)?.value ??
          0,
      averageSpeedKmh: analysis?.averageSpeedKmh ?? 0,
      maxValidatedSpeedKmh: analysis?.maxValidatedSpeedKmh ??
          score
              .getMetric(TeamWorkloadMetricKeys.maxValidatedSpeedKmh)
              ?.value ??
          0,
      maxAccelerationMps2: analysis?.maxAccelerationMps2 ??
          score.getMetric(TeamWorkloadMetricKeys.maxAccelerationMps2)?.value ??
          0,
      sprintCount: analysis?.sprintCount ??
          (score.getMetric(TeamWorkloadMetricKeys.sprintCount)?.value ?? 0)
              .round(),
      highAccelerationCount: analysis?.highAccelerationCount ??
          (score
                      .getMetric(TeamWorkloadMetricKeys.highAccelerationCount)
                      ?.value ??
                  0)
              .round(),
      highSpeedDuration: analysis?.highSpeedDuration ??
          Duration(
            milliseconds: ((score
                            .getMetric(
                              TeamWorkloadMetricKeys.highSpeedDuration,
                            )
                            ?.value ??
                        0) *
                    1000)
                .round(),
          ),
      workloadScore: analysis?.workloadScore ??
          score.getMetric(TeamWorkloadMetricKeys.workloadScore)?.value ??
          0,
      fatigueIndex: analysis?.fatigueIndex ?? 0,
      duration: analysis?.duration ?? Duration.zero,
      speedZones: speedZones,
      distanceTimeline: timeline,
      fieldZones: fieldZones,
      heatmaps: heatmaps,
    );
  }

  /// Same resolution as opening `#player_analysis` from the stats table.
  TrackerAnalysisResult? _resolveAnalysisForScore({
    required TeamPlayerMetricScores score,
    required String eventId,
    required Map<String, TrackerAnalysisResult> analysisByPlayerId,
    required Map<String, TrackerAnalysisResult> analysisByTrackerId,
  }) {
    final String playerId = score.playerId.trim();
    if (playerId.isNotEmpty) {
      final TrackerAnalysisResult? byPlayer = analysisByPlayerId[playerId];
      if (byPlayer != null) {
        return byPlayer;
      }
    }

    for (final String tid
        in TrackerSvgService.trackerIdCandidates(score.trackerId)) {
      final TrackerAnalysisResult? byTracker = analysisByTrackerId[tid];
      if (byTracker != null) {
        return byTracker;
      }
    }

    return null;
  }

  Future<SessionStatsReportTacticalSchema?> _loadTacticalSchema({
    required String matchId,
    required String? teamId,
    required String unknownPlayerLabel,
  }) async {
    try {
      MatchCompo? compo;
      if (teamId != null && teamId.trim().isNotEmpty) {
        compo = await _matchCompoService.getMatchCompoByMatchAndTeamId(
          matchId,
          teamId.trim(),
        );
      }
      compo ??= await _matchCompoService.getFirstMatchCompoByMatchId(matchId);
      if (compo == null) {
        return null;
      }

      final String? compoTypeId = compo.compoTypeID?.trim();
      CompoType? compoType;
      if (compoTypeId != null && compoTypeId.isNotEmpty) {
        compoType = await _compoTypeService.getCompoTypeById(compoTypeId);
      }
      if (compoType == null) {
        return null;
      }

      final Map<String, PlayerCompo> startersBySlot =
          startersFromMatchCompo(compo);
      final List<CompoSlot> slots = buildCompoSlots(compoType);
      final List<PlayerCompo> bench = substitutesFromMatchCompo(compo);

      final Set<String> playerIds = <String>{
        for (final PlayerCompo p in startersBySlot.values)
          if ((p.playerID ?? '').trim().isNotEmpty) p.playerID!.trim(),
        for (final PlayerCompo p in bench)
          if ((p.playerID ?? '').trim().isNotEmpty) p.playerID!.trim(),
      };

      final Map<String, Player> playersById = <String, Player>{};
      final Map<String, Uint8List?> photosById = <String, Uint8List?>{};
      await Future.wait(
        playerIds.map((String id) async {
          final Player? player =
              await _playerService.getPlayerById(id).catchError((_) => null);
          if (player != null) {
            playersById[id] = player;
            // Keep original photo bytes; PDF clips to a circle via ClipOval
            // (no white/black square plate behind the avatar).
            photosById[id] = await _loadPlayerPhotoBytes(player);
          }
        }),
      );

      final List<SessionStatsReportPitchPlayer> starters =
          <SessionStatsReportPitchPlayer>[];
      for (final CompoSlot slot in slots) {
        final PlayerCompo? slotPlayer = startersBySlot[slot.id];
        if (slotPlayer == null) {
          continue;
        }
        final String playerId = (slotPlayer.playerID ?? '').trim();
        if (playerId.isEmpty) {
          continue;
        }
        final Player? player = playersById[playerId];
        final String displayName = _pitchDisplayName(
          compo: slotPlayer,
          player: player,
          unknownPlayerLabel: unknownPlayerLabel,
        );

        starters.add(
          SessionStatsReportPitchPlayer(
            playerId: playerId,
            displayName: displayName,
            slotId: slot.id,
            role: slot.role,
            x: slot.x,
            y: slot.y,
            shirtNumber: slotPlayer.number,
            photoBytes: photosById[playerId],
          ),
        );
      }

      final List<SessionStatsReportBenchPlayer> substitutes =
          <SessionStatsReportBenchPlayer>[];
      for (final PlayerCompo sub in bench) {
        final String playerId = (sub.playerID ?? '').trim();
        if (playerId.isEmpty) {
          continue;
        }
        final Player? player = playersById[playerId];
        final String displayName = _pitchDisplayName(
          compo: sub,
          player: player,
          unknownPlayerLabel: unknownPlayerLabel,
        );
        substitutes.add(
          SessionStatsReportBenchPlayer(
            playerId: playerId,
            displayName: displayName,
            shirtNumber: sub.number,
            photoBytes: photosById[playerId],
          ),
        );
      }

      final String formationName = (compoType.name ?? '').trim().isNotEmpty
          ? compoType.name!.trim()
          : 'Compo';

      if (starters.isEmpty && substitutes.isEmpty) {
        return null;
      }

      return SessionStatsReportTacticalSchema(
        formationName: formationName,
        starters: starters,
        substitutes: substitutes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'SessionStatsReportService: tactical schema failed for '
          'matchId=$matchId: $e',
        );
      }
      return null;
    }
  }

  Future<List<SessionStatsReportHighlightEvent>> _loadHighlightEvents({
    required String matchId,
    required grinta_match.Match? match,
    required String? teamId,
  }) async {
    try {
      // 1) FMI (matchStats) when present.
      final MatchStats? matchStats =
          await _matchStatsService.getMatchStatsByMatchId(matchId);
      final List<MatchStatHighLight> fmi =
          List<MatchStatHighLight>.from(matchStats?.highlights ?? const [])
              .where(_isUsableFmiHighlight)
              .toList();
      if (fmi.isNotEmpty) {
        final String home = (match?.team1 ?? '').trim();
        final String away = (match?.team2 ?? '').trim();
        fmi.sort((a, b) => (a.time ?? 0).compareTo(b.time ?? 0));
        if (kDebugMode) {
          debugPrint(
            'SessionStatsReportService: using FMI highlights '
            'count=${fmi.length} matchId=$matchId',
          );
        }
        return fmi
            .map(
              (MatchStatHighLight h) => _mapFmiHighlight(
                highlight: h,
                homeTeamName: home,
                awayTeamName: away,
              ),
            )
            .toList();
      }

      // 2) Fallback: temps forts créés dans l'app (collection highLights).
      if (kDebugMode) {
        debugPrint(
          'SessionStatsReportService: no FMI highlights, '
          'fallback to Grinta app highlights matchId=$matchId',
        );
      }
      return _loadGrintaHighlightEvents(matchId: matchId, match: match, teamId: teamId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'SessionStatsReportService: highlights failed for matchId=$matchId: $e',
        );
      }
      // Last resort: still try Grinta if FMI path threw.
      try {
        return await _loadGrintaHighlightEvents(
          matchId: matchId,
          match: match,
          teamId: teamId,
        );
      } catch (_) {
        return const <SessionStatsReportHighlightEvent>[];
      }
    }
  }

  bool _isUsableFmiHighlight(MatchStatHighLight h) {
    final String type = (h.type ?? '').trim();
    final String player = (h.player ?? '').trim();
    final String team = (h.team ?? '').trim();
    return type.isNotEmpty || player.isNotEmpty || team.isNotEmpty;
  }

  Future<List<SessionStatsReportHighlightEvent>> _loadGrintaHighlightEvents({
    required String matchId,
    required grinta_match.Match? match,
    required String? teamId,
  }) async {
    List<Highlights> grinta =
        await _highlightsService.getHighlightsByMatchCalendarId(
      matchId,
      teamId: teamId,
    );
    // Retry without team filter — some docs omit teamId.
    if (grinta.isEmpty && (teamId ?? '').trim().isNotEmpty) {
      grinta = await _highlightsService.getHighlightsByMatchCalendarId(matchId);
    }
    if (grinta.isEmpty) {
      return const <SessionStatsReportHighlightEvent>[];
    }

    final List<SessionStatsReportHighlightEvent> out =
        <SessionStatsReportHighlightEvent>[];
    for (final Highlights h in grinta) {
      final SessionStatsReportHighlightEvent? mapped =
          await _mapGrintaHighlight(highlight: h, match: match);
      if (mapped != null) {
        out.add(mapped);
      }
    }
    out.sort((a, b) {
      final int byMin = a.minute.compareTo(b.minute);
      if (byMin != 0) return byMin;
      return a.extraTime.compareTo(b.extraTime);
    });
    if (kDebugMode) {
      debugPrint(
        'SessionStatsReportService: Grinta highlights count=${out.length} '
        'matchId=$matchId',
      );
    }
    return out;
  }

  SessionStatsReportHighlightEvent _mapFmiHighlight({
    required MatchStatHighLight highlight,
    required String homeTeamName,
    required String awayTeamName,
  }) {
    final String type = _normalizeHighlightType(highlight.type);
    final String team = (highlight.team ?? '').trim();
    final bool isHome = _isHomeTeamName(team, homeTeamName, awayTeamName);
    final String player = (highlight.player ?? '').trim();
    final String incoming = (highlight.incomingPlayer ?? '').trim();

    return SessionStatsReportHighlightEvent(
      minute: highlight.time ?? 0,
      type: type,
      typeLabel: _highlightTypeLabel(type),
      playerName: player.isNotEmpty ? player : '-',
      secondaryPlayerName: incoming.isNotEmpty ? incoming : null,
      teamName: team.isNotEmpty
          ? team
          : (isHome ? homeTeamName : awayTeamName),
      isHomeSide: isHome,
    );
  }

  Future<SessionStatsReportHighlightEvent?> _mapGrintaHighlight({
    required Highlights highlight,
    required grinta_match.Match? match,
  }) async {
    final ActionType? action = highlight.actionType;
    if (action == null || action == ActionType.timeEvent) {
      return null;
    }

    String type;
    String playerName = '';
    String? secondary;
    String? primaryPlayerId;
    String? secondaryPlayerId;

    switch (action) {
      case ActionType.goal:
        type = 'goal';
        final Goal? goal = highlight.value is Goal ? highlight.value as Goal : null;
        playerName = (goal?.playerName ?? '').trim();
        primaryPlayerId = goal?.playerId?.trim();
        final String passer = (goal?.playerDecisivePasser ?? '').trim();
        secondary = passer.isEmpty ? null : passer;
        secondaryPlayerId = goal?.decisivePasserPlayerId?.trim();
        break;
      case ActionType.yellowCard:
        type = 'yellowCard';
        final YellowRedCard? card =
            highlight.value is YellowRedCard ? highlight.value as YellowRedCard : null;
        playerName = (card?.playerName ?? '').trim();
        primaryPlayerId = card?.playerId?.trim();
        break;
      case ActionType.redCard:
        type = 'redCard';
        final YellowRedCard? card =
            highlight.value is YellowRedCard ? highlight.value as YellowRedCard : null;
        playerName = (card?.playerName ?? '').trim();
        primaryPlayerId = card?.playerId?.trim();
        break;
      case ActionType.substitution:
        type = 'substitution';
        final Substitution? sub =
            highlight.value is Substitution ? highlight.value as Substitution : null;
        playerName = (sub?.outgoingPlayerName ?? '').trim();
        primaryPlayerId = sub?.outgoingPlayerId?.trim();
        final String incoming = (sub?.enteringPlayerName ?? '').trim();
        secondary = incoming.isEmpty ? null : incoming;
        secondaryPlayerId = sub?.enteringPlayerId?.trim();
        break;
      case ActionType.timeEvent:
        return null;
    }

    if (playerName.isEmpty && (primaryPlayerId ?? '').isNotEmpty) {
      playerName = await _resolvePlayerLabel(primaryPlayerId!);
    }
    if ((secondary == null || secondary.isEmpty) &&
        (secondaryPlayerId ?? '').isNotEmpty) {
      secondary = await _resolvePlayerLabel(secondaryPlayerId!);
    }
    if (playerName.isEmpty) {
      playerName = '-';
    }

    final MatchSide? side = match == null
        ? null
        : sideForAffiliationTeam(
            match,
            affiliationTeamForHighlight(highlight),
          );
    final bool isHome = side != MatchSide.team2;
    final String teamName = (match == null || side == null)
        ? ''
        : teamDisplayNameForSide(match, side);

    return SessionStatsReportHighlightEvent(
      minute: highlight.minute ?? 0,
      extraTime: highlight.extraTime ?? 0,
      type: type,
      typeLabel: _highlightTypeLabel(type),
      playerName: playerName,
      secondaryPlayerName: secondary,
      teamName: teamName,
      isHomeSide: isHome,
    );
  }

  Future<String> _resolvePlayerLabel(String playerId) async {
    try {
      final Player? player =
          await _playerService.getPlayerById(playerId).catchError((_) => null);
      if (player == null) return '';
      return formatPlayerShortName(player, unknownLabel: '');
    } catch (_) {
      return '';
    }
  }

  String _normalizeHighlightType(String? raw) {
    final String n = (raw ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('-', '_');
    switch (n) {
      case 'goal':
      case 'but':
      case 'penalty':
        return 'goal';
      case 'own_goal':
      case 'owngoal':
        return 'ownGoal';
      case 'yellowcard':
      case 'yellow_card':
      case 'carton_jaune':
        return 'yellowCard';
      case 'redcard':
      case 'red_card':
      case 'carton_rouge':
        return 'redCard';
      case 'replacement':
      case 'substitution':
      case 'change':
      case 'changement':
        return 'substitution';
      default:
        return n.isEmpty ? 'other' : n;
    }
  }

  String _highlightTypeLabel(String type) {
    switch (type) {
      case 'goal':
        return 'But';
      case 'ownGoal':
        return 'CSC';
      case 'yellowCard':
        return 'Carton jaune';
      case 'redCard':
        return 'Carton rouge';
      case 'substitution':
        return 'Changement';
      default:
        return 'Evenement';
    }
  }

  bool _isHomeTeamName(String eventTeam, String home, String away) {
    final String event = eventTeam.trim().toLowerCase();
    final String left = home.trim().toLowerCase();
    final String right = away.trim().toLowerCase();
    if (event.isEmpty) return true;
    if (left.isNotEmpty && event == left) return true;
    if (right.isNotEmpty && event == right) return false;
    return true;
  }

  /// Prefer Player short name (A.DELEAU); fall back to compo label.
  String _pitchDisplayName({
    required PlayerCompo compo,
    required Player? player,
    required String unknownPlayerLabel,
  }) {
    if (player != null) {
      final String fromPlayer = formatPlayerShortName(
        player,
        unknownLabel: '',
      ).trim();
      if (fromPlayer.isNotEmpty) {
        return fromPlayer;
      }
    }

    final String custom = (compo.playerNameDisplayed ?? '').trim();
    if (custom.isNotEmpty) {
      return _compactDisplayedName(custom);
    }

    return unknownPlayerLabel;
  }

  String _compactDisplayedName(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final String first = parts.first;
      final String last = parts.last.toUpperCase();
      final String initial =
          first.isNotEmpty ? '${first[0].toUpperCase()}.' : '';
      return '$initial$last';
    }
    return trimmed.toUpperCase();
  }

  Future<SessionStatsReportMatchHeader?> _buildMatchHeader({
    required grinta_match.Match? match,
    required String? teamId,
  }) async {
    if (match == null) {
      return null;
    }

    final String home = (match.team1 ?? '').trim();
    final String away = (match.team2 ?? '').trim();
    final String scoreLabel =
        '${match.homeScore ?? 0} - ${match.outSideScore ?? 0}';

    TeamStatsOpponent? opponent;
    if (teamId != null && teamId.isNotEmpty) {
      opponent = opponentForMatch(match: match, teamId: teamId);
    }

    final Uint8List? homeLogo = await _downloadBytes(match.team1UrlLogo);
    final Uint8List? awayLogo = await _downloadBytes(match.team2UrlLogo);

    Uint8List? opponentLogo;
    String? opponentName = opponent?.displayName.trim();
    if (opponentName != null && opponentName.isNotEmpty) {
      final MatchSide? ownSide = teamSideForMatch(match: match, teamId: teamId!);
      if (ownSide == MatchSide.team1) {
        opponentLogo = awayLogo;
      } else if (ownSide == MatchSide.team2) {
        opponentLogo = homeLogo;
      }
    }

    return SessionStatsReportMatchHeader(
      homeTeamName: home.isEmpty ? 'Equipe 1' : home,
      awayTeamName: away.isEmpty ? 'Equipe 2' : away,
      scoreLabel: scoreLabel,
      opponentName: opponentName?.isNotEmpty == true ? opponentName : null,
      homeLogoBytes: homeLogo,
      awayLogoBytes: awayLogo,
      opponentLogoBytes: opponentLogo,
    );
  }

  /// Loads heatmaps using only [TeamPlayerMetricScores.trackerId] + eventId.
  ///
  /// Document id: `{trackerId}-{eventId}_{firstHalf|secondHalf|fullMatch}`.
  Future<List<SessionStatsReportHeatmapImage>>
      _loadHeatmapsFromPlayerScoreTrackerId({
    required String eventId,
    required String trackerId,
  }) async {
    final String safeEventId = eventId.trim();
    final String safeTrackerId = trackerId.trim();
    if (safeEventId.isEmpty || safeTrackerId.isEmpty) {
      return const <SessionStatsReportHeatmapImage>[];
    }

    if (kDebugMode) {
      debugPrint(
        'SessionStatsReportService: heatmaps from playerScores.trackerId '
        'trackerId=$safeTrackerId eventId=$safeEventId '
        'keys=${TrackerSvgService.buildSvgDocumentIds(
          trackerId: safeTrackerId,
          eventId: safeEventId,
          period: 'firstHalf',
        ).join(" | ")}',
      );
    }

    final List<SessionStatsReportHeatmapImage> heatmaps =
        <SessionStatsReportHeatmapImage>[];
    for (final period in _heatmapPeriods) {
      try {
        final String? svg = await _svgService.getSvgForTrackerPeriod(
          trackerId: safeTrackerId,
          eventId: safeEventId,
          periodSuffix: period.key,
        );
        if (svg == null || svg.trim().isEmpty) {
          if (kDebugMode) {
            debugPrint(
              'SessionStatsReportService: missing SVG '
              '${TrackerSvgService.buildSvgDocumentIds(
                trackerId: safeTrackerId,
                eventId: safeEventId,
                period: period.key,
              ).join(" | ")}',
            );
          }
          continue;
        }

        final Uint8List? png = await svgStringToPngBytes(svg, targetWidth: 720);
        if (kDebugMode) {
          debugPrint(
            'SessionStatsReportService: heatmap $safeTrackerId/${period.key} '
            'svgChars=${svg.length} pngBytes=${png?.length ?? 0}',
          );
        }

        heatmaps.add(
          SessionStatsReportHeatmapImage(
            periodKey: period.key,
            periodLabel: period.label,
            svg: svg,
            pngBytes: png,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'SessionStatsReportService: heatmap $safeTrackerId/'
            '${period.key} failed: $e',
          );
        }
      }
    }
    return heatmaps;
  }

  Future<Uint8List?> _loadPlayerPhotoBytes(Player player) async {
    try {
      final List<String> urls = await resolvePlayerAvatarUrls(player);
      for (final String url in urls) {
        final Uint8List? bytes = await _downloadBytes(url);
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SessionStatsReportService: photo load failed: $e');
      }
    }
    return null;
  }

  Future<Uint8List?> _downloadBytes(String? url) async {
    final String trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final Uri? uri = Uri.tryParse(trimmed);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return null;
      }
      final http.Response response = await _httpClient.get(uri);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  SpeedZoneStat? _findSpeedZone(List<SpeedZoneStat> stats, String zoneId) {
    for (final SpeedZoneStat stat in stats) {
      if (stat.zoneId == zoneId) {
        return stat;
      }
    }
    return null;
  }

  FieldZoneStats? _findFieldZone(List<FieldZoneStats> zones, String zoneId) {
    for (final FieldZoneStats zone in zones) {
      if (zone.zoneId == zoneId) {
        return zone;
      }
    }
    return null;
  }

  String _speedZoneRange(TeamSpeedZone zone) {
    if (zone.maxKmh == null) {
      return '>= ${zone.minKmh.toStringAsFixed(1)} km/h';
    }
    return '${zone.minKmh.toStringAsFixed(1)} - ${zone.maxKmh!.toStringAsFixed(1)} km/h';
  }
}
