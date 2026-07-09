import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/services/intense_live_data_service.dart';

void main() {
  group('resolveIntenseLiveMetricsWindow', () {
    test('uses rolling lookback ending at fetch stop', () {
      final sessionStart = DateTime.utc(2026, 7, 9, 18, 0);
      final fetchStop = DateTime.utc(2026, 7, 9, 18, 46);

      final window = resolveIntenseLiveMetricsWindow(
        sessionStartUtc: sessionStart,
        fetchStopUtc: fetchStop,
      );

      expect(window.stop.toUtc(), fetchStop);
      expect(
        window.start.toUtc(),
        fetchStop.subtract(kIntenseLiveMetricsLookback),
      );
    });

    test('clamps start to session start when lookback exceeds elapsed time', () {
      final sessionStart = DateTime.utc(2026, 7, 9, 18, 40);
      final fetchStop = DateTime.utc(2026, 7, 9, 18, 46);

      final window = resolveIntenseLiveMetricsWindow(
        sessionStartUtc: sessionStart,
        fetchStopUtc: fetchStop,
      );

      expect(window.start.toUtc(), sessionStart);
      expect(window.stop.toUtc(), fetchStop);
    });

    test('respects custom lookback duration', () {
      final sessionStart = DateTime.utc(2026, 7, 9, 18, 0);
      final fetchStop = DateTime.utc(2026, 7, 9, 18, 46);
      const lookback = Duration(minutes: 5);

      final window = resolveIntenseLiveMetricsWindow(
        sessionStartUtc: sessionStart,
        fetchStopUtc: fetchStop,
        lookback: lookback,
      );

      expect(window.start.toUtc(), fetchStop.subtract(lookback));
    });
  });
}
