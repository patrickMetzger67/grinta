import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/mail_attachment.dart';
import 'package:grinta/model/match.dart' as grinta_match;
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
    this.pdfDownloadUrl,
  });

  final bool success;
  final String? error;
  final SessionStatsReport? report;
  final String? pdfDownloadUrl;

  factory SessionReportSendResult.ok(
    SessionStatsReport report, {
    String? pdfDownloadUrl,
  }) {
    return SessionReportSendResult(
      success: true,
      report: report,
      pdfDownloadUrl: pdfDownloadUrl,
    );
  }

  factory SessionReportSendResult.failed(String error) {
    return SessionReportSendResult(success: false, error: error);
  }
}

/// Builds a stats PDF and queues a branded report email (invitation charter).
///
/// Flow:
/// 1. Build report + PDF
/// 2. Upload PDF to Storage (`sessionReports/…`) for a public download link
/// 3. Queue mail via [InvitationEmailService] with attachment + link in HTML
/// 4. Cloud Function `sendMailOnCreate` delivers via SendGrid
class SessionReportSenderService {
  SessionReportSenderService({
    SessionStatsReportService? reportService,
    SessionStatsReportPdfService? pdfService,
    InvitationEmailService? emailService,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _reportService = reportService ?? SessionStatsReportService(),
        _pdfService = pdfService ?? SessionStatsReportPdfService(),
        _emailService = emailService ?? InvitationEmailService(),
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final SessionReportSenderService instance =
      SessionReportSenderService();

  final SessionStatsReportService _reportService;
  final SessionStatsReportPdfService _pdfService;
  final InvitationEmailService _emailService;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<SessionReportSendResult> sendReport({
    required AppLocalizations l10n,
    required String toEmail,
    required String eventId,
    required bool isMatch,
    String? title,
    String? subtitle,
    String? teamName,
    String? teamId,
    DateTime? eventDate,
    String localeCode = 'fr',
    TeamWorkloadSummary? summary,
    String? clubId,
    grinta_match.Match? match,
  }) async {
    final String to = toEmail.trim();
    if (to.isEmpty) {
      return SessionReportSendResult.failed('emptyEmail');
    }
    if (!isValidEmailFormat(to) || to.length < 3) {
      return SessionReportSendResult.failed('invalidEmail');
    }
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
        teamId: teamId,
        eventDate: eventDate,
        localeCode: localeCode,
        unknownPlayerLabel: l10n.entityPlayer,
        summary: summary,
        match: match,
      );

      if (report == null) {
        return SessionReportSendResult.failed('noStats');
      }

      final Uint8List pdfBytes = await _pdfService.buildPdf(
        report,
        localeCode: localeCode,
      );

      final String? pdfDownloadUrl = await _uploadPdf(
        bytes: pdfBytes,
        filename: report.suggestedFileName,
        eventId: report.eventId,
      );

      // Firestore mail docs must stay under ~1 MiB; large multi-player PDFs
      // (heatmaps) are delivered via Storage download link only.
      final bool canAttachInline =
          pdfBytes.lengthInBytes <= InvitationEmailService.maxAttachmentBytes;
      final List<MailAttachment> attachments = canAttachInline
          ? <MailAttachment>[
              MailAttachment.fromBytes(
                filename: report.suggestedFileName,
                bytes: pdfBytes,
              ),
            ]
          : const <MailAttachment>[];

      if (!canAttachInline &&
          (pdfDownloadUrl == null || pdfDownloadUrl.trim().isEmpty)) {
        debugPrint(
          'SessionReportSenderService: PDF too large for mail attachment '
          '(${pdfBytes.lengthInBytes} bytes) and Storage upload unavailable',
        );
        return SessionReportSendResult.failed('attachmentTooLarge');
      }

      if (!canAttachInline) {
        debugPrint(
          'SessionReportSenderService: skipping inline PDF attachment '
          '(${pdfBytes.lengthInBytes} bytes); using Storage link',
        );
      }

      final config = await InvitationConfig.resolve();
      final emailContent = SessionReportEmailBuilder.build(
        l10n: l10n,
        config: config,
        report: report,
        pdfDownloadUrl: pdfDownloadUrl,
      );

      final String? sendError = await _emailService.send(
        toEmail: to,
        subject: emailContent.subject,
        text: emailContent.text,
        html: emailContent.html,
        clubId: clubId,
        attachments: attachments,
      );

      if (sendError != null) {
        return SessionReportSendResult.failed(sendError);
      }

      return SessionReportSendResult.ok(
        report,
        pdfDownloadUrl: pdfDownloadUrl,
      );
    } catch (error, stackTrace) {
      debugPrint('SessionReportSenderService.sendReport failed: $error\n$stackTrace');
      return SessionReportSendResult.failed(error.toString());
    }
  }

  Future<String?> _uploadPdf({
    required Uint8List bytes,
    required String filename,
    required String eventId,
  }) async {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      debugPrint('SessionReportSenderService: no auth uid for PDF upload');
      return null;
    }

    final safeEventId = eventId.trim().isEmpty
        ? 'event'
        : eventId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final safeFilename = filename.trim().isEmpty
        ? 'rapport.pdf'
        : filename.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '_');
    final path =
        'sessionReports/$uid/${safeEventId}_${DateTime.now().millisecondsSinceEpoch}_$safeFilename';

    try {
      final ref = _storage.ref().child(path);
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'application/pdf',
          cacheControl: 'public,max-age=604800',
        ),
      );
      final url = await ref.getDownloadURL();
      debugPrint('SessionReportSenderService: uploaded PDF $path');
      return url;
    } catch (error, stackTrace) {
      debugPrint(
        'SessionReportSenderService: PDF upload failed: $error\n$stackTrace',
      );
      return null;
    }
  }

  static bool _looksLikeEmail(String value) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(value);
  }
}
