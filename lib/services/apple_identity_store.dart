import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Name and email Apple sends with Sign in with Apple.
///
/// Authentication Services only includes [givenName], [familyName] and [email]
/// on the **first** authorization. Later sign-ins return those fields as null,
/// so they must be persisted locally.
class AppleIdentityRecord {
  const AppleIdentityRecord({
    this.givenName,
    this.familyName,
    this.email,
  });

  final String? givenName;
  final String? familyName;
  final String? email;

  bool get isEmpty =>
      !_hasValue(givenName) && !_hasValue(familyName) && !_hasValue(email);

  Map<String, String> toMap() {
    return {
      if (_hasValue(givenName)) 'givenName': givenName!.trim(),
      if (_hasValue(familyName)) 'familyName': familyName!.trim(),
      if (_hasValue(email)) 'email': email!.trim(),
    };
  }

  factory AppleIdentityRecord.fromMap(Map<String, dynamic> map) {
    return AppleIdentityRecord(
      givenName: _stringOrNull(map['givenName']),
      familyName: _stringOrNull(map['familyName']),
      email: _stringOrNull(map['email']),
    );
  }
}

/// Keeps the last non-empty Apple identity fields. [incoming] wins when set.
AppleIdentityRecord mergeAppleIdentity({
  required AppleIdentityRecord incoming,
  AppleIdentityRecord? cached,
}) {
  if (cached == null || cached.isEmpty) return incoming;
  return AppleIdentityRecord(
    givenName: _nonEmpty(incoming.givenName) ?? cached.givenName,
    familyName: _nonEmpty(incoming.familyName) ?? cached.familyName,
    email: _nonEmpty(incoming.email) ?? cached.email,
  );
}

class AppleIdentityStore {
  AppleIdentityStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _keyPrefix = 'siwa_identity_v1_';

  final SharedPreferences? _prefsOverride;

  Future<AppleIdentityRecord?> read(String? userIdentifier) async {
    final key = _keyFor(userIdentifier);
    if (key == null) return null;
    try {
      final prefs = await _prefs();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final record = AppleIdentityRecord.fromMap(
        Map<String, dynamic>.from(decoded),
      );
      return record.isEmpty ? null : record;
    } catch (e) {
      debugPrint('AppleIdentityStore.read failed: $e');
      return null;
    }
  }

  Future<AppleIdentityRecord> save({
    required String? userIdentifier,
    required AppleIdentityRecord incoming,
  }) async {
    final key = _keyFor(userIdentifier);
    final merged = mergeAppleIdentity(
      incoming: incoming,
      cached: key == null ? null : await read(userIdentifier),
    );
    if (key == null || merged.isEmpty) return merged;
    try {
      final prefs = await _prefs();
      await prefs.setString(key, jsonEncode(merged.toMap()));
    } catch (e) {
      debugPrint('AppleIdentityStore.save failed: $e');
    }
    return merged;
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsOverride ?? await SharedPreferences.getInstance();
  }

  String? _keyFor(String? userIdentifier) {
    final id = userIdentifier?.trim() ?? '';
    if (id.isEmpty) return null;
    return '$_keyPrefix$id';
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String? _stringOrNull(dynamic value) {
  if (value is! String) return null;
  return _nonEmpty(value);
}

bool _hasValue(String? value) => _nonEmpty(value) != null;
