import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Loads heatmap SVGs from [TRACKER_Svg].
///
/// Production keys (cloud writer):
/// `{sensorNumber}-{docId}` where [docId] is the Firestore document id of
/// `TRACKER_TeamAnalysis_fullMatch` / `_firstHalf` / `_secondHalf`.
///
/// Legacy local keys remain supported as fallback:
/// `{sensorNumber}-{eventId}_{periodSuffix}`.
class TrackerSvgService {
  static const String collectionName = 'TRACKER_Svg';

  static const Map<String, String> periodCollections = <String, String>{
    'fullMatch': 'TRACKER_TeamAnalysis_fullMatch',
    'firstHalf': 'TRACKER_TeamAnalysis_firstHalf',
    'secondHalf': 'TRACKER_TeamAnalysis_secondHalf',
  };

  final FirebaseFirestore _firestore;
  final Map<String, String?> _periodDocIdCache = <String, String?>{};

  TrackerSvgService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Resolves the three period TeamAnalysis document ids for [eventId].
  ///
  /// Returns a map keyed by `fullMatch` / `firstHalf` / `secondHalf`.
  Future<Map<String, String>> resolvePeriodTeamAnalysisDocIds(
    String eventId,
  ) async {
    final String safeEventId = eventId.trim();
    if (safeEventId.isEmpty) {
      return const <String, String>{};
    }

    final Map<String, String> out = <String, String>{};
    for (final String period in periodCollections.keys) {
      final String? docId = await resolvePeriodTeamAnalysisDocId(
        eventId: safeEventId,
        periodKey: period,
      );
      if (docId != null && docId.isNotEmpty) {
        out[period] = docId;
      }
    }
    return out;
  }

  /// Finds the document id in `TRACKER_TeamAnalysis_{period}` for [eventId].
  Future<String?> resolvePeriodTeamAnalysisDocId({
    required String eventId,
    required String periodKey,
  }) async {
    final String safeEventId = eventId.trim();
    final String safePeriod = periodKey.trim();
    if (safeEventId.isEmpty || safePeriod.isEmpty) {
      return null;
    }

    final String cacheKey = '$safeEventId|$safePeriod';
    if (_periodDocIdCache.containsKey(cacheKey)) {
      return _periodDocIdCache[cacheKey];
    }

    final String? collectionNameForPeriod = periodCollections[safePeriod];
    if (collectionNameForPeriod == null) {
      _periodDocIdCache[cacheKey] = null;
      return null;
    }

    try {
      final CollectionReference<Map<String, dynamic>> col =
          _firestore.collection(collectionNameForPeriod);

      // Try deterministic ids first (no composite index needed).
      for (final String candidateId in <String>[
        safeEventId,
        '${safeEventId}_$safePeriod',
        '$safeEventId-$safePeriod',
      ]) {
        final DocumentSnapshot<Map<String, dynamic>> byId =
            await col.doc(candidateId).get();
        if (byId.exists) {
          _periodDocIdCache[cacheKey] = byId.id;
          return byId.id;
        }
      }

      // Query by eventId / matchId when the period doc uses another id.
      for (final String field in const <String>['eventId', 'matchId']) {
        final QuerySnapshot<Map<String, dynamic>> snap = await col
            .where(field, isEqualTo: safeEventId)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) {
          final String id = snap.docs.first.id;
          _periodDocIdCache[cacheKey] = id;
          return id;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'TrackerSvgService: resolvePeriodTeamAnalysisDocId '
          '$collectionNameForPeriod/$safeEventId failed: $e',
        );
      }
    }

    _periodDocIdCache[cacheKey] = null;
    return null;
  }

  /// Primary production lookup: `{sensor}-{periodTeamAnalysisDocId}`.
  Future<String?> getSvgForSensorAndAnalysisDoc({
    required String trackerId,
    required String teamAnalysisDocId,
  }) async {
    final String analysisId = teamAnalysisDocId.trim();
    if (analysisId.isEmpty) {
      return null;
    }

    for (final String candidateTracker in trackerIdCandidates(trackerId)) {
      final String documentId = '$candidateTracker-$analysisId';
      final String? svg = await readSvgFromDocument(documentId);
      if (svg != null && svg.trim().isNotEmpty) {
        return svg;
      }
    }
    return null;
  }

  /// Loads an SVG for a tracker + event period.
  ///
  /// Order:
  /// 1. `{sensor}-{TRACKER_TeamAnalysis_{period} docId}` (cloud / production)
  /// 2. Legacy `{sensor}-{eventId}_{period}` (+ WithSprints)
  Future<String?> getSvgForTrackerPeriod({
    required String trackerId,
    required String eventId,
    required String periodSuffix,
  }) async {
    final String safeEventId = eventId.trim();
    final String safePeriodSuffix = periodSuffix.trim();
    if (safeEventId.isEmpty || safePeriodSuffix.isEmpty) {
      return null;
    }

    // Strip optional WithSprints when resolving the period TeamAnalysis doc.
    final String basePeriod = safePeriodSuffix.endsWith('WithSprints')
        ? safePeriodSuffix.substring(
            0,
            safePeriodSuffix.length - 'WithSprints'.length,
          )
        : safePeriodSuffix;

    final String? periodDocId = await resolvePeriodTeamAnalysisDocId(
      eventId: safeEventId,
      periodKey: basePeriod,
    );
    if (periodDocId != null && periodDocId.isNotEmpty) {
      final String? fromPeriodDoc = await getSvgForSensorAndAnalysisDoc(
        trackerId: trackerId,
        teamAnalysisDocId: periodDocId,
      );
      if (fromPeriodDoc != null && fromPeriodDoc.trim().isNotEmpty) {
        return fromPeriodDoc;
      }
    }

    // Legacy local writers: `{tracker}-{eventId}_{period}`.
    for (final String candidateTracker in trackerIdCandidates(trackerId)) {
      for (final String suffix in <String>[
        if (safePeriodSuffix != basePeriod) safePeriodSuffix,
        if (!basePeriod.endsWith('WithSprints')) '${basePeriod}WithSprints',
        basePeriod,
      ]) {
        final String documentId =
            '$candidateTracker-${safeEventId}_$suffix';
        final String? svg = await readSvgFromDocument(documentId);
        if (svg != null && svg.trim().isNotEmpty) {
          return svg;
        }
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

  /// Builds production TRACKER_Svg document ids for tests / debugging.
  static List<String> svgDocumentIdCandidates({
    required String trackerId,
    required String teamAnalysisDocId,
  }) {
    final String analysisId = teamAnalysisDocId.trim();
    if (analysisId.isEmpty) return const <String>[];
    return <String>[
      for (final String tracker in trackerIdCandidates(trackerId))
        '$tracker-$analysisId',
    ];
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
