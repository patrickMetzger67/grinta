import 'package:flutter/material.dart';
import 'package:grinta/l10n/app_localizations.dart';

/// Supported wearable device integrations (plus individual Intense GPS claim).
enum WearableDeviceType {
  whoop,
  strava,
  polar,
  oura,
  fitbit,
  appleHealth,
  googleHealthConnect,
  gpsInsidersIntense,
  ;

  /// Fitbit is intentionally omitted from the Devices / Apps picker.
  static const List<WearableDeviceType> selectable = [
    WearableDeviceType.whoop,
    WearableDeviceType.strava,
    WearableDeviceType.polar,
    WearableDeviceType.oura,
    WearableDeviceType.appleHealth,
    WearableDeviceType.googleHealthConnect,
    WearableDeviceType.gpsInsidersIntense,
  ];

  static List<WearableDeviceType> selectableSorted(AppLocalizations l10n) {
    return [
      for (final type in selectable) type,
    ]..sort((a, b) => a.label(l10n).compareTo(b.label(l10n)));
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case WearableDeviceType.whoop:
        return l10n.wearableDeviceWhoop;
      case WearableDeviceType.strava:
        return l10n.wearableDeviceStrava;
      case WearableDeviceType.polar:
        return l10n.wearableDevicePolar;
      case WearableDeviceType.oura:
        return l10n.wearableDeviceOura;
      case WearableDeviceType.fitbit:
        return l10n.wearableDeviceFitbit;
      case WearableDeviceType.appleHealth:
        return l10n.wearableDeviceAppleHealth;
      case WearableDeviceType.googleHealthConnect:
        return l10n.wearableDeviceGoogleHealthConnect;
      case WearableDeviceType.gpsInsidersIntense:
        return l10n.wearableDeviceGpsInsidersIntense;
    }
  }

  IconData get icon {
    switch (this) {
      case WearableDeviceType.whoop:
        return Icons.monitor_heart_outlined;
      case WearableDeviceType.strava:
        return Icons.directions_run_outlined;
      case WearableDeviceType.polar:
        return Icons.favorite_outline;
      case WearableDeviceType.oura:
        return Icons.nightlight_round;
      case WearableDeviceType.fitbit:
        return Icons.watch_outlined;
      case WearableDeviceType.appleHealth:
        return Icons.fitness_center_outlined;
      case WearableDeviceType.googleHealthConnect:
        return Icons.directions_run_outlined;
      case WearableDeviceType.gpsInsidersIntense:
        return Icons.gps_fixed_rounded;
    }
  }
}
