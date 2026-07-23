part of 'field_localization_screen.dart';

const String kGoogleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyDyHHcP9py2HCyx18Ssels7qqygKxeUZG0',
);

class FieldLocalizationResult {
  final String fieldName;
  final String fieldAddress;
  final int playersPerTeam;
  final FieldGpsCorners fieldGpsCorners;
  final FieldGeometry? geometry;

  const FieldLocalizationResult({
    required this.fieldName,
    this.fieldAddress = '',
    required this.playersPerTeam,
    required this.fieldGpsCorners,
    required this.geometry,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'fieldAddress': fieldAddress,
      'playersPerTeam': playersPerTeam,
      'fieldGpsCorners': fieldGpsCorners.toMap(),
      'geometry': geometry?.toMap(),
    };
  }
}
