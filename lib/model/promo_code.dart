import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore field names on `admin_promo_codes/{code}`.
abstract final class PromoCodeDocumentFields {
  static const code = 'code';
  /// Separator-free form for tolerant server lookup (DEMO-2026 → DEMO2026).
  static const codeCompact = 'codeCompact';
  static const maxUses = 'maxUses';
  static const usedCount = 'usedCount';
  static const entitlement = 'entitlement';
  static const durationDays = 'durationDays';
  static const expiresAt = 'expiresAt';
  static const teamId = 'teamId';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const active = 'active';
}

class PromoCode {
  const PromoCode({
    required this.id,
    required this.code,
    required this.maxUses,
    required this.usedCount,
    required this.entitlement,
    required this.durationDays,
    this.expiresAt,
    this.teamId,
    required this.createdBy,
    this.createdAt,
    required this.active,
  });

  final String id;
  final String code;
  final int maxUses;
  final int usedCount;
  final String entitlement;
  final int durationDays;
  final DateTime? expiresAt;
  final String? teamId;
  final String createdBy;
  final DateTime? createdAt;
  final bool active;

  bool get isExpired {
    final endsAt = expiresAt;
    if (endsAt == null) return false;
    return DateTime.now().isAfter(endsAt);
  }

  bool get isExhausted => usedCount >= maxUses;

  bool get isRedeemable => active && !isExpired && !isExhausted;

  int get remainingUses => (maxUses - usedCount).clamp(0, maxUses);

  factory PromoCode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PromoCode(
      id: doc.id,
      code: data[PromoCodeDocumentFields.code]?.toString() ?? doc.id,
      maxUses: readInt(data[PromoCodeDocumentFields.maxUses], fallback: 1),
      usedCount: readInt(data[PromoCodeDocumentFields.usedCount]),
      entitlement: data[PromoCodeDocumentFields.entitlement]?.toString() ?? '',
      durationDays:
          readInt(data[PromoCodeDocumentFields.durationDays], fallback: 30),
      expiresAt: _readTimestamp(data[PromoCodeDocumentFields.expiresAt]),
      teamId: _readOptionalString(data[PromoCodeDocumentFields.teamId]),
      createdBy: data[PromoCodeDocumentFields.createdBy]?.toString() ?? '',
      createdAt: _readTimestamp(data[PromoCodeDocumentFields.createdAt]),
      active: data[PromoCodeDocumentFields.active] != false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      PromoCodeDocumentFields.code: code,
      PromoCodeDocumentFields.codeCompact: compactCode(code),
      PromoCodeDocumentFields.maxUses: maxUses,
      PromoCodeDocumentFields.usedCount: usedCount,
      PromoCodeDocumentFields.entitlement: entitlement,
      PromoCodeDocumentFields.durationDays: durationDays,
      if (expiresAt != null)
        PromoCodeDocumentFields.expiresAt: Timestamp.fromDate(expiresAt!),
      if (teamId != null && teamId!.isNotEmpty)
        PromoCodeDocumentFields.teamId: teamId,
      PromoCodeDocumentFields.createdBy: createdBy,
      PromoCodeDocumentFields.createdAt:
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      PromoCodeDocumentFields.active: active,
    };
  }

  static String normalizeCode(String raw) {
    // Tag icon in the redeem UI often leads users to type "# JOUEURGPS".
    // Dart: use replaceFirst/replaceAll — String has no JS-style .replace.
    return raw
        .trim()
        .replaceFirst(RegExp(r'^#+'), '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'\s+'), '');
  }

  /// Separator-free form used by Cloud Function lookup (DEMO-2026 → DEMO2026).
  static String compactCode(String raw) {
    return normalizeCode(raw).replaceAll(RegExp(r'[-_.#]'), '');
  }

  /// Firestore document IDs cannot contain `/` or match reserved patterns.
  static bool isValidDocumentId(String normalized) {
    if (normalized.isEmpty || normalized.length > 1500) return false;
    if (normalized == '.' || normalized == '..') return false;
    if (normalized.contains('/')) return false;
    if (RegExp(r'^__.*__$').hasMatch(normalized)) return false;
    return true;
  }

  static int readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String? _readOptionalString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
