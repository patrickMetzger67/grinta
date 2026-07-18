import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/session_stats_report_pdf_service.dart';
import 'package:grinta/services/trackerSvgService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds non-empty PDF bytes from report with player pages', () async {
    final report = SessionStatsReport(
      eventId: 'evt-1',
      title: 'U15 Entrainement',
      subtitle: 'Terrain A',
      dateLabel: '7 juillet 2026',
      timeLabel: '18:30',
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
          trackerId: '01',
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
      playerDetails: const <SessionStatsReportPlayerDetail>[
        SessionStatsReportPlayerDetail(
          playerId: 'p1',
          displayName: 'Alex Dupont',
          trackerId: '01',
          distanceKm: 4.2,
          averageSpeedKmh: 5.1,
          maxValidatedSpeedKmh: 28.1,
          maxAccelerationMps2: 4.1,
          sprintCount: 8,
          highAccelerationCount: 12,
          highSpeedDuration: Duration(seconds: 46),
          workloadScore: 72,
          fatigueIndex: 0.88,
          duration: Duration(minutes: 90),
          speedZones: <SessionStatsReportSpeedZoneRow>[
            SessionStatsReportSpeedZoneRow(
              zoneId: 'Z1',
              label: 'Marche',
              rangeLabel: '0.0 - 7.0 km/h',
              duration: Duration(minutes: 40),
              percent: 45,
            ),
            SessionStatsReportSpeedZoneRow(
              zoneId: 'Z5',
              label: 'Sprint',
              rangeLabel: '>= 21.0 km/h',
              duration: Duration(seconds: 90),
              percent: 2.5,
            ),
          ],
          distanceTimeline: <SessionStatsReportTimelineBucket>[
            SessionStatsReportTimelineBucket(
              label: '0-5',
              walkingMeters: 120,
              joggingMeters: 80,
              runningMeters: 40,
              highIntensityMeters: 10,
            ),
            SessionStatsReportTimelineBucket(
              label: '5-10',
              walkingMeters: 100,
              joggingMeters: 90,
              runningMeters: 50,
              highIntensityMeters: 20,
            ),
          ],
        ),
      ],
    );

    final bytes = await SessionStatsReportPdfService().buildPdf(report);
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    // Optional preview dump for local visual checks.
    final previewPath = Platform.environment['PDF_PREVIEW_OUT'];
    if (previewPath != null && previewPath.isNotEmpty) {
      await File(previewPath).writeAsBytes(bytes);
    }
  });

  test('builds match PDF with field zones and heatmaps placeholders', () async {
    // Minimal 1x1 PNG
    final png = Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB0, 0x00, 0x00, 0x00,
      0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    final report = SessionStatsReport(
      eventId: 'match-1',
      title: 'vs Rival FC',
      dateLabel: '7 juillet 2026',
      timeLabel: '15:00',
      teamName: 'Grinta FC',
      isMatch: true,
      generatedAt: DateTime(2026, 7, 8, 10, 0),
      playersCount: 1,
      averageWorkloadScore: 80,
      sessionDuration: const Duration(minutes: 90),
      teamAverages: const <String, double>{},
      playerRows: const <SessionStatsReportPlayerRow>[
        SessionStatsReportPlayerRow(
          playerId: 'p1',
          displayName: 'Alex Dupont',
          trackerId: '01',
          metrics: <String, double>{},
        ),
      ],
      matchHeader: const SessionStatsReportMatchHeader(
        homeTeamName: 'Grinta FC',
        awayTeamName: 'Rival FC',
        scoreLabel: '2 - 1',
        opponentName: 'Rival FC',
      ),
      playerDetails: <SessionStatsReportPlayerDetail>[
        SessionStatsReportPlayerDetail(
          playerId: 'p1',
          displayName: 'Alex Dupont',
          trackerId: '01',
          distanceKm: 9.2,
          averageSpeedKmh: 6.4,
          maxValidatedSpeedKmh: 30.1,
          maxAccelerationMps2: 4.5,
          sprintCount: 14,
          highAccelerationCount: 18,
          highSpeedDuration: const Duration(seconds: 120),
          workloadScore: 80,
          fatigueIndex: 1.02,
          duration: const Duration(minutes: 90),
          fieldZones: const <SessionStatsReportFieldZoneCell>[
            SessionStatsReportFieldZoneCell(
              zoneId: 'ATT_LEFT',
              label: 'Attaque gauche',
              distanceKm: 1.2,
              occupancyPercent: 18,
            ),
            SessionStatsReportFieldZoneCell(
              zoneId: 'ATT_RIGHT',
              label: 'Attaque droite',
              distanceKm: 1.1,
              occupancyPercent: 16,
            ),
            SessionStatsReportFieldZoneCell(
              zoneId: 'MID_LEFT',
              label: 'Milieu gauche',
              distanceKm: 1.5,
              occupancyPercent: 20,
            ),
            SessionStatsReportFieldZoneCell(
              zoneId: 'MID_RIGHT',
              label: 'Milieu droite',
              distanceKm: 1.4,
              occupancyPercent: 19,
            ),
            SessionStatsReportFieldZoneCell(
              zoneId: 'DEF_LEFT',
              label: 'Defense gauche',
              distanceKm: 1.0,
              occupancyPercent: 14,
            ),
            SessionStatsReportFieldZoneCell(
              zoneId: 'DEF_RIGHT',
              label: 'Defense droite',
              distanceKm: 0.9,
              occupancyPercent: 13,
            ),
          ],
          heatmaps: <SessionStatsReportHeatmapImage>[
            SessionStatsReportHeatmapImage(
              periodKey: 'fullMatch',
              periodLabel: 'Match complet',
              svg:
                  '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="10" height="10" fill="#0f0"/></svg>',
              pngBytes: png,
            ),
          ],
        ),
      ],
    );

    final bytes = await SessionStatsReportPdfService().buildPdf(report);
    expect(bytes.length, greaterThan(500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    // Header must include both clubs + score (not only "vs opponent").
    expect(
      SessionStatsReportPdfService.matchScorelineLabel(report.matchHeader!),
      'Grinta FC  2 - 1  Rival FC',
    );
  });

  test('tracker id candidates cover padded and raw forms', () {
    expect(
      TrackerSvgService.trackerIdCandidates('01'),
      containsAll(<String>['01', '1']),
    );
    expect(
      TrackerSvgService.trackerIdCandidates('1'),
      containsAll(<String>['1', '01']),
    );
  });

  test('production SVG doc ids are sensor-matchId_period', () {
    expect(
      TrackerSvgService.buildSvgDocumentIds(
        trackerId: '9',
        eventId: '53514382',
        period: 'firstHalf',
      ),
      contains('09-53514382_firstHalf'),
    );
    expect(
      TrackerSvgService.buildSvgDocumentIds(
        trackerId: '09',
        eventId: '53514382',
        period: 'fullMatch',
      ),
      contains('09-53514382_fullMatch'),
    );
    // Same trackerId form as player_analysis "Tracker 02".
    expect(
      TrackerSvgService.buildSvgDocumentIds(
        trackerId: '02',
        eventId: '53514382',
        period: 'firstHalf',
      ),
      contains('02-53514382_firstHalf'),
    );
  });
}
