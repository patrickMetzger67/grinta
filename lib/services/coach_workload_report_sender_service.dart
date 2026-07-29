import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/coach_workload_report_pdf_service.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:intl/intl.dart';

class CoachWorkloadReportSendResult {
  const CoachWorkloadReportSendResult({
    required this.success,
    this.error,
    this.pdfDownloadUrl,
  });

  final bool success;
  final String? error;
  final String? pdfDownloadUrl;

  factory CoachWorkloadReportSendResult.ok({String? pdfDownloadUrl}) {
    return CoachWorkloadReportSendResult(
      success: true,
      pdfDownloadUrl: pdfDownloadUrl,
    );
  }

  factory CoachWorkloadReportSendResult.failed(String error) {
    return CoachWorkloadReportSendResult(success: false, error: error);
  }
}

/// Builds the coach workload PDF, uploads it, and queues email via `mail`.
class CoachWorkloadReportSenderService {
  CoachWorkloadReportSenderService({
    CoachWorkloadReportPdfService? pdfService,
    InvitationEmailService? emailService,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _pdfService = pdfService ?? CoachWorkloadReportPdfService(),
        _emailService = emailService ?? InvitationEmailService(),
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final CoachWorkloadReportSenderService instance =
      CoachWorkloadReportSenderService();

  final CoachWorkloadReportPdfService _pdfService;
  final InvitationEmailService _emailService;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<CoachWorkloadReportSendResult> sendReport({
    required AppLocalizations l10n,
    required List<String> toEmails,
    required CoachTeamWorkloadReport report,
    required String teamName,
    required String teamId,
    required DateTime rangeStart,
    required DateTime rangeEndInclusive,
    String localeCode = 'fr',
    String? clubId,
  }) async {
    final recipients = <String>{
      for (final email in toEmails)
        if (email.trim().isNotEmpty) email.trim(),
    }.toList(growable: false);

    if (recipients.isEmpty) {
      return CoachWorkloadReportSendResult.failed('emptyEmail');
    }
    for (final to in recipients) {
      if (!isValidEmailFormat(to) ||
          !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
              .hasMatch(to)) {
        return CoachWorkloadReportSendResult.failed('invalidEmail');
      }
    }
    if (report.summaries.isEmpty) {
      return CoachWorkloadReportSendResult.failed('noStats');
    }

    try {
      final pdfBytes = await _pdfService.buildPdf(
        report: report,
        teamName: teamName,
        rangeStart: rangeStart,
        rangeEndInclusive: rangeEndInclusive,
        localeCode: localeCode,
      );

      final safeTeam = teamId.trim().isEmpty
          ? 'team'
          : teamId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final filename =
          'grinta_analyse_charge_${safeTeam}_${DateFormat('yyyyMMdd').format(rangeStart)}.pdf';

      final uploaded = await _uploadPdf(
        bytes: pdfBytes,
        filename: filename,
        teamId: safeTeam,
      );
      if (uploaded == null) {
        return CoachWorkloadReportSendResult.failed('uploadFailed');
      }

      final config = await InvitationConfig.resolve();
      final periodLabel =
          '${DateFormat.yMMMd(localeCode).format(rangeStart)} – '
          '${DateFormat.yMMMd(localeCode).format(rangeEndInclusive)}';
      final subject = l10n.coachWorkloadReportEmailSubject(teamName, periodLabel);
      final text = l10n.coachWorkloadReportEmailText(
        teamName,
        periodLabel,
        uploaded.downloadUrl,
      );
      final html = '''
<!DOCTYPE html>
<html>
<body style="font-family:Arial,sans-serif;color:#111214;">
  <p>${_escape(l10n.coachWorkloadReportEmailGreeting)}</p>
  <p>${_escape(l10n.coachWorkloadReportEmailIntro(teamName, periodLabel))}</p>
  <p><a href="${uploaded.downloadUrl}" style="color:#F95C1B;font-weight:700;">
    ${_escape(l10n.coachWorkloadReportEmailDownload)}
  </a></p>
  <p style="color:#6B7280;font-size:12px;">${_escape(config.fromEmail)}</p>
</body>
</html>
''';

      for (final to in recipients) {
        final sendError = await _emailService.send(
          toEmail: to,
          subject: subject,
          text: text,
          html: html,
          clubId: clubId,
          pdfStoragePath: uploaded.storagePath,
          pdfFilename: uploaded.filename,
          pdfDownloadUrl: uploaded.downloadUrl,
        );
        if (sendError != null) {
          return CoachWorkloadReportSendResult.failed(sendError);
        }
      }

      return CoachWorkloadReportSendResult.ok(
        pdfDownloadUrl: uploaded.downloadUrl,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'CoachWorkloadReportSenderService.sendReport failed: $error\n$stackTrace',
      );
      return CoachWorkloadReportSendResult.failed(error.toString());
    }
  }

  Future<_UploadedPdf?> _uploadPdf({
    required Uint8List bytes,
    required String filename,
    required String teamId,
  }) async {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;

    final path =
        'coachWorkloadReports/$uid/${teamId}_${DateTime.now().millisecondsSinceEpoch}_$filename';
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
      return _UploadedPdf(
        storagePath: path,
        downloadUrl: url,
        filename: filename,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'CoachWorkloadReportSenderService: PDF upload failed: $error\n$stackTrace',
      );
      return null;
    }
  }

  static String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
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
