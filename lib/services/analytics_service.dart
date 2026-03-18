import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalytics get analytics => _analytics;

  Future<void> logScreen({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e, st) {
      debugPrint('Analytics logScreen error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e, st) {
      debugPrint('Analytics logEvent error: $e');
      debugPrintStack(stackTrace: st);
    }
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