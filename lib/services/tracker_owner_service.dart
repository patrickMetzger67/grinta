import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/tracker_owner.dart';
import 'package:grinta/services/user_root_service.dart';

/// CRUD for the shared `TRACKER_Owner` collection. Writes are restricted to
/// platform admins (`isRoot`), mirroring [PromoCodeService] conventions.
class TrackerOwnerService {
  TrackerOwnerService._();

  static final TrackerOwnerService instance = TrackerOwnerService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(kTrackerOwnerCollection);

  Stream<List<TrackerOwner>> watchOwners({int limit = 200}) {
    return _collection
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(TrackerOwner.fromDoc)
              .toList(growable: false),
        );
  }

  Future<void> saveOwner(TrackerOwner owner) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('authentication-required');
    }

    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    final typeTracker = owner.typeTracker.trim();
    if (!TrackerOwner.typeTrackers.contains(typeTracker)) {
      throw ArgumentError.value(
        owner.typeTracker,
        'typeTracker',
        'must be one of ${TrackerOwner.typeTrackers.join(', ')}',
      );
    }

    try {
      await _collection
          .doc(owner.id)
          .set(owner.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e, st) {
      debugPrint('saveOwner failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }

  Future<void> deleteOwner(String ownerId) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    try {
      await _collection.doc(ownerId).delete();
    } on FirebaseException catch (e, st) {
      debugPrint('deleteOwner failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }
}
