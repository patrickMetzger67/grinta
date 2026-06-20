import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Persists whether the home-page subscription prompt was dismissed.
///
/// Document: `users/{firebaseUid}/app_state/subscription_prompt`
/// ```json
/// { "dismissed": true, "dismissedAt": Timestamp }
/// ```
class SubscriptionPromptService {
  SubscriptionPromptService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final SubscriptionPromptService instance =
      SubscriptionPromptService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _dismissed = false;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('subscription_prompt');

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _dismissed = false;
    _initialized = false;
    _initFuture = null;
    _loadedUid = null;
    if (uid != null) {
      unawaited(ensureInitialized());
    }
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _initialized = true;
      return;
    }

    try {
      final snap = await _docRef(uid).get();
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;

      _dismissed = snap.data()?['dismissed'] == true;
      _loadedUid = uid;
      _initialized = true;
    } catch (e, st) {
      debugPrint('SubscriptionPromptService load failed: $e\n$st');
      _initialized = true;
    }
  }

  bool get isDismissed => _dismissed;

  bool shouldShowPrompt({required bool isSubscribed}) {
    if (isSubscribed) return false;
    return !_dismissed;
  }

  Future<void> dismiss() async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _dismissed) return;

    _dismissed = true;
    try {
      await _docRef(uid).set(
        <String, dynamic>{
          'dismissed': true,
          'dismissedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _dismissed = false;
      debugPrint('SubscriptionPromptService dismiss failed: $e\n$st');
    }
  }
}
