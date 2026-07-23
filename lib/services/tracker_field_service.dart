import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/fieldGpsCorners.dart';
import '../model/tracker_field.dart';

class TrackerFieldService {
  final FirebaseFirestore _firestore;

  TrackerFieldService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'TRACKER_Fields';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<void> saveOrUpdate(TrackerField field) async {
    if (field.id.isEmpty) {
      throw ArgumentError('TrackerField id must not be empty.');
    }

    await _collection.doc(field.id).set(field.toMap(), SetOptions(merge: true));
  }

  Future<void> saveFromMatchLocalization({
    required String terrainNom,
    required String terrainAdresse1,
    required FieldGpsCorners fieldGpsCorners,
    required String uid,
  }) async {
    final field = TrackerField.fromMatchLocalization(
      terrainNom: terrainNom,
      terrainAdresse1: terrainAdresse1,
      fieldGpsCorners: fieldGpsCorners,
      uid: uid,
    );

    if (field.id.isEmpty) {
      debugPrint(
        'TrackerFieldService: skipped save — empty id '
        '(terrainNom="$terrainNom", adresse="$terrainAdresse1").',
      );
      return;
    }

    await saveOrUpdate(field);
  }

  Future<TrackerField?> getById(String id) async {
    if (id.isEmpty) return null;

    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;

    return TrackerField.fromDocument(doc);
  }

  /// Lists tracker fields (admin tooling). Newest docs first when possible.
  Future<List<TrackerField>> listAll({int limit = 200}) async {
    final snapshot = await _collection.limit(limit).get();
    final fields = <TrackerField>[];
    for (final doc in snapshot.docs) {
      try {
        fields.add(TrackerField.fromDocument(doc));
      } catch (_) {}
    }
    fields.sort(
      (a, b) => a.terrainNom.toLowerCase().compareTo(b.terrainNom.toLowerCase()),
    );
    return fields;
  }
}
