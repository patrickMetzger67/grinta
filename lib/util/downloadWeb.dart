import 'dart:convert';
import 'dart:html' as html;

import '../model/trackerDeviceRaw.dart';

void downloadJsonWeb(List<Map<String, dynamic>> data) {
  final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

  final bytes = utf8.encode(jsonStr);
  final blob = html.Blob([bytes]);

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "tracker_data.json")
    ..click();

  html.Url.revokeObjectUrl(url);
}

Future<String> saveRowsLocallyWeb(
    List<TrackerDeviceRaw> rows, {
      required String deviceId,
    }) async {
  final fileName =
      'tracker_${deviceId.isNotEmpty ? deviceId : "unknown"}_${DateTime.now().millisecondsSinceEpoch}.csv';

  if (rows.isEmpty) return '';

  // Headers
  final headers = [
    'id',
    'deviceId',
    'timestamp',
    'latitude',
    'longitude',
    'altitude',
    'speed',
    'hr',
  ];

  String escape(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') || str.contains('"') || str.contains('\n')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  final buffer = StringBuffer();

  // Header line
  buffer.writeln(headers.join(','));

  // Data lines
  for (final row in rows) {
    buffer.writeln([
      escape(row.id),
      escape(row.deviceId),
      escape(row.timestamp.toDate().toIso8601String()),
      escape(row.latitude),
      escape(row.longitude),
      escape(row.altitude),
      escape(row.speed),
      escape(row.hr),
    ].join(','));
  }

  final csvStr = buffer.toString();

  // Download navigateur (équivalent écriture fichier)
  final bytes = utf8.encode(csvStr);
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);

  return fileName;
}