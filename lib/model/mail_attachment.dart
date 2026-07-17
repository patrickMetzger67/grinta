import 'dart:convert';
import 'dart:typed_data';

/// Attachment payload queued on a Firestore `mail` document (SendGrid).
class MailAttachment {
  const MailAttachment({
    required this.filename,
    required this.contentBase64,
    this.type = 'application/pdf',
    this.disposition = 'attachment',
  });

  final String filename;
  final String contentBase64;
  final String type;
  final String disposition;

  factory MailAttachment.fromBytes({
    required String filename,
    required Uint8List bytes,
    String type = 'application/pdf',
    String disposition = 'attachment',
  }) {
    return MailAttachment(
      filename: filename,
      contentBase64: base64Encode(bytes),
      type: type,
      disposition: disposition,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'filename': filename,
      'content': contentBase64,
      'type': type,
      'disposition': disposition,
    };
  }
}
