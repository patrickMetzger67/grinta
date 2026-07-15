import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';

/// Queues invitation emails via Firestore `mail` collection (Cloud Function).
class InvitationEmailService {
  InvitationEmailService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'mail';

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
  }) async {
    final String to = toEmail.trim();
    if (to.isEmpty) {
      return 'emptyEmail';
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
    };

    try {
      debugPrint(
        'InvitationEmailService.send to=$to subject=$subject '
        'from=$resolvedFrom replyTo=$resolvedReplyTo clubId=$resolvedClubId '
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
