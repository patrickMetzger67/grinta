import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore field names on `users/{uid}`.
abstract final class UserDocumentFields {
  static const email = 'email';
  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const createdAt = 'createdAt';
  static const trialEndsAt = 'trialEndsAt';
  static const isRoot = 'isRoot';
  /// Server-written paid access mirror (promo / future webhooks). Clients read only.
  static const subscriptionAccess = 'subscriptionAccess';

  /// `active` | `pendingParentalConsent` (missing ⇒ treat as active).
  static const accountStatus = 'accountStatus';
  static const birthDay = 'birthDay';
  static const parentEmail = 'parentEmail';
  static const parentalConsentToken = 'parentalConsentToken';
  static const parentalConsentRequestedAt = 'parentalConsentRequestedAt';
  static const parentalConsentAt = 'parentalConsentAt';

  /// Explicit consent for heart rate / physiological wearable data (CNIL).
  /// `true` = authorized, `false` = refused, missing = not decided.
  static const physiologicalDataConsent = 'physiologicalDataConsent';
  static const physiologicalDataConsentAt = 'physiologicalDataConsentAt';
  static const physiologicalDataConsentVersion =
      'physiologicalDataConsentVersion';
  /// `self` | `parent` — see [PhysiologicalDataConsentSource].
  static const physiologicalDataConsentSource =
      'physiologicalDataConsentSource';
}

/// Account lifecycle for age / parental consent.
abstract final class UserAccountStatus {
  static const active = 'active';
  static const pendingParentalConsent = 'pendingParentalConsent';
}

/// Free trial length applied on first account creation.
const Duration kUserTrialDuration = Duration(days: 15);

class UserProfile {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String photoURL;
  final bool isRoot;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoURL = '',
    this.isRoot = false,
  });

  String get displayFirstName {
    if (firstName.trim().isNotEmpty) return firstName.trim();
    if (lastName.trim().isNotEmpty) return lastName.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return uid;
  }

  String get displayName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    if (email.trim().isNotEmpty) return email.trim();
    return uid;
  }

  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    final fallback = displayFirstName;
    if (fallback.isEmpty) return '?';
    return fallback.substring(0, 1).toUpperCase();
  }

  bool matchesSearch(String query) {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return true;

    final haystacks = <String>[
      email.trim().toLowerCase(),
      firstName.trim().toLowerCase(),
      lastName.trim().toLowerCase(),
      displayName.toLowerCase(),
    ].where((value) => value.isNotEmpty);

    return tokens.every(
      (token) => haystacks.any((value) => value.contains(token)),
    );
  }
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionName = 'users';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Future<bool> existsByEmail(String email) async {
    final uid = await getUidByEmail(email);
    return uid != null;
  }

  /// Returns the Firestore `users` document id for [email], if any.
  ///
  /// Tries the trimmed value and its lowercase form (emails are often stored
  /// normalized at signup).
  Future<String?> getUidByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;

    final candidates = <String>{trimmed, trimmed.toLowerCase()};
    for (final candidate in candidates) {
      final snapshot = await _collection
          .where(UserDocumentFields.email, isEqualTo: candidate)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
    }
    return null;
  }

  Future<UserProfile?> getById(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (!doc.exists) return null;
    return userProfileFromSnapshot(doc);
  }

  /// Live list of all app accounts (`users/{uid}`).
  Stream<List<UserProfile>> streamUsers() {
    return _collection.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map(userProfileFromSnapshot)
          .toList(growable: false);
      users.sort((a, b) {
        final byLast = a.lastName.toLowerCase().compareTo(
          b.lastName.toLowerCase(),
        );
        if (byLast != 0) return byLast;
        final byFirst = a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        );
        if (byFirst != 0) return byFirst;
        return a.email.toLowerCase().compareTo(b.email.toLowerCase());
      });
      return users;
    });
  }

  UserProfile userProfileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      firstName: _readNameField(data, 'firstName', 'firstname'),
      lastName: _readNameField(data, 'lastName', 'lastname'),
      email: data[UserDocumentFields.email]?.toString() ?? '',
      photoURL: _readPhotoUrl(data),
      isRoot: data[UserDocumentFields.isRoot] == true,
    );
  }

  String _readPhotoUrl(Map<String, dynamic> data) {
    for (final key in ['photoURL', 'photo', 'image']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
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
    String accountStatus = UserAccountStatus.active,
    String? birthDay,
    String? parentEmail,
    String? parentalConsentToken,
  }) async {
    final ref = _collection.doc(uid);
    final existing = await ref.get();

    final trimmedEmail = email.trim();
    final trimmedFirst = firstName.trim();
    final trimmedLast = lastName.trim();
    final trimmedBirthDay = birthDay?.trim();
    final trimmedParentEmail = parentEmail?.trim();
    final trimmedToken = parentalConsentToken?.trim();

    if (!existing.exists) {
      final trialEndsAt = DateTime.now().add(kUserTrialDuration);
      await ref.set(<String, dynamic>{
        UserDocumentFields.email: trimmedEmail,
        UserDocumentFields.firstName: trimmedFirst,
        UserDocumentFields.lastName: trimmedLast,
        UserDocumentFields.createdAt: FieldValue.serverTimestamp(),
        UserDocumentFields.trialEndsAt: Timestamp.fromDate(trialEndsAt),
        UserDocumentFields.accountStatus: accountStatus,
        if (trimmedBirthDay != null && trimmedBirthDay.isNotEmpty)
          UserDocumentFields.birthDay: trimmedBirthDay,
        if (trimmedParentEmail != null && trimmedParentEmail.isNotEmpty)
          UserDocumentFields.parentEmail: trimmedParentEmail,
        if (trimmedToken != null && trimmedToken.isNotEmpty) ...{
          UserDocumentFields.parentalConsentToken: trimmedToken,
          UserDocumentFields.parentalConsentRequestedAt:
              FieldValue.serverTimestamp(),
        },
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
    if (accountStatus == UserAccountStatus.pendingParentalConsent &&
        data[UserDocumentFields.accountStatus] != UserAccountStatus.active) {
      updates[UserDocumentFields.accountStatus] = accountStatus;
    }
    if (trimmedBirthDay != null && trimmedBirthDay.isNotEmpty) {
      updates[UserDocumentFields.birthDay] = trimmedBirthDay;
    }
    if (trimmedParentEmail != null && trimmedParentEmail.isNotEmpty) {
      updates[UserDocumentFields.parentEmail] = trimmedParentEmail;
    }
    if (trimmedToken != null && trimmedToken.isNotEmpty) {
      updates[UserDocumentFields.parentalConsentToken] = trimmedToken;
      updates[UserDocumentFields.parentalConsentRequestedAt] =
          FieldValue.serverTimestamp();
    }
    if (updates.isEmpty) return;

    await ref.set(updates, SetOptions(merge: true));
  }

  /// Resolves account status; missing field means legacy active accounts.
  Future<String> getAccountStatus(String uid) async {
    final snap = await _collection.doc(uid).get();
    if (!snap.exists) return UserAccountStatus.active;
    final raw = snap.data()?[UserDocumentFields.accountStatus]?.toString().trim();
    if (raw == null || raw.isEmpty) return UserAccountStatus.active;
    return raw;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snap = await _collection.doc(uid).get();
    if (!snap.exists) return null;
    return snap.data();
  }

  /// Deletes `users/{uid}` (and nested client-writable state is left as orphans
  /// only if subcollections exist — call while still authenticated).
  ///
  /// Used when aborting a partially completed signup so Auth deletion does not
  /// leave a Firestore account document behind.
  Future<void> deleteAccountDocument(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;
    final ref = _collection.doc(trimmed);
    final snap = await ref.get();
    if (!snap.exists) return;
    await ref.delete();
  }

  Future<void> refreshParentalConsentRequest({
    required String uid,
    required String parentEmail,
    required String token,
  }) async {
    await _collection.doc(uid).set(
      <String, dynamic>{
        UserDocumentFields.accountStatus:
            UserAccountStatus.pendingParentalConsent,
        UserDocumentFields.parentEmail: parentEmail.trim(),
        UserDocumentFields.parentalConsentToken: token.trim(),
        UserDocumentFields.parentalConsentRequestedAt:
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
