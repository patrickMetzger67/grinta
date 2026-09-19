import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/services/gio_session_opinion.dart';

void main() {
  group('buildGioSessionOpinionContext', () {
    test('keeps the 5 newest sessions of the same type', () {
      final current = _record(
        id: 'current',
        type: kGioSessionTypeTraining,
        date: DateTime(2026, 9, 19),
        metrics: const <String, num>{'distanceKm': 8.4, 'sprintCount': 12},
      );
      final history = <GioOpinionSessionRecord>[
        _record(
          id: 'old',
          type: kGioSessionTypeTraining,
          date: DateTime(2026, 8, 1),
          metrics: const <String, num>{'distanceKm': 5},
        ),
        _record(
          id: 'match',
          type: kGioSessionTypeMatch,
          date: DateTime(2026, 9, 18),
          metrics: const <String, num>{'distanceKm': 11},
        ),
        current,
        for (var day = 2; day <= 7; day++)
          _record(
            id: 't$day',
            type: kGioSessionTypeTraining,
            date: DateTime(2026, 9, day),
            metrics: <String, num>{'distanceKm': day.toDouble()},
          ),
      ];

      final context = buildGioSessionOpinionContext(
        sessionType: kGioSessionTypeTraining,
        source: GioSessionOpinionSource.gps,
        playerName: 'Alex',
        current: current,
        history: history,
      );

      expect(context['sessionType'], 'training');
      expect(context['source'], 'gps');
      expect(context['playerName'], 'Alex');
      expect(context['recentCount'], 5);
      final recent = context['recentSameType'] as List<dynamic>;
      expect(recent.map((item) => (item as Map)['eventId']).toList(), <String>[
        't7',
        't6',
        't5',
        't4',
        't3',
      ]);
      expect((context['recentAverages'] as Map)['distanceKm'], 5);
      final distance =
          (context['currentVsRecentAverage'] as Map)['distanceKm'] as Map;
      expect(distance['current'], 8.4);
      expect(distance['recentAverage'], 5);
      expect(distance['changePercent'], 68);
    });

    test('comments the current session when there is no history', () {
      final context = buildGioSessionOpinionContext(
        sessionType: kGioSessionTypeMatch,
        source: GioSessionOpinionSource.polar,
        current: _record(
          id: 'm1',
          type: kGioSessionTypeMatch,
          metrics: const <String, num>{'avgHrBpm': 154},
        ),
        history: const <GioOpinionSessionRecord>[],
      );

      expect(context['recentCount'], 0);
      expect(context['recentSameType'], isEmpty);
      expect(context['recentAverages'], isEmpty);
      final hr = (context['currentVsRecentAverage'] as Map)['avgHrBpm'] as Map;
      expect(hr['current'], 154);
      expect(hr.containsKey('changePercent'), isFalse);
    });

    test('omits change percent when the recent average is zero', () {
      final context = buildGioSessionOpinionContext(
        sessionType: kGioSessionTypeMatch,
        source: GioSessionOpinionSource.gps,
        current: _record(
          id: 'now',
          type: kGioSessionTypeMatch,
          metrics: const <String, num>{'sprintCount': 4},
        ),
        history: <GioOpinionSessionRecord>[
          _record(
            id: 'prev',
            type: kGioSessionTypeMatch,
            date: DateTime(2026, 9, 1),
            metrics: const <String, num>{'sprintCount': 0},
          ),
        ],
      );

      final sprints =
          (context['currentVsRecentAverage'] as Map)['sprintCount'] as Map;
      expect(sprints['recentAverage'], 0);
      expect(sprints.containsKey('changePercent'), isFalse);
    });

    test('dedupes a session and keeps the newest copy', () {
      final recent = selectRecentSameTypeSessions(
        currentEventId: 'current',
        sessionType: kGioSessionTypeTraining,
        history: <GioOpinionSessionRecord>[
          _record(
            id: 'a',
            type: kGioSessionTypeTraining,
            date: DateTime(2026, 9, 1),
            metrics: const <String, num>{'distanceKm': 1},
          ),
          _record(
            id: 'a',
            type: kGioSessionTypeTraining,
            date: DateTime(2026, 9, 2),
            metrics: const <String, num>{'distanceKm': 2},
          ),
        ],
      );

      expect(recent, hasLength(1));
      expect(recent.single.metrics['distanceKm'], 2);
    });
  });

  test('gps metrics expose the synthesis indicators', () {
    final metrics = gioMetricsFromTrackerAnalysis(
      const TrackerAnalysisResult(
        trackerId: 't',
        playerId: 'p',
        eventId: 'e',
        distanceKm: 8.456,
        duration: Duration(minutes: 90, seconds: 30),
        averageSpeedKmh: 6.24,
        maxSpeedKmh: 30,
        maxValidatedSpeedKmh: 28.16,
        samplesCount: 10,
        heatmapPoints: <HeatmapPoint>[],
        sprintCount: 7,
        highAccelerationCount: 4,
        highSpeedDuration: Duration(seconds: 42),
        maxAccelerationMps2: 3.456,
        distanceByZones: <FieldZoneStats>[],
        speedZones: <SpeedZoneStat>[],
        halfStats: <HalfStats>[],
        workloadScore: 174.2,
        workloadScorePerMinute: 1.9,
        playerProfile: '',
        fatigueIndex: 0.876,
        firstHalfDistanceKm: 4.2,
        secondHalfDistanceKm: 3.7,
        distanceTimeline: <DistanceTimelineStat>[],
      ),
    );

    expect(metrics['distanceKm'], 8.46);
    expect(metrics['durationMinutes'], 90.5);
    expect(metrics['sprintCount'], 7);
    expect(metrics['highSpeedDurationSeconds'], 42);
    expect(metrics['workloadScore'], 174);
    expect(metrics['fatigueIndex'], 0.88);
  });

  test('polar metrics skip missing cardio fields', () {
    final metrics = gioMetricsFromPolarAnalysis(
      const PolarSessionAnalysis(
        eventId: 'e',
        playerId: 'p',
        trackerId: 't',
        polarDeviceId: 'd',
        deviceType: 'Verity Sense',
        duration: Duration(minutes: 60),
        avgHrBpm: 148,
        hrZoneSeconds: <String, int>{'z4': 600},
      ),
    );

    expect(metrics['durationMinutes'], 60);
    expect(metrics['avgHrBpm'], 148);
    expect(metrics['hrZoneZ4Seconds'], 600);
    expect(metrics.containsKey('maxHrBpm'), isFalse);
    expect(metrics.containsKey('distanceKm'), isFalse);
  });

  test('user message names the session type', () {
    expect(
      gioSessionOpinionUserMessage(isMatch: false),
      contains('entraînement'),
    );
    expect(gioSessionOpinionUserMessage(isMatch: true), contains('matchs'));
  });
}

GioOpinionSessionRecord _record({
  required String id,
  required String type,
  required Map<String, num> metrics,
  DateTime? date,
  String? label,
}) {
  return GioOpinionSessionRecord(
    eventId: id,
    sessionType: type,
    metrics: metrics,
    date: date,
    label: label,
  );
}
