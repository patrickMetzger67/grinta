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
    this.teamName,
  });

  final String eventId;
  final String title;
  final String? subtitle;
  final String? dateLabel;
  final String? teamName;
  final bool isMatch;
  final DateTime generatedAt;
  final int playersCount;
  final double averageWorkloadScore;
  final Duration sessionDuration;
  final Map<String, double> teamAverages;
  final List<SessionStatsReportPlayerRow> playerRows;

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

class SessionStatsReportPlayerRow {
  const SessionStatsReportPlayerRow({
    required this.playerId,
    required this.displayName,
    required this.trackerId,
    required this.metrics,
  });

  final String playerId;
  final String displayName;
  final String trackerId;
  final Map<String, double> metrics;

  double metricValue(String key) => metrics[key] ?? 0;
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
