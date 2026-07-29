import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/personal_sport_activity.dart';

class PersonalSportActivityService {
  static const String collectionName = 'personalSportActivities';

  PersonalSportActivityService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<PersonalSportActivity> create(PersonalSportActivity activity) async {
    final ref = _collection.doc();
    await ref.set(activity.toFirestore(forCreate: true));
    final snap = await ref.get();
    return PersonalSportActivity.fromFirestore(snap);
  }

  Future<PersonalSportActivity> update(PersonalSportActivity activity) async {
    final id = activity.id?.trim() ?? '';
    if (id.isEmpty) {
      throw ArgumentError('PersonalSportActivity.id is required for update');
    }
    final ref = _collection.doc(id);
    await ref.set(activity.toFirestore(forCreate: false), SetOptions(merge: true));
    final snap = await ref.get();
    return PersonalSportActivity.fromFirestore(snap);
  }

  Future<void> delete(PersonalSportActivity activity) async {
    final id = activity.id?.trim() ?? '';
    if (id.isEmpty) {
      throw ArgumentError('PersonalSportActivity.id is required for delete');
    }
    await _collection.doc(id).delete();
  }

  Future<PersonalSportActivity?> getById(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final snap = await _collection.doc(trimmed).get();
    if (!snap.exists) return null;
    return PersonalSportActivity.fromFirestore(snap);
  }

  Future<bool> hasExternalActivity({
    required String memberId,
    required String externalSource,
    required String externalId,
  }) async {
    final snap = await _collection
        .where('memberId', isEqualTo: memberId.trim())
        .where('externalSource', isEqualTo: externalSource.trim())
        .where('externalId', isEqualTo: externalId.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<Set<String>> importedExternalIds({
    required String memberId,
    required String externalSource,
  }) async {
    final snap = await _collection
        .where('memberId', isEqualTo: memberId.trim())
        .where('externalSource', isEqualTo: externalSource.trim())
        .get();
    final ids = <String>{};
    for (final doc in snap.docs) {
      final id = (doc.data()['externalId'] ?? '').toString().trim();
      if (id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  Stream<List<PersonalSportActivity>> watchForMemberBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return Stream<List<PersonalSportActivity>>.value(const []);
    }

    return _collection
        .where('accessMemberIds', arrayContains: trimmed)
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(PersonalSportActivity.fromFirestore)
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return items;
    }).handleError((Object e, StackTrace st) {
      debugPrint('watch personalSportActivities failed: $e\n$st');
    });
  }

  /// Owner-scoped stream for coaches: activities owned by [memberId] in range,
  /// filtered to [PersonalSportVisibility.coach] client-side.
  Stream<List<PersonalSportActivity>> watchCoachVisibleOwnedBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return Stream<List<PersonalSportActivity>>.value(const []);
    }

    return _collection
        .where('memberId', isEqualTo: trimmed)
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(PersonalSportActivity.fromFirestore)
          .where(
            (activity) => activity.visibility == PersonalSportVisibility.coach,
          )
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return items;
    }).handleError((Object e, StackTrace st) {
      debugPrint('watch coach-visible personalSportActivities failed: $e\n$st');
    });
  }

  /// One-shot coach-visible personal activities for [memberId] in [start, end).
  Future<List<PersonalSportActivity>> fetchCoachVisibleOwnedBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    return fetchOwnedBetweenDates(
      memberId: memberId,
      start: start,
      end: end,
      includeCoach: true,
      includeTeam: false,
      includePrivate: false,
    );
  }

  /// Personal activities visible to a coach (not private) in [start, end).
  Future<List<PersonalSportActivity>> fetchNonPrivateOwnedBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
  }) {
    return fetchOwnedBetweenDates(
      memberId: memberId,
      start: start,
      end: end,
      includeCoach: true,
      includeTeam: true,
      includePrivate: false,
    );
  }

  Future<List<PersonalSportActivity>> fetchOwnedBetweenDates({
    required String memberId,
    required DateTime start,
    required DateTime end,
    bool includeCoach = true,
    bool includeTeam = false,
    bool includePrivate = false,
  }) async {
    final trimmed = memberId.trim();
    if (trimmed.isEmpty) return const [];

    try {
      final snap = await _collection
          .where('memberId', isEqualTo: trimmed)
          .where(
            'startAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .where('startAt', isLessThan: Timestamp.fromDate(end))
          .get();
      final items = snap.docs
          .map(PersonalSportActivity.fromFirestore)
          .where((activity) {
            switch (activity.visibility) {
              case PersonalSportVisibility.private:
                return includePrivate;
              case PersonalSportVisibility.coach:
                return includeCoach;
              case PersonalSportVisibility.team:
                return includeTeam;
            }
          })
          .toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return items;
    } catch (e, st) {
      debugPrint('fetch personalSportActivities failed: $e\n$st');
      return const [];
    }
  }
}
