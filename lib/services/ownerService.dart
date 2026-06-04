import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../model/team.dart';
import '../model/tracker/owner.dart';


class OwnerService {
  OwnerService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(kTrackerOwnerCollection);

  /// Upsert (doc id = owner.id)
  Future<void> upsertOwner(Owner owner) async {
    await _col.doc(owner.id).set(owner.toMap(), SetOptions(merge: true));
  }

  /// Create (doc id = owner.id)
  Future<Owner> createOwner({
    required String name,
    required String typeTracker,
    required bool isActive,
    required String email,
    required String firstname,
    required String lastname,
    required String uidCreate,
    required String uidUpdate,
  }) async {
    final now = Timestamp.now();

    final owner = Owner(
      name: name,
      typeTracker: typeTracker,
      isActive: isActive,
      email: email,
      firstname: firstname,
      lastname: lastname,
      createdAt: now,
      updatedAt: now,
      uidCreate: uidCreate,
      uidUpdate: uidUpdate,
    );

    await _col.doc(owner.id).set(owner.toMap());
    return owner;
  }

  /// Resolves [TeamOwnerRef.displayLabel] from TRACKER_Owner when team data only has ids.
  Future<List<TeamOwnerRef>> enrichTeamOwnerRefs(List<TeamOwnerRef> refs) async {
    if (refs.isEmpty) return refs;
    return Future.wait(
      refs.map((ref) async {
        if (!ref.needsNameLookup) return ref;
        final owner = await getOwnerById(ref.id);
        final resolved = owner?.name.trim() ?? '';
        if (resolved.isEmpty) return ref;
        return ref.withName(resolved);
      }),
    );
  }

  /// Read
  Future<Owner?> getOwnerById(String ownerId) async {
    final doc = await _col.doc(ownerId).get();
    if (!doc.exists) return null;
    return Owner.fromDoc(doc);
  }

  /// Owners whose [Owner.email] matches [email] (trimmed, case-sensitive).
  Future<List<Owner>> getOwnersByEmail(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) return [];

    final query = await _col.where('email', isEqualTo: normalized).get();

    final owners = <Owner>[];
    for (final doc in query.docs) {
      try {
        owners.add(Owner.fromDoc(doc));
      } catch (_) {}
    }

    owners.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return owners;
  }

  Future<List<Owner>> getOwnersByClubId(String clubId) async {
    final query = await _col
        .where('clubs', arrayContains: clubId)
        .get();

    return query.docs.map((doc) => Owner.fromDoc(doc)).toList();
  }

  Future<List<Owner>> getActiveOwners() async {
    final query = await _col
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();

    final List<Owner> owners = [];

    for (final doc in query.docs) {
      try {
        owners.add(Owner.fromDoc(doc));
      } catch (_) {}
    }

    return owners;
  }
  /// Stream d'un owner
  Stream<Owner?> watchOwner(String ownerId) {
    return _col.doc(ownerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Owner.fromDoc(doc);
    });
  }

  /// Liste (optionnel: filtre typeTracker / actifs)
  Stream<List<Owner>> watchOwners({
    String? typeTracker,
    bool? onlyActive,
    int limit = 200,
  }) {
    Query<Map<String, dynamic>> q = _col;

    if (typeTracker != null && typeTracker.isNotEmpty) {
      q = q.where('typeTracker', isEqualTo: typeTracker);
    }
    if (onlyActive == true) {
      q = q.where('isActive', isEqualTo: true);
    }

    q = q.limit(limit);

    return q.snapshots().map(
          (snap) => snap.docs.map((d) => Owner.fromDoc(d)).toList(),
    );
  }

  /// Delete
  Future<void> deleteOwner(String ownerId) async {
    await _col.doc(ownerId).delete();
  }

  /// Updates ciblés
  Future<void> setActive(String ownerId, bool isActive) async {
    await _col.doc(ownerId).update({
      'isActive': isActive,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateName(String ownerId, String name) async {
    await _col.doc(ownerId).update({
      'name': name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> updateTypeTracker(String ownerId, String typeTracker) async {
    await _col.doc(ownerId).update({
      'typeTracker': typeTracker,
      'updatedAt': Timestamp.now(),
    });
  }
}