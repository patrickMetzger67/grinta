import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/tracker/device.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/util/insiders_device_resolver.dart';

void main() {
  group('isInsidersNumericId', () {
    test('accepts positive integer strings', () {
      expect(isInsidersNumericId('12'), isTrue);
      expect(isInsidersNumericId('24990'), isTrue);
      expect(isInsidersNumericId('0'), isTrue);
    });

    test('rejects UUID and non-numeric labels', () {
      expect(
        isInsidersDeviceUuid('550e8400-e29b-41d4-a716-446655440000'),
        isTrue,
      );
      expect(isInsidersNumericId('550e8400-e29b-41d4-a716-446655440000'), isFalse);
      expect(isInsidersNumericId('INTENSE-42'), isFalse);
    });
  });

  group('isInsidersDeviceUuid', () {
    test('accepts standard UUID', () {
      expect(
        isInsidersDeviceUuid('550e8400-e29b-41d4-a716-446655440000'),
        isTrue,
      );
    });

    test('rejects short numeric labels', () {
      expect(isInsidersDeviceUuid('7'), isFalse);
      expect(isInsidersDeviceUuid('24990'), isFalse);
    });
  });

  group('insidersUuidFromDevice', () {
    test('returns UUID from device id field', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final device = Device(id: uuid);
      expect(insidersUuidFromDevice(device), uuid);
    });

    test('rejects non-UUID device id', () {
      final device = Device(id: '24990');
      expect(insidersUuidFromDevice(device), isNull);
    });
  });

  group('resolveInsidersDeviceIdentifierFromOwner', () {
    test('returns DeviceOwner.deviceId as Insiders API identifier', () {
      final owner = _deviceOwner(
        docId: 'owner-doc-abc',
        deviceId: '24990',
        customName: '10',
      );

      final resolution = resolveInsidersDeviceIdentifierFromOwner(owner);

      expect(resolution?.identifier, '24990');
      expect(
        resolution?.fieldUsed,
        InsidersDeviceIdentifierField.deviceOwnerDeviceId,
      );
    });

    test('trims whitespace from deviceId', () {
      final owner = _deviceOwner(
        docId: 'owner-doc-abc',
        deviceId: '  24990  ',
      );

      final resolution = resolveInsidersDeviceIdentifierFromOwner(owner);

      expect(resolution?.identifier, '24990');
    });

    test('returns null when deviceId empty', () {
      final owner = _deviceOwner(docId: 'owner-doc-abc', deviceId: '  ');

      expect(resolveInsidersDeviceIdentifierFromOwner(owner), isNull);
    });

    test('does not resolve via TRACKER_Device device_name or serial_number', () {
      // DeviceOwner.deviceId is the Insiders sensor id — not IMEI/serial labels.
      final owner = _deviceOwner(
        docId: 'owner-doc-xyz',
        deviceId: '24990',
        customName: '10',
      );

      final resolution = resolveInsidersDeviceIdentifierFromOwner(owner);

      expect(resolution?.identifier, isNot('25053'));
      expect(resolution?.identifier, isNot('869084062463389'));
      expect(resolution?.identifier, '24990');
    });
  });

  group('trackerDisplayLabel', () {
    test('prefers customName over deviceId', () {
      final owner = _deviceOwner(customName: '7', deviceId: '24990');
      expect(trackerDisplayLabel(owner), '7');
    });
  });
}

DeviceOwner _deviceOwner({
  String docId = 'doc-1',
  required String deviceId,
  String? customName,
}) {
  return DeviceOwner(
    id: docId,
    ownerId: 'owner-1',
    deviceId: deviceId,
    customName: customName,
    affectedAt: Timestamp.now(),
    affectedUid: 'uid-1',
  );
}
