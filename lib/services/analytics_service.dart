import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/analytics/analytics_events.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  Future<void> logScreen({
    required String screenName,
    String? screenClass,
  }) async =>
      logScreenView(screenName: screenName, screenClass: screenClass);

  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e, st) {
      debugPrint('Analytics logScreenView error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logFeatureEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async =>
      logEvent(name: name, parameters: parameters);

  Future<void> logFeatureDuration({
    required String feature,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    await logEvent(
      name: AnalyticsEvents.screenDuration,
      parameters: <String, Object>{
        'feature': feature,
        'duration_seconds': seconds,
      },
    );
  }

  Future<void> logFeatureUsed({
    required String feature,
    Map<String, Object>? parameters,
  }) async {
    await logEvent(
      name: AnalyticsEvents.featureUsed,
      parameters: <String, Object>{
        'feature': feature,
        ...?parameters,
      },
    );
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _sanitizeParameters(parameters),
      );
    } catch (e, st) {
      debugPrint('Analytics logEvent error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Firebase Analytics accepts only [String] or [num] parameter values.
  static Map<String, Object>? _sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null || parameters.isEmpty) return parameters;

    final sanitized = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = _sanitizeParameterValue(entry.value);
      if (value != null) {
        sanitized[entry.key] = value;
      }
    }
    return sanitized.isEmpty ? null : sanitized;
  }

  static Object? _sanitizeParameterValue(Object? value) {
    if (value == null) return null;
    if (value is bool) return value ? 'true' : 'false';
    if (value is String || value is num) return value;
    return value.toString();
  }

  Future<void> logLogin({String method = 'password'}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e, st) {
      debugPrint('Analytics logLogin error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logSignUp({String method = 'password'}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
    } catch (e, st) {
      debugPrint('Analytics logSignUp error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    String? itemCategory,
    double? price,
    String? currency,
  }) async {
    try {
      await _analytics.logViewItem(
        currency: currency,
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            itemCategory: itemCategory,
            price: price,
          ),
        ],
      );
    } catch (e, st) {
      debugPrint('Analytics logViewItem error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required int quantity,
    double? price,
    String? currency,
    String? itemCategory,
  }) async {
    try {
      await _analytics.logAddToCart(
        currency: currency,
        value: price != null ? price * quantity : null,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            itemCategory: itemCategory,
            quantity: quantity,
            price: price,
          ),
        ],
      );
    } catch (e, st) {
      debugPrint('Analytics logAddToCart error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logPurchase({
    required String transactionId,
    required double value,
    required String currency,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: transactionId,
        value: value,
        currency: currency,
      );
    } catch (e, st) {
      debugPrint('Analytics logPurchase error: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}