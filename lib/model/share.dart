import 'package:cloud_firestore/cloud_firestore.dart';

String keyShareUserId = 'userId';
String keyShareShareAt = 'shareAt';
String keyShareWhere = 'where';
String keySharePlatformShareId = 'platformShareId';
String keyShareStatId = 'statId';
String keyShareStatType = 'statType';
String keyShareStatus = 'status';
String keyShareViews = 'views';
String keyShareInteractions = 'interactions';
String keyShareLastSyncedAt = 'lastSyncedAt';
String keySharePostUrl = 'postUrl';
String keyShareError = 'error';

abstract final class ShareStatType {
  static const sessionSynthesis = 'session_synthesis';
  static const seasonSummary = 'season_summary';
  static const sessionAverages = 'session_averages';
}

abstract final class ShareStatus {
  static const shared = 'shared';
}

/// Firestore `share` (singular — same convention as [Team], [Season], [Ranking]).
///
/// [platformShareId] is a Graph `media_id` / `post_id` after Meta API publish,
/// or the native share-sheet activity type (WhatsApp, etc.) otherwise.
/// Snapchat is out of scope for insights.
///
/// Named `Share` like other collection models. Import `share_plus` with
/// `hide Share` (or a prefix) if both are needed in the same file.
class Share {
  String userId;
  Timestamp? shareAt;
  String where;
  String? platformShareId;
  String statId;
  String statType;
  String status;
  int views;
  int interactions;
  Timestamp? lastSyncedAt;
  String? postUrl;
  String? error;
  DocumentReference? ref;

  Share({
    required this.userId,
    this.shareAt,
    required this.where,
    this.platformShareId,
    required this.statId,
    required this.statType,
    this.status = ShareStatus.shared,
    this.views = 0,
    this.interactions = 0,
    this.lastSyncedAt,
    this.postUrl,
    this.error,
    this.ref,
  });

  Share.fromMap(Map<String, dynamic>? map, {this.ref})
      : userId = _asString(map?[keyShareUserId]),
        shareAt = _asTimestamp(map?[keyShareShareAt]),
        where = _asString(map?[keyShareWhere]),
        platformShareId = _asOptionalString(map?[keySharePlatformShareId]),
        statId = _asString(map?[keyShareStatId]),
        statType = _asString(map?[keyShareStatType]),
        status = _asString(map?[keyShareStatus], ShareStatus.shared),
        views = _asInt(map?[keyShareViews]),
        interactions = _asInt(map?[keyShareInteractions]),
        lastSyncedAt = _asTimestamp(map?[keyShareLastSyncedAt]),
        postUrl = _asOptionalString(map?[keySharePostUrl]),
        error = _asOptionalString(map?[keyShareError]);

  factory Share.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    return Share.fromMap(
      snapshot.data() as Map<String, dynamic>?,
      ref: snapshot.reference,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyShareUserId: userId,
      if (shareAt != null) keyShareShareAt: shareAt,
      keyShareWhere: where,
      if (platformShareId != null && platformShareId!.trim().isNotEmpty)
        keySharePlatformShareId: platformShareId!.trim(),
      keyShareStatId: statId,
      keyShareStatType: statType,
      keyShareStatus: status,
      keyShareViews: views,
      keyShareInteractions: interactions,
      if (lastSyncedAt != null) keyShareLastSyncedAt: lastSyncedAt,
      if (postUrl != null && postUrl!.trim().isNotEmpty)
        keySharePostUrl: postUrl!.trim(),
      if (error != null && error!.trim().isNotEmpty) keyShareError: error!.trim(),
    };
  }

  /// Client create payload: server `shareAt`, counts at 0, no `lastSyncedAt`.
  Map<String, dynamic> toCreateMap() {
    return <String, dynamic>{
      keyShareUserId: userId,
      keyShareShareAt: FieldValue.serverTimestamp(),
      keyShareWhere: where,
      if (platformShareId != null && platformShareId!.trim().isNotEmpty)
        keySharePlatformShareId: platformShareId!.trim(),
      keyShareStatId: statId,
      keyShareStatType: statType,
      keyShareStatus: status.isEmpty ? ShareStatus.shared : status,
      keyShareViews: 0,
      keyShareInteractions: 0,
    };
  }

  @override
  String toString() {
    return 'Share: userId=$userId shareAt=$shareAt where=$where '
        'platformShareId=$platformShareId statId=$statId statType=$statType '
        'status=$status views=$views interactions=$interactions '
        'lastSyncedAt=$lastSyncedAt postUrl=$postUrl error=$error';
  }
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _asOptionalString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

Timestamp? _asTimestamp(dynamic value) {
  if (value is Timestamp) return value;
  return null;
}
