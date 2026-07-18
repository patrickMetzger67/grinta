import 'dart:typed_data';

import 'package:grinta/model/tracker/team_workload_summary.dart';

/// Snapshot of session/match tracker stats used for PDF/email reports.
class SessionStatsReport {
  const SessionStatsReport({
    required this.eventId,
    required this.title,
    required this.isMatch,
    required this.generatedAt,
    required this.playersCount,
    required this.averageWorkloadScore,
    required this.sessionDuration,
    required this.teamAverages,
    required this.playerRows,
    this.subtitle,
    this.dateLabel,
    this.timeLabel,
    this.teamName,
    this.matchHeader,
    this.tacticalSchema,
    this.highlightEvents = const <SessionStatsReportHighlightEvent>[],
    this.playerDetails = const <SessionStatsReportPlayerDetail>[],
  });

  final String eventId;
  final String title;
  final String? subtitle;
  final String? dateLabel;
  final String? timeLabel;
  final String? teamName;
  final bool isMatch;
  final DateTime generatedAt;
  final int playersCount;
  final double averageWorkloadScore;
  final Duration sessionDuration;
  final Map<String, double> teamAverages;
  final List<SessionStatsReportPlayerRow> playerRows;

  /// Match-only header extras (opponent, logos, score).
  final SessionStatsReportMatchHeader? matchHeader;

  /// Match page 1: schéma tactique (compo terrain + remplaçants).
  final SessionStatsReportTacticalSchema? tacticalSchema;

  /// Match page 2: temps forts (timeline buts / cartons / changements).
  final List<SessionStatsReportHighlightEvent> highlightEvents;

  /// One detailed section per player (Synthèse, zones, timeline, heatmaps…).
  final List<SessionStatsReportPlayerDetail> playerDetails;

  String get eventKindLabel => isMatch ? 'match' : 'training';

  String get suggestedFileName {
    final safeTitle = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final stem = safeTitle.isEmpty ? eventKindLabel : safeTitle;
    return 'grinta_${eventKindLabel}_$stem.pdf';
  }
}

class SessionStatsReportMatchHeader {
  const SessionStatsReportMatchHeader({
    required this.homeTeamName,
    required this.awayTeamName,
    required this.scoreLabel,
    this.opponentName,
    this.homeLogoBytes,
    this.awayLogoBytes,
    this.opponentLogoBytes,
  });

  final String homeTeamName;
  final String awayTeamName;
  final String scoreLabel;
  final String? opponentName;
  final Uint8List? homeLogoBytes;
  final Uint8List? awayLogoBytes;
  final Uint8List? opponentLogoBytes;
}

/// Pitch lineup for the match PDF (mirrors Schéma tactique).
class SessionStatsReportTacticalSchema {
  const SessionStatsReportTacticalSchema({
    required this.formationName,
    required this.starters,
    this.substitutes = const <SessionStatsReportBenchPlayer>[],
  });

  final String formationName;
  final List<SessionStatsReportPitchPlayer> starters;
  final List<SessionStatsReportBenchPlayer> substitutes;
}

class SessionStatsReportPitchPlayer {
  const SessionStatsReportPitchPlayer({
    required this.playerId,
    required this.displayName,
    required this.slotId,
    required this.role,
    required this.x,
    required this.y,
    this.shirtNumber,
    this.photoBytes,
  });

  final String playerId;
  final String displayName;
  final String slotId;
  final String role;
  /// Relative pitch coords from [buildCompoSlots] (0–1).
  final double x;
  final double y;
  final int? shirtNumber;
  final Uint8List? photoBytes;
}

class SessionStatsReportBenchPlayer {
  const SessionStatsReportBenchPlayer({
    required this.playerId,
    required this.displayName,
    this.shirtNumber,
    this.photoBytes,
  });

  final String playerId;
  final String displayName;
  final int? shirtNumber;
  final Uint8List? photoBytes;
}

/// One event on the match highlights timeline PDF page.
class SessionStatsReportHighlightEvent {
  const SessionStatsReportHighlightEvent({
    required this.minute,
    required this.type,
    required this.typeLabel,
    required this.playerName,
    required this.teamName,
    required this.isHomeSide,
    this.extraTime = 0,
    this.secondaryPlayerName,
  });

  final int minute;
  final int extraTime;
  /// Normalized: goal | yellowCard | redCard | substitution | ownGoal | other
  final String type;
  final String typeLabel;
  final String playerName;
  final String? secondaryPlayerName;
  final String teamName;
  /// true = left (team1 / home), false = right (team2 / away).
  final bool isHomeSide;
}

class SessionStatsReportPlayerRow {
  const SessionStatsReportPlayerRow({
    required this.playerId,
    required this.displayName,
    required this.trackerId,
    required this.metrics,
    this.zScores = const <String, double>{},
  });

  final String playerId;
  final String displayName;
  final String trackerId;
  final Map<String, double> metrics;

  /// Per-metric z-score (same values as the Stats table badges).
  final Map<String, double> zScores;

  double metricValue(String key) => metrics[key] ?? 0;

  double? zScoreValue(String key) => zScores[key];
}

class SessionStatsReportSpeedZoneRow {
  const SessionStatsReportSpeedZoneRow({
    required this.zoneId,
    required this.label,
    required this.rangeLabel,
    required this.duration,
    required this.percent,
  });

  final String zoneId;
  final String label;
  final String rangeLabel;
  final Duration duration;
  final double percent;
}

class SessionStatsReportFieldZoneCell {
  const SessionStatsReportFieldZoneCell({
    required this.zoneId,
    required this.label,
    required this.distanceKm,
    required this.occupancyPercent,
  });

  final String zoneId;
  final String label;
  final double distanceKm;
  final double occupancyPercent;
}

class SessionStatsReportTimelineBucket {
  const SessionStatsReportTimelineBucket({
    required this.label,
    required this.walkingMeters,
    required this.joggingMeters,
    required this.runningMeters,
    required this.highIntensityMeters,
  });

  final String label;
  final double walkingMeters;
  final double joggingMeters;
  final double runningMeters;
  final double highIntensityMeters;

  double get totalMeters =>
      walkingMeters + joggingMeters + runningMeters + highIntensityMeters;
}

class SessionStatsReportHeatmapImage {
  const SessionStatsReportHeatmapImage({
    required this.periodKey,
    required this.periodLabel,
    this.svg,
    this.pngBytes,
  });

  final String periodKey;
  final String periodLabel;

  /// Optional raw SVG (debug / simple shapes). Prefer [pngBytes] in PDF.
  final String? svg;

  /// Rasterized heatmap (flutter_svg — same renderer as player_analysis UI).
  final Uint8List? pngBytes;

  bool get hasVisual =>
      (svg != null && svg!.trim().isNotEmpty) ||
      (pngBytes != null && pngBytes!.isNotEmpty);
}

/// Full per-player content for dedicated PDF pages.
class SessionStatsReportPlayerDetail {
  const SessionStatsReportPlayerDetail({
    required this.playerId,
    required this.displayName,
    required this.trackerId,
    required this.distanceKm,
    required this.averageSpeedKmh,
    required this.maxValidatedSpeedKmh,
    required this.maxAccelerationMps2,
    required this.sprintCount,
    required this.highAccelerationCount,
    required this.highSpeedDuration,
    required this.workloadScore,
    required this.fatigueIndex,
    required this.duration,
    this.photoBytes,
    this.speedZones = const <SessionStatsReportSpeedZoneRow>[],
    this.distanceTimeline = const <SessionStatsReportTimelineBucket>[],
    this.fieldZones = const <SessionStatsReportFieldZoneCell>[],
    this.heatmaps = const <SessionStatsReportHeatmapImage>[],
  });

  final String playerId;
  final String displayName;
  final String trackerId;
  final Uint8List? photoBytes;

  final double distanceKm;
  final double averageSpeedKmh;
  final double maxValidatedSpeedKmh;
  final double maxAccelerationMps2;
  final int sprintCount;
  final int highAccelerationCount;
  final Duration highSpeedDuration;
  final double workloadScore;
  final double fatigueIndex;
  final Duration duration;

  final List<SessionStatsReportSpeedZoneRow> speedZones;
  final List<SessionStatsReportTimelineBucket> distanceTimeline;
  final List<SessionStatsReportFieldZoneCell> fieldZones;
  final List<SessionStatsReportHeatmapImage> heatmaps;
}

/// Metric columns included in the PDF (aligned with the Stats table).
class SessionStatsReportMetric {
  const SessionStatsReportMetric({
    required this.key,
    required this.title,
    required this.unit,
    required this.fractionDigits,
  });

  final String key;
  final String title;
  final String unit;
  final int fractionDigits;

  String format(double value) => value.toStringAsFixed(fractionDigits);
}

const List<SessionStatsReportMetric> kSessionStatsReportMetrics =
    <SessionStatsReportMetric>[
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.workloadScore,
    title: 'Workload',
    unit: 'score',
    fractionDigits: 0,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.distanceKm,
    title: 'Distance',
    unit: 'km',
    fractionDigits: 2,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.maxValidatedSpeedKmh,
    title: 'Vitesse max',
    unit: 'km/h',
    fractionDigits: 1,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.highAccelerationCount,
    title: 'Acc. hautes',
    unit: 'nb',
    fractionDigits: 0,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.highSpeedDuration,
    title: 'Haute vitesse',
    unit: 's',
    fractionDigits: 1,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.maxAccelerationMps2,
    title: 'Acc. max',
    unit: 'm/s²',
    fractionDigits: 2,
  ),
  SessionStatsReportMetric(
    key: TeamWorkloadMetricKeys.sprintCount,
    title: 'Sprints',
    unit: 'nb',
    fractionDigits: 0,
  ),
];
