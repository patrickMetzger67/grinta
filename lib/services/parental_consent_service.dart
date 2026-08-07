import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitation_email_builder.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/services/physiological_data_consent_service.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/account_age_gate.dart';
import 'package:uuid/uuid.dart';

/// Opaque URL-safe token for parental / physio consent links.
///
/// Avoids `Random.nextInt(1 << 32)` which throws [RangeError] on web
/// (JS bitwise `1 << 32` is 0).
@visibleForTesting
String newParentalConsentToken({Random? random, Uuid? uuid}) {
  final rng = random ?? Random.secure();
  final id = (uuid ?? const Uuid()).v4().replaceAll('-', '');
  final entropy = List<String>.generate(
    4,
    (_) => rng.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
  ).join();
  return '$id$entropy';
}

/// Handles 13–14 parental consent: token + email + pending account status.
class ParentalConsentService {
  ParentalConsentService({
    UserService? userService,
    InvitationEmailService? emailService,
    PhysiologicalDataConsentService? physiologicalConsentService,
  })  : _userService = userService ?? UserService(),
        _emailService = emailService ?? InvitationEmailService(),
        _physiologicalConsentService =
            physiologicalConsentService ?? PhysiologicalDataConsentService();

  final UserService _userService;
  final InvitationEmailService _emailService;
  final PhysiologicalDataConsentService _physiologicalConsentService;

  static const _approveFunctionName = 'approveParentalConsent';
  static const _functionsRegion = 'europe-west1';
  static const _projectId = 'aserstein-2453e';

  /// Emails the legal guardian, then creates / updates `users/{uid}` as pending.
  ///
  /// The Firestore account document is written only after the email succeeds,
  /// so a mail failure never leaves an orphan `users/{uid}` row.
  ///
  /// Returns an error message key/code, or `null` on success.
  Future<String?> requestParentalConsent({
    required String uid,
    required String accountEmail,
    required Player profile,
    required String parentEmail,
    required String childDisplayName,
  }) async {
    final gate = classifyPlayerAccountAge(profile);
    if (gate != AccountAgeGateResult.parentalConsentRequired) {
      return 'invalidAge';
    }

    final normalizedParent = parentEmail.trim().toLowerCase();
    if (normalizedParent.isEmpty) return 'emptyParentEmail';

    // Send the guardian email *before* writing `users/{uid}`. If the mail
    // provider fails, the caller can delete Auth without leaving an orphan
    // account document (PII + pending token) in Firestore.
    final token = _newToken();
    final approveUrl = _approveUrl(token);
    final config = await InvitationConfig.resolve();
    final subject =
        'Autorisation parentale — Grinta Performance ($childDisplayName)';
    final text = _plainText(
      childName: childDisplayName,
      approveUrl: approveUrl,
    );
    final html = _html(
      childName: childDisplayName,
      approveUrl: approveUrl,
      logoUrl: config.logoUrl,
      appName: config.appDisplayName,
    );

    final error = await _emailService.send(
      toEmail: normalizedParent,
      subject: subject,
      text: text,
      html: html,
    );
    if (error != null) {
      debugPrint('ParentalConsentService email failed: $error');
      return error;
    }

    await _userService.createAccountIfNeeded(
      uid: uid,
      email: accountEmail,
      firstName: profile.firstName?.trim() ?? '',
      lastName: profile.lastName?.trim() ?? '',
      accountStatus: UserAccountStatus.pendingParentalConsent,
      birthDay: profile.birthDay,
      parentEmail: normalizedParent,
      parentalConsentToken: token,
    );
    return null;
  }

  Future<String?> resendParentalConsentEmail({
    required String uid,
    required String childDisplayName,
  }) async {
    final data = await _userService.getUserData(uid);
    if (data == null) return 'missingUser';

    final parentEmail =
        data[UserDocumentFields.parentEmail]?.toString().trim() ?? '';
    if (parentEmail.isEmpty) return 'emptyParentEmail';

    final token = _newToken();
    await _userService.refreshParentalConsentRequest(
      uid: uid,
      parentEmail: parentEmail,
      token: token,
    );

    final approveUrl = _approveUrl(token);
    final config = await InvitationConfig.resolve();
    final subject =
        'Autorisation parentale — Grinta Performance ($childDisplayName)';
    final error = await _emailService.send(
      toEmail: parentEmail,
      subject: subject,
      text: _plainText(childName: childDisplayName, approveUrl: approveUrl),
      html: _html(
        childName: childDisplayName,
        approveUrl: approveUrl,
        logoUrl: config.logoUrl,
        appName: config.appDisplayName,
      ),
    );
    return error;
  }

  /// Active 13–14 account missing physio consent: email guardian for HR/devices.
  ///
  /// Does not change [UserAccountStatus]. Approve link grants physio only.
  Future<String?> requestPhysiologicalConsentFromParent({
    required String uid,
    required String parentEmail,
    required String childDisplayName,
  }) async {
    final normalizedParent = parentEmail.trim().toLowerCase();
    if (normalizedParent.isEmpty) return 'emptyParentEmail';

    final token = _newToken();
    await _physiologicalConsentService.storeParentalPhysiologicalConsentRequest(
      uid: uid,
      parentEmail: normalizedParent,
      token: token,
    );

    final approveUrl = _approveUrl(token);
    final config = await InvitationConfig.resolve();
    final subject =
        'Autorisation données physiologiques — Grinta Performance ($childDisplayName)';
    final error = await _emailService.send(
      toEmail: normalizedParent,
      subject: subject,
      text: _plainText(
        childName: childDisplayName,
        approveUrl: approveUrl,
        physioOnly: true,
      ),
      html: _html(
        childName: childDisplayName,
        approveUrl: approveUrl,
        logoUrl: config.logoUrl,
        appName: config.appDisplayName,
        physioOnly: true,
      ),
    );
    return error;
  }

  String _newToken() => newParentalConsentToken();


  String _approveUrl(String token) {
    return 'https://$_functionsRegion-$_projectId.cloudfunctions.net/'
        '$_approveFunctionName?token=${Uri.encodeQueryComponent(token)}';
  }

  String _plainText({
    required String childName,
    required String approveUrl,
    bool physioOnly = false,
  }) {
    if (physioOnly) {
      return '''
Bonjour,

$childName souhaite connecter un appareil de fréquence cardiaque à Grinta Performance (Polar, Whoop, Fitbit, Apple Forme, Google Health Connect, etc.).

Pour les utilisateurs de 13 et 14 ans, l'autorisation du représentant légal est requise pour traiter les données de fréquence cardiaque et autres données physiologiques.

Pour autoriser ce traitement, ouvrez ce lien :
$approveUrl

Sans cette autorisation, votre enfant pourra continuer à utiliser l'application, mais pas connecter ces capteurs de santé.

Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.

— L'équipe Grinta Performance
''';
    }
    return '''
Bonjour,

$childName souhaite utiliser Grinta Performance (application pour sportifs à partir de 13 ans).

Les utilisateurs de 13 et 14 ans peuvent créer un compte uniquement avec l'autorisation de leur représentant légal.

En autorisant ce compte, vous autorisez également Grinta Performance à traiter les données de fréquence cardiaque et autres données physiologiques provenant des appareils connectés de votre enfant (Polar, Whoop, Fitbit, Apple Forme, Google Health Connect, etc.) afin d'analyser sa performance sportive. Sans cette autorisation, votre enfant pourra utiliser l'application, mais pas connecter ces capteurs de santé.

Pour autoriser ce compte et le traitement des données physiologiques, ouvrez ce lien :
$approveUrl

Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.

— L'équipe Grinta Performance
''';
  }

  /// Same visual system as [InvitationEmailBuilder] (logo banner + AppColors).
  String _html({
    required String childName,
    required String approveUrl,
    required String logoUrl,
    required String appName,
    bool physioOnly = false,
  }) {
    final safeName = _escapeHtml(childName);
    final safeUrl = _escapeHtml(approveUrl);
    final safeLogo = _escapeHtml(logoUrl);
    final safeApp = _escapeHtml(
      appName.trim().isEmpty ? 'Grinta Performance' : appName.trim(),
    );
    final primary = InvitationEmailBrand.primary;
    final secondary = InvitationEmailBrand.secondary;
    final background = InvitationEmailBrand.background;
    final surface = InvitationEmailBrand.surface;
    final textPrimary = InvitationEmailBrand.textPrimary;
    final textSecondary = InvitationEmailBrand.textSecondary;
    final border = InvitationEmailBrand.border;
    final bannerTitle = physioOnly
        ? 'Données physiologiques'
        : 'Autorisation parentale';
    final intro = physioOnly
        ? '''
              <p style="margin:0 0 16px;color:$textPrimary;font-size:15px;line-height:1.55;">
                <strong>$safeName</strong> souhaite connecter un appareil de
                fréquence cardiaque à <strong>$safeApp</strong>.
              </p>
              <p style="margin:0 0 24px;color:$textSecondary;font-size:15px;line-height:1.55;">
                Pour les utilisateurs âgés de
                <strong style="color:$textPrimary;">13 à 14 ans</strong>,
                l'autorisation du représentant légal est requise pour traiter les
                <strong style="color:$textPrimary;">données de fréquence cardiaque</strong>
                et autres données physiologiques (Polar, Whoop, Fitbit, Apple Forme,
                Google Health Connect, etc.). Sans cette autorisation, votre enfant
                pourra continuer à utiliser l'application, mais pas lier ces capteurs.
              </p>'''
        : '''
              <p style="margin:0 0 16px;color:$textPrimary;font-size:15px;line-height:1.55;">
                <strong>$safeName</strong> souhaite utiliser <strong>$safeApp</strong>.
              </p>
              <p style="margin:0 0 16px;color:$textSecondary;font-size:15px;line-height:1.55;">
                Les utilisateurs âgés de <strong style="color:$textPrimary;">13 à 14 ans</strong>
                peuvent utiliser l'application sous réserve de l'autorisation de leur représentant légal.
              </p>
              <p style="margin:0 0 24px;color:$textSecondary;font-size:15px;line-height:1.55;">
                En cliquant sur <strong style="color:$textPrimary;">Autoriser</strong>, vous autorisez
                également <strong>$safeApp</strong> à traiter les
                <strong style="color:$textPrimary;">données de fréquence cardiaque</strong>
                et autres données physiologiques provenant des appareils connectés de votre enfant
                (Polar, Whoop, Fitbit, Apple Forme, Google Health Connect, etc.) afin d'analyser sa
                performance sportive. Refuser cette autorisation n'empêche pas l'usage des autres
                fonctions de l'application&nbsp;: seuls les capteurs de santé ne pourront pas être liés.
              </p>''';
    final cta = physioOnly
        ? 'Autoriser les données physiologiques'
        : 'Autoriser le compte et les données physiologiques';
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$bannerTitle — $safeApp</title>
</head>
<body style="margin:0;padding:0;background-color:$background;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:$background;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background-color:$surface;border:1px solid $border;border-radius:16px;overflow:hidden;">
          <tr>
            <td style="background:linear-gradient(135deg,$primary 0%,$secondary 100%);padding:28px 32px;text-align:center;">
              <img src="$safeLogo" alt="$safeApp" width="160" style="display:block;margin:0 auto 12px;max-width:160px;height:auto;border:0;" />
              <p style="margin:0;color:#FFFFFF;font-size:18px;font-weight:600;line-height:1.4;">$bannerTitle</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px;">
$intro
              <table role="presentation" cellspacing="0" cellpadding="0" style="margin:0 auto 24px;">
                <tr>
                  <td align="center">
                    <a href="$safeUrl" style="display:inline-block;background-color:$primary;color:#FFFFFF;text-decoration:none;font-size:15px;font-weight:700;padding:14px 24px;border-radius:999px;">
                      $cta
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 12px;color:$textSecondary;font-size:13px;line-height:1.5;">
                Si le bouton ne fonctionne pas, copiez ce lien&nbsp;:<br>
                <a href="$safeUrl" style="color:$primary;word-break:break-all;">$safeUrl</a>
              </p>
              <p style="margin:0;color:$textSecondary;font-size:13px;line-height:1.5;">
                Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px;border-top:1px solid $border;">
              <p style="margin:0;color:$textSecondary;font-size:12px;line-height:1.6;text-align:center;">
                — L'équipe $safeApp
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
