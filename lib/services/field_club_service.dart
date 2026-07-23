import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/fieldGpsCorners.dart';
import 'package:grinta/model/field_club.dart';

/// CRUD / queries for [kFieldClubCollection].
class FieldClubService {
  FieldClubService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(kFieldClubCollection);

  Future<FieldClub?> getById(String id) async {
    final docId = id.trim();
    if (docId.isEmpty) return null;
    final doc = await _col.doc(docId).get();
    if (!doc.exists) return null;
    try {
      return FieldClub.fromDoc(doc);
    } catch (e, st) {
      debugPrint('FieldClubService.getById parse failed: $e\n$st');
      return null;
    }
  }

  /// Fields belonging to [clubId], sorted by name.
  Future<List<FieldClub>> listByClubId(String clubId) async {
    final normalized = clubId.trim();
    if (normalized.isEmpty) return const [];

    final snapshot = await _col
        .where(FieldClubDocumentFields.clubId, isEqualTo: normalized)
        .get();

    return _parseDocs(snapshot.docs);
  }

  Stream<List<FieldClub>> watchByClubId(String clubId) {
    final normalized = clubId.trim();
    if (normalized.isEmpty) {
      return Stream.value(const <FieldClub>[]);
    }

    return _col
        .where(FieldClubDocumentFields.clubId, isEqualTo: normalized)
        .snapshots()
        .map((snap) => _parseDocs(snap.docs));
  }

  Future<List<FieldClub>> listAll({int limit = 500}) async {
    final snapshot = await _col.limit(limit).get();
    return _parseDocs(snapshot.docs);
  }

  /// Creates or merges [field] at [field.id] (or auto-id when empty).
  Future<FieldClub> upsert(FieldClub field) async {
    final ref = field.id.trim().isEmpty ? _col.doc() : _col.doc(field.id.trim());
    final toSave = field.id.trim().isEmpty
        ? field.copyWith(id: ref.id)
        : field;
    final data = toSave.toMap()
      ..[FieldClubDocumentFields.updateDate] = FieldValue.serverTimestamp();

    await ref.set(data, SetOptions(merge: true));
    return toSave.copyWith(updateDate: Timestamp.now());
  }

  /// Persists pitch GPS corners on an existing fieldClub document.
  Future<FieldClub?> updateFieldGpsCorners({
    required String fieldClubId,
    required FieldGpsCorners fieldGpsCorners,
  }) async {
    final id = fieldClubId.trim();
    if (id.isEmpty) return null;

    await _col.doc(id).set(
      <String, dynamic>{
        FieldClubDocumentFields.fieldGpsCorners: fieldGpsCorners.toMap(),
        FieldClubDocumentFields.updateDate: FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return getById(id);
  }

  Future<void> delete(String id) async {
    final docId = id.trim();
    if (docId.isEmpty) return;
    await _col.doc(docId).delete();
  }

  List<FieldClub> _parseDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final fields = <FieldClub>[];
    for (final doc in docs) {
      try {
        fields.add(FieldClub.fromDoc(doc));
      } catch (e, st) {
        debugPrint('FieldClubService parse ${doc.id} failed: $e\n$st');
      }
    }
    fields.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return fields;
  }
}
