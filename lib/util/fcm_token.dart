import 'package:grinta/config/fcm_config.dart';
import 'package:grinta/model/user.dart' show keyUserGrintaTokens;
import 'package:grinta/util/chat_fcm_notification.dart';

/// Raw APNs device tokens are 32 bytes hex-encoded (64 chars).
/// FCM registration tokens are longer and typically contain `:APA91`.
final RegExp _apnsDeviceTokenPattern = RegExp(r'^[0-9a-fA-F]{64}$');

/// True when [token] looks like an APNs device token, not an FCM token.
///
/// Sending an APNs token through `sendEachForMulticast` fails with
/// `invalid-registration-token` and never reaches the iOS lock screen.
bool isLikelyApnsDeviceToken(String token) {
  return _apnsDeviceTokenPattern.hasMatch(token.trim());
}

/// True when [token] can be passed to FCM (non-empty, not a raw APNs token).
bool isSendableFcmRegistrationToken(String token) {
  final trimmed = token.trim();
  if (trimmed.isEmpty) return false;
  return !isLikelyApnsDeviceToken(trimmed);
}

/// Resolves the FCM token stored on a `users/{uid}/fcmTokens` document.
///
/// Prefers `data.token` (written by current clients) and falls back to the
/// document id (legacy path used by Android / web / older iOS builds).
String? fcmTokenFromFirestoreDoc({
  required String id,
  Map<String, dynamic>? data,
}) {
  return firstNonEmptyText([
    data?['token']?.toString(),
    id,
  ]);
}

bool _isAsersteinPackage(String packageName) {
  final lower = packageName.trim().toLowerCase();
  if (lower.isEmpty) return false;
  if (lower == FcmConfig.asersteinAndroidPackage.toLowerCase()) return true;
  return lower.contains('aserstein');
}

bool _isGrintaPackage(String packageName) {
  final lower = packageName.trim().toLowerCase();
  if (lower.isEmpty) return false;
  return lower == FcmConfig.grintaPackageName.toLowerCase();
}

bool _docLooksLikeAserstein(Map<String, dynamic> data) {
  final app = data['app']?.toString().trim().toLowerCase() ?? '';
  if (app == FcmConfig.brandAserstein) return true;
  return _isAsersteinPackage(data['packageName']?.toString() ?? '');
}

bool _isExplicitGrintaDoc(Map<String, dynamic> data) {
  if (_docLooksLikeAserstein(data)) return false;
  final app = data['app']?.toString().trim().toLowerCase() ?? '';
  if (app == FcmConfig.brandGrinta) return true;
  return _isGrintaPackage(data['packageName']?.toString() ?? '');
}

/// Deduped sendable FCM registration tokens from a raw Firestore list.
List<String> sendableFcmTokensFromList(Iterable<dynamic>? raw) {
  if (raw == null) return const [];
  final tokens = <String>{};
  for (final entry in raw) {
    final token = entry?.toString().trim() ?? '';
    if (!isSendableFcmRegistrationToken(token)) continue;
    tokens.add(token);
  }
  return tokens.toList();
}

/// Parses `users/{uid}.grintaTokens` from a user document map.
List<String> grintaTokensFromUserMap(Map<String, dynamic>? map) {
  if (map == null) return const [];
  final raw = map[keyUserGrintaTokens];
  return sendableFcmTokensFromList(raw is List ? raw : null);
}

/// Grinta FCM send list: prefer `users.grintaTokens`, else explicit subcollection.
///
/// Fallback is for old clients that have not opened Grinta since the field
/// was added. Aserstein-tagged subcollection tokens are never used.
List<String> resolveGrintaSendTokens({
  List<dynamic>? grintaTokens,
  List<String> subcollectionTokens = const [],
}) {
  final fromUser = sendableFcmTokensFromList(grintaTokens);
  if (fromUser.isNotEmpty) return fromUser;
  return sendableFcmTokensFromList(subcollectionTokens);
}

/// Collects Grinta FCM registration tokens from `fcmTokens` documents.
///
/// Only `app: grinta` or `packageName: io.grinta.app`. Untagged leftovers on
/// the shared Firebase project are often the AS Erstein app: sending to them
/// makes the OS show AS Erstein's **name and launcher icon**. Used as fallback
/// when `users/{uid}.grintaTokens` is missing or empty.
List<String> collectGrintaFcmTokens(
  Iterable<({String id, Map<String, dynamic> data})> docs,
) {
  final tokens = <String>{};
  for (final doc in docs) {
    if (!_isExplicitGrintaDoc(doc.data)) continue;
    final token = fcmTokenFromFirestoreDoc(id: doc.id, data: doc.data);
    if (token == null || !isSendableFcmRegistrationToken(token)) continue;
    tokens.add(token);
  }
  return tokens.toList();
}

/// Aserstein tokens on the shared project (never register these with Stream
/// for a Grinta user — Stream would show the banner as AS Erstein).
List<String> collectAsersteinFcmTokens(
  Iterable<({String id, Map<String, dynamic> data})> docs,
) {
  final tokens = <String>{};
  for (final doc in docs) {
    if (!_docLooksLikeAserstein(doc.data)) continue;
    final token = fcmTokenFromFirestoreDoc(id: doc.id, data: doc.data);
    if (token == null || !isSendableFcmRegistrationToken(token)) continue;
    tokens.add(token);
  }
  return tokens.toList();
}

/// Outgoing chat FCM should run whenever there are peer user ids.
///
/// The Cloud Function loads `users/{uid}.grintaTokens` (then explicit
/// `fcmTokens`) with admin rights, so an empty client-side token list must not
/// skip the send (typical when the recipient's iOS token was registered after
/// the sender's last read).
bool shouldCallChatPushCloudFunction({
  required Iterable<String> peerUserIds,
}) {
  return peerUserIds.any((id) => id.trim().isNotEmpty);
}
