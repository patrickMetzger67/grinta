import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-readable Meta connection state (no tokens).
class MetaSyncConfig {
  const MetaSyncConfig({
    required this.connected,
    this.connectedAt,
    this.pageName,
    this.instagramUsername,
    this.hasInstagram = false,
    this.hasFacebookPage = false,
  });

  final bool connected;
  final DateTime? connectedAt;
  final String? pageName;
  final String? instagramUsername;
  final bool hasInstagram;
  final bool hasFacebookPage;

  /// API publish is available only after a successful OAuth connect.
  bool get canPublish => connected && (hasInstagram || hasFacebookPage);

  factory MetaSyncConfig.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return MetaSyncConfig(
      connected: data['connected'] == true,
      connectedAt: _readTimestamp(data['connectedAt']),
      pageName: _asOptionalString(data['pageName']),
      instagramUsername: _asOptionalString(data['instagramUsername']),
      hasInstagram: data['hasInstagram'] == true,
      hasFacebookPage: data['hasFacebookPage'] == true,
    );
  }

  factory MetaSyncConfig.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return MetaSyncConfig.fromMap(doc.data());
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

String? _asOptionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
