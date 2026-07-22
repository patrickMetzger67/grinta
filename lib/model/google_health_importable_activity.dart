/// Platform-agnostic DTO for a Google Fit / Health Connect workout ready to import.
class GoogleHealthImportableActivity {
  const GoogleHealthImportableActivity({
    required this.externalId,
    required this.name,
    required this.typeId,
    required this.startDate,
    required this.endDate,
    this.durationSeconds,
    this.distanceMeters,
    this.paceSecondsPerKm,
    this.caloriesKcal,
    this.averageHeartRateBpm,
    this.workoutActivityType,
  });

  final String externalId;
  final String name;
  final String typeId;
  final DateTime startDate;
  final DateTime endDate;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? paceSecondsPerKm;
  final double? caloriesKcal;
  final int? averageHeartRateBpm;
  final String? workoutActivityType;

  String get displayLabel {
    final parts = <String>[name];
    parts.add(
      '${startDate.day.toString().padLeft(2, '0')}/'
      '${startDate.month.toString().padLeft(2, '0')}',
    );
    if (distanceMeters != null && distanceMeters! > 0) {
      parts.add('${(distanceMeters! / 1000).toStringAsFixed(1)} km');
    } else if (durationSeconds != null && durationSeconds! > 0) {
      final minutes = (durationSeconds! / 60).round();
      parts.add('${minutes} min');
    }
    return parts.join(' · ');
  }
}
