import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore key for Grinta FCM registration tokens on `users/{uid}`.
const String keyUserGrintaTokens = 'grintaTokens';

/// Firestore `users/{uid}` document (Grinta-owned fields used by push).
///
/// [grintaTokens] is the source of truth for Grinta FCM delivery. The shared
/// `users/{uid}/fcmTokens` subcollection also holds AS Erstein devices.
class User {
  String uid;

  /// FCM registration tokens for the Grinta app (`io.grinta.app`).
  List<dynamic>? grintaTokens;

  User({
    this.uid = '',
    this.grintaTokens,
  });

  User.fromMap(Map<String, dynamic>? map, {this.uid = ''}) {
    final raw = map?[keyUserGrintaTokens];
    if (raw is List) {
      grintaTokens = List<dynamic>.from(raw);
    } else {
      grintaTokens = null;
    }
  }

  User.fromDocumentSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(_dataMap(snapshot.data()), uid: snapshot.id);

  static Map<String, dynamic>? _dataMap(Object? data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      keyUserGrintaTokens: grintaTokens ?? <dynamic>[],
    };
  }
}
