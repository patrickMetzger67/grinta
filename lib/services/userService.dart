import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore field names on `users/{uid}`.
abstract final class UserDocumentFields {
  static const email = 'email';
  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const createdAt = 'createdAt';
  static const trialEndsAt = 'trialEndsAt';
  static const isRoot = 'isRoot';
}

/// Free trial length applied on first account creation.
const Duration kUserTrialDuration = Duration(days: 15);

class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final bool isRoot;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isRoot = false,
  });
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'users';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<bool> existsByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;

    final snapshot = await _collection
        .where('email', isEqualTo: trimmed)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<UserProfile?> getById(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    return UserProfile(
      uid: uid,
      firstName: _readNameField(data, 'firstName', 'firstname'),
      lastName: _readNameField(data, 'lastName', 'lastname'),
      email: data['email']?.toString() ?? '',
      isRoot: data[UserDocumentFields.isRoot] == true,
    );
  }

  String _readNameField(
    Map<String, dynamic> data,
    String primaryKey,
    String fallbackKey,
  ) {
    final primary = data[primaryKey]?.toString().trim();
    if (primary != null && primary.isNotEmpty) return primary;

    return data[fallbackKey]?.toString().trim() ?? '';
  }

  /// Creates the user document with a 15-day trial on first signup only.
  ///
  /// If a stub document already exists (e.g. avatar cache wrote `photoURL`
  /// first), missing trial and profile fields are merged without resetting an
  /// existing [UserDocumentFields.trialEndsAt].
  Future<void> createAccountIfNeeded({
    required String uid,
    required String email,
    required String firstName,
    required String lastName,
  }) async {
    final ref = _collection.doc(uid);
    final existing = await ref.get();

    final trimmedEmail = email.trim();
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();

    if (!existing.exists) {
      final trialEndsAt = DateTime.now().add(kUserTrialDuration);
      await ref.set(<String, dynamic>{
        UserDocumentFields.email: trimmedEmail,
        UserDocumentFields.firstName: trimmedFirst,
        UserDocumentFields.lastName: trimmedLast,
        UserDocumentFields.createdAt: FieldValue.serverTimestamp(),
        UserDocumentFields.trialEndsAt: Timestamp.fromDate(trialEndsAt),
      });
      return;
    }

    final data = existing.data() ?? {};
    final updates = _missingTrialAndProfileUpdates(
      data: data,
      email: trimmedEmail,
      firstName: trimmedFirst,
      lastName: trimmedLast,
    );
    if (updates.isEmpty) return;

    await ref.set(updates, SetOptions(merge: true));
  }

  /// Backfills missing trial timestamps for accounts created before trial
  /// fields were written. Never overwrites an existing trial end date.
  Future<DateTime?> backfillTrialFieldsIfMissing(String uid) async {
    final ref = _collection.doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return null;

    final data = snap.data() ?? {};
    final existingEndsAt = _readTimestamp(data[UserDocumentFields.trialEndsAt]);
    if (existingEndsAt != null) return existingEndsAt;

    final trialEndsAt = DateTime.now().add(kUserTrialDuration);
    final updates = <String, dynamic>{
      UserDocumentFields.trialEndsAt: Timestamp.fromDate(trialEndsAt),
    };
    if (data[UserDocumentFields.createdAt] == null) {
      updates[UserDocumentFields.createdAt] = FieldValue.serverTimestamp();
    }

    await ref.set(updates, SetOptions(merge: true));
    return trialEndsAt;
  }

  Map<String, dynamic> _missingTrialAndProfileUpdates({
    required Map<String, dynamic> data,
    required String email,
    required String firstName,
    required String lastName,
  }) {
    final updates = <String, dynamic>{};

    if (_readTimestamp(data[UserDocumentFields.trialEndsAt]) == null) {
      updates[UserDocumentFields.trialEndsAt] =
          Timestamp.fromDate(DateTime.now().add(kUserTrialDuration));
    }
    if (data[UserDocumentFields.createdAt] == null) {
      updates[UserDocumentFields.createdAt] = FieldValue.serverTimestamp();
    }

    if (email.isNotEmpty) {
      updates[UserDocumentFields.email] = email;
    }
    if (firstName.isNotEmpty) {
      updates[UserDocumentFields.firstName] = firstName;
    }
    if (lastName.isNotEmpty) {
      updates[UserDocumentFields.lastName] = lastName;
    }

    return updates;
  }

  DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Future<void> updateProfileNames({
    required String uid,
    required String firstName,
    required String lastName,
  }) async {
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    if (trimmedFirst.isEmpty && trimmedLast.isEmpty) return;

    final updates = <String, dynamic>{};
    if (trimmedFirst.isNotEmpty) {
      updates[UserDocumentFields.firstName] = trimmedFirst;
    }
    if (trimmedLast.isNotEmpty) {
      updates[UserDocumentFields.lastName] = trimmedLast;
    }

    await _collection.doc(uid).set(updates, SetOptions(merge: true));
  }
}
