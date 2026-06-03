import 'dart:async' show Future, StreamSubscription, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Enforces a single active app session per Firebase user (cross-device).
///
/// ## Firestore schema
/// Document: `users/{firebaseUid}/app_state/session`
/// ```json
/// {
///   "sessionId": "uuid-v4",
///   "platform": "web|ios|android|...",
///   "updatedAt": "<server timestamp>"
/// }
/// ```
///
/// ## Security rules (expected, not in repo)
/// ```
/// match /users/{userId}/app_state/{docId} {
///   allow read, write: if request.auth != null && request.auth.uid == userId;
/// }
/// ```
class ActiveSessionService {
  ActiveSessionService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  static final ActiveSessionService instance = ActiveSessionService._();

  static const Uuid _uuid = Uuid();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _localSessionId;
  String? _activeUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;
  Future<void>? _claimFuture;
  bool _isForceLoggingOut = false;
  bool _forcedLogoutDueToRemoteSession = false;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('session');

  void _onAuthStateChanged(User? user) {
    final String? uid = user?.uid;
    if (uid == _activeUid) return;

    _stopListening();
    _localSessionId = null;
    _activeUid = null;
    _claimFuture = null;

    if (uid != null) {
      unawaited(ensureSessionActive());
    }
  }

  /// True once after a remote session replaced this device; cleared by
  /// [consumeForcedLogoutDueToRemoteSession].
  bool consumeForcedLogoutDueToRemoteSession() {
    if (!_forcedLogoutDueToRemoteSession) return false;
    _forcedLogoutDueToRemoteSession = false;
    return true;
  }

  Future<void> ensureSessionActive() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (_activeUid == uid &&
        _localSessionId != null &&
        _sessionSub != null &&
        _claimFuture == null) {
      return;
    }

    _claimFuture ??= _claimSession(uid);
    try {
      await _claimFuture;
    } finally {
      if (_claimFuture != null && _activeUid == uid) {
        _claimFuture = null;
      }
    }
  }

  Future<void> _claimSession(String uid) async {
    _stopListening();

    final String sessionId = _uuid.v4();
    _localSessionId = sessionId;
    _activeUid = uid;

    try {
      await _docRef(uid).set(<String, dynamic>{
        'sessionId': sessionId,
        'platform': _platformLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      _startListener(uid);
    } catch (e, st) {
      debugPrint('ActiveSessionService claim failed: $e\n$st');
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _localSessionId = null;
        _activeUid = null;
      }
      rethrow;
    }
  }

  void _startListener(String uid) {
    _sessionSub?.cancel();
    _sessionSub = _docRef(uid).snapshots().listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        if (_isForceLoggingOut) return;

        final String? remoteSessionId =
            snapshot.data()?['sessionId'] as String?;
        if (remoteSessionId == null || remoteSessionId.isEmpty) return;

        final String? localSessionId = _localSessionId;
        if (localSessionId == null || remoteSessionId == localSessionId) {
          return;
        }

        unawaited(_forceLogout());
      },
      onError: (Object e, StackTrace st) {
        debugPrint('ActiveSessionService listener failed: $e\n$st');
      },
    );
  }

  Future<void> _forceLogout() async {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    _forcedLogoutDueToRemoteSession = true;
    _stopListening();
    _localSessionId = null;
    _activeUid = null;
    _claimFuture = null;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e, st) {
      debugPrint('ActiveSessionService force logout failed: $e\n$st');
    } finally {
      _isForceLoggingOut = false;
    }
  }

  void _stopListening() {
    unawaited(_sessionSub?.cancel());
    _sessionSub = null;
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
