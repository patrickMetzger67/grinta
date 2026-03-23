import 'package:cloud_firestore/cloud_firestore.dart';

class TrackerDeviceRaw {
  final String id;
  final String deviceId;
  final Timestamp timestamp;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? speed;
  final int? hr;
  final String rawLine;

  TrackerDeviceRaw({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.rawLine,
    this.latitude,
    this.longitude,
    this.altitude,
    this.speed,
    this.hr,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'hr': hr,
      'rawLine': rawLine,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class TrackerDeviceRawNoHeaderParser {
  static List<String> _splitCsvLine(String line) {
    return line.split(',').map((e) => e.trim()).toList();
  }

  static double? _toDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  static int? _toInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return int.tryParse(value);
  }

  static DateTime? _parseEpochSecondsToTimestamp(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;

    final seconds = double.tryParse(v);
    if (seconds == null) return null;

    final millis = (seconds * 1000).round();
    if (millis <= 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  static List<TrackerDeviceRaw> parseCsv({
    required String csv,
    required String deviceId,
  }) {
    final lines = csv
        .split(RegExp(r'\r\n|\n|\r'))
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final items = <TrackerDeviceRaw>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();

      // Ignore l'en-tête
      if (line.toLowerCase().startsWith('timestamp,')) {
        continue;
      }

      final cols = _splitCsvLine(line);

      while (cols.length < 6) {
        cols.add('');
      }

      final ts = _parseEpochSecondsToTimestamp(cols[0]);
      if (ts == null) {
        continue;
      }

      final latitude = _toDouble(cols[1]);
      final longitude = _toDouble(cols[2]);
      final altitude = _toDouble(cols[3]);
      final speed = _toDouble(cols[4]);
      final hr = _toInt(cols[5]);

      if (latitude == null || longitude == null) {
        continue;
      }

      final millis = ts.millisecondsSinceEpoch;
      final docId = '${deviceId}_$millis';

      items.add(
        TrackerDeviceRaw(
          id: docId,
          deviceId: deviceId,
          timestamp: Timestamp.fromMillisecondsSinceEpoch(millis),
          latitude: latitude,
          longitude: longitude,
          altitude: altitude,
          speed: speed,
          hr: hr,
          rawLine: line,
        ),
      );
    }

    return items;
  }
}