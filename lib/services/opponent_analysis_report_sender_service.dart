import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/invitation_email_service.dart';
import 'package:grinta/services/opponent_analysis_report_data_service.dart';
import 'package:grinta/services/opponent_analysis_report_email_builder.dart';
import 'package:grinta/services/opponent_analysis_report_pdf_service.dart';
import 'package:grinta/util/player_profile_validator.dart';
import 'package:intl/intl.dart';

class OpponentAnalysisReportSendResult {
  const OpponentAnalysisReportSendResult({
    required this.success,
    this.error,
    this.pdfDownloadUrl,
  });

  final bool success;
  final String? error;
  final String? pdfDownloadUrl;

  factory OpponentAnalysisReportSendResult.ok({String? pdfDownloadUrl}) {
    return OpponentAnalysisReportSendResult(
      success: true,
      pdfDownloadUrl: pdfDownloadUrl,
    );
  }

  factory OpponentAnalysisReportSendResult.failed(String error) {
    return OpponentAnalysisReportSendResult(success: false, error: error);
  }
}

class OpponentAnalysisReportSenderService {
  OpponentAnalysisReportSenderService({
    OpponentAnalysisReportPdfService? pdfService,
    InvitationEmailService? emailService,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _pdfService = pdfService ?? OpponentAnalysisReportPdfService(),
        _emailService = emailService ?? InvitationEmailService(),
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static final OpponentAnalysisReportSenderService instance =
      OpponentAnalysisReportSenderService();

  final OpponentAnalysisReportPdfService _pdfService;
  final InvitationEmailService _emailService;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  Future<OpponentAnalysisReportSendResult> sendReport({
    required AppLocalizations l10n,
    required List<String> toEmails,
    required OpponentAnalysisReportData data,
    String localeCode = 'fr',
  }) async {
    final recipients = <String>{
      for (final email in toEmails)
        if (email.trim().isNotEmpty) email.trim(),
    }.toList(growable: false);

    if (recipients.isEmpty) {
      return OpponentAnalysisReportSendResult.failed('emptyEmail');
    }
    for (final to in recipients) {
      if (!isValidEmailFormat(to) ||
          !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
              .hasMatch(to)) {
        return OpponentAnalysisReportSendResult.failed('invalidEmail');
      }
    }

    try {
      final pdfBytes = await _pdfService.buildPdf(
        data: data,
        localeCode: localeCode,
      );

      final safeOpponent = data.opponent.displayName
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
      final filename =
          'grinta_analyse_adversaire_${safeOpponent}_${DateFormat('yyyyMMdd').format(data.upcomingKickoff)}.pdf';

      final uploaded = await _uploadPdf(
        bytes: pdfBytes,
        filename: filename,
      );
      if (uploaded == null) {
        return OpponentAnalysisReportSendResult.failed('uploadFailed');
      }

      final config = await InvitationConfig.resolve();
      final kickoffLabel =
          DateFormat('yyyy-MM-dd HH:mm').format(data.upcomingKickoff);
      final emailContent = OpponentAnalysisReportEmailBuilder.build(
        l10n: l10n,
        config: config,
        teamName: data.teamName,
        opponentName: data.opponent.displayName,
        kickoffLabel: kickoffLabel,
        pdfDownloadUrl: uploaded.downloadUrl,
      );

      for (final to in recipients) {
        final sendError = await _emailService.send(
          toEmail: to,
          subject: emailContent.subject,
          text: emailContent.text,
          html: emailContent.html,
          clubId: data.team.clubId,
          pdfStoragePath: uploaded.storagePath,
          pdfFilename: uploaded.filename,
          pdfDownloadUrl: uploaded.downloadUrl,
        );
        if (sendError != null) {
          return OpponentAnalysisReportSendResult.failed(sendError);
        }
      }

      return OpponentAnalysisReportSendResult.ok(
        pdfDownloadUrl: uploaded.downloadUrl,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'OpponentAnalysisReportSenderService.sendReport failed: $error\n$stackTrace',
      );
      return OpponentAnalysisReportSendResult.failed(error.toString());
    }
  }

  Future<_UploadedPdf?> _uploadPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) return null;

    final path =
        'sessionReports/$uid/opponent_analysis_${DateTime.now().millisecondsSinceEpoch}_$filename';
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
        'OpponentAnalysisReportSenderService: PDF upload failed: $error\n$stackTrace',
      );
      return null;
    }
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
