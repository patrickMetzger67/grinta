import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore field names on `users/{uid}`.
abstract final class UserDocumentFields {
  static const email = 'email';
  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const createdAt = 'createdAt';
  static const trialEndsAt = 'trialEndsAt';
  static const isRoot = 'isRoot';
  static const isAnonymous = 'isAnonymous';
  static const providerIds = 'providerIds';

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

  /// Shop ads opt-out. Missing field is treated as `true` (ads on).
  static const eshopAds = 'eshopAds';

  /// Last time a shop ad overlay was shown (Timestamp).
  static const eshopAdsLastShownAt = 'eshopAdsLastShownAt';

  /// Local calendar day (`YYYY-MM-DD`) of the last shop ad impression.
  static const eshopAdsLastShownDate = 'eshopAdsLastShownDate';
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
  final bool isAnonymous;
  final List<String> providerIds;

  const UserProfile({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoURL = '',
    this.isRoot = false,
    this.isAnonymous = false,
    this.providerIds = const [],
  });

  /// First/last name with uid-shaped placeholders stripped.
  String get personName {
    final first = _usableGivenName(firstName);
    final last = _usableGivenName(lastName);
    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return '';
  }

  /// Email suitable for display (never the raw uid).
  String get usableEmail {
    final mail = email.trim();
    if (mail.isEmpty || mail == uid) return '';
    if (!mail.contains('@')) return '';
    return mail;
  }

  String get displayFirstName {
    if (personName.isNotEmpty) {
      final first = _usableGivenName(firstName);
      return first.isNotEmpty ? first : personName;
    }
    return usableEmail;
  }

  /// Person name, else email. Empty when neither is available (never the uid).
  String get displayName {
    if (personName.isNotEmpty) return personName;
    return usableEmail;
  }

  /// Admin list/detail title: person name, else [noNameLabel].
  ///
  /// Never uses the email or uid as the title — email belongs on
  /// [adminEmailSubtitle].
  String adminListLabel({required String noNameLabel}) {
    if (personName.isNotEmpty) return personName;
    return noNameLabel;
  }

  /// Email on the line below the title, when the account has one.
  String? get adminEmailSubtitle {
    final mail = usableEmail;
    if (mail.isEmpty) return null;
    return mail;
  }

  /// Shown in Admin → Utilisateurs: not anonymous, and has a name or email.
  ///
  /// Empty nameless/email-less docs are the « Sans email » / « ? » stub row.
  bool get isListedInAdminUsers {
    if (isAnonymousAccount) return false;
    return personName.isNotEmpty || usableEmail.isNotEmpty;
  }

  String get initials {
    final first = _usableGivenName(firstName);
    final last = _usableGivenName(lastName);
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
      usableEmail.toLowerCase(),
      email.trim().toLowerCase(),
      firstName.trim().toLowerCase(),
      lastName.trim().toLowerCase(),
      personName.toLowerCase(),
      displayName.toLowerCase(),
      '$firstName $lastName'.trim().toLowerCase(),
    ].where((value) => value.isNotEmpty);

    return tokens.every(
      (token) => haystacks.any((value) => value.contains(token)),
    );
  }

  String _usableGivenName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == uid) return '';
    return trimmed;
  }

  /// Firebase Anonymous Auth only (`isAnonymous` or `anonymous` provider).
  ///
  /// Never hides a named account (e.g. Mohamed-Amine ABDESSAMAD). Missing
  /// email/name is not enough — that heuristic dropped real users from Admin.
  bool get isAnonymousAccount {
    if (personName.isNotEmpty) return false;
    if (isAnonymous) return true;
    return providerIds.any(isAnonymousSignInProviderId);
  }

  /// Signed in with Google (`google.com` on the user document).
  bool get signedInWithGoogle => providerIds.any(isGoogleSignInProviderId);

  /// Signed in with Apple (`apple.com` on the user document).
  bool get signedInWithApple => providerIds.any(isAppleSignInProviderId);

  /// Email / password (or email-link) Auth — useful when neither Google nor Apple.
  bool get signedInWithPassword => providerIds.any(isPasswordSignInProviderId);
}

bool isAnonymousSignInProviderId(String value) {
  return _normalizedProviderId(value) == 'anonymous';
}

bool isGoogleSignInProviderId(String value) {
  final id = _normalizedProviderId(value);
  return id == 'google.com' || id == 'google';
}

bool isAppleSignInProviderId(String value) {
  final id = _normalizedProviderId(value);
  return id == 'apple.com' || id == 'apple';
}

bool isPasswordSignInProviderId(String value) {
  final id = _normalizedProviderId(value);
  return id == 'password' ||
      id == 'email' ||
      id == 'emaillink' ||
      id == 'email_link';
}

String _normalizedProviderId(String value) => value.trim().toLowerCase();

/// Provider ids already stored on `users/{uid}` (`providerIds`, `providers`,
/// `providerId`, `signInProvider`). No extra queries.
List<String> readUserProviderIds(Map<String, dynamic> data) {
  final ids = <String>[];
  final seen = <String>{};

  void addId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final key = trimmed.toLowerCase();
    if (seen.add(key)) ids.add(trimmed);
  }

  void addRaw(dynamic raw, {int depth = 0}) {
    if (raw == null || depth > 3) return;
    if (raw is String) {
      addId(raw);
      return;
    }
    if (raw is Iterable) {
      for (final item in raw) {
        addRaw(item, depth: depth + 1);
      }
      return;
    }
    if (raw is Map) {
      for (final key in const [
        'providerId',
        'provider',
        'signInProvider',
        'id',
      ]) {
        if (raw.containsKey(key)) {
          addRaw(raw[key], depth: depth + 1);
        }
      }
      for (final key in raw.keys) {
        final text = key.toString().trim();
        if (_looksLikeStandaloneProviderId(text)) addId(text);
      }
      return;
    }
    addId(raw.toString());
  }

  addRaw(data[UserDocumentFields.providerIds]);
  addRaw(data['providers']);
  addRaw(data['providerId']);
  addRaw(data['signInProvider']);
  return List<String>.unmodifiable(ids);
}

bool _looksLikeStandaloneProviderId(String value) {
  final id = _normalizedProviderId(value);
  if (id.isEmpty) return false;
  if (id.contains('.')) return true;
  return const {
    'google',
    'apple',
    'password',
    'anonymous',
    'email',
    'emaillink',
    'phone',
  }.contains(id);
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
      final users =
          snapshot.docs.map(userProfileFromSnapshot).toList(growable: false);
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
      email: _readEmail(data),
      photoURL: _readPhotoUrl(data),
      isRoot: data[UserDocumentFields.isRoot] == true,
      isAnonymous: _readAnonymousFlag(data),
      providerIds: readUserProviderIds(data),
    );
  }

  bool _readAnonymousFlag(Map<String, dynamic> data) {
    final raw = data[UserDocumentFields.isAnonymous] ?? data['anonymous'];
    if (raw == true) return true;
    if (raw is String && raw.trim().toLowerCase() == 'true') return true;
    return false;
  }

  String _readEmail(Map<String, dynamic> data) {
    for (final key in [
      UserDocumentFields.email,
      'Email',
      'mail',
      'userEmail',
    ]) {
      final raw = data[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isEmpty) continue;
      if (value.contains('@')) return value;
    }
    return '';
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
    final raw =
        snap.data()?[UserDocumentFields.accountStatus]?.toString().trim();
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
