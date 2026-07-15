import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/app_theme.dart';

/// Grinta brand colors for HTML invitation emails (derived from [AppColors.light]).
abstract final class InvitationEmailBrand {
  static final String primary = colorToCssHex(AppColors.light.primary);
  static final String secondary = colorToCssHex(AppColors.light.secondary);
  static final String background = colorToCssHex(AppColors.light.background);
  static final String surface = colorToCssHex(AppColors.light.surface);
  static final String textPrimary = colorToCssHex(AppColors.light.textPrimary);
  static final String textSecondary =
      colorToCssHex(AppColors.light.textSecondary);
  static final String border = colorToCssHex(AppColors.light.border);
}

/// Subject, plain-text, and HTML bodies for a member invitation email.
class InvitationEmailContent {
  const InvitationEmailContent({
    required this.subject,
    required this.text,
    required this.html,
  });

  final String subject;
  final String text;
  final String html;
}

/// Builds Grinta-branded invitation email content from l10n + runtime config.
///
/// Runtime values come from [InvitationConfig.resolve] (Firestore `config/invitation`
/// with compile-time defaults as fallback). To change invitation emails without
/// redeploying the app:
///
/// 1. Open Firebase Console → Firestore Database.
/// 2. Create or edit document `config/invitation` (collection `config`, id `invitation`).
/// 3. Set optional string fields: `appDisplayName`, `appleStoreUrl`, `googlePlayUrl`,
///    `logoUrl`, `contactPrefixCode` (legacy alias: `shortClubName` for `appDisplayName`).
/// 4. Empty or missing fields fall back to defaults in [InvitationConfig].
///
/// `logoUrl` must point to a publicly readable image (default: Storage `logoClubs/thumbs/Grinta_1920x1920.png`).
/// See `docs/email-sending.md` for upload and verification steps.
///
/// Seed reference: `firestore/config/invitation.json`.
abstract final class InvitationEmailBuilder {
  static InvitationEmailContent build({
    required AppLocalizations l10n,
    required InvitationRuntimeConfig config,
    required String invitationCode,
  }) {
    final String appName = config.appDisplayName.trim();
    final String code = invitationCode.trim();
    final String appleUrl = config.appleStoreUrl.trim();
    final String playUrl = config.googlePlayUrl.trim();
    final String logoUrl = config.logoUrl.trim();

    final String subject = l10n.invitationEmailSubject(appName);
    final String text = l10n.invitationSmsMessage(
      appName,
      code,
      appleUrl,
      playUrl,
    );
    final String html = _buildHtml(
      l10n: l10n,
      appName: appName,
      code: code,
      appleUrl: appleUrl,
      playUrl: playUrl,
      logoUrl: logoUrl,
    );

    return InvitationEmailContent(
      subject: subject,
      text: text,
      html: html,
    );
  }

  static String _buildHtml({
    required AppLocalizations l10n,
    required String appName,
    required String code,
    required String appleUrl,
    required String playUrl,
    required String logoUrl,
  }) {
    final String intro = _escapeHtml(l10n.invitationEmailIntro(appName));
    final String codeLabel = _escapeHtml(l10n.invitationEmailCodeLabel);
    final String iosLabel = _escapeHtml(l10n.invitationEmailDownloadIos);
    final String androidLabel =
        _escapeHtml(l10n.invitationEmailDownloadAndroid);
    final String footer = _escapeHtml(l10n.invitationEmailFooter(appName));
    final String safeCode = _escapeHtml(code);
    final String safeAppleUrl = _escapeHtml(appleUrl);
    final String safePlayUrl = _escapeHtml(playUrl);
    final String safeLogoUrl = _escapeHtml(logoUrl);

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$intro</title>
</head>
<body style="margin:0;padding:0;background-color:${InvitationEmailBrand.background};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:${InvitationEmailBrand.background};padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:560px;background-color:${InvitationEmailBrand.surface};border:1px solid ${InvitationEmailBrand.border};border-radius:16px;overflow:hidden;">
          <tr>
            <td style="background:linear-gradient(135deg,${InvitationEmailBrand.primary} 0%,${InvitationEmailBrand.secondary} 100%);padding:28px 32px;text-align:center;">
              <img src="$safeLogoUrl" alt="$appName" width="160" style="display:block;margin:0 auto 12px;max-width:160px;height:auto;border:0;" />
              <p style="margin:0;color:#FFFFFF;font-size:18px;font-weight:600;line-height:1.4;">$intro</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 16px;color:${InvitationEmailBrand.textSecondary};font-size:14px;line-height:1.5;text-transform:uppercase;letter-spacing:0.08em;font-weight:600;">$codeLabel</p>
              <p style="margin:0 0 28px;color:${InvitationEmailBrand.primary};font-size:36px;font-weight:700;letter-spacing:0.12em;line-height:1.2;">$safeCode</p>
              <table role="presentation" cellspacing="0" cellpadding="0" style="margin:0 0 8px;">
                <tr>
                  <td style="padding-right:12px;padding-bottom:12px;">
                    <a href="$safeAppleUrl" style="display:inline-block;background-color:${InvitationEmailBrand.primary};color:#FFFFFF;text-decoration:none;font-size:14px;font-weight:600;padding:12px 20px;border-radius:999px;">$iosLabel</a>
                  </td>
                  <td style="padding-bottom:12px;">
                    <a href="$safePlayUrl" style="display:inline-block;background-color:${InvitationEmailBrand.textPrimary};color:#FFFFFF;text-decoration:none;font-size:14px;font-weight:600;padding:12px 20px;border-radius:999px;">$androidLabel</a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px;border-top:1px solid ${InvitationEmailBrand.border};">
              <p style="margin:0;color:${InvitationEmailBrand.textSecondary};font-size:12px;line-height:1.6;text-align:center;">$footer</p>
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

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
