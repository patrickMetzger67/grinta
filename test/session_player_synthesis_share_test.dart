import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/session_player_synthesis_share_service.dart';

TrackerAnalysisResult _sampleAnalysis() {
  return const TrackerAnalysisResult(
    trackerId: 't1',
    playerId: 'p1',
    eventId: 'e1',
    distanceKm: 5.98,
    duration: Duration(minutes: 90),
    averageSpeedKmh: 3.4,
    maxSpeedKmh: 27.0,
    maxValidatedSpeedKmh: 26.7,
    samplesCount: 1000,
    heatmapPoints: <HeatmapPoint>[],
    sprintCount: 9,
    highAccelerationCount: 8,
    highSpeedDuration: Duration(seconds: 30),
    maxAccelerationMps2: 6.69,
    distanceByZones: <FieldZoneStats>[],
    speedZones: <SpeedZoneStat>[],
    halfStats: <HalfStats>[],
    workloadScore: 175,
    workloadScorePerMinute: 1.9,
    playerProfile: 'mid',
    fatigueIndex: 0.92,
    firstHalfDistanceKm: 3.1,
    secondHalfDistanceKm: 2.88,
    distanceTimeline: <DistanceTimelineStat>[],
  );
}

void main() {
  testWidgets('session share text includes match score when applied',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final text = const SessionPlayerSynthesisShareService().buildShareText(
      l10n: l10n,
      playerName: 'Léa Martin',
      analysis: _sampleAnalysis(),
      isMatch: true,
      matchContext: const SessionShareMatchContext(
        team1Name: 'AS Exemple',
        team2Name: 'FC Rival',
        homeScore: 2,
        awayScore: 1,
        isStatApplied: true,
      ),
    );

    expect(text, contains('Léa Martin'));
    expect(text, contains('AS Exemple'));
    expect(text, contains('2'));
    expect(text, contains('FC Rival'));
    expect(text, contains('5.98'));
    expect(text, contains('#GrintaPerformance'));
  });

  test('match header only when isStatApplied', () {
    const applied = SessionShareMatchContext(
      team1Name: 'A',
      team2Name: 'B',
      homeScore: 1,
      awayScore: 0,
      isStatApplied: true,
    );
    const pending = SessionShareMatchContext(
      team1Name: 'A',
      team2Name: 'B',
      homeScore: 0,
      awayScore: 0,
      isStatApplied: false,
    );
    expect(applied.showMatchHeader, isTrue);
    expect(pending.showMatchHeader, isFalse);
  });
}
