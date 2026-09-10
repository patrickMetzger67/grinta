import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player_task_type.dart';

class PlayerTaskTypeService {
  static const String collectionName = 'playerTaskTypes';

  final FirebaseFirestore _firestore;

  PlayerTaskTypeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Stream<List<PlayerTaskType>> watchTypesForOwner(String ownerUserId) {
    final String trimmed = ownerUserId.trim();
    if (trimmed.isEmpty) {
      return Stream<List<PlayerTaskType>>.value(const <PlayerTaskType>[]);
    }

    return _collection
        .where(keyPlayerTaskTypeOwnerUserId, isEqualTo: trimmed)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<PlayerTaskType> types = snapshot.docs
          .map(PlayerTaskType.fromSnapshot)
          .where((PlayerTaskType type) => type.name.isNotEmpty)
          .toList()
        ..sort(
          (PlayerTaskType a, PlayerTaskType b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      return types;
    });
  }

  Future<List<PlayerTaskType>> loadTypesForOwner(String ownerUserId) async {
    final String trimmed = ownerUserId.trim();
    if (trimmed.isEmpty) {
      return const <PlayerTaskType>[];
    }
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .where(keyPlayerTaskTypeOwnerUserId, isEqualTo: trimmed)
        .get();
    final List<PlayerTaskType> types = snapshot.docs
        .map(PlayerTaskType.fromSnapshot)
        .where((PlayerTaskType type) => type.name.isNotEmpty)
        .toList()
      ..sort(
        (PlayerTaskType a, PlayerTaskType b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    return types;
  }

  /// Seeds "Matériel" / "Maillots" the first time a manager opens the form.
  Future<List<PlayerTaskType>> ensureDefaultTypes({
    required String ownerUserId,
    required AppLocalizations l10n,
  }) async {
    final String trimmed = ownerUserId.trim();
    if (trimmed.isEmpty) {
      return const <PlayerTaskType>[];
    }

    final List<PlayerTaskType> existing = await loadTypesForOwner(trimmed);
    if (existing.isNotEmpty) {
      return existing;
    }

    final List<({String name, int color})> defaults = <({String name, int color})>[
      (name: l10n.playerTaskDefaultTypeEquipment, color: kPlayerTaskTypePalette[0]),
      (name: l10n.playerTaskDefaultTypeJerseys, color: kPlayerTaskTypePalette[1]),
    ];

    final List<PlayerTaskType> created = <PlayerTaskType>[];
    for (final ({String name, int color}) entry in defaults) {
      created.add(
        await createType(
          ownerUserId: trimmed,
          name: entry.name,
          color: entry.color,
        ),
      );
    }
    return created;
  }

  Future<PlayerTaskType> createType({
    required String ownerUserId,
    required String name,
    required int color,
  }) async {
    final String trimmedOwner = ownerUserId.trim();
    final String trimmedName = name.trim();
    if (trimmedOwner.isEmpty) {
      throw StateError('missingAuth');
    }
    if (trimmedName.isEmpty) {
      throw StateError('missingName');
    }

    final PlayerTaskType type = PlayerTaskType(
      ownerUserId: trimmedOwner,
      name: trimmedName,
      color: playerTaskColorFrom(color),
    );
    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(type.toMap());
    return type.copyWith(id: ref.id, ref: ref);
  }

  Future<void> deleteType(PlayerTaskType type) async {
    final DocumentReference? ref = type.ref;
    if (ref != null) {
      await ref.delete();
      return;
    }
    final String? id = type.id?.trim();
    if (id == null || id.isEmpty) {
      throw StateError('missingId');
    }
    await _collection.doc(id).delete();
  }
}
