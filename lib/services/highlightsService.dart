import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/highlights.dart';

class HighlightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'highLights';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<DocumentReference<Map<String, dynamic>>> addHighlight(
      Highlights highlight,
      ) async {
    return await _collection.add(highlight.toMap());
  }

  /// CREATE with custom id
  Future<void> setHighlight({
    required String id,
    required Highlights highlight,
    bool merge = true,
  }) async {
    await _collection.doc(id).set(highlight.toMap(), SetOptions(merge: merge));
  }

  /// READ ONE
  Future<Highlights?> getHighlightById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Highlights.fromSnapshot(doc);
  }

  /// READ ALL
  Future<List<Highlights>> getAllHighlights() async {
    final snapshot = await _collection
        .orderBy(keyHlDateTime, descending: false)
        .get();

    return snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList();
  }

  /// READ ALL as stream
  Stream<List<Highlights>> streamAllHighlights() {
    return _collection
        .orderBy(keyHlDateTime, descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList());
  }

  /// READ by matchCalendarId
  Future<List<Highlights>> getHighlightsByMatchCalendarId(
      String matchCalendarId,
      ) async {
    final snapshot = await _collection
        .where(keyHlMatchCalendarId, isEqualTo: matchCalendarId)
        .get();
    return snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList();
  }

  /// STREAM by matchCalendarId
  Stream<List<Highlights>> streamHighlightsByMatchCalendarId(
      String matchCalendarId,
      ) {
    return _collection
        .where(keyHlMatchCalendarId, isEqualTo: matchCalendarId)
        .orderBy(keyHlMinute, descending: false)
        .orderBy(keyHlExtraTime, descending: false)
        .orderBy(keyHlDateTime, descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList());
  }

  /// READ by actionType
  Future<List<Highlights>> getHighlightsByActionType(
      ActionType actionType,
      ) async {
    final snapshot = await _collection
        .where(keyHlAction, isEqualTo: actionType.toString())
        .orderBy(keyHlDateTime, descending: false)
        .get();

    return snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList();
  }

  /// STREAM by actionType
  Stream<List<Highlights>> streamHighlightsByActionType(
      ActionType actionType,
      ) {
    return _collection
        .where(keyHlAction, isEqualTo: actionType.toString())
        .orderBy(keyHlDateTime, descending: false)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Highlights.fromSnapshot(doc)).toList());
  }

  /// UPDATE from document id
  Future<void> updateHighlight({
    required String id,
    required Highlights highlight,
  }) async {
    await _collection.doc(id).update(highlight.toMap());
  }

  /// UPDATE from object.ref
  Future<void> updateHighlightFromRef(Highlights highlight) async {
    if (highlight.ref == null) {
      throw Exception('Impossible de mettre à jour : ref null');
    }
    await highlight.ref!.update(highlight.toMap());
  }

  /// DELETE by id
  Future<void> deleteHighlightById(String id) async {
    await _collection.doc(id).delete();
  }

  /// DELETE from object.ref
  Future<void> deleteHighlight(Highlights highlight) async {
    if (highlight.ref == null) {
      throw Exception('Impossible de supprimer : ref null');
    }
    await highlight.ref!.delete();
  }

  /// DELETE all highlights of a match
  Future<void> deleteHighlightsByMatchCalendarId(String matchCalendarId) async {
    final snapshot = await _collection
        .where(keyHlMatchCalendarId, isEqualTo: matchCalendarId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Count highlights for a match
  Future<int> countHighlightsByMatchCalendarId(String matchCalendarId) async {
    final snapshot = await _collection
        .where(keyHlMatchCalendarId, isEqualTo: matchCalendarId)
        .get();

    return snapshot.docs.length;
  }
}