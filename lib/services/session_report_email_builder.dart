import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/services/invitation_email_builder.dart';

/// Subject, plain-text, and HTML bodies for a session/match stats report email.
class SessionReportEmailContent {
  const SessionReportEmailContent({
    required this.subject,
    required this.text,
    required this.html,
  });

  final String subject;
  final String text;
  final String html;
}

/// Builds Grinta-branded session report emails (same visual charter as invitations).
///
/// Reuses [InvitationRuntimeConfig] (`config/invitation`) for logo, app name,
/// and sender-facing labels. HTML layout mirrors [InvitationEmailBuilder]:
/// gradient header + logo, surface card, footer.
///
/// Prefer providing [pdfDownloadUrl] so the PDF is reachable even when the mail
/// processor does not yet forward SendGrid attachments.
///
/// See `docs/email-sending.md`.
abstract final class SessionReportEmailBuilder {
  static SessionReportEmailContent build({
    required AppLocalizations l10n,
    required InvitationRuntimeConfig config,
    required SessionStatsReport report,
    String? pdfDownloadUrl,
  }) {
    final String appName = config.appDisplayName.trim();
    final String logoUrl = config.logoUrl.trim();
    final String eventLabel = report.isMatch
        ? l10n.sessionReportEmailEventMatch
        : l10n.sessionReportEmailEventTraining;
    final String? downloadUrl = pdfDownloadUrl?.trim();

    final String subject = l10n.sessionReportEmailSubject(
      appName,
      eventLabel,
      report.title,
    );
    final String text = _buildText(
      l10n: l10n,
      appName: appName,
      eventLabel: eventLabel,
      report: report,
      pdfDownloadUrl: downloadUrl,
    );
    final String html = _buildHtml(
      l10n: l10n,
      appName: appName,
      logoUrl: logoUrl,
      eventLabel: eventLabel,
      report: report,
      pdfDownloadUrl: downloadUrl,
    );

    return SessionReportEmailContent(
      subject: subject,
      text: text,
      html: html,
    );
  }

  static String _buildText({
    required AppLocalizations l10n,
    required String appName,
    required String eventLabel,
    required SessionStatsReport report,
    String? pdfDownloadUrl,
  }) {
    final buffer = StringBuffer()
      ..writeln(l10n.sessionReportEmailIntro(appName))
      ..writeln()
      ..writeln('$eventLabel: ${report.title}');
    final dateLabel = report.dateLabel?.trim();
    if (dateLabel != null && dateLabel.isNotEmpty) {
      buffer.writeln(l10n.sessionReportEmailDateLine(dateLabel));
    }
    final teamName = report.teamName?.trim();
    if (teamName != null && teamName.isNotEmpty) {
      buffer.writeln(l10n.sessionReportEmailTeamLine(teamName));
    }
    buffer.writeln(
      l10n.sessionReportEmailPlayersLine(report.playersCount),
    );
    buffer.writeln();
    if (pdfDownloadUrl != null && pdfDownloadUrl.isNotEmpty) {
      buffer.writeln(l10n.sessionReportEmailDownloadHint);
    } else {
      buffer.writeln(l10n.sessionReportEmailAttachmentHint);
    }
    buffer
      ..writeln()
      ..writeln(l10n.sessionReportEmailFooter(appName));
    return buffer.toString().trim();
  }

  static String _buildHtml({
    required AppLocalizations l10n,
    required String appName,
    required String logoUrl,
    required String eventLabel,
    required SessionStatsReport report,
    String? pdfDownloadUrl,
  }) {
    final String intro = _escapeHtml(l10n.sessionReportEmailIntro(appName));
    final String detailsLabel =
        _escapeHtml(l10n.sessionReportEmailDetailsLabel);
    final String footer = _escapeHtml(l10n.sessionReportEmailFooter(appName));
    final String safeAppName = _escapeHtml(appName);
    final String safeLogoUrl = _escapeHtml(logoUrl);
    final String safeTitle = _escapeHtml(report.title);
    final String safeEventLabel = _escapeHtml(eventLabel);
    final bool hasDownload =
        pdfDownloadUrl != null && pdfDownloadUrl.trim().isNotEmpty;
    final String pdfHint = _escapeHtml(
      hasDownload
          ? l10n.sessionReportEmailDownloadHint
          : l10n.sessionReportEmailAttachmentHint,
    );
    final String downloadButtonLabel =
        _escapeHtml(l10n.sessionReportEmailDownloadButton);
    final String safeDownloadUrl =
        hasDownload ? _escapeHtml(pdfDownloadUrl.trim()) : '';

    final detailsRows = StringBuffer()
      ..writeln(_detailRow(l10n.sessionReportEmailTypeLabel, safeEventLabel))
      ..writeln(_detailRow(l10n.sessionReportEmailTitleLabel, safeTitle));

    final dateLabel = report.dateLabel?.trim();
    if (dateLabel != null && dateLabel.isNotEmpty) {
      detailsRows.writeln(
        _detailRow(
          l10n.sessionReportEmailDateLabel,
          _escapeHtml(dateLabel),
        ),
      );
    }
    final teamName = report.teamName?.trim();
    if (teamName != null && teamName.isNotEmpty) {
      detailsRows.writeln(
        _detailRow(
          l10n.sessionReportEmailTeamLabel,
          _escapeHtml(teamName),
        ),
      );
    }
    detailsRows.writeln(
      _detailRow(
        l10n.sessionReportEmailPlayersLabel,
        report.playersCount.toString(),
      ),
    );
    detailsRows.writeln(
      _detailRow(
        l10n.sessionReportEmailAvgWorkloadLabel,
        report.averageWorkloadScore.toStringAsFixed(0),
      ),
    );

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
              $downloadBlock
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

  static String _detailRow(String label, String value) {
    return '''
<tr>
  <td style="padding:6px 0;color:${InvitationEmailBrand.textSecondary};font-size:13px;line-height:1.4;width:40%;vertical-align:top;">${_escapeHtml(label)}</td>
  <td style="padding:6px 0;color:${InvitationEmailBrand.textPrimary};font-size:15px;font-weight:600;line-height:1.4;vertical-align:top;">$value</td>
</tr>
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
