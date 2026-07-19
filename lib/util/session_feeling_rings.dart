import 'package:flutter/material.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/activity_rings_card.dart';

/// Builds the same activity rings used in the agenda (icons + colors).
List<ActivityRingItem> buildSessionFeelingRings({
  required AppLocalizations l10n,
  required AppColors colors,
  required TeamWorkloadSummary? summary,
  TeamPlayerMetricScores? playerScore,
}) {
  double metricValue(String key, double fallback) {
    final fromPlayer = playerScore?.getMetric(key)?.value;
    if (fromPlayer != null && fromPlayer.isFinite) return fromPlayer;
    final fromTeam = summary?.metricStats[key]?.mean;
    if (fromTeam != null && fromTeam.isFinite) return fromTeam;
    return fallback;
  }

  double metricGoal(String key) {
    final max = summary?.metricStats[key]?.max;
    if (max != null && max.isFinite && max > 0) return max;
    final value = metricValue(key, 0);
    return value > 0 ? value : 1;
  }

  final distance = metricValue(TeamWorkloadMetricKeys.distanceKm, 0);
  final highSpeed = metricValue(TeamWorkloadMetricKeys.highSpeedDuration, 0);
  final sprints = metricValue(TeamWorkloadMetricKeys.sprintCount, 0);
  final accel = metricValue(TeamWorkloadMetricKeys.maxAccelerationMps2, 0);

  return [
    ActivityRingItem(
      label: l10n.statsDistance,
      value: distance,
      goal: metricGoal(TeamWorkloadMetricKeys.distanceKm),
      unit: l10n.statsUnitKm,
      color: colors.success,
      trackColor: Colors.greenAccent.withValues(alpha: 0.18),
      icon: Icons.directions_run,
    ),
    ActivityRingItem(
      label: l10n.statsHighSpeedTimeShort,
      value: highSpeed,
      goal: metricGoal(TeamWorkloadMetricKeys.highSpeedDuration),
      unit: l10n.statsUnitSeconds,
      color: colors.primary,
      trackColor: Colors.blueAccent.withValues(alpha: 0.18),
      icon: Icons.timer,
    ),
    ActivityRingItem(
      label: l10n.statsSprints,
      value: sprints,
      goal: metricGoal(TeamWorkloadMetricKeys.sprintCount),
      unit: l10n.statsUnitCount,
      color: colors.warning,
      trackColor: Colors.redAccent.withValues(alpha: 0.18),
      icon: Icons.speed,
    ),
    ActivityRingItem(
      label: l10n.statsMaxAccelSample,
      value: accel,
      goal: metricGoal(TeamWorkloadMetricKeys.maxAccelerationMps2),
      unit: l10n.statsUnitMps2,
      color: colors.danger,
      trackColor: Colors.redAccent.withValues(alpha: 0.18),
      icon: Icons.speed,
    ),
  ];
}

double sessionFeelingWorkloadScore({
  required TeamWorkloadSummary? summary,
  TeamPlayerMetricScores? playerScore,
}) {
  final fromPlayer =
      playerScore?.getMetric(TeamWorkloadMetricKeys.workloadScore)?.value;
  if (fromPlayer != null && fromPlayer.isFinite) return fromPlayer;
  final fromTeam = summary?.averageWorkloadScore;
  if (fromTeam != null && fromTeam.isFinite) return fromTeam;
  return 0;
}

TeamPlayerMetricScores? findPlayerScoreInSummary({
  required TeamWorkloadSummary? summary,
  required String playerId,
}) {
  final trimmed = playerId.trim();
  if (summary == null || trimmed.isEmpty) return null;
  for (final score in summary.playerScores) {
    if (score.playerId.trim() == trimmed) return score;
  }
  return null;
}
