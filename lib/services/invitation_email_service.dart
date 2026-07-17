import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';
import 'package:grinta/model/mail_attachment.dart';

/// Queues emails via Firestore `mail` collection (Cloud Function).
///
/// Used for member invitations and session/match PDF reports. Optional
/// [attachments] are base64 payloads consumed by `sendMailOnCreate`.
/// Large PDFs should use [pdfStoragePath] instead so the Cloud Function
/// loads the file from Storage and attaches it server-side.
class InvitationEmailService {
  InvitationEmailService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'mail';

  /// Soft limit so Firestore docs stay under ~1 MiB with base64 PDF.
  static const int maxAttachmentBytes = 700 * 1024;

  final FirebaseFirestore _firestore;

  /// Creates a mail document. Returns `null` on success, or an error message.
  Future<String?> send({
    required String toEmail,
    required String subject,
    required String text,
    required String html,
    String? fromEmail,
    String? replyToEmail,
    String? clubId,
    List<MailAttachment> attachments = const <MailAttachment>[],
    String? pdfStoragePath,
    String? pdfFilename,
    String? pdfDownloadUrl,
  }) async {
    final String to = toEmail.trim();
    if (to.isEmpty) {
      return 'emptyEmail';
    }

    for (final attachment in attachments) {
      final estimatedBytes = (attachment.contentBase64.length * 3) ~/ 4;
      if (estimatedBytes <= 0) {
        return 'emptyAttachment';
      }
      if (estimatedBytes > maxAttachmentBytes) {
        return 'attachmentTooLarge';
      }
    }

    final InvitationRuntimeConfig config = await InvitationConfig.resolve();
    final String resolvedFrom =
        fromEmail?.trim().isNotEmpty == true ? fromEmail!.trim() : config.fromEmail;
    final String resolvedReplyTo = replyToEmail?.trim().isNotEmpty == true
        ? replyToEmail!.trim()
        : config.replyToEmail;
    final String resolvedClubId = clubId?.trim().isNotEmpty == true
        ? clubId!.trim()
        : InvitationConfig.grintaInvitationClubId;

    final String? storagePath = pdfStoragePath?.trim();
    final String? storageFilename = pdfFilename?.trim();
    final String? downloadUrl = pdfDownloadUrl?.trim();

    final Map<String, dynamic> payload = {
      'to': to,
      'from': resolvedFrom,
      'replyTo': resolvedReplyTo,
      'clubId': resolvedClubId,
      'message': {
        'subject': subject,
        'text': text,
        'html': html,
      },
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toMap()).toList(),
      if (storagePath != null && storagePath.isNotEmpty)
        'pdfStoragePath': storagePath,
      if (storageFilename != null && storageFilename.isNotEmpty)
        'pdfFilename': storageFilename,
      if (downloadUrl != null && downloadUrl.isNotEmpty)
        'pdfDownloadUrl': downloadUrl,
    };

    try {
      debugPrint(
        'InvitationEmailService.send to=$to subject=$subject '
        'from=$resolvedFrom replyTo=$resolvedReplyTo clubId=$resolvedClubId '
        'attachments=${attachments.length} '
        'pdfStoragePath=${storagePath ?? '-'} '
        'collection=$collectionName',
      );
      await _firestore.collection(collectionName).add(payload);
      return null;
    } catch (e, st) {
      debugPrint('InvitationEmailService.send failed: to=$to $e\n$st');
      return e.toString();
    }
  }
}
