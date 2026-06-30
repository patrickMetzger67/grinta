import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/comptetion_group.dart';

class ComptetionGroupService {
  static final CollectionReference<Map<String, dynamic>> _ref =
  FirebaseFirestore.instance.collection('competitionGroup');

  /// Création ou remplacement complet du groupe
  static Future<void> createOrUpdate(ComptetionGroup group) async {
    await _ref.doc(group.id).set(
      group.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Création depuis les champs principaux
  static Future<ComptetionGroup> create({
    required String seasonId,
    required String comptetitonId,
    required String phase,
    required String groupe,
    List<String> clubIds = const [],
  }) async {
    final group = ComptetionGroup.create(
      seasonId: seasonId,
      comptetitonId: comptetitonId,
      phase: phase,
      groupe: groupe,
      clubIds: clubIds,
    );

    await _ref.doc(group.id).set(group.toMap());

    return group;
  }

  /// Mise à jour partielle
  static Future<void> update(
      String id,
      Map<String, dynamic> data,
      ) async {
    await _ref.doc(id).update(data);
  }

  /// Suppression
  static Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }

  /// Lecture par ID
  static Future<ComptetionGroup?> getById(String id) async {
    final doc = await _ref.doc(id).get();

    if (!doc.exists) return null;

    return ComptetionGroup.fromDoc(doc);
  }

  /// Lecture par composition de l'ID
  static Future<ComptetionGroup?> getByParams({
    required String seasonId,
    required String comptetitonId,
    required String phase,
    required String groupe,
  }) async {
    final id = ComptetionGroup.buildId(
      seasonId: seasonId,
      comptetitonId: comptetitonId,
      phase: phase,
      groupe: groupe,
    );

    return getById(id);
  }

  /// Stream de tous les groupes
  static Stream<List<ComptetionGroup>> streamAll() {
    return _ref
        .orderBy('seasonId')
        .orderBy('comptetitonId')
        .orderBy('phase')
        .orderBy('groupe')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ComptetionGroup.fromDoc(doc))
          .toList(),
    );
  }

  /// Stream par saison
  static Stream<List<ComptetionGroup>> streamBySeason(String seasonId) {
    return _ref
        .where('seasonId', isEqualTo: seasonId)
        .orderBy('comptetitonId')
        .orderBy('phase')
        .orderBy('groupe')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ComptetionGroup.fromDoc(doc))
          .toList(),
    );
  }

  /// Stream par saison + compétition
  static Stream<List<ComptetionGroup>> streamByCompetition({
    required String seasonId,
    required String comptetitonId,
  }) {
    return _ref
        .where('seasonId', isEqualTo: seasonId)
        .where('comptetitonId', isEqualTo: comptetitonId)
        .orderBy('phase')
        .orderBy('groupe')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ComptetionGroup.fromDoc(doc))
          .toList(),
    );
  }

  /// Stream par saison + compétition + phase
  static Stream<List<ComptetionGroup>> streamByPhase({
    required String seasonId,
    required String comptetitonId,
    required String phase,
  }) {
    return _ref
        .where('seasonId', isEqualTo: seasonId)
        .where('comptetitonId', isEqualTo: comptetitonId)
        .where('phase', isEqualTo: phase)
        .orderBy('groupe')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => ComptetionGroup.fromDoc(doc))
          .toList(),
    );
  }

  /// Liste simple par saison + compétition
  static Future<List<ComptetionGroup>> getByCompetition({
    required String seasonId,
    required String comptetitonId,
  }) async {
    final snapshot = await _ref
        .where('seasonId', isEqualTo: seasonId)
        .where('comptetitonId', isEqualTo: comptetitonId)
        .orderBy('phase')
        .orderBy('groupe')
        .get();

    return snapshot.docs
        .map((doc) => ComptetionGroup.fromDoc(doc))
        .toList();
  }

  /// Ajoute un club au groupe
  static Future<void> addClub({
    required String groupId,
    required String clubId,
  }) async {
    await _ref.doc(groupId).update({
      'clubIds': FieldValue.arrayUnion([clubId]),
    });
  }

  /// Supprime un club du groupe
  static Future<void> removeClub({
    required String groupId,
    required String clubId,
  }) async {
    await _ref.doc(groupId).update({
      'clubIds': FieldValue.arrayRemove([clubId]),
    });
  }

  /// Remplace complètement la liste des clubs
  static Future<void> setClubs({
    required String groupId,
    required List<String> clubIds,
  }) async {
    await _ref.doc(groupId).update({
      'clubIds': clubIds,
    });
  }

  /// Ajoute plusieurs clubs
  static Future<void> addClubs({
    required String groupId,
    required List<String> clubIds,
  }) async {
    if (clubIds.isEmpty) return;

    await _ref.doc(groupId).update({
      'clubIds': FieldValue.arrayUnion(clubIds),
    });
  }

  /// Supprime plusieurs clubs
  static Future<void> removeClubs({
    required String groupId,
    required List<String> clubIds,
  }) async {
    if (clubIds.isEmpty) return;

    await _ref.doc(groupId).update({
      'clubIds': FieldValue.arrayRemove(clubIds),
    });
  }
}