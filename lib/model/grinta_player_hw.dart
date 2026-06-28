import 'package:cloud_firestore/cloud_firestore.dart';

String keyGrintaPlayerHwHeight = 'height';
String keyGrintaPlayerHwWeight = 'weight';
String keyGrintaPlayerHwDateTime = 'dateTime';

/// Height/weight measurement recorded for a [GrintaPlayer].
class GrintaPlayerHW {
  int height;
  double weight;
  DateTime dateTime;

  GrintaPlayerHW({
    required this.height,
    required this.weight,
    required this.dateTime,
  });

  factory GrintaPlayerHW.fromMap(Map<String, dynamic>? map) {
    final int height = _parseHeight(map?[keyGrintaPlayerHwHeight]);
    final double weight = _parseWeight(map?[keyGrintaPlayerHwWeight]);
    final DateTime dateTime =
        _parseDateTime(map?[keyGrintaPlayerHwDateTime]) ?? DateTime.now();

    return GrintaPlayerHW(
      height: height,
      weight: weight,
      dateTime: dateTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      keyGrintaPlayerHwHeight: height,
      keyGrintaPlayerHwWeight: weight,
      keyGrintaPlayerHwDateTime: Timestamp.fromDate(dateTime),
    };
  }

  static int _parseHeight(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static double _parseWeight(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  @override
  String toString() {
    return 'GrintaPlayerHW(height=$height, weight=$weight, dateTime=$dateTime)';
  }
}
