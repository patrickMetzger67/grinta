import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/teamParam.dart';



class TeamParamService {
  TeamParamService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'TRACKER_TeamParam';

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// Crée le document par défaut teamId = "0" s'il n'existe pas.
  static Future<void> ensureDefaultParams() async {
    final doc = await _collection.doc(TeamParam.defaultTeamId).get();

    if (!doc.exists) {
      final defaults = TeamParam.defaultConfig(
        teamId: TeamParam.defaultTeamId,
      ).copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _collection.doc(TeamParam.defaultTeamId).set(defaults.toMap());
    }
  }

  /// Sauvegarde / met à jour les paramètres d'une équipe.
  /// docId = teamId
  static Future<String> saveTeamParam(
      TeamParam teamParam, {
        String? docId,
      }) async {
    final effectiveDocId = (docId ?? teamParam.teamId).trim();
    final now = DateTime.now();

    final existing = await _collection.doc(effectiveDocId).get();

    final data = teamParam
        .copyWith(
      teamId: effectiveDocId,
      createdAt: existing.exists
          ? TeamParam.fromMap(existing.data()!).createdAt ?? now
          : now,
      updatedAt: now,
    )
        .toMap();

    await _collection.doc(effectiveDocId).set(data, SetOptions(merge: true));
    return effectiveDocId;
  }

  static Future<TeamParam?> getTeamParamByTeamId(String teamId) async {
    final doc = await _collection.doc(teamId.trim()).get();

    if (!doc.exists || doc.data() == null) return null;

    return TeamParam.fromMap(doc.data()!);
  }

  /// Retourne les paramètres de l'équipe.
  /// Si absents, fallback sur teamId = "0".
  static Future<TeamParam> getEffectiveTeamParam(String teamId) async {
    await ensureDefaultParams();

    final teamParam = await getTeamParamByTeamId(teamId);
    if (teamParam != null) return teamParam;

    final defaultParam =
    await getTeamParamByTeamId(TeamParam.defaultTeamId);

    return defaultParam ?? TeamParam.defaultConfig();
  }

  static Stream<TeamParam?> watchTeamParamByTeamId(String teamId) {
    return _collection.doc(teamId.trim()).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return TeamParam.fromMap(doc.data()!);
    });
  }

  static Future<void> upsertDefaultParams({
    TeamParam? customDefaults,
  }) async {
    final defaults = (customDefaults ?? TeamParam.defaultConfig()).copyWith(
      teamId: TeamParam.defaultTeamId,
      updatedAt: DateTime.now(),
      createdAt: customDefaults?.createdAt ?? DateTime.now(),
    );

    await _collection
        .doc(TeamParam.defaultTeamId)
        .set(defaults.toMap(), SetOptions(merge: true));
  }

  static Future<void> deleteTeamParam(String teamId) async {
    final cleanTeamId = teamId.trim();

    if (cleanTeamId == TeamParam.defaultTeamId) {
      throw Exception(
        'Le document de paramètres par défaut (teamId = 0) ne peut pas être supprimé.',
      );
    }

    await _collection.doc(cleanTeamId).delete();
  }
}