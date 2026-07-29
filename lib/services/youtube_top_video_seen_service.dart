import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the current YouTube [topVideo] was already shown to the user.
///
/// Document: `users/{firebaseUid}/app_state/youtube_top_video`
/// ```json
/// { "seenTopVideoId": "xxxxxxxxxxx", "seenAt": Timestamp }
/// ```
///
/// When admin changes `config/youtube.topVideo`, the stored id no longer
/// matches and the prompt is shown again.
class YoutubeTopVideoSeenService {
  YoutubeTopVideoSeenService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final YoutubeTopVideoSeenService instance =
      YoutubeTopVideoSeenService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _seenTopVideoId;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('youtube_top_video');

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _seenTopVideoId = null;
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

      final raw = snap.data()?['seenTopVideoId']?.toString().trim();
      _seenTopVideoId = (raw == null || raw.isEmpty) ? null : raw;
      _loadedUid = uid;
      _initialized = true;
    } catch (e, st) {
      debugPrint('YoutubeTopVideoSeenService load failed: $e\n$st');
      _initialized = true;
    }
  }

  String? get seenTopVideoId => _seenTopVideoId;

  /// Returns true when [topVideoId] is set and different from the last seen id.
  bool shouldShow(String? topVideoId) {
    final id = topVideoId?.trim() ?? '';
    if (id.isEmpty) return false;
    return _seenTopVideoId != id;
  }

  Future<void> markSeen(String topVideoId) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = topVideoId.trim();
    if (uid == null || id.isEmpty) return;

    final previous = _seenTopVideoId;
    _seenTopVideoId = id;
    try {
      await _docRef(uid).set(
        <String, dynamic>{
          'seenTopVideoId': id,
          'seenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _seenTopVideoId = previous;
      debugPrint('YoutubeTopVideoSeenService markSeen failed: $e\n$st');
    }
  }
}
