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
    final safeTrackerId = _formatTrackerId(trackerId);
    final safeEventId = eventId.trim();
    final safePeriodSuffix = periodSuffix.trim();

    if (safeTrackerId.isEmpty ||
        safeEventId.isEmpty ||
        safePeriodSuffix.isEmpty) {
      return null;
    }
    
    // Donne exactement : 01-53514382_fullMatch
    final normalizedDocumentId =
        '$safeTrackerId-$safeEventId\_${safePeriodSuffix}';

    final doc = await _firestore
        .collection(collectionName)
        .doc(normalizedDocumentId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final data = doc.data()!;
    final svgFiles = data['svgFiles'];

    if (svgFiles is Map<String, dynamic>) {
      final directEntry = svgFiles[normalizedDocumentId];

      if (directEntry is Map<String, dynamic>) {
        final svg = directEntry['svg'];
        if (svg is String && svg.trim().isNotEmpty) {
          return svg;
        }
      }

      for (final entry in svgFiles.values) {
        if (entry is Map<String, dynamic>) {
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

  String _formatTrackerId(String value) {
    final safe = value.trim();

    if (safe.isEmpty) return '';

    final asInt = int.tryParse(safe);

    if (asInt != null) {
      return asInt.toString().padLeft(2, '0');
    }

    return safe.padLeft(2, '0');
  }
}