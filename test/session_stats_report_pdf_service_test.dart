import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/session_stats_report_pdf_service.dart';

void main() {
  test('builds non-empty PDF bytes from report', () async {
    final report = SessionStatsReport(
      eventId: 'evt-1',
      title: 'U15 Entraînement',
      subtitle: 'Terrain A',
      dateLabel: '7 juillet 2026',
      teamName: 'Grinta FC',
      isMatch: false,
      generatedAt: DateTime(2026, 7, 8, 10, 0),
      playersCount: 1,
      averageWorkloadScore: 72,
      sessionDuration: const Duration(minutes: 90),
      teamAverages: <String, double>{
        TeamWorkloadMetricKeys.workloadScore: 72,
        TeamWorkloadMetricKeys.distanceKm: 4.2,
        TeamWorkloadMetricKeys.maxValidatedSpeedKmh: 28.1,
        TeamWorkloadMetricKeys.highAccelerationCount: 12,
        TeamWorkloadMetricKeys.highSpeedDuration: 45.5,
        TeamWorkloadMetricKeys.maxAccelerationMps2: 4.1,
        TeamWorkloadMetricKeys.sprintCount: 8,
      },
      playerRows: const <SessionStatsReportPlayerRow>[
        SessionStatsReportPlayerRow(
          playerId: 'p1',
          displayName: 'Alex Dupont',
          trackerId: 'T01',
          metrics: <String, double>{
            TeamWorkloadMetricKeys.workloadScore: 72,
            TeamWorkloadMetricKeys.distanceKm: 4.2,
            TeamWorkloadMetricKeys.maxValidatedSpeedKmh: 28.1,
            TeamWorkloadMetricKeys.highAccelerationCount: 12,
            TeamWorkloadMetricKeys.highSpeedDuration: 45.5,
            TeamWorkloadMetricKeys.maxAccelerationMps2: 4.1,
            TeamWorkloadMetricKeys.sprintCount: 8,
          },
          zScores: <String, double>{
            TeamWorkloadMetricKeys.workloadScore: -0.60,
            TeamWorkloadMetricKeys.distanceKm: -0.36,
            TeamWorkloadMetricKeys.maxValidatedSpeedKmh: 0.53,
            TeamWorkloadMetricKeys.highAccelerationCount: -0.41,
            TeamWorkloadMetricKeys.highSpeedDuration: -0.91,
            TeamWorkloadMetricKeys.maxAccelerationMps2: -1.66,
            TeamWorkloadMetricKeys.sprintCount: 0.12,
          },
        ),
      ],
    );

    final bytes = await SessionStatsReportPdfService().buildPdf(report);
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
