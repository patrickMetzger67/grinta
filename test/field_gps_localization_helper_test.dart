import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';

void main() {
  group('FieldGpsLocalizationHelper.completeCornersOrNull', () {
    test('returns null when corners are null', () {
      expect(
        FieldGpsLocalizationHelper.completeCornersOrNull(null),
        isNull,
      );
    });

    test('returns null when any corner is missing', () {
      final incomplete = FieldGpsCorners(
        topLeft: const FieldCornerGps(latitude: 48.0, longitude: 2.0),
        topRight: const FieldCornerGps(latitude: 48.0, longitude: 2.001),
        bottomLeft: const FieldCornerGps(latitude: 47.999, longitude: 2.0),
      );

      expect(
        FieldGpsLocalizationHelper.completeCornersOrNull(incomplete),
        isNull,
      );
    });

    test('returns the same instance when all four corners are present', () {
      final complete = FieldGpsCorners(
        topLeft: const FieldCornerGps(latitude: 48.0, longitude: 2.0),
        topRight: const FieldCornerGps(latitude: 48.0, longitude: 2.001),
        bottomLeft: const FieldCornerGps(latitude: 47.999, longitude: 2.0),
        bottomRight: const FieldCornerGps(latitude: 47.999, longitude: 2.001),
      );

      expect(
        FieldGpsLocalizationHelper.completeCornersOrNull(complete),
        same(complete),
      );
    });
  });
}
