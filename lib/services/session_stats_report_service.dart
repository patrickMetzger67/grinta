import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/teamParam.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamParamService.dart';
import 'package:grinta/services/teamWorkloadSummaryService.dart';
import 'package:grinta/services/trackerDataAnalysisService.dart';
import 'package:grinta/services/trackerSvgService.dart';
import 'package:grinta/util/highlight_minute_helper.dart';
import 'package:grinta/util/insiders_device_resolver.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/svg_rasterizer.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// One match-composition player with its resolved sensor number (customeName).
class _MatchCompoSensorPlayer {
  const _MatchCompoSensorPlayer({
    required this.playerId,
    required this.sensorId,
    this.compoDisplayName,
  });

  final String playerId;
  /// TRACKER_Svg prefix = DeviceOwner.customeName (sensor number).
  final String sensorId;
  final String? compoDisplayName;
}

/// Builds [SessionStatsReport] from tracker team analysis (Stats tab data).
class SessionStatsReportService {
  SessionStatsReportService({
    TeamWorkloadSummaryService? summaryService,
    PlayerService? playerService,
    MatchService? matchService,
    MatchCompoService? matchCompoService,
    DeviceOwnerService? deviceOwnerService,
    TrackerSvgService? svgService,
    http.Client? httpClient,
  })  : _summaryService = summaryService ?? TeamWorkloadSummaryService(),
        _playerService = playerService ?? PlayerService(),
        _matchService = matchService ?? MatchService(),
        _matchCompoService = matchCompoService ?? MatchCompoService(),
        _deviceOwnerService = deviceOwnerService ?? DeviceOwnerService(),
        _svgService = svgService ?? TrackerSvgService(),
        _httpClient = httpClient ?? http.Client();

  final TeamWorkloadSummaryService _summaryService;
  final PlayerService _playerService;
  final MatchService _matchService;
  final MatchCompoService _matchCompoService;
  final DeviceOwnerService _deviceOwnerService;
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
      if (tid.isNotEmpty) {
        analysisByTrackerId[tid] = analysis;
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

    // Heatmap SVG keys are `{sensor}-{TRACKER_TeamAnalysis_{period} docId}`.
    final Map<String, String> periodTeamAnalysisDocIds = isMatch
        ? await _svgService.resolvePeriodTeamAnalysisDocIds(safeEventId)
        : const <String, String>{};
    if (isMatch && kDebugMode) {
      debugPrint(
        'SessionStatsReportService: period TeamAnalysis doc ids for '
        '$safeEventId => $periodTeamAnalysisDocIds',
      );
    }

    // Match reports: players come from matchCompo (+ deviceOwner → customeName).
    final List<_MatchCompoSensorPlayer> compoPlayers = isMatch
        ? await _loadMatchCompoSensorPlayers(
            matchId: safeEventId,
            teamId: safeTeamId,
          )
        : const <_MatchCompoSensorPlayer>[];
    if (isMatch && kDebugMode) {
      debugPrint(
        'SessionStatsReportService: matchCompo sensors '
        '${compoPlayers.map((p) => '${p.playerId}->${p.sensorId}').join(', ')}',
      );
    }

    final Map<String, TeamPlayerMetricScores> scoresByPlayerId =
        <String, TeamPlayerMetricScores>{
      for (final TeamPlayerMetricScores score in resolvedSummary.playerScores)
        if (score.playerId.trim().isNotEmpty)
          score.playerId.trim(): score,
    };

    final playerRows = <SessionStatsReportPlayerRow>[];
    final playerDetails = <SessionStatsReportPlayerDetail>[];

    if (isMatch && compoPlayers.isNotEmpty) {
      for (final _MatchCompoSensorPlayer slot in compoPlayers) {
        final TeamPlayerMetricScores score = scoresByPlayerId[slot.playerId] ??
            TeamPlayerMetricScores(
              playerId: slot.playerId,
              trackerId: slot.sensorId,
              metrics: const <String, PlayerMetricScore>{},
            );

        final Player? player = await _playerService
            .getPlayerById(slot.playerId)
            .catchError((_) => null);
        final String displayName = player != null
            ? playerDisplayName(player, unknownLabel: unknownPlayerLabel)
            : ((slot.compoDisplayName ?? '').trim().isNotEmpty
                ? slot.compoDisplayName!.trim()
                : slot.playerId);

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
            playerId: slot.playerId,
            displayName: displayName,
            trackerId: slot.sensorId,
            metrics: metrics,
            zScores: zScores,
          ),
        );

        final TrackerAnalysisResult? analysis =
            analysisByPlayerId[slot.playerId] ??
                analysisByTrackerId[slot.sensorId] ??
                analysisByTrackerId[score.trackerId.trim()];

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
            eventId: safeEventId,
            periodTeamAnalysisDocIds: periodTeamAnalysisDocIds,
            sensorIdOverride: slot.sensorId,
          ),
        );
      }
    } else {
      // Training (or match without usable compo): keep TeamAnalysis order.
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

        final TrackerAnalysisResult? analysis =
            analysisByPlayerId[score.playerId.trim()] ??
                analysisByTrackerId[score.trackerId.trim()];

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
            eventId: safeEventId,
            periodTeamAnalysisDocIds: periodTeamAnalysisDocIds,
          ),
        );
      }
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
    Map<String, String> periodTeamAnalysisDocIds = const <String, String>{},
    String? sensorIdOverride,
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

    final List<SessionStatsReportHeatmapImage> heatmaps =
        <SessionStatsReportHeatmapImage>[];
    if (isMatch) {
      // Sensor number from matchCompo → DeviceOwner.customeName first.
      final List<String> trackerCandidates = <String>{
        (sensorIdOverride ?? '').trim(),
        (analysis?.trackerId ?? '').trim(),
        score.trackerId.trim(),
      }.where((id) => id.isNotEmpty).toList(growable: false);

      for (final period in _heatmapPeriods) {
        try {
          final String? svg = await _loadHeatmapSvg(
            trackerCandidates: trackerCandidates,
            eventId: eventId,
            periodKey: period.key,
            periodTeamAnalysisDocId: periodTeamAnalysisDocIds[period.key],
          );
          if (svg == null || svg.trim().isEmpty) {
            if (kDebugMode) {
              debugPrint(
                'SessionStatsReportService: no heatmap SVG for '
                'tracker=${trackerCandidates.join("|")} period=${period.key} '
                'teamAnalysisDocId=${periodTeamAnalysisDocIds[period.key]}',
              );
            }
            continue;
          }
          final Uint8List? png = await svgStringToPngBytes(
            svg,
            targetWidth: 240,
          );
          if (png == null || png.isEmpty) {
            continue;
          }
          heatmaps.add(
            SessionStatsReportHeatmapImage(
              periodKey: period.key,
              periodLabel: period.label,
              pngBytes: png,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'SessionStatsReportService: heatmap '
              '${trackerCandidates.join("|")}/${period.key} failed: $e',
            );
          }
        }
      }
    }

    final String resolvedTrackerId =
        (sensorIdOverride ?? '').trim().isNotEmpty
            ? sensorIdOverride!.trim()
            : score.trackerId;

    return SessionStatsReportPlayerDetail(
      playerId: score.playerId,
      displayName: displayName,
      trackerId: resolvedTrackerId,
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

  /// Loads lineup players that have a tracker assignment and resolves the
  /// sensor number via TRACKER_DeviceOwner.customeName.
  Future<List<_MatchCompoSensorPlayer>> _loadMatchCompoSensorPlayers({
    required String matchId,
    required String? teamId,
  }) async {
    final MatchCompo? compo = await _loadMatchCompo(
      matchId: matchId,
      teamId: teamId,
    );
    if (compo == null) {
      return const <_MatchCompoSensorPlayer>[];
    }

    final List<PlayerCompo> lineup = allPlayersFromCompo(compo);
    if (lineup.isEmpty) {
      return const <_MatchCompoSensorPlayer>[];
    }

    final Set<String> deviceOwnerIds = <String>{
      for (final PlayerCompo p in lineup)
        if ((p.deviceOwnerId ?? '').trim().isNotEmpty) p.deviceOwnerId!.trim(),
    };

    final Map<String, DeviceOwner> ownersById = <String, DeviceOwner>{};
    await Future.wait(
      deviceOwnerIds.map((String id) async {
        try {
          final DeviceOwner? owner = await _deviceOwnerService.getById(id);
          if (owner != null) {
            ownersById[id] = owner;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              'SessionStatsReportService: DeviceOwner $id failed: $e',
            );
          }
        }
      }),
    );

    final List<_MatchCompoSensorPlayer> out = <_MatchCompoSensorPlayer>[];
    final Set<String> seenPlayers = <String>{};

    for (final PlayerCompo slot in lineup) {
      final String playerId = (slot.playerID ?? '').trim();
      final String deviceOwnerId = (slot.deviceOwnerId ?? '').trim();
      if (playerId.isEmpty || deviceOwnerId.isEmpty) {
        continue;
      }
      if (!seenPlayers.add(playerId)) {
        continue;
      }

      // Prefer customeName written on the compo, else DeviceOwner.customeName.
      final String fromCompo = (slot.customName ?? '').trim();
      final DeviceOwner? owner = ownersById[deviceOwnerId];
      final String fromOwner =
          owner == null ? '' : trackerIdForAnalysis(owner).trim();
      final String sensorId =
          fromCompo.isNotEmpty ? fromCompo : fromOwner;
      if (sensorId.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'SessionStatsReportService: no sensor for player=$playerId '
            'deviceOwnerId=$deviceOwnerId',
          );
        }
        continue;
      }

      out.add(
        _MatchCompoSensorPlayer(
          playerId: playerId,
          sensorId: sensorId,
          compoDisplayName: slot.playerNameDisplayed,
        ),
      );
    }

    return out;
  }

  Future<MatchCompo?> _loadMatchCompo({
    required String matchId,
    required String? teamId,
  }) async {
    try {
      if (teamId != null && teamId.trim().isNotEmpty) {
        final MatchCompo? byTeam =
            await _matchCompoService.getMatchCompoByMatchAndTeamId(
          matchId,
          teamId.trim(),
        );
        if (byTeam != null) {
          return byTeam;
        }
      }
      return await _matchCompoService.getFirstMatchCompoByMatchId(matchId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'SessionStatsReportService: load matchCompo failed for '
          'matchId=$matchId teamId=$teamId: $e',
        );
      }
      return null;
    }
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

  /// Production key: `{sensor}-{TRACKER_TeamAnalysis_{period} docId}`.
  /// Falls back to legacy `{sensor}-{eventId}_{period}` via TrackerSvgService.
  Future<String?> _loadHeatmapSvg({
    required List<String> trackerCandidates,
    required String eventId,
    required String periodKey,
    String? periodTeamAnalysisDocId,
  }) async {
    final String? analysisDocId = periodTeamAnalysisDocId?.trim();
    if (analysisDocId != null && analysisDocId.isNotEmpty) {
      for (final String trackerId in trackerCandidates) {
        final String? svg = await _svgService.getSvgForSensorAndAnalysisDoc(
          trackerId: trackerId,
          teamAnalysisDocId: analysisDocId,
        );
        if (svg != null && svg.trim().isNotEmpty) {
          return svg;
        }
      }
    }

    for (final String trackerId in trackerCandidates) {
      final String? svg = await _svgService.getSvgForTrackerPeriod(
        trackerId: trackerId,
        eventId: eventId,
        periodSuffix: periodKey,
      );
      if (svg != null && svg.trim().isNotEmpty) {
        return svg;
      }
    }
    return null;
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
