import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/physiological_data_consent.dart';

void main() {
  group('physiologicalConsentFromUserData', () {
    test('missing field → unknown', () {
      expect(
        physiologicalConsentFromUserData(<String, dynamic>{}),
        PhysiologicalDataConsentStatus.unknown,
      );
      expect(
        physiologicalConsentFromUserData(null),
        PhysiologicalDataConsentStatus.unknown,
      );
    });

    test('true → granted, false → refused', () {
      expect(
        physiologicalConsentFromUserData(<String, dynamic>{
          UserDocumentFields.physiologicalDataConsent: true,
        }),
        PhysiologicalDataConsentStatus.granted,
      );
      expect(
        physiologicalConsentFromUserData(<String, dynamic>{
          UserDocumentFields.physiologicalDataConsent: false,
        }),
        PhysiologicalDataConsentStatus.refused,
      );
    });
  });

  group('wearableRequiresPhysiologicalConsent', () {
    test('HR / health platforms require consent', () {
      expect(
        wearableRequiresPhysiologicalConsent(WearableDeviceType.whoop),
        isTrue,
      );
      expect(
        wearableRequiresPhysiologicalConsent(WearableDeviceType.polar),
        isTrue,
      );
      expect(
        wearableRequiresPhysiologicalConsent(WearableDeviceType.fitbit),
        isTrue,
      );
      expect(
        wearableRequiresPhysiologicalConsent(WearableDeviceType.appleHealth),
        isTrue,
      );
      expect(
        wearableRequiresPhysiologicalConsent(
          WearableDeviceType.googleHealthConnect,
        ),
        isTrue,
      );
    });

    test('Strava and Intense GPS do not require physio consent', () {
      expect(
        wearableRequiresPhysiologicalConsent(WearableDeviceType.strava),
        isFalse,
      );
      expect(
        wearableRequiresPhysiologicalConsent(
          WearableDeviceType.gpsInsidersIntense,
        ),
        isFalse,
      );
    });

    test('WearableDeviceType.requiresPhysiologicalConsent mirrors helper', () {
      for (final type in WearableDeviceType.values) {
        expect(
          type.requiresPhysiologicalConsent,
          wearableRequiresPhysiologicalConsent(type),
        );
      }
    });
  });
}
