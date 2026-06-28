import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model/invitation.dart';

class InvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'invitations';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  /// CREATE
  Future<Invitation> createInvitation({
    required String code,
    required int type,
    required String extId,
    required String uid,
    String? teamId,
    String? seasonId,
    String? documentId,
  }) async {
    final now = Timestamp.now();
    final invitation = Invitation(
      id: documentId ?? '',
      code: code,
      type: type,
      extId: extId,
      uid: uid,
      createdAt: now,
      teamId: teamId,
      seasonId: seasonId,
    );

    if (documentId != null && documentId.trim().isNotEmpty) {
      final Map<String, dynamic> payload = invitation.toMap();
      debugPrint(
        'InvitationService.createInvitation set id=${documentId.trim()} '
        'collection=$collectionName payload=$payload',
      );
      await _collection.doc(documentId.trim()).set(payload);
      return invitation.copyWith(id: documentId.trim());
    }

    final Map<String, dynamic> payload = invitation.toMap();
    debugPrint(
      'InvitationService.createInvitation add collection=$collectionName '
      'payload=$payload',
    );
    final docRef = await _collection.add(payload);
    return invitation.copyWith(id: docRef.id, ref: docRef);
  }

  /// CREATE / UPDATE avec id custom
  Future<void> setInvitation(String id, Invitation invitation) async {
    await _collection.doc(id).set(invitation.toMap());
  }

  /// READ many by document id (parallel individual reads).
  Future<Map<String, Invitation>> getInvitationsByIds(
    Iterable<String> ids,
  ) async {
    final Set<String> uniqueIds = ids
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();
    if (uniqueIds.isEmpty) {
      return const <String, Invitation>{};
    }

    final List<Invitation?> invitations = await Future.wait(
      uniqueIds.map((String id) async {
        final DocumentSnapshot<Map<String, dynamic>> doc =
            await _collection.doc(id).get();
        if (!doc.exists) {
          return null;
        }
        return Invitation.fromDocumentSnapshot(doc);
      }),
    );

    final Map<String, Invitation> result = <String, Invitation>{};
    for (final Invitation? invitation in invitations) {
      if (invitation != null) {
        result[invitation.id] = invitation;
      }
    }
    return result;
  }

  /// READ ONE par id document
  Future<Invitation?> getInvitationById(String id) async {
    final doc = await _collection.doc(id).get();

    if (!doc.exists) return null;

    return Invitation.fromDocumentSnapshot(doc);
  }

  /// READ ONE par code (alias for [getInvitationByCode]).
  Future<Invitation?> findByCode(String code) => getInvitationByCode(code);

  /// READ ONE par code
  Future<Invitation?> getInvitationByCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) return null;

    try {
      final snapshot = await _collection
          .where(keyInvitationCode, isEqualTo: normalizedCode)
          .limit(1)
          .get();

      debugPrint(
        'InvitationService.getInvitationByCode code=$normalizedCode '
        'collection=$collectionName resultCount=${snapshot.docs.length}',
      );

      if (snapshot.docs.isEmpty) return null;

      return Invitation.fromDocumentSnapshot(snapshot.docs.first);
    } on FirebaseException catch (e) {
      debugPrint(
        'InvitationService.getInvitationByCode failed code=$normalizedCode '
        'collection=$collectionName firebaseCode=${e.code} message=${e.message}',
      );
      rethrow;
    }
  }

  /// READ ONE par code pour une invitation membre (type = 1)
  Future<Invitation?> getMemberInvitationByCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) return null;

    final invitation = await getInvitationByCode(normalizedCode);
    if (invitation == null) {
      debugPrint(
        'InvitationService.getMemberInvitationByCode not found code=$normalizedCode',
      );
      return null;
    }

    if (invitation.type != invitationTypeMember) {
      debugPrint(
        'InvitationService.getMemberInvitationByCode wrong type '
        'code=$normalizedCode type=${invitation.type} expected=$invitationTypeMember',
      );
      return null;
    }

    return invitation;
  }

  /// STREAM ONE par id document
  Stream<Invitation?> streamInvitationById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Invitation.fromDocumentSnapshot(doc);
    });
  }

  /// READ BY uid
  Future<List<Invitation>> listInvitationsByUid(String uid) async {
    final snapshot = await _collection
        .where(keyInvitationUid, isEqualTo: uid)
        .orderBy(keyInvitationCreatedAt, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invitation.fromDocumentSnapshot(doc))
        .toList();
  }

  /// STREAM BY uid
  Stream<List<Invitation>> streamInvitationsByUid(String uid) {
    return _collection
        .where(keyInvitationUid, isEqualTo: uid)
        .orderBy(keyInvitationCreatedAt, descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Invitation.fromDocumentSnapshot(doc))
          .toList();
    });
  }

  /// READ BY extId
  Future<List<Invitation>> listInvitationsByExtId(String extId) async {
    final snapshot = await _collection
        .where(keyInvitationExtId, isEqualTo: extId)
        .orderBy(keyInvitationCreatedAt, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invitation.fromDocumentSnapshot(doc))
        .toList();
  }

  /// READ BY type
  Future<List<Invitation>> listInvitationsByType(int type) async {
    final snapshot = await _collection
        .where(keyInvitationType, isEqualTo: type)
        .orderBy(keyInvitationCreatedAt, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invitation.fromDocumentSnapshot(doc))
        .toList();
  }

  /// READ ALL
  Future<List<Invitation>> getAllInvitations() async {
    final snapshot = await _collection
        .orderBy(keyInvitationCreatedAt, descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invitation.fromDocumentSnapshot(doc))
        .toList();
  }

  /// UPDATE avec ref
  Future<void> updateInvitation(Invitation invitation) async {
    if (invitation.ref == null) {
      throw Exception('Impossible de mettre à jour : ref est null');
    }

    await invitation.ref!.update(invitation.toMap());
  }

  /// UPDATE par id
  Future<void> updateInvitationById(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _collection.doc(id).update(data);
  }

  /// Valider une invitation
  Future<void> validateInvitation(
    String invitationId,
    String validateUid,
  ) async {
    await _collection.doc(invitationId).update({
      keyInvitationValidateUid: validateUid,
      keyInvitationValidateAt: Timestamp.now(),
    });
  }

  /// DELETE avec ref
  Future<void> deleteInvitation(Invitation invitation) async {
    if (invitation.ref == null) {
      throw Exception('Impossible de supprimer : ref est null');
    }

    await invitation.ref!.delete();
  }

  /// DELETE par id
  Future<void> deleteInvitationById(String id) async {
    await _collection.doc(id).delete();
  }
}
