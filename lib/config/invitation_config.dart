import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Runtime invitation settings (constants with optional Firestore overrides).
class InvitationRuntimeConfig {
  const InvitationRuntimeConfig({
    required this.contactPrefixCode,
    required this.appDisplayName,
    required this.appleStoreUrl,
    required this.googlePlayUrl,
    required this.logoUrl,
    required this.fromEmail,
    required this.replyToEmail,
    required this.inviteBaseUrl,
    required this.whatsappTemplateName,
    required this.whatsappTemplateLanguage,
  });

  final String contactPrefixCode;
  final String appDisplayName;
  final String appleStoreUrl;
  final String googlePlayUrl;
  final String logoUrl;
  final String fromEmail;
  final String replyToEmail;

  /// Public HTTPS landing page for invite links (`…/invite?code=`).
  final String inviteBaseUrl;

  /// Meta-approved WhatsApp template name for member invitations.
  final String whatsappTemplateName;

  /// Template language code (e.g. `fr`, `en`).
  final String whatsappTemplateLanguage;
}

/// Invitation codes and store links for member onboarding emails.
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
/// | `appDisplayName`    | `Grinta Performance` | App/club name shown in invitation emails   |
/// | `appleStoreUrl`     | grinta.io link       | iOS download URL in emails                 |
/// | `googlePlayUrl`     | Play Store link      | Android download URL in emails             |
/// | `logoUrl`           | Firebase Storage URL | Logo image URL in invitation HTML emails   |
/// |                     |                      | Must be publicly readable (`logoClubs/`).  |
/// | `fromEmail`         | `noreply@grinta.io`  | Sender address on queued invitation emails   |
/// | `replyToEmail`      | `contact@grinta.io`  | Reply-to address on queued invitation emails |
/// | `inviteBaseUrl`     | `https://grinta.io/invite` | Public invite landing URL             |
/// | `whatsappTemplateName` | `member_invitation` | Meta WhatsApp template name             |
/// | `whatsappTemplateLanguage` | `fr`           | Meta WhatsApp template language         |
///
/// Legacy field `shortClubName` is accepted as an alias for `appDisplayName`.
///
/// Edit in Firebase Console: Firestore → `config/invitation`. Only root users
/// may write; any signed-in user may read. Seed: `firestore/config/invitation.json`.
abstract final class InvitationConfig {
  static const String contactPrefixCode = 'GT';

  static const String appDisplayName = 'Grinta Performance';

  /// Club id sent with member invitation notifications in the Grinta app.
  static const String grintaInvitationClubId = '0';

  static const String appleStoreUrl = 'https://grinta.io';

  static const String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=io.grinta.app';

  static const String logoUrl =
      'https://firebasestorage.googleapis.com/v0/b/aserstein-2453e.appspot.com/o/logoClubs%2Fthumbs%2FGrinta_1920x1920.png?alt=media';

  static const String fromEmail = 'noreply@grinta.io';

  static const String replyToEmail = 'contact@grinta.io';

  static const String inviteBaseUrl = 'https://grinta.io/invite';

  static const String whatsappTemplateName = 'member_invitation';

  static const String whatsappTemplateLanguage = 'fr';

  static const String _firestoreDocumentPath = 'config/invitation';

  static InvitationRuntimeConfig? _cached;
  static Future<InvitationRuntimeConfig>? _loading;

  static InvitationRuntimeConfig get defaults => const InvitationRuntimeConfig(
        contactPrefixCode: contactPrefixCode,
        appDisplayName: appDisplayName,
        appleStoreUrl: appleStoreUrl,
        googlePlayUrl: googlePlayUrl,
        logoUrl: logoUrl,
        fromEmail: fromEmail,
        replyToEmail: replyToEmail,
        inviteBaseUrl: inviteBaseUrl,
        whatsappTemplateName: whatsappTemplateName,
        whatsappTemplateLanguage: whatsappTemplateLanguage,
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
        logoUrl:
            _readString(map['logoUrl'], fallback: logoUrl) ?? logoUrl,
        fromEmail:
            _readString(map['fromEmail'], fallback: fromEmail) ?? fromEmail,
        replyToEmail: _readString(map['replyToEmail'],
                fallback: replyToEmail) ??
            replyToEmail,
        inviteBaseUrl: _readString(map['inviteBaseUrl'],
                fallback: inviteBaseUrl) ??
            inviteBaseUrl,
        whatsappTemplateName: _readString(map['whatsappTemplateName'],
                fallback: whatsappTemplateName) ??
            whatsappTemplateName,
        whatsappTemplateLanguage: _readString(
              map['whatsappTemplateLanguage'],
              fallback: whatsappTemplateLanguage,
            ) ??
            whatsappTemplateLanguage,
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
