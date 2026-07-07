import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Tracks opponent stats views per match for reminder deduplication.
///
/// Document: `users/{uid}/app_state/opponent_stats_views/{matchId}`
class OpponentStatsViewTracker {
  OpponentStatsViewTracker._() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      _cache.clear();
    });
  }

  static final OpponentStatsViewTracker instance = OpponentStatsViewTracker._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, bool> _cache = <String, bool>{};

  DocumentReference<Map<String, dynamic>> _docRef(String uid, String matchId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('app_state')
          .doc('opponent_stats_views')
          .collection('views')
          .doc(matchId);

  Future<bool> hasViewed(String matchId) async {
    final trimmed = matchId.trim();
    if (trimmed.isEmpty) return false;

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final snap = await _docRef(uid, trimmed).get();
      final viewed = snap.data()?['viewedAt'] != null;
      _cache[trimmed] = viewed;
      return viewed;
    } catch (e, st) {
      debugPrint('OpponentStatsViewTracker.hasViewed error: $e\n$st');
      return false;
    }
  }

  Future<void> markViewed({
    required String matchId,
    String? opponentKey,
    String? teamId,
  }) async {
    final trimmedMatchId = matchId.trim();
    if (trimmedMatchId.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _cache[trimmedMatchId] = true;

    try {
      await _docRef(uid, trimmedMatchId).set(
        <String, dynamic>{
          'viewedAt': FieldValue.serverTimestamp(),
          if (opponentKey != null && opponentKey.trim().isNotEmpty)
            'opponentKey': opponentKey.trim(),
          if (teamId != null && teamId.trim().isNotEmpty)
            'teamId': teamId.trim(),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _cache.remove(trimmedMatchId);
      debugPrint('OpponentStatsViewTracker.markViewed error: $e\n$st');
    }

    unawaited(
      InternalReminderServiceBridge.notifyStatsViewed(trimmedMatchId),
    );
  }
}

/// Avoids circular imports between tracker and reminder service.
class InternalReminderServiceBridge {
  static Future<void> Function(String matchId)? onStatsViewed;
  static Future<void> Function()? onPresenceConfirmed;

  static Future<void> notifyStatsViewed(String matchId) async {
    await onStatsViewed?.call(matchId);
  }

  static Future<void> notifyPresenceConfirmed() async {
    await onPresenceConfirmed?.call();
  }
}
