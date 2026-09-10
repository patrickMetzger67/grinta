import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/team_fine_type.dart';

class TeamFineTypeService {
  static const String collectionName = 'teamFineTypes';

  final FirebaseFirestore _firestore;

  TeamFineTypeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Stream<List<TeamFineType>> watchTypesForTeam(String teamId) {
    final String trimmed = teamId.trim();
    if (trimmed.isEmpty) {
      return Stream<List<TeamFineType>>.value(const <TeamFineType>[]);
    }

    return _collection
        .where(keyTeamFineTypeTeamId, isEqualTo: trimmed)
        .snapshots()
        .map(_typesFromSnapshot);
  }

  Future<List<TeamFineType>> loadTypesForTeam(String teamId) async {
    final String trimmed = teamId.trim();
    if (trimmed.isEmpty) {
      return const <TeamFineType>[];
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where(keyTeamFineTypeTeamId, isEqualTo: trimmed)
        .get();
    return _typesFromSnapshot(snapshot);
  }

  /// Seeds "Retard" / "Absence non justifiée" when missing for [teamId].
  Future<List<TeamFineType>> ensureDefaultTypes({
    required String teamId,
    required AppLocalizations l10n,
  }) async {
    final String trimmed = teamId.trim();
    if (trimmed.isEmpty) {
      return const <TeamFineType>[];
    }

    final List<TeamFineType> existing = await loadTypesForTeam(trimmed);
    final Set<String> names = <String>{
      for (final TeamFineType type in existing) type.name.toLowerCase(),
    };

    final List<String> defaults = <String>[
      l10n.teamFineDefaultTypeLate,
      l10n.teamFineDefaultTypeUnjustifiedAbsence,
    ];

    final List<TeamFineType> created = List<TeamFineType>.from(existing);
    for (final String name in defaults) {
      if (names.contains(name.toLowerCase())) {
        continue;
      }
      created.add(await createType(teamId: trimmed, name: name));
      names.add(name.toLowerCase());
    }

    created.sort(
      (TeamFineType a, TeamFineType b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return created;
  }

  Future<TeamFineType> createType({
    required String teamId,
    required String name,
  }) async {
    final String trimmedTeam = teamId.trim();
    final String trimmedName = name.trim();
    if (trimmedTeam.isEmpty) {
      throw StateError('missingTeam');
    }
    if (trimmedName.isEmpty) {
      throw StateError('missingName');
    }

    final TeamFineType type = TeamFineType(
      teamId: trimmedTeam,
      name: trimmedName,
    );
    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(type.toMap());
    return type.copyWith(id: ref.id, ref: ref);
  }

  List<TeamFineType> _typesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(TeamFineType.fromSnapshot)
        .where((TeamFineType type) => type.name.isNotEmpty)
        .toList()
      ..sort(
        (TeamFineType a, TeamFineType b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
  }
}
