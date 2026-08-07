import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/services/userService.dart';

/// Current copy / legal version of the physiological-data consent text.
const String kPhysiologicalDataConsentVersion = '1';

/// Consent source written on `users/{uid}`.
abstract final class PhysiologicalDataConsentSource {
  static const self = 'self';
  static const parent = 'parent';
}

/// Resolved consent state for heart-rate / physiological device sync.
enum PhysiologicalDataConsentStatus {
  /// Never asked / missing field.
  unknown,

  /// Explicit authorization recorded.
  granted,

  /// Explicit refusal recorded (other app features stay available).
  refused,
}

PhysiologicalDataConsentStatus physiologicalConsentFromUserData(
  Map<String, dynamic>? data,
) {
  if (data == null) return PhysiologicalDataConsentStatus.unknown;
  final raw = data[UserDocumentFields.physiologicalDataConsent];
  if (raw == true) return PhysiologicalDataConsentStatus.granted;
  if (raw == false) return PhysiologicalDataConsentStatus.refused;
  return PhysiologicalDataConsentStatus.unknown;
}

/// Device types that can transmit heart rate / physiological health data.
bool wearableRequiresPhysiologicalConsent(WearableDeviceType type) {
  switch (type) {
    case WearableDeviceType.whoop:
    case WearableDeviceType.polar:
    case WearableDeviceType.fitbit:
    case WearableDeviceType.appleHealth:
    case WearableDeviceType.googleHealthConnect:
      return true;
    case WearableDeviceType.strava:
    case WearableDeviceType.gpsInsidersIntense:
      return false;
  }
}
