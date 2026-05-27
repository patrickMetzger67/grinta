part of 'field_localization_screen.dart';

const String kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyDyHHcP9py2HCyx18Ssels7qqygKxeUZG0',
);

class FieldLocalizationResult {
  final String fieldName;
  final int playersPerTeam;
  final FieldGpsCorners fieldGpsCorners;
  final FieldGeometry? geometry;

  const FieldLocalizationResult({
    required this.fieldName,
    required this.playersPerTeam,
    required this.fieldGpsCorners,
    required this.geometry,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'playersPerTeam': playersPerTeam,
      'fieldGpsCorners': fieldGpsCorners.toMap(),
      'geometry': geometry?.toMap(),
    };
  }
}
