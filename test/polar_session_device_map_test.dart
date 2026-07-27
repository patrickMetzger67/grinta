import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/util/polar_session_device_map.dart';

void main() {
  group('buildPolarTrainingDevicePlayerMap', () {
    test('uses DeviceOwner doc ids (not customName) for present players',
        () async {
      final ownerDevices = <String, DeviceOwner>{
        'do1': DeviceOwner(
          id: 'do1',
          ownerId: 'owner1',
          deviceId: 'AABBCCDD',
          affectedAt: Timestamp.now(),
          affectedUid: 'u1',
          customName: '10',
        ),
        'do2': DeviceOwner(
          id: 'do2',
          ownerId: 'owner1',
          deviceId: '11223344',
          affectedAt: Timestamp.now(),
          affectedUid: 'u1',
          customName: '7',
        ),
      };

      final p1 = PlayerTraining(
        playerId: 'p1',
        presenceType: PresenceType.present,
      )..deviceId = 'do1';
      final p2 = PlayerTraining(
        playerId: 'p2',
        presenceType: PresenceType.absent,
      )..deviceId = 'do2';
      final p3 = PlayerTraining(
        playerId: 'p3',
        presenceType: PresenceType.late,
      )..deviceId = 'do2';

      final training = Training(
        docId: 'tr1',
        trainingId: 'tr1',
        seasonId: 's1',
        playerTraining: [p1, p2, p3],
      );

      final map = await buildPolarTrainingDevicePlayerMap(
        training: training,
        ownerDevicesByDocId: ownerDevices,
        seasonId: 's1',
        loadAnswers: (_) async => const [],
      );

      expect(map.keys, isNot(contains('10')));
      expect(map.keys, isNot(contains('7')));
      expect(map, {
        'do1': 'p1',
        'do2': 'p3',
      });
    });
  });
}
