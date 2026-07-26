import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/util/polar_device_id.dart';

void main() {
  group('parsePolarDeviceIdentity', () {
    test('parses Polar H10 name', () {
      final id = parsePolarDeviceIdentity('Polar H10 1C709B20');
      expect(id, isNotNull);
      expect(id!.deviceId, '1C709B20');
      expect(id.deviceType, 'H10');
      expect(id.displayName, 'Polar H10 1C709B20');
    });

    test('parses Polar Sense (Verity Sense) name', () {
      final id = parsePolarDeviceIdentity('Polar Sense 8C4CAD2D');
      expect(id, isNotNull);
      expect(id!.deviceId, '8C4CAD2D');
      expect(id.deviceType, 'Verity Sense');
    });

    test('parses Polar H9 and OH1', () {
      expect(parsePolarDeviceIdentity('Polar H9 AABBCCDD')!.deviceType, 'H9');
      expect(parsePolarDeviceIdentity('Polar OH1 12345678')!.deviceType, 'OH1');
    });

    test('uppercases device id', () {
      expect(
        parsePolarDeviceIdentity('Polar H10 ab12cd34')!.deviceId,
        'AB12CD34',
      );
    });

    test('returns null without trailing hex id', () {
      expect(parsePolarDeviceIdentity('Polar H10'), isNull);
      expect(parsePolarDeviceIdentity(''), isNull);
      expect(parsePolarDeviceIdentity(null), isNull);
    });
  });

  group('looksLikePolarDeviceId', () {
    test('accepts hex 6-12 chars', () {
      expect(looksLikePolarDeviceId('1C709B20'), isTrue);
      expect(looksLikePolarDeviceId('ABC123'), isTrue);
      expect(looksLikePolarDeviceId('not-hex'), isFalse);
      expect(looksLikePolarDeviceId('12345'), isFalse);
    });
  });
}
