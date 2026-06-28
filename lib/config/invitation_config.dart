import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Runtime invitation settings (constants with optional Firestore overrides).
class InvitationRuntimeConfig {
  const InvitationRuntimeConfig({
    required this.contactPrefixCode,
    required this.appDisplayName,
    required this.appleStoreUrl,
    required this.googlePlayUrl,
  });

  final String contactPrefixCode;
  final String appDisplayName;
  final String appleStoreUrl;
  final String googlePlayUrl;
}

/// Invitation codes and store links for member onboarding SMS.
///
/// Defaults are compile-time constants. [resolve] may override them from
/// Firestore document `config/invitation` when present.
///
/// ## Firestore overrides (`config/invitation`)
///
/// Optional string fields (empty values fall back to compile-time defaults):
///
/// | Field               | Default              | Notes                                      |
/// |---------------------|----------------------|--------------------------------------------|
/// | `contactPrefixCode` | `GT`                 | Prefix for invitation codes                |
/// | `appDisplayName`    | `Grinta Performance` | App/club name shown in invitation SMS      |
/// | `appleStoreUrl`     | grinta.io link       | iOS download URL in SMS                    |
/// | `googlePlayUrl`     | Play Store link      | Android download URL in SMS                |
///
/// Legacy field `shortClubName` is accepted as an alias for `appDisplayName`.
abstract final class InvitationConfig {
  static const String contactPrefixCode = 'GT';

  static const String appDisplayName = 'Grinta Performance';

  /// Club id sent with member invitation SMS in the Grinta app.
  static const String grintaInvitationClubId = '0';

  static const String appleStoreUrl = 'https://grinta.io';

  static const String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=io.grinta.app';

  static const String _firestoreDocumentPath = 'config/invitation';

  static InvitationRuntimeConfig? _cached;
  static Future<InvitationRuntimeConfig>? _loading;

  static InvitationRuntimeConfig get defaults => const InvitationRuntimeConfig(
        contactPrefixCode: contactPrefixCode,
        appDisplayName: appDisplayName,
        appleStoreUrl: appleStoreUrl,
        googlePlayUrl: googlePlayUrl,
      );

  /// Returns cached config, loading Firestore overrides once when available.
  static Future<InvitationRuntimeConfig> resolve({
    FirebaseFirestore? firestore,
  }) {
    final cached = _cached;
    if (cached != null) {
      return Future.value(cached);
    }

    return _loading ??= _load(firestore: firestore).then((config) {
      _cached = config;
      return config;
    });
  }

  static Future<InvitationRuntimeConfig> _load({
    FirebaseFirestore? firestore,
  }) async {
    try {
      final snapshot = await (firestore ?? FirebaseFirestore.instance)
          .doc(_firestoreDocumentPath)
          .get();
      if (!snapshot.exists) {
        return defaults;
      }

      final map = snapshot.data();
      if (map == null || map.isEmpty) {
        return defaults;
      }

      return InvitationRuntimeConfig(
        contactPrefixCode: _readString(
              map['contactPrefixCode'],
              fallback: contactPrefixCode,
            ) ??
            contactPrefixCode,
        appDisplayName:
            _readString(map['appDisplayName'] ?? map['shortClubName'],
                    fallback: appDisplayName) ??
                appDisplayName,
        appleStoreUrl: _readString(map['appleStoreUrl'],
                fallback: appleStoreUrl) ??
            appleStoreUrl,
        googlePlayUrl: _readString(map['googlePlayUrl'],
                fallback: googlePlayUrl) ??
            googlePlayUrl,
      );
    } catch (e, st) {
      debugPrint('InvitationConfig.resolve failed: $e\n$st');
      return defaults;
    }
  }

  static String? _readString(Object? value, {required String fallback}) {
    if (value == null) return fallback;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
