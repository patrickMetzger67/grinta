import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tracker/trackerData.dart';

class TrackerAnalysisService {
  TrackerAnalysisService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'TRACKER_Analysis';

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Sauvegarde une analyse.
  ///
  /// [docId] facultatif :
  /// - si fourni -> set avec cet id
  /// - sinon -> id auto
  static Future<String> saveAnalysis(
      TrackerAnalysisResult analysis, {
        String? docId,
        String? eventId,
        bool? isMatch,
      }) async {
    final data = analysis.toMap(
      eventId: eventId,
      createdAt: DateTime.now(),
    );

    if (docId != null && docId.trim().isNotEmpty) {
      await _collection.doc(docId).set(data, SetOptions(merge: true));
      return docId;
    }

    final doc = await _collection.add(data);
    return doc.id;
  }

  /// Sauvegarde plusieurs analyses en batch.
  static Future<void> saveManyAnalyses(
      List<TrackerAnalysisResult> analyses, {
        String? matchId,
        String? eventId,
      }) async {
    if (analyses.isEmpty) return;

    final batch = _firestore.batch();

    for (final analysis in analyses) {
      final docRef = _collection.doc();
      final data = analysis.toMap(
        eventId: eventId,
        createdAt: DateTime.now(),
      );
      batch.set(docRef, data);
    }

    await batch.commit();
  }

  /// Lecture par id document Firestore.
  static Future<TrackerAnalysisResult?> getAnalysisById(String docId) async {
    final doc = await _collection.doc(docId).get();

    if (!doc.exists || doc.data() == null) return null;

    return TrackerAnalysisResult.fromMap(doc.data()!);
  }

  /// Analyses d’un joueur.
  static Stream<List<TrackerAnalysisResult>> getAnalysesByPlayer(
      String playerId, {
        int? limit,
      }) {
    Query<Map<String, dynamic>> query = _collection
        .where('playerId', isEqualTo: playerId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => TrackerAnalysisResult.fromMap(doc.data()))
          .toList(),
    );
  }

  /// Analyses d’un tracker.
  static Stream<List<TrackerAnalysisResult>> getAnalysesByTracker(
      String trackerId, {
        int? limit,
      }) {
    Query<Map<String, dynamic>> query = _collection
        .where('trackerId', isEqualTo: trackerId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => TrackerAnalysisResult.fromMap(doc.data()))
          .toList(),
    );
  }

  /// Optionnel : filtre par match sans Stream
  static Future<List<TrackerAnalysisResult>> getAnalysesByEvent(
      String eventId, {
        int? limit,
      }) async {
    Query<Map<String, dynamic>> query = _collection
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => TrackerAnalysisResult.fromMap(doc.data()))
        .toList();
  }

  static Future<void> deleteAnalysis(String docId) async {
    await _collection.doc(docId).delete();
  }
}