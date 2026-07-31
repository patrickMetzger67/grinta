import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/invitation_email_builder.dart';

class OpponentAnalysisReportEmailContent {
  const OpponentAnalysisReportEmailContent({
    required this.subject,
    required this.text,
    required this.html,
  });

  final String subject;
  final String text;
  final String html;
}

/// Grinta-branded email for the opponent analysis PDF report.
abstract final class OpponentAnalysisReportEmailBuilder {
  static OpponentAnalysisReportEmailContent build({
    required AppLocalizations l10n,
    required InvitationRuntimeConfig config,
    required String teamName,
    required String opponentName,
    required String kickoffLabel,
    String? pdfDownloadUrl,
  }) {
    final appName = config.appDisplayName.trim();
    final logoUrl = config.logoUrl.trim();
    final reportLabel = l10n.opponentAnalysisReportTitle;
    final downloadUrl = pdfDownloadUrl?.trim();

    final subject = '$appName — $reportLabel : $opponentName';
    final text = _buildText(
      l10n: l10n,
      appName: appName,
      reportLabel: reportLabel,
      teamName: teamName,
      opponentName: opponentName,
      kickoffLabel: kickoffLabel,
      pdfDownloadUrl: downloadUrl,
    );
    final html = _buildHtml(
      l10n: l10n,
      appName: appName,
      logoUrl: logoUrl,
      reportLabel: reportLabel,
      teamName: teamName,
      opponentName: opponentName,
      kickoffLabel: kickoffLabel,
      pdfDownloadUrl: downloadUrl,
    );

    return OpponentAnalysisReportEmailContent(
      subject: subject,
      text: text,
      html: html,
    );
  }

  static String _buildText({
    required AppLocalizations l10n,
    required String appName,
    required String reportLabel,
    required String teamName,
    required String opponentName,
    required String kickoffLabel,
    String? pdfDownloadUrl,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        l10n.opponentAnalysisReportEmailIntro(opponentName, kickoffLabel),
      )
      ..writeln()
      ..writeln(reportLabel)
      ..writeln(l10n.sessionReportEmailTeamLine(teamName))
      ..writeln('${l10n.sessionReportEmailDateLabel}: $kickoffLabel')
      ..writeln()
      ..writeln(l10n.opponentAnalysisReportEmailIncludes);
    if (pdfDownloadUrl != null && pdfDownloadUrl.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.sessionReportEmailDownloadHint)
        ..writeln(l10n.sessionReportEmailDownloadLine(pdfDownloadUrl));
    } else {
      buffer
        ..writeln()
        ..writeln(l10n.sessionReportEmailAttachmentHint);
    }
    buffer
      ..writeln()
      ..writeln(l10n.sessionReportEmailFooter(appName));
    return buffer.toString().trim();
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _detailRow(String label, String value) {
    return '''
                <tr>
                  <td style="padding:8px 0;color:${InvitationEmailBrand.textSecondary};font-size:13px;width:40%;vertical-align:top;">${_escapeHtml(label)}</td>
                  <td style="padding:8px 0;color:${InvitationEmailBrand.textPrimary};font-size:14px;font-weight:600;vertical-align:top;">$value</td>
                </tr>
''';
  }

  static String _buildHtml({
    required AppLocalizations l10n,
    required String appName,
    required String logoUrl,
    required String reportLabel,
    required String teamName,
    required String opponentName,
    required String kickoffLabel,
    String? pdfDownloadUrl,
  }) {
    final intro = _escapeHtml(
      l10n.opponentAnalysisReportEmailIntro(opponentName, kickoffLabel),
    );
    final detailsLabel = _escapeHtml(l10n.sessionReportEmailDetailsLabel);
    final footer = _escapeHtml(l10n.sessionReportEmailFooter(appName));
    final safeAppName = _escapeHtml(appName);
    final safeLogoUrl = _escapeHtml(logoUrl);
    final hasDownload =
        pdfDownloadUrl != null && pdfDownloadUrl.trim().isNotEmpty;
    final pdfHint = _escapeHtml(
      hasDownload
          ? l10n.sessionReportEmailDownloadHint
          : l10n.sessionReportEmailAttachmentHint,
    );
    final downloadButtonLabel =
        _escapeHtml(l10n.sessionReportEmailDownloadButton);
    final safeDownloadUrl =
        hasDownload ? _escapeHtml(pdfDownloadUrl.trim()) : '';

    final detailsRows = StringBuffer()
      ..writeln(_detailRow(l10n.sessionReportEmailTypeLabel, _escapeHtml(reportLabel)))
      ..writeln(
        _detailRow(l10n.sessionReportEmailTeamLabel, _escapeHtml(teamName)),
      )
      ..writeln(
        _detailRow(
          l10n.opponentAnalysisReportOpponentLabel,
          _escapeHtml(opponentName),
        ),
      )
      ..writeln(
        _detailRow(l10n.sessionReportEmailDateLabel, _escapeHtml(kickoffLabel)),
      );

    final includes = _escapeHtml(l10n.opponentAnalysisReportEmailIncludes);

    final downloadBlock = hasDownload
        ? '''
              <p style="margin:0 0 16px;color:${InvitationEmailBrand.textPrimary};font-size:15px;line-height:1.6;">$pdfHint</p>
              <a href="$safeDownloadUrl" target="_blank" rel="noopener noreferrer" style="display:inline-block;background-color:${InvitationEmailBrand.primary};color:#FFFFFF;text-decoration:none;font-size:14px;font-weight:600;padding:12px 20px;border-radius:999px;">$downloadButtonLabel</a>
'''
        : '''
              <p style="margin:0;color:${InvitationEmailBrand.textPrimary};font-size:15px;line-height:1.6;">$pdfHint</p>
''';

    return '''
<!DOCTYPE html>
<html lang="fr">
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
              <img src="$safeLogoUrl" alt="$safeAppName" width="160" style="display:block;margin:0 auto 12px;max-width:160px;height:auto;border:0;" />
              <p style="margin:0;color:#FFFFFF;font-size:18px;font-weight:600;line-height:1.4;">$intro</p>
            </td>
          </tr>
          <tr>
            <td style="padding:32px;">
              <p style="margin:0 0 16px;color:${InvitationEmailBrand.textSecondary};font-size:14px;line-height:1.5;text-transform:uppercase;letter-spacing:0.08em;font-weight:600;">$detailsLabel</p>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:0 0 24px;">
                ${detailsRows.toString()}
              </table>
              <p style="margin:0 0 16px;color:${InvitationEmailBrand.textPrimary};font-size:15px;line-height:1.6;">$includes</p>
              $downloadBlock
            </td>
          </tr>
          <tr>
            <td style="padding:20px 32px 28px;border-top:1px solid ${InvitationEmailBrand.border};">
              <p style="margin:0;color:${InvitationEmailBrand.textSecondary};font-size:12px;line-height:1.5;">$footer</p>
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
}
