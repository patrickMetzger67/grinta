import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/mail_attachment.dart';
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/services/session_report_email_builder.dart';
import 'package:grinta/services/session_stats_report_pdf_service.dart';
import 'package:grinta/services/session_stats_report_service.dart';
import 'package:grinta/util/player_profile_validator.dart';

/// Outcome of [SessionReportSenderService.sendReport].
class SessionReportSendResult {
  const SessionReportSendResult({
    required this.success,
    this.error,
    this.report,
  });

  final bool success;
  final String? error;
  final SessionStatsReport? report;

  factory SessionReportSendResult.ok(SessionStatsReport report) {
    return SessionReportSendResult(success: true, report: report);
  }

  factory SessionReportSendResult.failed(String error) {
    return SessionReportSendResult(success: false, error: error);
  }
}

/// Builds a stats PDF and queues a branded report email (invitation charter).
///
/// Flow mirrors member invitations:
/// 1. Build content ([SessionReportEmailBuilder] + PDF)
/// 2. Queue via [InvitationEmailService] → Firestore `mail`
/// 3. Cloud Function `sendMailOnCreate` delivers via SendGrid (with attachment)
class SessionReportSenderService {
  SessionReportSenderService({
    SessionStatsReportService? reportService,
    SessionStatsReportPdfService? pdfService,
    InvitationEmailService? emailService,
  })  : _reportService = reportService ?? SessionStatsReportService(),
        _pdfService = pdfService ?? SessionStatsReportPdfService(),
        _emailService = emailService ?? InvitationEmailService();

  static final SessionReportSenderService instance =
      SessionReportSenderService();

  final SessionStatsReportService _reportService;
  final SessionStatsReportPdfService _pdfService;
  final InvitationEmailService _emailService;

  Future<SessionReportSendResult> sendReport({
    required AppLocalizations l10n,
    required String toEmail,
    required String eventId,
    required bool isMatch,
    String? title,
    String? subtitle,
    String? teamName,
    DateTime? eventDate,
    String localeCode = 'fr',
    TeamWorkloadSummary? summary,
    String? clubId,
  }) async {
    final String to = toEmail.trim();
    if (to.isEmpty) {
      return SessionReportSendResult.failed('emptyEmail');
    }
    if (!isValidEmailFormat(to) || to.length < 3) {
      return SessionReportSendResult.failed('invalidEmail');
    }
    // [isValidEmailFormat] treats empty as valid; require a real address here.
    if (!_looksLikeEmail(to)) {
      return SessionReportSendResult.failed('invalidEmail');
    }

    try {
      final report = await _reportService.buildReport(
        eventId: eventId,
        isMatch: isMatch,
        title: title,
        subtitle: subtitle,
        teamName: teamName,
        eventDate: eventDate,
        localeCode: localeCode,
        unknownPlayerLabel: l10n.entityPlayer,
        summary: summary,
      );

      if (report == null) {
        return SessionReportSendResult.failed('noStats');
      }

      final Uint8List pdfBytes = await _pdfService.buildPdf(
        report,
        localeCode: localeCode,
      );

      final config = await InvitationConfig.resolve();
      final emailContent = SessionReportEmailBuilder.build(
        l10n: l10n,
        config: config,
        report: report,
      );

      final attachment = MailAttachment.fromBytes(
        filename: report.suggestedFileName,
        bytes: pdfBytes,
      );

      final String? sendError = await _emailService.send(
        toEmail: to,
        subject: emailContent.subject,
        text: emailContent.text,
        html: emailContent.html,
        clubId: clubId,
        attachments: <MailAttachment>[attachment],
      );

      if (sendError != null) {
        return SessionReportSendResult.failed(sendError);
      }

      return SessionReportSendResult.ok(report);
    } catch (error, stackTrace) {
      debugPrint('SessionReportSenderService.sendReport failed: $error\n$stackTrace');
      return SessionReportSendResult.failed(error.toString());
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
  }
}
