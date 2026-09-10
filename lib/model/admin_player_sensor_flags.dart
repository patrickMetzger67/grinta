/// Sensor / connected-device indicators for a player in admin.
class AdminPlayerSensorFlags {
  const AdminPlayerSensorFlags({
    required this.hasTeamKitSensor,
    required this.hasConnectedDevices,
  });

  /// Assigned team-kit tracker on at least one Grinta roster (`trackers`).
  final bool hasTeamKitSensor;

  /// At least one wearable / personal Intense GPS app connected.
  final bool hasConnectedDevices;

  static const none = AdminPlayerSensorFlags(
    hasTeamKitSensor: false,
    hasConnectedDevices: false,
  );

  bool get hasAny => hasTeamKitSensor || hasConnectedDevices;
}
