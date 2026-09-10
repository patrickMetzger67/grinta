import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';

/// CRUD for Polar cardio session imports (`TRACKER_PolarAnalysis`).
///
/// Parallel to [TrackerAnalysisService] / `TRACKER_Analysis` (GPS kits).
/// End-of-session import only — no live streaming.
class PolarSessionAnalysisService {
  PolarSessionAnalysisService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'TRACKER_PolarAnalysis';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Upserts one player/device analysis for an event.
  Future<String> saveAnalysis(PolarSessionAnalysis analysis) async {
    final now = DateTime.now().toUtc();
    final docId = analysis.docId;
    final existing = await _collection.doc(docId).get();
    final createdAt = existing.exists
        ? PolarSessionAnalysis.fromDoc(existing).createdAt ?? now
        : now;

    final payload = analysis
        .copyWith(
          createdAt: createdAt,
          updatedAt: now,
          importedAt: analysis.importedAt ?? now,
        )
        .toMap();

    await _collection.doc(docId).set(payload, SetOptions(merge: true));
    return docId;
  }

  Future<PolarSessionAnalysis?> getByDocId(String docId) async {
    final doc = await _collection.doc(docId).get();
    if (!doc.exists) return null;
    return PolarSessionAnalysis.fromDoc(doc);
  }

  Future<PolarSessionAnalysis?> getForEventTracker({
    required String eventId,
    required String trackerId,
  }) {
    return getByDocId(
      PolarSessionAnalysis.docIdFor(eventId: eventId, trackerId: trackerId),
    );
  }

  /// First Polar analysis for [playerId] on [eventId] (doc id = event_tracker).
  Future<PolarSessionAnalysis?> getForEventPlayer({
    required String eventId,
    required String playerId,
  }) async {
    final pid = playerId.trim();
    if (pid.isEmpty) return null;
    final list = await listByEventId(eventId);
    for (final analysis in list) {
      if (analysis.playerId.trim() == pid) return analysis;
    }
    return null;
  }

  Future<String?> getDocIdByEventAndPlayerId({
    required String eventId,
    required String playerId,
  }) async {
    final analysis = await getForEventPlayer(
      eventId: eventId,
      playerId: playerId,
    );
    if (analysis == null) return null;
    return analysis.docId;
  }

  Future<List<PolarSessionAnalysis>> listByEventId(String eventId) async {
    final snap = await _collection
        .where('eventId', isEqualTo: eventId.trim())
        .get();
    return snap.docs.map(PolarSessionAnalysis.fromDoc).toList(growable: false);
  }

  Stream<List<PolarSessionAnalysis>> watchByEventId(String eventId) {
    return _collection
        .where('eventId', isEqualTo: eventId.trim())
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(PolarSessionAnalysis.fromDoc)
              .toList(growable: false),
        );
  }

  Future<void> deleteByDocId(String docId) async {
    await _collection.doc(docId).delete();
  }

  /// Analyses for [playerId], newest first, optionally limited to [start]–[end]
  /// (inclusive calendar bounds on `createdAt`).
  Future<List<PolarSessionAnalysis>> listByPlayerId(
    String playerId, {
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    final pid = playerId.trim();
    if (pid.isEmpty) return const <PolarSessionAnalysis>[];

    Query<Map<String, dynamic>> query = _collection
        .where('playerId', isEqualTo: pid)
        .orderBy('createdAt', descending: true);

    if (start != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime(start.year, start.month, start.day),
        ),
      );
    }
    if (end != null) {
      final endExclusive = DateTime(end.year, end.month, end.day)
          .add(const Duration(days: 1));
      query = query.where(
        'createdAt',
        isLessThan: Timestamp.fromDate(endExclusive),
      );
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snap = await query.get();
    return snap.docs
        .map(PolarSessionAnalysis.fromDoc)
        .toList(growable: false);
  }
}
