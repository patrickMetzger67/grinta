import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
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

    expect(text, contains('Grinta Performance'));
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

  test('fromMatch copies competition, day and tour', () {
    final ctx = SessionShareMatchContext.fromMatch(
      models.Match(
        chType: '  COUPE DE FRANCE CREDIT AGRICOLE  ',
        tour: '  2E TOUR  ',
        day: 0,
        team1: 'A',
        team2: 'B',
        isStatApplied: true,
      ),
    );
    expect(ctx.competitionLabel, 'COUPE DE FRANCE CREDIT AGRICOLE');
    expect(ctx.tourLabel, '2E TOUR');
    expect(ctx.day, 0);
  });

  testWidgets('match pills use competition and tour from the match',
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

    final pills = sessionShareEventPills(
      l10n: l10n,
      isMatch: true,
      matchContext: SessionShareMatchContext.fromMatch(
        models.Match(
          chType: 'COUPE DE FRANCE CREDIT AGRICOLE',
          tour: '2E TOUR',
          isStatApplied: true,
        ),
      ),
    );

    expect(pills.map((p) => p.label).toList(), [
      'COUPE DE FRANCE CREDIT AGRICOLE',
      '2E TOUR',
    ]);
    expect(pills.first.icon, Icons.emoji_events_outlined);
    expect(pills.last.icon, Icons.flag_outlined);
  });

  testWidgets('league match pills use journée when there is no tour',
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

    final pills = sessionShareEventPills(
      l10n: l10n,
      isMatch: true,
      matchContext: SessionShareMatchContext.fromMatch(
        models.Match(
          chType: 'Championnat Régional 1',
          day: 12,
          isStatApplied: true,
        ),
      ),
    );

    expect(pills.map((p) => p.label).toList(), [
      'Championnat Régional 1',
      l10n.periodMatchDay('12'),
    ]);
    expect(pills.last.icon, Icons.calendar_view_day_rounded);
  });

  testWidgets('training share shows a training pill, not empty pills',
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

    final pills = sessionShareEventPills(
      l10n: l10n,
      isMatch: false,
      matchContext: null,
    );

    expect(pills, hasLength(1));
    expect(pills.single.label, l10n.entityTraining);
    expect(pills.single.icon, Icons.fitness_center_rounded);
  });

  testWidgets('match without competition or tour hides pills', (tester) async {
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

    expect(
      sessionShareEventPills(
        l10n: l10n,
        isMatch: true,
        matchContext: const SessionShareMatchContext(
          team1Name: 'A',
          team2Name: 'B',
          homeScore: 0,
          awayScore: 0,
          isStatApplied: false,
        ),
      ),
      isEmpty,
    );
  });

  testWidgets('cartouche meta lines are competition + tour in white source data',
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

    expect(
      sessionShareCartoucheMetaLines(
        l10n: l10n,
        matchContext: SessionShareMatchContext.fromMatch(
          models.Match(
            chType: 'COUPE DE FRANCE CREDIT AGRICOLE',
            tour: '2E TOUR',
            isStatApplied: true,
          ),
        ),
      ),
      ['COUPE DE FRANCE CREDIT AGRICOLE', '2E TOUR'],
    );
  });

  test('session share tramé overlay stays light enough to show the photo', () {
    expect(
      SessionPlayerSynthesisShareService.trameOverlayOpacity,
      lessThan(0.45),
    );
  });
}
