import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/matchStats.dart';

class MatchStatsService {
  static const String collectionName = 'matchStats';

  final FirebaseFirestore _firestore;

  MatchStatsService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(collectionName);
  }

  DocumentReference<Map<String, dynamic>> _doc(String matchId) {
    return _collection.doc(matchId);
  }

  // ---------------------------------------------------------------------------
  // GET ONE
  // ---------------------------------------------------------------------------

  Future<MatchStats?> getMatchStatsByMatchId(String matchId) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      return null;
    }

    final docSnapshot = await _doc(safeMatchId).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      return MatchStats.fromMap(
        _withDocumentId(
          docSnapshot.data()!,
          docSnapshot.id,
        ),
      );
    }

    // Fallback si jamais ton document Firestore n'a pas matchId comme ID,
    // mais possède un champ "id".
    final querySnapshot = await _collection
        .where('id', isEqualTo: safeMatchId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final queryDoc = querySnapshot.docs.first;

    return MatchStats.fromMap(
      _withDocumentId(
        queryDoc.data(),
        queryDoc.id,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STREAM ONE
  // ---------------------------------------------------------------------------

  Stream<MatchStats?> streamMatchStatsByMatchId(String matchId) {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      return Stream.value(null);
    }

    return _doc(safeMatchId).snapshots().map((docSnapshot) {
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return null;
      }

      return MatchStats.fromMap(
        _withDocumentId(
          docSnapshot.data()!,
          docSnapshot.id,
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SAVE / UPDATE FULL OBJECT
  // ---------------------------------------------------------------------------

  Future<void> saveMatchStats(MatchStats matchStats) async {
    final safeMatchId = (matchStats.matchId ?? '').trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible de sauvegarder MatchStats : matchId vide.');
    }

    await _doc(safeMatchId).set(
      _matchStatsToMap(matchStats),
      SetOptions(merge: true),
    );
  }

  Future<void> createOrUpdateMatchStats({
    required String matchId,
    List<MatchStatHighLight> highlights = const [],
    List<MatchStatPlayer> titulars = const [],
    List<MatchStatPlayer> substitutes = const [],
  }) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible de sauvegarder MatchStats : matchId vide.');
    }

    final matchStats = MatchStats(
      matchId: safeMatchId,
      highlights: highlights,
      titulars: titulars,
      substitutes: substitutes,
    );

    await saveMatchStats(matchStats);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> deleteMatchStats(String matchId) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      return;
    }

    await _doc(safeMatchId).delete();
  }

  // ---------------------------------------------------------------------------
  // HIGHLIGHTS
  // ---------------------------------------------------------------------------

  Future<void> addHighlight({
    required String matchId,
    required MatchStatHighLight highlight,
  }) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible d’ajouter un temps fort : matchId vide.');
    }

    await _doc(safeMatchId).set(
      {
        'id': safeMatchId,
        'highLights': FieldValue.arrayUnion([
          _highlightToMap(highlight),
        ]),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateHighlights({
    required String matchId,
    required List<MatchStatHighLight> highlights,
  }) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible de modifier les temps forts : matchId vide.');
    }

    await _doc(safeMatchId).set(
      {
        'id': safeMatchId,
        'highLights': highlights.map(_highlightToMap).toList(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeHighlightAt({
    required String matchId,
    required int index,
  }) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible de supprimer le temps fort : matchId vide.');
    }

    final currentStats = await getMatchStatsByMatchId(safeMatchId);

    if (currentStats == null) {
      return;
    }

    final currentHighlights = List<MatchStatHighLight>.from(
      currentStats.highlights ?? [],
    );

    if (index < 0 || index >= currentHighlights.length) {
      return;
    }

    currentHighlights.removeAt(index);

    await updateHighlights(
      matchId: safeMatchId,
      highlights: currentHighlights,
    );
  }

  Future<void> clearHighlights(String matchId) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      return;
    }

    await _doc(safeMatchId).set(
      {
        'id': safeMatchId,
        'highLights': [],
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // PLAYERS / COMPOSITION
  // ---------------------------------------------------------------------------

  Future<void> updateComposition({
    required String matchId,
    required List<MatchStatPlayer> titulars,
    required List<MatchStatPlayer> substitutes,
  }) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      throw Exception('Impossible de modifier la composition : matchId vide.');
    }

    await _doc(safeMatchId).set(
      {
        'id': safeMatchId,
        'players': _playersToFirestoreStructure(
          titulars: titulars,
          substitutes: substitutes,
        ),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearComposition(String matchId) async {
    final safeMatchId = matchId.trim();

    if (safeMatchId.isEmpty) {
      return;
    }

    await _doc(safeMatchId).set(
      {
        'id': safeMatchId,
        'players': [],
      },
      SetOptions(merge: true),
    );
  }

  // ---------------------------------------------------------------------------
  // INTERNAL CONVERTERS
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _matchStatsToMap(MatchStats matchStats) {
    return {
      'id': matchStats.matchId ?? '',
      'highLights': (matchStats.highlights ?? [])
          .map(_highlightToMap)
          .toList(),
      'players': _playersToFirestoreStructure(
        titulars: matchStats.titulars ?? [],
        substitutes: matchStats.substitutes ?? [],
      ),
    };
  }

  Map<String, dynamic> _highlightToMap(MatchStatHighLight highlight) {
    return {
      'team': highlight.team ?? '',
      'player': highlight.player ?? '',
      'incomingPlayer': highlight.incomingPlayer ?? '',
      'time': highlight.time ?? 0,
      'type': highlight.type ?? '',
    };
  }

  Map<String, dynamic> _playerToMap(MatchStatPlayer player) {
    return {
      'name': player.player ?? '',
      'shirt': player.shirt ?? '',
    };
  }

  List<Map<String, dynamic>> _playersToFirestoreStructure({
    required List<MatchStatPlayer> titulars,
    required List<MatchStatPlayer> substitutes,
  }) {
    final teams = <String>{};

    for (final player in titulars) {
      final team = (player.team ?? '').trim();
      if (team.isNotEmpty) {
        teams.add(team);
      }
    }

    for (final player in substitutes) {
      final team = (player.team ?? '').trim();
      if (team.isNotEmpty) {
        teams.add(team);
      }
    }

    return teams.map((team) {
      final teamTitulars = titulars
          .where((player) => (player.team ?? '').trim() == team)
          .map(_playerToMap)
          .toList();

      final teamSubstitutes = substitutes
          .where((player) => (player.team ?? '').trim() == team)
          .map(_playerToMap)
          .toList();

      return {
        'team': team,
        'titulars': teamTitulars,
        'substitutes': teamSubstitutes,
      };
    }).toList();
  }

  Map<String, dynamic> _withDocumentId(
      Map<String, dynamic> data,
      String documentId,
      ) {
    final map = Map<String, dynamic>.from(data);

    if (map['id'] == null || map['id'].toString().trim().isEmpty) {
      map['id'] = documentId;
    }

    return map;
  }
}