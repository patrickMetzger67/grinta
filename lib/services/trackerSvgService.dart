import 'package:cloud_firestore/cloud_firestore.dart';

class TrackerSvgService {
  static const String collectionName = 'TRACKER_Svg';

  final FirebaseFirestore _firestore;

  TrackerSvgService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> getSvgForTrackerPeriod({
    required String trackerId,
    required String eventId,
    required String periodSuffix,
  }) async {
    final safeEventId = eventId.trim();
    final safePeriodSuffix = periodSuffix.trim();
    if (safeEventId.isEmpty || safePeriodSuffix.isEmpty) {
      return null;
    }

    // Writers use raw device/tracker ids; readers historically pad to 2 digits.
    // Try every plausible doc id so existing heatmaps are not missed.
    for (final String candidateTracker in trackerIdCandidates(trackerId)) {
      final String documentId =
          '$candidateTracker-${safeEventId}_$safePeriodSuffix';
      final String? svg = await _readSvgFromDocument(documentId);
      if (svg != null && svg.trim().isNotEmpty) {
        return svg;
      }
    }

    return null;
  }

  /// Distinct tracker-id forms used as Firestore document prefixes.
  static List<String> trackerIdCandidates(String value) {
    final String raw = value.trim();
    if (raw.isEmpty) return const <String>[];

    final Set<String> out = <String>{raw};

    final int? asInt = int.tryParse(raw);
    if (asInt != null) {
      out.add(asInt.toString());
      out.add(asInt.toString().padLeft(2, '0'));
    } else {
      out.add(raw.padLeft(2, '0'));
      final String stripped = raw.replaceFirst(RegExp(r'^0+'), '');
      if (stripped.isNotEmpty) {
        out.add(stripped);
      }
    }

    return out.toList(growable: false);
  }

  Future<String?> _readSvgFromDocument(String documentId) async {
    final doc =
        await _firestore.collection(collectionName).doc(documentId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;
    final svgFiles = data['svgFiles'];

    if (svgFiles is Map) {
      final directEntry = svgFiles[documentId];
      if (directEntry is Map) {
        final svg = directEntry['svg'];
        if (svg is String && svg.trim().isNotEmpty) {
          return svg;
        }
      }

      for (final entry in svgFiles.values) {
        if (entry is Map) {
          final svg = entry['svg'];
          if (svg is String && svg.trim().isNotEmpty) {
            return svg;
          }
        }
      }
    }

    final directSvg = data['svg'];
    if (directSvg is String && directSvg.trim().isNotEmpty) {
      return directSvg;
    }

    return null;
  }
}
