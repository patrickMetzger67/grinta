import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/subscription_config.dart';
import 'package:grinta/model/promo_code.dart';
import 'package:grinta/services/user_root_service.dart';
import 'package:grinta/util/promo_redeem_errors.dart';

class PromoCodeRedeemResult {
  const PromoCodeRedeemResult({
    required this.entitlement,
    required this.durationDays,
    this.expiresAt,
  });

  final String entitlement;
  final int durationDays;
  final DateTime? expiresAt;
}

class PromoCodeService {
  PromoCodeService._();

  static final PromoCodeService instance = PromoCodeService._();

  static const String collectionName = 'admin_promo_codes';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  Stream<List<PromoCode>> watchAll() {
    return _collection
        .orderBy(PromoCodeDocumentFields.createdAt, descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(PromoCode.fromFirestore).toList(growable: false),
        );
  }

  Future<void> createPromoCode({
    required String code,
    required int maxUses,
    required String entitlement,
    required int durationDays,
    DateTime? expiresAt,
    String? teamId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('authentication-required');
    }

    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    final normalized = PromoCode.normalizeCode(code);
    if (normalized.length < 4) {
      throw StateError('invalid-document-id');
    }
    if (!PromoCode.isValidDocumentId(normalized)) {
      throw StateError('invalid-document-id');
    }
    if (!_isValidEntitlement(entitlement)) {
      throw ArgumentError('Invalid entitlement.');
    }
    if (maxUses < 1) {
      throw ArgumentError('maxUses must be at least 1.');
    }
    if (durationDays < 1) {
      throw ArgumentError('durationDays must be at least 1.');
    }

    try {
      final existing = await _collection.doc(normalized).get();
      if (existing.exists) {
        throw StateError('Promo code already exists.');
      }

      final promo = PromoCode(
        id: normalized,
        code: normalized,
        maxUses: maxUses,
        usedCount: 0,
        entitlement: entitlement,
        durationDays: durationDays,
        expiresAt: expiresAt,
        teamId: teamId?.trim().isNotEmpty == true ? teamId!.trim() : null,
        createdBy: uid,
        createdAt: DateTime.now(),
        active: true,
      );

      await _collection.doc(normalized).set(promo.toFirestore());
    } on FirebaseException catch (e, st) {
      debugPrint('createPromoCode failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      if (e.code == 'already-exists') {
        throw StateError('Promo code already exists.');
      }
      rethrow;
    }
  }

  Future<void> updatePromoCode({
    required String codeId,
    required int maxUses,
    required String entitlement,
    required int durationDays,
    DateTime? expiresAt,
    String? teamId,
    required bool active,
    bool clearExpiresAt = false,
  }) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }
    if (!_isValidEntitlement(entitlement)) {
      throw ArgumentError('Invalid entitlement.');
    }
    if (maxUses < 1) {
      throw ArgumentError('maxUses must be at least 1.');
    }
    if (durationDays < 1) {
      throw ArgumentError('durationDays must be at least 1.');
    }

    final docRef = _collection.doc(codeId);
    final existing = await docRef.get();
    if (!existing.exists) {
      throw StateError('not-found');
    }

    final usedCount = PromoCode.readInt(
      existing.data()?[PromoCodeDocumentFields.usedCount],
    );
    if (maxUses < usedCount) {
      throw StateError('max-uses-below-used');
    }

    final existingCode = existing.data()?[PromoCodeDocumentFields.code]
            ?.toString() ??
        codeId;
    final updates = <String, dynamic>{
      PromoCodeDocumentFields.maxUses: maxUses,
      PromoCodeDocumentFields.entitlement: entitlement,
      PromoCodeDocumentFields.durationDays: durationDays,
      PromoCodeDocumentFields.active: active,
      // Backfill compact key so redeem lookup stays indexable for older docs.
      PromoCodeDocumentFields.codeCompact: PromoCode.compactCode(existingCode),
    };

    if (clearExpiresAt) {
      updates[PromoCodeDocumentFields.expiresAt] = FieldValue.delete();
    } else if (expiresAt != null) {
      updates[PromoCodeDocumentFields.expiresAt] =
          Timestamp.fromDate(expiresAt);
    }

    final trimmedTeamId = teamId?.trim();
    if (trimmedTeamId == null || trimmedTeamId.isEmpty) {
      updates[PromoCodeDocumentFields.teamId] = FieldValue.delete();
    } else {
      updates[PromoCodeDocumentFields.teamId] = trimmedTeamId;
    }

    try {
      await docRef.update(updates);
    } on FirebaseException catch (e, st) {
      debugPrint('updatePromoCode failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      if (e.code == 'not-found') {
        throw StateError('not-found');
      }
      rethrow;
    }
  }

  Future<void> deletePromoCode({required String codeId}) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    try {
      await _collection.doc(codeId).delete();
    } on FirebaseException catch (e, st) {
      debugPrint('deletePromoCode failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }

  Future<void> setActive({
    required String codeId,
    required bool active,
  }) async {
    await UserRootService.instance.reload();
    if (!UserRootService.instance.isRoot) {
      throw StateError('permission-denied');
    }

    try {
      await _collection.doc(codeId).update({
        PromoCodeDocumentFields.active: active,
      });
    } on FirebaseException catch (e, st) {
      debugPrint('setActive failed: ${e.code} ${e.message}\n$st');
      if (e.code == 'permission-denied') {
        throw StateError('permission-denied');
      }
      rethrow;
    }
  }

  Future<PromoCodeRedeemResult> redeemCode(String rawCode) async {
    final normalized = PromoCode.normalizeCode(rawCode);
    if (normalized.isEmpty) {
      throw ArgumentError('Promo code is required.');
    }

    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
    final callable = functions.httpsCallable('redeemPromoCode');
    final result = await callable.call(<String, dynamic>{
      'code': normalized,
    });

    final data = result.data;
    if (data is! Map) {
      throw StateError('Invalid redeem response.');
    }

    final entitlement = data['entitlement']?.toString() ?? '';
    final durationDays = PromoCode.readInt(data['durationDays'], fallback: 0);
    if (entitlement.isEmpty || durationDays < 1) {
      throw StateError('Invalid redeem response.');
    }

    DateTime? expiresAt;
    final rawExpiresAt = data['expiresAt']?.toString();
    if (rawExpiresAt != null && rawExpiresAt.isNotEmpty) {
      expiresAt = DateTime.tryParse(rawExpiresAt);
    }

    return PromoCodeRedeemResult(
      entitlement: entitlement,
      durationDays: durationDays,
      expiresAt: expiresAt,
    );
  }

  bool _isValidEntitlement(String entitlement) {
    return SubscriptionEntitlementIds.isKnown(entitlement);
  }

  static String formatFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'permission-denied';
      case 'unauthenticated':
        return 'unauthenticated';
      case 'already-exists':
        return 'already-exists';
      default:
        debugPrint('createPromoCode Firestore error: ${e.code} ${e.message}');
        return 'internal';
    }
  }

  static String formatFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return 'not-found';
      case 'failed-precondition':
        return 'failed-precondition';
      case 'permission-denied':
        return 'permission-denied';
      case 'resource-exhausted':
        return 'resource-exhausted';
      case 'unauthenticated':
        return 'unauthenticated';
      case 'invalid-argument':
        return 'invalid-argument';
      case 'unavailable':
        return 'unavailable';
      default:
        debugPrint(
          'redeemPromoCode error: ${e.code} ${e.message} details=${e.details}',
        );
        return 'internal';
    }
  }

  /// True when Firebase could not reach the callable (undeployed / wrong region).
  ///
  /// Must not be shown as "promo code not found" — that message is reserved for
  /// [PROMO_NOT_FOUND] from [redeemPromoCode] itself.
  static bool isCallableMissing(FirebaseFunctionsException e) {
    return PromoRedeemErrors.isCallableMissing(
      httpsCode: e.code,
      message: e.message,
      details: e.details,
    );
  }

  /// Stable promo error code from callable [details.errorCode], or inferred
  /// from known English server messages (covers undeployed CF fallbacks).
  static String? extractPromoErrorCode(FirebaseFunctionsException e) {
    return PromoRedeemErrors.extractErrorCode(
      httpsCode: e.code,
      message: e.message,
      details: e.details,
    );
  }

  /// Best available callable error text (message or details), ignoring values
  /// that only repeat the error code (e.g. message == "internal").
  static String? extractFunctionsErrorMessage(FirebaseFunctionsException e) {
    final code = e.code.trim().toLowerCase();

    bool isRedundant(String value) {
      final normalized = value.trim().toLowerCase();
      return normalized.isEmpty || normalized == code;
    }

    final message = e.message?.trim();
    if (message != null && !isRedundant(message)) {
      return message;
    }

    final details = e.details;
    if (details is String) {
      final trimmed = details.trim();
      if (!isRedundant(trimmed)) {
        return trimmed;
      }
    }
    if (details is Map) {
      for (final key in ['message', 'error', 'detail', 'details', 'reason']) {
        final value = details[key]?.toString().trim();
        if (value != null && !isRedundant(value)) {
          return value;
        }
      }
    }

    return null;
  }

  static String redeemErrorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      return extractFunctionsErrorMessage(error) ??
          'Callable failed (${error.code}).';
    }
    if (error is StateError) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return message;
      }
    }
    if (error is FirebaseException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
      return 'Firebase error (${error.code}).';
    }
    final text = error.toString().trim();
    return text.isEmpty ? 'Unknown error.' : text;
  }
}
