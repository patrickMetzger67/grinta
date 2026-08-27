import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local last-known paid entitlements for a Firebase UID.
///
/// Used when RevenueCat is slow, mis-linked, or temporarily empty so a paying
/// user (or promo grant) does not lose access mid-session / after relaunch.
class SubscriptionEntitlementCache {
  SubscriptionEntitlementCache._();

  static const _prefsKey = 'grinta.subscription_entitlement_cache.v1';

  /// Reads a non-expired cache entry for [uid], if any.
  static Future<CachedSubscriptionEntitlements?> loadForUid(String uid) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final cachedUid = decoded['uid']?.toString().trim() ?? '';
      if (cachedUid != trimmed) return null;

      final expiresAt = _readDate(decoded['expiresAt']);
      if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) {
        return null;
      }

      final entitlements = <String>{};
      final rawEntitlements = decoded['entitlements'];
      if (rawEntitlements is List) {
        for (final entry in rawEntitlements) {
          final id = entry?.toString().trim() ?? '';
          if (id.isNotEmpty) entitlements.add(id);
        }
      }
      if (entitlements.isEmpty) return null;

      return CachedSubscriptionEntitlements(
        uid: trimmed,
        entitlements: entitlements,
        coachTier: _coachTierFromEntitlements(entitlements),
        hasPlayerSubscription:
            SubscriptionEntitlementIds.grantsPlayerAccess(entitlements),
        hasPlayerGpsSubscription:
            entitlements.contains(SubscriptionEntitlementIds.playerGps),
        activeProductId: decoded['productId']?.toString(),
        expiresAt: expiresAt,
      );
    } catch (e, st) {
      debugPrint('SubscriptionEntitlementCache.loadForUid failed: $e\n$st');
      return null;
    }
  }

  /// Persists [entitlements] for [uid]. Pass an empty set to clear.
  static Future<void> saveForUid({
    required String uid,
    required Set<String> entitlements,
    String? productId,
    DateTime? expiresAt,
  }) async {
    final trimmed = uid.trim();
    if (trimmed.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (entitlements.isEmpty) {
        final existing = prefs.getString(_prefsKey);
        if (existing != null) {
          final decoded = jsonDecode(existing);
          if (decoded is Map &&
              (decoded['uid']?.toString().trim() ?? '') == trimmed) {
            await prefs.remove(_prefsKey);
          }
        }
        return;
      }

      await prefs.setString(
        _prefsKey,
        jsonEncode(<String, dynamic>{
          'uid': trimmed,
          'entitlements': entitlements.toList()..sort(),
          'productId': productId,
          'expiresAt': expiresAt?.toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e, st) {
      debugPrint('SubscriptionEntitlementCache.saveForUid failed: $e\n$st');
    }
  }

  static CoachTier? _coachTierFromEntitlements(Set<String> entitlements) {
    for (final id in SubscriptionEntitlementIds.coachTiersOrdered) {
      if (entitlements.contains(id)) {
        return CoachTier.fromEntitlementId(id);
      }
    }
    return null;
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}

class CachedSubscriptionEntitlements {
  const CachedSubscriptionEntitlements({
    required this.uid,
    required this.entitlements,
    required this.coachTier,
    required this.hasPlayerSubscription,
    this.hasPlayerGpsSubscription = false,
    this.activeProductId,
    this.expiresAt,
  });

  final String uid;
  final Set<String> entitlements;
  final CoachTier? coachTier;
  final bool hasPlayerSubscription;
  final bool hasPlayerGpsSubscription;
  final String? activeProductId;
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());
}
