import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/invitation_config.dart';

/// Queues WhatsApp template messages via Firestore `whatsapp_messages`.
///
/// Processed by Cloud Function `sendWhatsAppOnCreate` (Meta WhatsApp Cloud API).
/// Requires approved message template + Firebase secrets — see
/// `docs/whatsapp-invitations.md`.
class InvitationWhatsAppService {
  InvitationWhatsAppService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'whatsapp_messages';

  final FirebaseFirestore _firestore;

  /// Creates a WhatsApp queue document. Returns `null` on success, or an error.
  Future<String?> sendTemplate({
    required String toPhoneE164,
    required String templateName,
    required String languageCode,
    required List<String> bodyParameters,
    String? clubId,
    String? invitationId,
    String? invitationCode,
    String kind = 'member_invitation',
  }) async {
    final String to = toPhoneE164.trim();
    if (to.isEmpty) {
      return 'emptyPhone';
    }

    final String resolvedClubId = clubId?.trim().isNotEmpty == true
        ? clubId!.trim()
        : InvitationConfig.grintaInvitationClubId;

    final Map<String, dynamic> payload = <String, dynamic>{
      'to': to,
      'templateName': templateName.trim(),
      'languageCode': languageCode.trim(),
      'bodyParameters': bodyParameters,
      'clubId': resolvedClubId,
      'kind': kind,
      if (invitationId != null && invitationId.trim().isNotEmpty)
        'invitationId': invitationId.trim(),
      if (invitationCode != null && invitationCode.trim().isNotEmpty)
        'invitationCode': invitationCode.trim(),
    };

    try {
      debugPrint(
        'InvitationWhatsAppService.sendTemplate to=$to '
        'template=${templateName.trim()} lang=${languageCode.trim()} '
        'params=${bodyParameters.length} collection=$collectionName',
      );
      await _firestore.collection(collectionName).add(payload);
      return null;
    } catch (e, st) {
      debugPrint('InvitationWhatsAppService.sendTemplate failed: to=$to $e\n$st');
      return e.toString();
    }
  }
}
