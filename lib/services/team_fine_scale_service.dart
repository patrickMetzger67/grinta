import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/team_fine_scale.dart';
import 'package:grinta/model/team_fine_type.dart';

class TeamFineScaleService {
  static const String collectionName = 'teamFineScales';
  static const String duplicateTypeError = 'duplicateType';

  final FirebaseFirestore _firestore;

  TeamFineScaleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Stream<List<TeamFineScale>> watchScalesForTeam(String teamId) {
    final String trimmed = teamId.trim();
    if (trimmed.isEmpty) {
      return Stream<List<TeamFineScale>>.value(const <TeamFineScale>[]);
    }

    return _collection
        .where(keyTeamFineScaleTeamId, isEqualTo: trimmed)
        .snapshots()
        .map(_scalesFromSnapshot);
  }

  Future<TeamFineScale> createScale({
    required String teamId,
    required TeamFineType type,
    required double amount,
    required String createdByUserId,
    String? createdByMemberId,
  }) async {
    final String trimmedTeam = teamId.trim();
    final String trimmedUser = createdByUserId.trim();
    final String? typeId = type.id?.trim();
    if (trimmedTeam.isEmpty) {
      throw StateError('missingTeam');
    }
    if (trimmedUser.isEmpty) {
      throw StateError('missingAuth');
    }
    if (typeId == null || typeId.isEmpty) {
      throw StateError('missingType');
    }
    if (amount < 0) {
      throw StateError('invalidAmount');
    }

    final QuerySnapshot<Map<String, dynamic>> existing = await _collection
        .where(keyTeamFineScaleTeamId, isEqualTo: trimmedTeam)
        .get();
    final bool duplicateType = existing.docs.any((doc) {
      final Object? rawType = doc.data()[keyTeamFineScaleTypeId];
      return (rawType ?? '').toString().trim() == typeId;
    });
    if (duplicateType) {
      throw StateError(duplicateTypeError);
    }

    final String? memberId = createdByMemberId?.trim();
    final TeamFineScale scale = TeamFineScale(
      teamId: trimmedTeam,
      typeId: typeId,
      typeName: type.name.trim(),
      amount: amount,
      createdByUserId: trimmedUser,
      createdByMemberId: (memberId == null || memberId.isEmpty) ? null : memberId,
    );
    final DocumentReference<Map<String, dynamic>> ref =
        await _collection.add(scale.toMap());
    return scale.copyWith(id: ref.id, ref: ref);
  }

  Future<void> deleteScale(TeamFineScale scale) async {
    final DocumentReference? ref = scale.ref;
    if (ref != null) {
      await ref.delete();
      return;
    }
    final String? id = scale.id?.trim();
    if (id == null || id.isEmpty) {
      throw StateError('missingId');
    }
    await _collection.doc(id).delete();
  }

  List<TeamFineScale> _scalesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(TeamFineScale.fromSnapshot).toList()
      ..sort((TeamFineScale a, TeamFineScale b) {
        final int nameCmp =
            a.typeName.toLowerCase().compareTo(b.typeName.toLowerCase());
        if (nameCmp != 0) {
          return nameCmp;
        }
        return a.amount.compareTo(b.amount);
      });
  }
}
