import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';

void main() {
  group('PolarSessionAnalysis', () {
    test('docIdFor joins event and tracker', () {
      expect(
        PolarSessionAnalysis.docIdFor(
          eventId: 'evt1',
          trackerId: 'devOwner9',
        ),
        'evt1_devOwner9',
      );
    });

    test('round-trips cardio fields through toMap/fromMap', () {
      final original = PolarSessionAnalysis(
        eventId: 'evt1',
        playerId: 'p1',
        trackerId: 't1',
        polarDeviceId: '1C709B20',
        deviceType: 'Verity Sense',
        duration: const Duration(minutes: 75),
        avgHrBpm: 142,
        maxHrBpm: 188,
        minHrBpm: 98,
        hrSamplesCount: 4500,
        hrZoneSeconds: const {'z1': 600, 'z2': 1200, 'z3': 1800, 'z4': 900},
        caloriesKcal: null,
        distanceMeters: null,
        steps: null,
        importChannel: PolarImportChannel.bleMobile,
        importedUid: 'coach1',
      );

      final restored = PolarSessionAnalysis.fromMap(original.toMap());

      expect(restored.eventId, original.eventId);
      expect(restored.playerId, original.playerId);
      expect(restored.trackerId, original.trackerId);
      expect(restored.polarDeviceId, original.polarDeviceId);
      expect(restored.deviceType, original.deviceType);
      expect(restored.duration, original.duration);
      expect(restored.avgHrBpm, 142);
      expect(restored.maxHrBpm, 188);
      expect(restored.minHrBpm, 98);
      expect(restored.hrSamplesCount, 4500);
      expect(restored.hrZoneSeconds['z3'], 1800);
      expect(restored.caloriesKcal, isNull);
      expect(restored.importChannel, PolarImportChannel.bleMobile);
      expect(restored.docId, 'evt1_t1');
    });

    test('Loop extras serialize when present', () {
      final loop = PolarSessionAnalysis(
        eventId: 'e',
        playerId: 'p',
        trackerId: 't',
        polarDeviceId: 'AABBCCDD',
        deviceType: 'Loop',
        duration: const Duration(minutes: 60),
        avgHrBpm: 130,
        caloriesKcal: 512.5,
        distanceMeters: 4200,
        steps: 5800,
        importChannel: PolarImportChannel.bleChrome,
      );

      final map = loop.toMap();
      expect(map['provider'], 'polar');
      expect(map['kind'], 'cardio');
      expect(map['importChannel'], 'ble_chrome');
      expect(map['caloriesKcal'], 512.5);
      expect(map['distanceMeters'], 4200);
      expect(map['steps'], 5800);
    });

    test('PolarImportChannel fromWire defaults to ble_mobile', () {
      expect(
        PolarImportChannel.fromWire(null),
        PolarImportChannel.bleMobile,
      );
      expect(
        PolarImportChannel.fromWire('ble_chrome'),
        PolarImportChannel.bleChrome,
      );
    });
  });
}
