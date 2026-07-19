import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations_fr.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/session_feeling_rings.dart';

void main() {
  test('findPlayerScoreInSummary matches player id', () {
    final summary = TeamWorkloadSummary(
      eventId: 'e1',
      totalWorkloadScore: 10,
      averageWorkloadScore: 5,
      teamWorkloadPerMinute: 1,
      averagePlayerWorkloadPerMinute: 1,
      playersCount: 1,
      sessionDuration: const Duration(minutes: 90),
      metricStats: const {},
      playerScores: [
        TeamPlayerMetricScores(
          playerId: 'p1',
          trackerId: 't1',
          metrics: {
            TeamWorkloadMetricKeys.workloadScore: const PlayerMetricScore(
              metricKey: TeamWorkloadMetricKeys.workloadScore,
              value: 42,
              zScore: 0,
              tScore: 50,
            ),
          },
        ),
      ],
    );

    final found = findPlayerScoreInSummary(summary: summary, playerId: 'p1');
    expect(found?.playerId, 'p1');
    expect(
      sessionFeelingWorkloadScore(summary: summary, playerScore: found),
      42,
    );
  });

  test('buildSessionFeelingRings keeps agenda icons and colors', () {
    final l10n = AppLocalizationsFr();
    final colors = AppColors.light;
    final summary = TeamWorkloadSummary(
      eventId: 'e1',
      totalWorkloadScore: 10,
      averageWorkloadScore: 5,
      teamWorkloadPerMinute: 1,
      averagePlayerWorkloadPerMinute: 1,
      playersCount: 1,
      sessionDuration: const Duration(minutes: 90),
      metricStats: {
        TeamWorkloadMetricKeys.distanceKm: const TeamMetricStat(
          metricKey: TeamWorkloadMetricKeys.distanceKm,
          mean: 3,
          standardDeviation: 0,
          min: 1,
          max: 5,
          count: 1,
        ),
        TeamWorkloadMetricKeys.highSpeedDuration: const TeamMetricStat(
          metricKey: TeamWorkloadMetricKeys.highSpeedDuration,
          mean: 20,
          standardDeviation: 0,
          min: 10,
          max: 40,
          count: 1,
        ),
        TeamWorkloadMetricKeys.sprintCount: const TeamMetricStat(
          metricKey: TeamWorkloadMetricKeys.sprintCount,
          mean: 4,
          standardDeviation: 0,
          min: 1,
          max: 8,
          count: 1,
        ),
        TeamWorkloadMetricKeys.maxAccelerationMps2: const TeamMetricStat(
          metricKey: TeamWorkloadMetricKeys.maxAccelerationMps2,
          mean: 2,
          standardDeviation: 0,
          min: 1,
          max: 4,
          count: 1,
        ),
      },
      playerScores: const [],
    );

    final rings = buildSessionFeelingRings(
      l10n: l10n,
      colors: colors,
      summary: summary,
    );

    expect(rings, hasLength(4));
    expect(rings[0].icon, Icons.directions_run);
    expect(rings[0].color, colors.success);
    expect(rings[1].icon, Icons.timer);
    expect(rings[1].color, colors.primary);
    expect(rings[2].icon, Icons.speed);
    expect(rings[2].color, colors.warning);
    expect(rings[3].color, colors.danger);
  });
}
