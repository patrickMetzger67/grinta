import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/compoType.dart';

class CompoTypeService {
  static const String collectionName = 'compoType';

  final CollectionReference _collection =
  FirebaseFirestore.instance.collection(collectionName);

  /// Charge tous les types puis filtre par [preferredSoccerType] en mémoire.
  /// Si aucun ne correspond (ex. match mal typé), renvoie toute la liste.
  Stream<List<CompoType>> streamCompoTypesResolved({
    int? preferredSoccerType,
    bool orderByName = true,
  }) {
    return streamCompoTypes(soccerType: null, orderByName: orderByName).map(
      (allTypes) => _filterCompoTypes(allTypes, preferredSoccerType),
    );
  }

  /// Même logique que [streamCompoTypesResolved], en une requête.
  Future<List<CompoType>> getCompoTypesResolved({
    int? preferredSoccerType,
    bool orderByName = true,
  }) async {
    final allTypes = await getCompoTypes(soccerType: null, orderByName: orderByName);
    return _filterCompoTypes(allTypes, preferredSoccerType);
  }

  List<CompoType> _filterCompoTypes(
    List<CompoType> allTypes,
    int? preferredSoccerType,
  ) {
    if (preferredSoccerType == null || allTypes.isEmpty) {
      return allTypes;
    }

    final filtered = allTypes
        .where((t) => t.soccerType == preferredSoccerType)
        .toList();

    return filtered.isNotEmpty ? filtered : allTypes;
  }

  Stream<List<CompoType>> streamCompoTypes({
    int? soccerType,
    bool orderByName = true,
  }) {
    Query query = _collection;

    if (soccerType != null) {
      query = query.where(keyCompoTypeSoccerType, isEqualTo: soccerType);
    }

    if (orderByName) {
      query = query.orderBy(keyCompoTypeName);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CompoType.fromDocumentSnapshot(doc);
      }).toList();
    });
  }

  Future<List<CompoType>> getCompoTypes({
    int? soccerType,
    bool orderByName = true,
  }) async {
    Query query = _collection;

    if (soccerType != null) {
      query = query.where(keyCompoTypeSoccerType, isEqualTo: soccerType);
    }

    if (orderByName) {
      query = query.orderBy(keyCompoTypeName);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return CompoType.fromDocumentSnapshot(doc);
    }).toList();
  }

  Future<CompoType?> getCompoTypeById(String id) async {
    if (id.trim().isEmpty) return null;

    final snapshot = await _collection.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return CompoType.fromDocumentSnapshot(snapshot);
  }

  Future<DocumentReference> addCompoType(CompoType compoType) async {
    return _collection.add(_toMap(compoType));
  }

  Future<void> updateCompoType(CompoType compoType) async {
    final ref = compoType.ref;

    if (ref == null) {
      throw Exception('Impossible de modifier le type de composition : référence Firestore absente.');
    }

    await ref.update(_toMap(compoType));
  }

  Future<void> deleteCompoType(CompoType compoType) async {
    final ref = compoType.ref;

    if (ref == null) {
      throw Exception('Impossible de supprimer le type de composition : référence Firestore absente.');
    }

    await ref.delete();
  }

  Future<void> deleteCompoTypeById(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('Impossible de supprimer le type de composition : id vide.');
    }

    await _collection.doc(id).delete();
  }

  Future<bool> existsByName({
    required String name,
    int? soccerType,
    DocumentReference? excludedRef,
  }) async {
    final safeName = name.trim();

    if (safeName.isEmpty) {
      return false;
    }

    Query query = _collection.where(
      keyCompoTypeName,
      isEqualTo: safeName,
    );

    if (soccerType != null) {
      query = query.where(
        keyCompoTypeSoccerType,
        isEqualTo: soccerType,
      );
    }

    final snapshot = await query.limit(10).get();

    for (final doc in snapshot.docs) {
      if (excludedRef != null && doc.reference.path == excludedRef.path) {
        continue;
      }

      return true;
    }

    return false;
  }

  Map<String, dynamic> _toMap(CompoType compoType) {
    return {
      keyCompoTypeName: compoType.name?.trim() ?? '',
      keyCompoTypeDefender: compoType.defender ?? 0,
      keyCompoTypeMidfielder: compoType.midfielder ?? 0,
      keyCompoTypeMidfielderDefensive: compoType.midfielderDefensive ?? 0,
      keyCompoTypeMidfielderAttacking: compoType.midfielderAttacking ?? 0,
      keyCompoTypeStricker: compoType.stricker ?? 0,
      keyCompoTypeIsDiamond: compoType.isDiamond ?? false,
      keyCompoTypeSoccerType: compoType.soccerType ?? 11,
    };
  }
}