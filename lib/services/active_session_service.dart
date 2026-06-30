import 'dart:async' show Future, StreamSubscription, TimeoutException, unawaited;

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
  static Duration get _claimWriteTimeout =>
      kIsWeb ? const Duration(seconds: 30) : const Duration(seconds: 15);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _localSessionId;
  String? _activeUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;
  Future<void>? _claimFuture;
  bool _isForceLoggingOut = false;
  bool _forcedLogoutDueToRemoteSession = false;
  bool _awaitingOwnSessionConfirmation = false;

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
    _awaitingOwnSessionConfirmation = false;

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
    _awaitingOwnSessionConfirmation = true;

    try {
      await _docRef(uid).set(<String, dynamic>{
        'sessionId': sessionId,
        'platform': _platformLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(_claimWriteTimeout);

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        _awaitingOwnSessionConfirmation = false;
        return;
      }

      _startListener(uid);
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint(
          'ActiveSessionService claim write timed out for uid=$uid; continuing',
        );
      }
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _startListener(uid);
      } else {
        _awaitingOwnSessionConfirmation = false;
      }
    } catch (e, st) {
      debugPrint('ActiveSessionService claim failed: $e\n$st');
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _localSessionId = null;
        _activeUid = null;
      }
      _awaitingOwnSessionConfirmation = false;
      rethrow;
    }
  }

  void _startListener(String uid) {
    _sessionSub?.cancel();
    _sessionSub = _docRef(uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (FirebaseAuth.instance.currentUser?.uid != uid) return;
        if (_isForceLoggingOut) return;

        final String? remoteSessionId =
            snapshot.data()?['sessionId'] as String?;
        if (remoteSessionId == null || remoteSessionId.isEmpty) return;

        final String? localSessionId = _localSessionId;
        if (localSessionId == null) return;

        if (remoteSessionId == localSessionId) {
          _awaitingOwnSessionConfirmation = false;
          return;
        }

        _handleSessionMismatch(
          uid: uid,
          localSessionId: localSessionId,
          fromCache: snapshot.metadata.isFromCache,
        );
      },
      onError: (Object e, StackTrace st) {
        debugPrint('ActiveSessionService listener failed: $e\n$st');
      },
    );
  }

  void _handleSessionMismatch({
    required String uid,
    required String localSessionId,
    required bool fromCache,
  }) {
    if (_awaitingOwnSessionConfirmation) {
      // Hot restart: ignore stale local cache from a previous session on this
      // device. A server-confirmed mismatch means another device claimed session.
      if (fromCache) return;

      unawaited(
        _verifyRemoteSessionAndMaybeLogout(
          uid: uid,
          localSessionId: localSessionId,
        ),
      );
      return;
    }

    if (fromCache) {
      // Running session: verify stale cache against server before signing out.
      unawaited(
        _verifyRemoteSessionAndMaybeLogout(
          uid: uid,
          localSessionId: localSessionId,
        ),
      );
      return;
    }

    // Server-confirmed remote takeover on an established session.
    unawaited(_forceLogout());
  }

  Future<void> _verifyRemoteSessionAndMaybeLogout({
    required String uid,
    required String localSessionId,
  }) async {
    if (_isForceLoggingOut) return;
    if (FirebaseAuth.instance.currentUser?.uid != uid) return;
    if (_localSessionId != localSessionId) return;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _docRef(uid).get(const GetOptions(source: Source.server));
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      if (_localSessionId != localSessionId) return;

      final String? serverSessionId =
          snapshot.data()?['sessionId'] as String?;
      if (serverSessionId == null ||
          serverSessionId.isEmpty ||
          serverSessionId == localSessionId) {
        _awaitingOwnSessionConfirmation = false;
        return;
      }

      await _forceLogout();
    } catch (e, st) {
      debugPrint('ActiveSessionService server verify failed: $e\n$st');
    }
  }

  Future<void> _forceLogout() async {
    if (_isForceLoggingOut) return;
    _isForceLoggingOut = true;

    _forcedLogoutDueToRemoteSession = true;
    _stopListening();
    _localSessionId = null;
    _activeUid = null;
    _claimFuture = null;
    _awaitingOwnSessionConfirmation = false;

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
