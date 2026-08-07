import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/model/player.dart';
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

  String _html({
    required String childName,
    required String approveUrl,
    required String logoUrl,
  }) {
    final safeName = _escapeHtml(childName);
    final safeUrl = _escapeHtml(approveUrl);
    final safeLogo = _escapeHtml(logoUrl);
    return '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"></head>
<body style="margin:0;padding:0;background:#F7F7F8;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F7F7F8;padding:32px 16px;">
    <tr><td align="center">
      <table width="100%" style="max-width:520px;background:#FFFFFF;border-radius:16px;border:1px solid #E5E5EA;overflow:hidden;">
        <tr><td style="padding:28px 28px 8px;text-align:center;">
          <img src="$safeLogo" alt="Grinta" width="72" height="72" style="border-radius:16px;">
          <h1 style="margin:16px 0 0;font-size:22px;color:#1C1C1E;">Autorisation parentale</h1>
        </td></tr>
        <tr><td style="padding:8px 28px 28px;color:#6E6E73;font-size:15px;line-height:1.55;">
          <p><strong style="color:#1C1C1E;">$safeName</strong> souhaite utiliser <strong>Grinta Performance</strong>.</p>
          <p>Les utilisateurs âgés de <strong>13 à 14 ans</strong> peuvent utiliser l'application sous réserve de l'autorisation de leur représentant légal.</p>
          <p style="text-align:center;margin:28px 0;">
            <a href="$safeUrl" style="display:inline-block;background:#F95C1B;color:#FFFFFF;text-decoration:none;font-weight:700;padding:14px 22px;border-radius:12px;">
              Autoriser le compte
            </a>
          </p>
          <p style="font-size:13px;">Si le bouton ne fonctionne pas, copiez ce lien :<br>
            <a href="$safeUrl" style="color:#F95C1B;word-break:break-all;">$safeUrl</a>
          </p>
          <p style="font-size:13px;">Si vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.</p>
        </td></tr>
      </table>
    </td></tr>
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
