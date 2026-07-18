import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Loads heatmap SVGs from [TRACKER_Svg].
///
/// Document id format (confirmed production example):
/// `09-53514382_firstHalf` = `{sensor}-{matchId}_{period}`
/// with period in `firstHalf` / `secondHalf` / `fullMatch`.
class TrackerSvgService {
  static const String collectionName = 'TRACKER_Svg';

  static const List<String> periods = <String>[
    'firstHalf',
    'secondHalf',
    'fullMatch',
  ];

  final FirebaseFirestore _firestore;

  TrackerSvgService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Builds the TRACKER_Svg document id for a sensor + match period.
  ///
  /// Example: `buildSvgDocumentId(trackerId: '9', eventId: '53514382', period: 'firstHalf')`
  /// → candidates include `09-53514382_firstHalf`.
  static List<String> buildSvgDocumentIds({
    required String trackerId,
    required String eventId,
    required String period,
  }) {
    final String safeEventId = eventId.trim();
    final String safePeriod = period.trim();
    if (safeEventId.isEmpty || safePeriod.isEmpty) {
      return const <String>[];
    }

    final String basePeriod = safePeriod.endsWith('WithSprints')
        ? safePeriod.substring(0, safePeriod.length - 'WithSprints'.length)
        : safePeriod;

    final List<String> suffixes = <String>[
      basePeriod,
      if (!basePeriod.endsWith('WithSprints')) '${basePeriod}WithSprints',
    ];

    final List<String> out = <String>[];
    for (final String sensor in trackerIdCandidates(trackerId)) {
      for (final String suffix in suffixes) {
        out.add('$sensor-${safeEventId}_$suffix');
      }
    }
    return out;
  }

  /// Loads SVG for `{sensor}-{matchId}_{period}`.
  Future<String?> getSvgForTrackerPeriod({
    required String trackerId,
    required String eventId,
    required String periodSuffix,
  }) async {
    final List<String> documentIds = buildSvgDocumentIds(
      trackerId: trackerId,
      eventId: eventId,
      period: periodSuffix,
    );
    if (documentIds.isEmpty) {
      return null;
    }

    for (final String documentId in documentIds) {
      final String? svg = await readSvgFromDocument(documentId);
      if (svg != null && svg.trim().isNotEmpty) {
        if (kDebugMode) {
          debugPrint('TrackerSvgService: loaded TRACKER_Svg/$documentId');
        }
        return svg;
      }
    }

    if (kDebugMode) {
      debugPrint(
        'TrackerSvgService: no SVG for tracker=$trackerId '
        'eventId=$eventId period=$periodSuffix '
        'tried=${documentIds.join(", ")}',
      );
    }
    return null;
  }

  /// Prefer padded sensor ids first (`09` before `9`) to match production keys.
  static List<String> trackerIdCandidates(String value) {
    final String raw = value.trim();
    if (raw.isEmpty) return const <String>[];

    final List<String> ordered = <String>[];
    void add(String candidate) {
      if (candidate.isNotEmpty && !ordered.contains(candidate)) {
        ordered.add(candidate);
      }
    }

    final int? asInt = int.tryParse(raw);
    if (asInt != null) {
      add(asInt.toString().padLeft(2, '0'));
      add(asInt.toString());
      add(raw);
    } else {
      add(raw);
      add(raw.padLeft(2, '0'));
      final String stripped = raw.replaceFirst(RegExp(r'^0+'), '');
      if (stripped.isNotEmpty) {
        add(stripped);
      }
    }

    return ordered;
  }

  Future<String?> readSvgFromDocument(String documentId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection(collectionName).doc(documentId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    final Map<String, dynamic> data = doc.data()!;
    final dynamic svgFiles = data['svgFiles'];

    if (svgFiles is Map) {
      final dynamic directEntry = svgFiles[documentId];
      if (directEntry is Map) {
        final dynamic svg = directEntry['svg'];
        if (svg is String && svg.trim().isNotEmpty) {
          return svg;
        }
      }

      for (final dynamic entry in svgFiles.values) {
        if (entry is Map) {
          final dynamic svg = entry['svg'];
          if (svg is String && svg.trim().isNotEmpty) {
            return svg;
          }
        }
      }
    }

    final dynamic directSvg = data['svg'];
    if (directSvg is String && directSvg.trim().isNotEmpty) {
      return directSvg;
    }

    return null;
  }
}
