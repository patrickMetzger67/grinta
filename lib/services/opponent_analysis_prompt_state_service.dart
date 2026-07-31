import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Persistence for the coach opponent-analysis report prompt.
///
/// Document: `users/{uid}/app_state/opponent_analysis_prompt`
/// ```json
/// {
///   "snoozeUntilDate": "2026-08-01",
///   "matches": {
///     "<matchId>": { "status": "sent"|"skipped", "at": Timestamp }
///   }
/// }
/// ```
class OpponentAnalysisPromptStateService {
  OpponentAnalysisPromptStateService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final OpponentAnalysisPromptStateService instance =
      OpponentAnalysisPromptStateService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, String> _matchStatus = {};
  String? _snoozeUntilDate;
  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  @visibleForTesting
  DateTime Function() nowLocal = DateTime.now;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('opponent_analysis_prompt');

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    _matchStatus.clear();
    _snoozeUntilDate = null;
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
      final data = snap.data() ?? const <String, dynamic>{};
      _snoozeUntilDate = _cleanString(data['snoozeUntilDate']);
      _matchStatus.clear();
      final matches = data['matches'];
      if (matches is Map) {
        for (final entry in matches.entries) {
          final key = entry.key.toString().trim();
          if (key.isEmpty) continue;
          final value = entry.value;
          if (value is Map) {
            final status = _cleanString(value['status']);
            if (status != null) {
              _matchStatus[key] = status;
            }
          } else if (value is String) {
            final status = value.trim();
            if (status.isNotEmpty) {
              _matchStatus[key] = status;
            }
          }
        }
      }
      _loadedUid = uid;
      _initialized = true;
    } catch (e, st) {
      debugPrint('OpponentAnalysisPromptStateService load failed: $e\n$st');
      _initialized = true;
    }
  }

  @visibleForTesting
  void debugReset({
    Map<String, String>? matchStatus,
    String? snoozeUntilDate,
  }) {
    _matchStatus
      ..clear()
      ..addAll(matchStatus ?? const {});
    _snoozeUntilDate = snoozeUntilDate;
    _initialized = true;
  }

  static String formatLocalDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? parseLocalDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static String? _cleanString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  bool get isSnoozed {
    final until = parseLocalDate(_snoozeUntilDate);
    if (until == null) return false;
    final today = DateTime(
      nowLocal().year,
      nowLocal().month,
      nowLocal().day,
    );
    return today.isBefore(until);
  }

  bool shouldPromptMatch(String matchId) {
    final id = matchId.trim();
    if (id.isEmpty) return false;
    if (isSnoozed) return false;
    final status = _matchStatus[id];
    // Skip / sent are final. "accepted" alone means Oui failed before send —
    // allow asking again so the coach can retry.
    return status != 'skipped' && status != 'sent';
  }

  Future<void> markAccepted(String matchId) => _markStatus(matchId, 'accepted');

  Future<void> markSent(String matchId) => _markStatus(matchId, 'sent');

  Future<void> markSkipped(String matchId) => _markStatus(matchId, 'skipped');

  Future<void> clearMatch(String matchId) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = matchId.trim();
    if (uid == null || id.isEmpty) return;
    final previous = _matchStatus.remove(id);
    try {
      await _docRef(uid).set(const {}, SetOptions(merge: true));
      await _docRef(uid).update({
        'matches.$id': FieldValue.delete(),
      });
    } catch (e, st) {
      if (previous != null) {
        _matchStatus[id] = previous;
      }
      debugPrint(
        'OpponentAnalysisPromptStateService clearMatch failed: $e\n$st',
      );
    }
  }

  Future<void> _markStatus(String matchId, String status) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = matchId.trim();
    if (uid == null || id.isEmpty) return;

    final previous = _matchStatus[id];
    _matchStatus[id] = status;

    try {
      await _docRef(uid).set(const {}, SetOptions(merge: true));
      await _docRef(uid).update({
        'matches.$id': {
          'status': status,
          'at': FieldValue.serverTimestamp(),
        },
      });
    } catch (e, st) {
      if (previous == null) {
        _matchStatus.remove(id);
      } else {
        _matchStatus[id] = previous;
      }
      debugPrint(
        'OpponentAnalysisPromptStateService markStatus($status) failed: $e\n$st',
      );
    }
  }

  Future<void> snoozeUntilTomorrow() async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final now = nowLocal();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final until = formatLocalDate(tomorrow);
    final previous = _snoozeUntilDate;
    _snoozeUntilDate = until;

    try {
      await _docRef(uid).set(
        {'snoozeUntilDate': until},
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _snoozeUntilDate = previous;
      debugPrint(
        'OpponentAnalysisPromptStateService snoozeUntilTomorrow failed: $e\n$st',
      );
    }
  }
}
