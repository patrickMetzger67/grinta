import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Prompt slots that can be shown once / snoozed until tomorrow.
enum YoutubePromptSlot {
  topVideo,
  welcomePlayer,
  welcomeCoach,
}

/// Tracks seen / snoozed state for YouTube tip & welcome prompts.
///
/// Document: `users/{firebaseUid}/app_state/youtube_top_video`
/// ```json
/// {
///   "seenTopVideoId": "...",
///   "seenAt": Timestamp,
///   "snoozeTopVideoId": "...",
///   "snoozeUntilDate": "2026-07-31",
///   "seenWelcomePlayerId": "...",
///   "snoozeWelcomePlayerId": "...",
///   "snoozeWelcomePlayerUntilDate": "2026-07-31",
///   "seenWelcomeCoachId": "...",
///   "snoozeWelcomeCoachId": "...",
///   "snoozeWelcomeCoachUntilDate": "2026-07-31"
/// }
/// ```
///
/// [snoozeUntilDate] is a local calendar `YYYY-MM-DD`: the prompt stays hidden
/// while `today < snoozeUntilDate`, then reappears (unless marked seen).
class YoutubeTopVideoSeenService {
  YoutubeTopVideoSeenService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  static final YoutubeTopVideoSeenService instance =
      YoutubeTopVideoSeenService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<YoutubePromptSlot, _SlotState> _slots = {
    for (final slot in YoutubePromptSlot.values) slot: _SlotState(),
  };

  bool _initialized = false;
  Future<void>? _initFuture;
  String? _loadedUid;

  /// Overrideable clock for tests (local calendar day).
  @visibleForTesting
  DateTime Function() nowLocal = DateTime.now;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('youtube_top_video');

  void _onAuthChanged(User? user) {
    final uid = user?.uid;
    if (uid == _loadedUid) return;
    for (final slot in YoutubePromptSlot.values) {
      _slots[slot] = _SlotState();
    }
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
      _slots[YoutubePromptSlot.topVideo] = _SlotState.fromFields(
        seenId: data['seenTopVideoId'],
        snoozeId: data['snoozeTopVideoId'],
        snoozeUntilDate: data['snoozeUntilDate'],
      );
      _slots[YoutubePromptSlot.welcomePlayer] = _SlotState.fromFields(
        seenId: data['seenWelcomePlayerId'],
        snoozeId: data['snoozeWelcomePlayerId'],
        snoozeUntilDate: data['snoozeWelcomePlayerUntilDate'],
      );
      _slots[YoutubePromptSlot.welcomeCoach] = _SlotState.fromFields(
        seenId: data['seenWelcomeCoachId'],
        snoozeId: data['snoozeWelcomeCoachId'],
        snoozeUntilDate: data['snoozeWelcomeCoachUntilDate'],
      );
      _loadedUid = uid;
      _initialized = true;
    } catch (e, st) {
      debugPrint('YoutubeTopVideoSeenService load failed: $e\n$st');
      _initialized = true;
    }
  }

  String? get seenTopVideoId => _slots[YoutubePromptSlot.topVideo]?.seenId;

  /// Test helper to seed in-memory slot state without Firestore.
  @visibleForTesting
  void debugSetSlotState({
    required YoutubePromptSlot slot,
    String? seenId,
    String? snoozeId,
    String? snoozeUntilDate,
  }) {
    _slots[slot] = _SlotState(
      seenId: seenId,
      snoozeId: snoozeId,
      snoozeUntilDate: snoozeUntilDate,
    );
    _initialized = true;
  }

  /// Local calendar day as `YYYY-MM-DD`.
  @visibleForTesting
  static String formatLocalDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @visibleForTesting
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

  /// True when [videoId] should be prompted for [slot].
  bool shouldShow(String? videoId, {YoutubePromptSlot slot = YoutubePromptSlot.topVideo}) {
    final id = videoId?.trim() ?? '';
    if (id.isEmpty) return false;

    final state = _slots[slot] ?? _SlotState();
    if (state.seenId == id) return false;

    if (state.snoozeId == id) {
      final until = parseLocalDate(state.snoozeUntilDate);
      if (until != null) {
        final today = DateTime(
          nowLocal().year,
          nowLocal().month,
          nowLocal().day,
        );
        if (today.isBefore(until)) return false;
      }
    }
    return true;
  }

  Future<void> markSeen(
    String videoId, {
    YoutubePromptSlot slot = YoutubePromptSlot.topVideo,
  }) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = videoId.trim();
    if (uid == null || id.isEmpty) return;

    final previous = _slots[slot] ?? _SlotState();
    _slots[slot] = _SlotState(seenId: id);

    try {
      await _docRef(uid).set(
        {
          ..._seenFields(slot, id),
          ..._clearSnoozeFields(slot),
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _slots[slot] = previous;
      debugPrint('YoutubeTopVideoSeenService markSeen failed: $e\n$st');
    }
  }

  /// Hides [videoId] for the rest of today; shows again tomorrow (not marked seen).
  Future<void> snoozeUntilTomorrow(
    String videoId, {
    YoutubePromptSlot slot = YoutubePromptSlot.topVideo,
  }) async {
    await ensureInitialized();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final id = videoId.trim();
    if (uid == null || id.isEmpty) return;

    final now = nowLocal();
    final tomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    final until = formatLocalDate(tomorrow);

    final previous = _slots[slot] ?? _SlotState();
    _slots[slot] = _SlotState(
      seenId: previous.seenId,
      snoozeId: id,
      snoozeUntilDate: until,
    );

    try {
      await _docRef(uid).set(
        _snoozeFields(slot, id, until),
        SetOptions(merge: true),
      );
    } catch (e, st) {
      _slots[slot] = previous;
      debugPrint(
        'YoutubeTopVideoSeenService snoozeUntilTomorrow failed: $e\n$st',
      );
    }
  }

  Map<String, dynamic> _seenFields(YoutubePromptSlot slot, String id) {
    switch (slot) {
      case YoutubePromptSlot.topVideo:
        return {
          'seenTopVideoId': id,
          'seenAt': FieldValue.serverTimestamp(),
        };
      case YoutubePromptSlot.welcomePlayer:
        return {
          'seenWelcomePlayerId': id,
          'seenWelcomePlayerAt': FieldValue.serverTimestamp(),
        };
      case YoutubePromptSlot.welcomeCoach:
        return {
          'seenWelcomeCoachId': id,
          'seenWelcomeCoachAt': FieldValue.serverTimestamp(),
        };
    }
  }

  Map<String, dynamic> _clearSnoozeFields(YoutubePromptSlot slot) {
    switch (slot) {
      case YoutubePromptSlot.topVideo:
        return {
          'snoozeTopVideoId': FieldValue.delete(),
          'snoozeUntilDate': FieldValue.delete(),
        };
      case YoutubePromptSlot.welcomePlayer:
        return {
          'snoozeWelcomePlayerId': FieldValue.delete(),
          'snoozeWelcomePlayerUntilDate': FieldValue.delete(),
        };
      case YoutubePromptSlot.welcomeCoach:
        return {
          'snoozeWelcomeCoachId': FieldValue.delete(),
          'snoozeWelcomeCoachUntilDate': FieldValue.delete(),
        };
    }
  }

  Map<String, dynamic> _snoozeFields(
    YoutubePromptSlot slot,
    String id,
    String until,
  ) {
    switch (slot) {
      case YoutubePromptSlot.topVideo:
        return {
          'snoozeTopVideoId': id,
          'snoozeUntilDate': until,
        };
      case YoutubePromptSlot.welcomePlayer:
        return {
          'snoozeWelcomePlayerId': id,
          'snoozeWelcomePlayerUntilDate': until,
        };
      case YoutubePromptSlot.welcomeCoach:
        return {
          'snoozeWelcomeCoachId': id,
          'snoozeWelcomeCoachUntilDate': until,
        };
    }
  }
}

class _SlotState {
  _SlotState({
    this.seenId,
    this.snoozeId,
    this.snoozeUntilDate,
  });

  factory _SlotState.fromFields({
    dynamic seenId,
    dynamic snoozeId,
    dynamic snoozeUntilDate,
  }) {
    String? clean(dynamic v) {
      final text = v?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return _SlotState(
      seenId: clean(seenId),
      snoozeId: clean(snoozeId),
      snoozeUntilDate: clean(snoozeUntilDate),
    );
  }

  final String? seenId;
  final String? snoozeId;
  final String? snoozeUntilDate;
}
