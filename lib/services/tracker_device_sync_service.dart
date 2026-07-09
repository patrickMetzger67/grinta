import 'package:cloud_functions/cloud_functions.dart';

/// Fetches tracker devices from external providers via Cloud Functions.
class TrackerDeviceSyncService {
  TrackerDeviceSyncService({FirebaseFunctions? functions})
      : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<List<Map<String, dynamic>>> fetchInspiritInsidersDevices() async {
    final devices = <Map<String, dynamic>>[];
    String? next;

    do {
      final res = await _functions
          .httpsCallable('insidersListDevices')
          .call(_buildListDevicesPayload(next));

      final page = Map<String, dynamic>.from(res.data['data'] as Map);

      final results = (page['results'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          <Map<String, dynamic>>[];

      devices.addAll(results);
      next = _nextPageToken(page['next']);
    } while (next != null);

    return devices;
  }

  Map<String, dynamic> _buildListDevicesPayload(String? next) {
    if (next == null) {
      return <String, dynamic>{
        'query': <String, dynamic>{'limit': 50},
      };
    }

    if (next.startsWith('http') || next.startsWith('/')) {
      return <String, dynamic>{'next': next};
    }

    final pageNum = int.tryParse(next);
    if (pageNum != null) {
      return <String, dynamic>{
        'query': <String, dynamic>{'limit': 50, 'page': pageNum},
      };
    }

    return <String, dynamic>{'next': next};
  }

  /// Insiders may return [next] as a URL, a page number (int), or a string token.
  String? _nextPageToken(dynamic value) {
    if (value == null) return null;
    final token = value.toString().trim();
    return token.isEmpty ? null : token;
  }
}
