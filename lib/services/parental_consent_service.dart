import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/invitation_email_builder.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/account_age_gate.dart';
import 'package:uuid/uuid.dart';

/// Handles 13–14 parental consent: token + email + pending account status.
class ParentalConsentService {
  ParentalConsentService({
    UserService? userService,
    InvitationEmailService? emailService,
  })  : _userService = userService ?? UserService(),
        _emailService = emailService ?? InvitationEmailService();

  final UserService _userService;
  final InvitationEmailService _emailService;

  static const _approveFunctionName = 'approveParentalConsent';
  static const _functionsRegion = 'europe-west1';
  static const _projectId = 'aserstein-2453e';

  /// Creates / updates the user doc as pending and emails the legal guardian.
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

    final token = _newToken();
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

  String _newToken() {
    // Opaque URL-safe token (uuid + entropy).
    final rand = Random.secure().nextInt(1 << 32).toRadixString(16);
    return '${const Uuid().v4().replaceAll('-', '')}$rand';
  }

  String _approveUrl(String token) {
    return 'https://$_functionsRegion-$_projectId.cloudfunctions.net/'
        '$_approveFunctionName?token=${Uri.encodeQueryComponent(token)}';
  }

  String _plainText({
    required String childName,
    required String approveUrl,
  }) {
    return '''
Bonjour,

$childName souhaite utiliser Grinta Performance (application pour sportifs à partir de 13 ans).

Les utilisateurs de 13 et 14 ans peuvent créer un compte uniquement avec l'autorisation de leur représentant légal.

Pour autoriser ce compte, ouvrez ce lien :
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
  }) {
    final safeName = _escapeHtml(childName);
    final safeUrl = _escapeHtml(approveUrl);
    final safeLogo = _escapeHtml(logoUrl);
    final safeApp = _escapeHtml(
      appName.trim().isEmpty ? 'Grinta Performance' : appName.trim(),
    );
    final b = InvitationEmailBrand;
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Autorisation parentale — $safeApp</title>
</head>
<body style="margin:0;padding:0;background-color:${b.background};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:${b.background};padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background-color:${b.surface};border:1px solid ${b.border};border-radius:16px;overflow:hidden;">
          <tr>
            <td style="background:linear-gradient(135deg,${b.primary} 0%,${b.secondary} 100%);padding:28px 32px;text-align:center;">
              <img src="$safeLogo" alt="$safeApp" width="160" style="display:block;margin:0 auto 12px;max-width:160px;height:auto;border:0;" />
              <p style="margin:0;color:#FFFFFF;font-size:18px;font-weight:600;line-height:1.4;">Autorisation parentale</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 16px;color:${b.textPrimary};font-size:15px;line-height:1.55;">
                <strong>$safeName</strong> souhaite utiliser <strong>$safeApp</strong>.
              </p>
              <p style="margin:0 0 24px;color:${b.textSecondary};font-size:15px;line-height:1.55;">
                Les utilisateurs âgés de <strong style="color:${b.textPrimary};">13 à 14 ans</strong>
                peuvent utiliser l'application sous réserve de l'autorisation de leur représentant légal.
              </p>
              <table role="presentation" cellspacing="0" cellpadding="0" style="margin:0 auto 24px;">
                <tr>
                  <td align="center">
                    <a href="$safeUrl" style="display:inline-block;background-color:${b.primary};color:#FFFFFF;text-decoration:none;font-size:15px;font-weight:700;padding:14px 24px;border-radius:999px;">
                      Autoriser le compte
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin:0 0 12px;color:${b.textSecondary};font-size:13px;line-height:1.5;">
                Si le bouton ne fonctionne pas, copiez ce lien&nbsp;:<br>
                <a href="$safeUrl" style="color:${b.primary};word-break:break-all;">$safeUrl</a>
              </p>
              <p style="margin:0;color:${b.textSecondary};font-size:13px;line-height:1.5;">
                Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px;border-top:1px solid ${b.border};">
              <p style="margin:0;color:${b.textSecondary};font-size:12px;line-height:1.6;text-align:center;">
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
