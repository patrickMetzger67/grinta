import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/util/player_activity_report_aggregator.dart';

void main() {
  group('aggregateTrackerSessionMetrics', () {
    test('averages metrics across sessions', () {
      final averages = aggregateTrackerSessionMetrics(
        <PlayerTrackerSessionMetrics>[
          PlayerTrackerSessionMetrics(
            eventId: 't1',
            eventType: 'training',
            values: <String, double>{
              TeamWorkloadMetricKeys.distanceKm: 4.0,
              TeamWorkloadMetricKeys.workloadScore: 40.0,
            },
          ),
          PlayerTrackerSessionMetrics(
            eventId: 't2',
            eventType: 'training',
            values: <String, double>{
              TeamWorkloadMetricKeys.distanceKm: 6.0,
              TeamWorkloadMetricKeys.workloadScore: 60.0,
            },
          ),
        ],
      );

      expect(averages.sessionsWithData, 2);
      expect(averages.averages[TeamWorkloadMetricKeys.distanceKm], 5.0);
      expect(averages.averages[TeamWorkloadMetricKeys.workloadScore], 50.0);
    });

    test('returns empty averages when no sessions', () {
      final averages = aggregateTrackerSessionMetrics(
        const <PlayerTrackerSessionMetrics>[],
      );

      expect(averages.sessionsWithData, 0);
      expect(averages.averages, isEmpty);
    });
  });

  group('computeTrackerTrends', () {
    test('computes percent change vs previous period', () {
      final current = aggregateTrackerSessionMetrics(
        <PlayerTrackerSessionMetrics>[
          PlayerTrackerSessionMetrics(
            eventId: 'm1',
            eventType: 'match',
            values: <String, double>{
              TeamWorkloadMetricKeys.distanceKm: 10.0,
            },
          ),
        ],
      );
      final previous = aggregateTrackerSessionMetrics(
        <PlayerTrackerSessionMetrics>[
          PlayerTrackerSessionMetrics(
            eventId: 'm0',
            eventType: 'match',
            values: <String, double>{
              TeamWorkloadMetricKeys.distanceKm: 8.0,
            },
          ),
        ],
      );

      final trends = computeTrackerTrends(
        current: current,
        previous: previous,
      );

      final distanceTrend = trends[TeamWorkloadMetricKeys.distanceKm];
      expect(distanceTrend, isNotNull);
      expect(distanceTrend!.current, 10.0);
      expect(distanceTrend.previous, 8.0);
      expect(distanceTrend.changePercent, 25.0);
    });
  });
}
