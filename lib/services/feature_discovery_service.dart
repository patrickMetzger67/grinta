import 'dart:async' show Future, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/services/analytics_service.dart';

/// Persists which app areas the user has opened and which discovery prompts
/// were dismissed (separate from "visited").
///
/// ## Firestore schema
/// Document: `users/{firebaseUid}/app_state/feature_discovery`
/// ```json
/// {
///   "visited": { "tab_agenda": true, ... },
///   "visitedAt": { "tab_agenda": Timestamp, ... },
///   "promptDismissed": { "tab_dashboard": true, ... },
///   "promptDismissedAt": { "tab_dashboard": Timestamp, ... }
/// }
/// ```
/// [visited] booleans remain for backward compatibility; [visitedAt] is the
/// source of truth for re-engagement timing. Legacy entries may store a
/// [Timestamp] directly under [visited] — those are migrated into cache on load.
///
/// ## Prompt semantics
/// - [shouldShowPrompt]: first-time onboarding (never visited, not dismissed).
/// - [shouldShowReengagementPrompt]: never visited **or** last visit older than
///   [inactiveFor], and prompt not dismissed.
///
/// ## Security rules (expected, not in repo)
/// ```
/// match /users/{userId}/app_state/{docId} {
///   allow read, write: if request.auth != null && request.auth.uid == userId;
/// }
/// ```
///
/// ## Migration
/// Local SharedPreferences keys (`fd_visited_*`, `fd_dismissed_*`) are no longer
/// read or written. Per-user state now lives only in Firestore (cross-device).
///
/// ## Déconnexion / changement d'utilisateur
/// Le cache mémoire est vidé à la déconnexion ou au changement d'uid Firebase ;
/// au prochain login, [ensureInitialized] recharge le document de l'utilisateur.
class FeatureDiscoveryService {
  FeatureDiscoveryService._() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  static final FeatureDiscoveryService instance = FeatureDiscoveryService._();

  static const String _visitedField = 'visited';
  static const String _visitedAtField = 'visitedAt';
  static const String _promptDismissedField = 'promptDismissed';
  static const String _promptDismissedAtField = 'promptDismissedAt';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Set<String> _visited = <String>{};
  final Map<String, DateTime> _visitedAt = <String, DateTime>{};
  final Set<String> _dismissed = <String>{};
  final Map<String, DateTime> _promptDismissedAt = <String, DateTime>{};

  String? _loadedUid;
  bool _initialized = false;
  Future<void>? _initFuture;

  DocumentReference<Map<String, dynamic>> _docRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('app_state')
      .doc('feature_discovery');

  void _onAuthStateChanged(User? user) {
    final String? uid = user?.uid;
    if (uid == _loadedUid) return;

    _clearInMemoryCache();
    _initialized = false;
    _initFuture = null;

    if (uid != null) {
      unawaited(ensureInitialized());
    }
  }

  void _clearInMemoryCache() {
    _visited.clear();
    _visitedAt.clear();
    _dismissed.clear();
    _promptDismissedAt.clear();
    _loadedUid = null;
  }

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _loadForCurrentUser();
    await _initFuture;
  }

  Future<void> _loadForCurrentUser() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _clearInMemoryCache();
      _initialized = true;
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _docRef(uid).get();

      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }

      final Map<String, dynamic>? data = snapshot.data();

      _visited
        ..clear()
        ..addAll(_featureIdsFromMap(data?[_visitedField]));
      _visitedAt
        ..clear()
        ..addAll(_dateTimesFromMap(data?[_visitedAtField]));
      _mergeLegacyVisitedTimestamps(data?[_visitedField]);

      _dismissed
        ..clear()
        ..addAll(_featureIdsFromMap(data?[_promptDismissedField]));
      _promptDismissedAt
        ..clear()
        ..addAll(_dateTimesFromMap(data?[_promptDismissedAtField]));
      _mergeLegacyDismissedTimestamps(data?[_promptDismissedField]);

      _loadedUid = uid;
      _initialized = true;
    } catch (e, st) {
      debugPrint('FeatureDiscoveryService load failed: $e\n$st');
      if (FirebaseAuth.instance.currentUser?.uid == uid) {
        _loadedUid = uid;
        _initialized = true;
      }
    }
  }

  void _mergeLegacyVisitedTimestamps(Object? visitedRaw) {
    if (visitedRaw is! Map) return;
    for (final MapEntry<dynamic, dynamic> entry in visitedRaw.entries) {
      final String? id = entry.key?.toString();
      if (id == null || id.isEmpty) continue;
      if (entry.value is Timestamp && !_visitedAt.containsKey(id)) {
        _visitedAt[id] = (entry.value as Timestamp).toDate();
      }
    }
  }

  void _mergeLegacyDismissedTimestamps(Object? dismissedRaw) {
    if (dismissedRaw is! Map) return;
    for (final MapEntry<dynamic, dynamic> entry in dismissedRaw.entries) {
      final String? id = entry.key?.toString();
      if (id == null || id.isEmpty) continue;
      if (entry.value is Timestamp && !_promptDismissedAt.containsKey(id)) {
        _promptDismissedAt[id] = (entry.value as Timestamp).toDate();
      }
    }
  }

  Set<String> _featureIdsFromMap(Object? raw) {
    if (raw is! Map) return const <String>{};

    final Set<String> ids = <String>{};
    for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
      final String? id = entry.key?.toString();
      if (id == null || id.isEmpty) continue;
      if (_isSetMarker(entry.value)) {
        ids.add(id);
      }
    }
    return ids;
  }

  Map<String, DateTime> _dateTimesFromMap(Object? raw) {
    if (raw is! Map) return <String, DateTime>{};

    final Map<String, DateTime> result = <String, DateTime>{};
    for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
      final String? id = entry.key?.toString();
      if (id == null || id.isEmpty) continue;
      final DateTime? at = _parseDateTime(entry.value);
      if (at != null) {
        result[id] = at;
      }
    }
    return result;
  }

  DateTime? _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  bool _isSetMarker(Object? value) {
    if (value == true) return true;
    if (value is Timestamp) return true;
    return false;
  }

  bool hasVisited(String featureId) => _visited.contains(featureId);

  bool isPromptDismissed(String featureId) =>
      _dismissed.contains(featureId);

  /// Last visit time from in-memory cache (after [ensureInitialized]).
  DateTime? lastVisitedAt(String featureId) => _visitedAt[featureId];

  /// Elapsed time since [lastVisitedAt], or null if never visited.
  Duration? timeSinceLastVisit(String featureId) {
    final DateTime? last = lastVisitedAt(featureId);
    if (last == null) return null;
    return DateTime.now().difference(last);
  }

  DateTime? promptDismissedAt(String featureId) =>
      _promptDismissedAt[featureId];

  /// First-time onboarding: never opened this feature and prompt not dismissed.
  bool shouldShowPrompt(String featureId) =>
      !hasVisited(featureId) && !isPromptDismissed(featureId);

  /// Re-engagement: inactive for [inactiveFor] (or never visited) and not dismissed.
  bool shouldShowReengagementPrompt(
    String featureId, {
    required Duration inactiveFor,
  }) {
    if (isPromptDismissed(featureId)) return false;

    final DateTime? last = lastVisitedAt(featureId);
    if (last == null) return true;

    return DateTime.now().difference(last) >= inactiveFor;
  }

  /// Records a visit and refreshes [visitedAt] (merge write, server timestamp).
  Future<void> markFeatureVisited(String featureId) async {
    await ensureInitialized();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final bool wasVisited = _visited.contains(featureId);
    final DateTime? previousAt = _visitedAt[featureId];
    final DateTime now = DateTime.now();
    _visited.add(featureId);
    _visitedAt[featureId] = now;

    try {
      await _docRef(uid).set(
        <String, dynamic>{
          _visitedField: <String, bool>{featureId: true},
          _visitedAtField: <String, dynamic>{
            featureId: FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );
    } catch (e, st) {
      if (!wasVisited) {
        _visited.remove(featureId);
      }
      if (previousAt != null) {
        _visitedAt[featureId] = previousAt;
      } else {
        _visitedAt.remove(featureId);
      }
      debugPrint('FeatureDiscoveryService markFeatureVisited failed: $e\n$st');
    }
  }

  Future<void> dismissPrompt(String featureId) async {
    await ensureInitialized();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (_dismissed.contains(featureId)) return;

    final DateTime now = DateTime.now();
    _dismissed.add(featureId);
    _promptDismissedAt[featureId] = now;

    try {
      await _docRef(uid).set(
        <String, dynamic>{
          _promptDismissedField: <String, bool>{featureId: true},
          _promptDismissedAtField: <String, dynamic>{
            featureId: FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      await AnalyticsService.instance.logEvent(
        name: 'feature_discovery_prompt_dismissed',
        parameters: {'feature_id': featureId},
      );
    } catch (e, st) {
      _dismissed.remove(featureId);
      _promptDismissedAt.remove(featureId);
      debugPrint('FeatureDiscoveryService dismissPrompt failed: $e\n$st');
    }
  }

  Future<void> logPromptShown(String featureId) async {
    await AnalyticsService.instance.logEvent(
      name: 'feature_discovery_prompt_shown',
      parameters: {'feature_id': featureId},
    );
  }
}
