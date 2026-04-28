import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/tracker/team_workload_summary.dart';
import '../model/tracker/trackerData.dart';

class TeamWorkloadSummaryService {
  static const String collectionName = 'TRACKER_TeamAnalysis';

  final FirebaseFirestore _firestore;

  TeamWorkloadSummaryService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(collectionName);
  }

  Future<TeamWorkloadSummary> computeAndSave({
    required String eventId,
    required List<TrackerAnalysisResult> playerResults,
    Duration? sessionDuration,
  }) async {
    final summary = TeamWorkloadSummary.fromPlayerResults(
      eventId: eventId,
      playerResults: playerResults,
      sessionDuration: sessionDuration,
    );

    await save(summary);

    return summary;
  }

  Future<void> save(TeamWorkloadSummary summary) async {
    final ref = _collection.doc(summary.eventId);
    final snapshot = await ref.get();

    final data = summary.toMap();

    data['updatedAt'] = FieldValue.serverTimestamp();

    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(data, SetOptions(merge: true));
  }

  Future<TeamWorkloadSummary?> getByEventId(String eventId) async {
    final snapshot = await _collection.doc(eventId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return TeamWorkloadSummary.fromMap(snapshot.data()!);
  }

  Stream<TeamWorkloadSummary?> watchByEventId(String eventId) {
    return _collection.doc(eventId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return TeamWorkloadSummary.fromMap(snapshot.data()!);
    });
  }

  Stream<List<TeamWorkloadSummary>> watchLatest({
    int limit = 50,
  }) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamWorkloadSummary.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> deleteByEventId(String eventId) async {
    await _collection.doc(eventId).delete();
  }
}