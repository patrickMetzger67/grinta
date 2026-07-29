import 'dart:convert';

import 'package:grinta/model/agenda_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists [AgendaFilter] locally per user / player / season.
class AgendaFilterPrefs {
  AgendaFilterPrefs._();

  static final AgendaFilterPrefs instance = AgendaFilterPrefs._();

  static String _key({
    required String uid,
    required String playerId,
    required String seasonId,
  }) {
    return 'agenda_filter_v1_${uid.trim()}_${playerId.trim()}_${seasonId.trim()}';
  }

  Future<AgendaFilter> load({
    required String uid,
    required String playerId,
    required String seasonId,
  }) async {
    if (uid.trim().isEmpty ||
        playerId.trim().isEmpty ||
        seasonId.trim().isEmpty) {
      return AgendaFilter.none;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _key(uid: uid, playerId: playerId, seasonId: seasonId),
    );
    if (raw == null || raw.trim().isEmpty) {
      return AgendaFilter.none;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AgendaFilter.fromJson(decoded);
      }
      if (decoded is Map) {
        return AgendaFilter.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (_) {
      // Corrupted prefs — fall back to no filter.
    }
    return AgendaFilter.none;
  }

  Future<void> save({
    required String uid,
    required String playerId,
    required String seasonId,
    required AgendaFilter filter,
  }) async {
    if (uid.trim().isEmpty ||
        playerId.trim().isEmpty ||
        seasonId.trim().isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _key(uid: uid, playerId: playerId, seasonId: seasonId);
    if (!filter.isActive) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(filter.toJson()));
  }
}
