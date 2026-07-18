import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
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

class _UploadedPdf {
  const _UploadedPdf({
    required this.storagePath,
    required this.downloadUrl,
    required this.filename,
  });

  final String storagePath;
  final String downloadUrl;
  final String filename;
}

/// Builds a stats PDF and queues a branded report email (invitation charter).
///
/// Flow:
/// 1. Build report + PDF
/// 2. Upload PDF to Storage (`sessionReports/{uid}/…`)
/// 3. Queue mail with `pdfStoragePath` (Cloud Function attaches from Storage)
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
    String? toEmail,
    List<String>? toEmails,
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
    final List<String> recipients = _normalizeRecipients(
      toEmail: toEmail,
      toEmails: toEmails,
    );
    if (recipients.isEmpty) {
      return SessionReportSendResult.failed('emptyEmail');
    }
    for (final String to in recipients) {
      if (!isValidEmailFormat(to) || to.length < 3 || !_looksLikeEmail(to)) {
        return SessionReportSendResult.failed('invalidEmail');
      }
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

      final _UploadedPdf? uploaded = await _uploadPdf(
        bytes: pdfBytes,
        filename: report.suggestedFileName,
        eventId: report.eventId,
      );

      if (uploaded == null) {
        return SessionReportSendResult.failed('uploadFailed');
      }

      final config = await InvitationConfig.resolve();
      final emailContent = SessionReportEmailBuilder.build(
        l10n: l10n,
        config: config,
        report: report,
        pdfDownloadUrl: uploaded.downloadUrl,
      );

      // Never put large base64 PDFs in Firestore. The Cloud Function loads
      // [pdfStoragePath] from Storage and attaches it for SendGrid.
      // Build/upload once, then queue one mail doc per recipient.
      for (final String to in recipients) {
        final String? sendError = await _emailService.send(
          toEmail: to,
          subject: emailContent.subject,
          text: emailContent.text,
          html: emailContent.html,
          clubId: clubId,
          pdfStoragePath: uploaded.storagePath,
          pdfFilename: uploaded.filename,
          pdfDownloadUrl: uploaded.downloadUrl,
        );

        if (sendError != null) {
          return SessionReportSendResult.failed(sendError);
        }
      }

      return SessionReportSendResult.ok(
        report,
        pdfDownloadUrl: uploaded.downloadUrl,
      );
    } catch (error, stackTrace) {
      debugPrint('SessionReportSenderService.sendReport failed: $error\n$stackTrace');
      return SessionReportSendResult.failed(error.toString());
    }
  }

  static List<String> _normalizeRecipients({
    String? toEmail,
    List<String>? toEmails,
  }) {
    final Set<String> out = <String>{};
    void add(String? raw) {
      final String email = raw?.trim() ?? '';
      if (email.isNotEmpty) {
        out.add(email);
      }
    }

    add(toEmail);
    for (final String email in toEmails ?? const <String>[]) {
      add(email);
    }
    return out.toList(growable: false);
  }

  Future<_UploadedPdf?> _uploadPdf({
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
      debugPrint(
        'SessionReportSenderService: uploaded PDF path=$path '
        'bytes=${bytes.lengthInBytes} url=$url',
      );
      return _UploadedPdf(
        storagePath: path,
        downloadUrl: url,
        filename: safeFilename,
      );
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
