import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/last_results.dart';

/// Firestore `lastResults` — one doc per club + competition.
///
/// Document id: `{clubId}_{competitionId}`.
/// Written by the data-update script after match retrieval; the app only reads.
class LastResultsService {
  LastResultsService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'lastResults';

  static final LastResultsService instance = LastResultsService();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  DocumentReference<Map<String, dynamic>> docRef({
    required String clubId,
    required String competitionId,
  }) {
    return _collection.doc(lastResultsDocumentId(clubId, competitionId));
  }

  DocumentReference<Map<String, dynamic>> docRefForId(String documentId) {
    return _collection.doc(documentId.trim());
  }

  static LastResults fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return LastResults.fromDocumentSnapshot(snapshot);
  }

  static Map<String, dynamic> toFirestore(
    LastResults lastResults, {
    Timestamp? updatedAt,
  }) {
    return lastResults.toMap(
      updatedAtOverride: updatedAt ?? lastResults.updatedAt,
    );
  }

  /// CREATE / UPSERT — id = `{clubId}_{competitionId}`.
  ///
  /// Sets [keyLastResultsUpdatedAt] to [updatedAt] or `serverTimestamp()`.
  Future<void> setLastResults(
    LastResults lastResults, {
    Timestamp? updatedAt,
    bool merge = false,
  }) async {
    final clubId = lastResults.clubId.trim();
    final competitionId = lastResults.competitionId.trim();
    if (clubId.isEmpty || competitionId.isEmpty) {
      throw ArgumentError(
        'LastResults.clubId and competitionId must not be empty.',
      );
    }

    try {
      await docRef(clubId: clubId, competitionId: competitionId).set(
        toFirestore(
          lastResults,
          updatedAt: updatedAt ?? lastResults.updatedAt,
        )..[keyLastResultsUpdatedAt] =
            updatedAt ?? lastResults.updatedAt ?? FieldValue.serverTimestamp(),
        SetOptions(merge: merge),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Same as [setLastResults] for several clubs after a scrape.
  Future<void> setLastResultsList(
    Iterable<LastResults> documents, {
    Timestamp? updatedAt,
    bool merge = false,
  }) async {
    final items = documents.toList(growable: false);
    const chunkSize = 400;
    for (var offset = 0; offset < items.length; offset += chunkSize) {
      final end =
          offset + chunkSize > items.length ? items.length : offset + chunkSize;
      final batch = _firestore.batch();
      for (final lastResults in items.sublist(offset, end)) {
        final clubId = lastResults.clubId.trim();
        final competitionId = lastResults.competitionId.trim();
        if (clubId.isEmpty || competitionId.isEmpty) {
          continue;
        }
        batch.set(
          docRef(clubId: clubId, competitionId: competitionId),
          toFirestore(
            lastResults,
            updatedAt: updatedAt ?? lastResults.updatedAt,
          )..[keyLastResultsUpdatedAt] = updatedAt ??
              lastResults.updatedAt ??
              FieldValue.serverTimestamp(),
          SetOptions(merge: merge),
        );
      }
      await batch.commit();
    }
  }

  /// READ ONE by club + competition.
  Future<LastResults?> getLastResults({
    required String clubId,
    required String competitionId,
  }) async {
    final key = lastResultsKeyFromIds(
      clubId: clubId,
      competitionId: competitionId,
    );
    if (key == null) {
      return null;
    }
    return getById(key.documentId);
  }

  /// READ ONE by document id (`{clubId}_{competitionId}`).
  Future<LastResults?> getById(String documentId) async {
    try {
      final snapshot = await docRefForId(documentId).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return fromFirestore(snapshot);
    } catch (e) {
      rethrow;
    }
  }

  /// STREAM ONE by club + competition.
  Stream<LastResults?> streamLastResults({
    required String clubId,
    required String competitionId,
  }) {
    final key = lastResultsKeyFromIds(
      clubId: clubId,
      competitionId: competitionId,
    );
    if (key == null) {
      return Stream<LastResults?>.value(null);
    }
    return streamById(key.documentId);
  }

  /// One broadcast stream per document so rebuilds do not resubscribe
  /// (a new `snapshots()` each build keeps StreamBuilder in `waiting`).
  final Map<String, Stream<LastResults?>> _docStreams = {};

  Stream<LastResults?> streamById(String documentId) {
    final id = documentId.trim();
    return _docStreams.putIfAbsent(id, () {
      return docRefForId(id).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return null;
        }
        return fromFirestore(snapshot);
      }).asBroadcastStream();
    });
  }

  /// READ ALL for a club (every competition).
  Future<List<LastResults>> getByClubId(String clubId) async {
    final trimmed = clubId.trim();
    if (trimmed.isEmpty) {
      return const <LastResults>[];
    }
    try {
      final snapshot = await _collection
          .where(keyLastResultsClubId, isEqualTo: trimmed)
          .get();
      return snapshot.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// READ ALL for a competition (every club).
  Future<List<LastResults>> getByCompetitionId(String competitionId) async {
    final trimmed = competitionId.trim();
    if (trimmed.isEmpty) {
      return const <LastResults>[];
    }
    try {
      final snapshot = await _collection
          .where(keyLastResultsCompetitionId, isEqualTo: trimmed)
          .get();
      return snapshot.docs.map(fromFirestore).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE one club + competition document.
  Future<void> deleteLastResults({
    required String clubId,
    required String competitionId,
  }) async {
    final key = lastResultsKeyFromIds(
      clubId: clubId,
      competitionId: competitionId,
    );
    if (key == null) {
      return;
    }
    try {
      await docRefForId(key.documentId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
