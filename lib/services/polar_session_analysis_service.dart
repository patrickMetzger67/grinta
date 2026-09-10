import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    final snap =
        await _collection.where('eventId', isEqualTo: eventId.trim()).get();
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
  /// (inclusive calendar bounds on `startedAt` / `createdAt`).
  ///
  /// Queries `playerId ==` only (automatic single-field index). Date bounds are
  /// applied in memory so production does not need a composite index.
  Future<List<PolarSessionAnalysis>> listByPlayerId(
    String playerId, {
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    final pid = playerId.trim();
    if (pid.isEmpty) return const <PolarSessionAnalysis>[];

    final snap = await _collection.where('playerId', isEqualTo: pid).get();
    final items = <PolarSessionAnalysis>[];
    for (final doc in snap.docs) {
      try {
        final analysis = PolarSessionAnalysis.fromDoc(doc);
        final date = analysis.startedAt ?? analysis.createdAt;
        if (!_sessionDateInRange(date, start: start, end: end)) continue;
        items.add(analysis);
      } catch (e, st) {
        debugPrint(
          'TRACKER_PolarAnalysis skip doc=${doc.id} playerId=$pid: $e\n$st',
        );
      }
    }

    items.sort((a, b) {
      final aDate =
          a.startedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          b.startedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    if (limit != null && items.length > limit) {
      return items.sublist(0, limit);
    }
    return items;
  }

  static bool _sessionDateInRange(
    DateTime? date, {
    DateTime? start,
    DateTime? end,
  }) {
    if (date == null) return true;
    final day = DateTime(date.year, date.month, date.day);
    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);
      if (day.isBefore(startDay)) return false;
    }
    if (end != null) {
      final endDay = DateTime(end.year, end.month, end.day);
      if (day.isAfter(endDay)) return false;
    }
    return true;
  }
}
