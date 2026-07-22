import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/whoop_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/whoop_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class WhoopImportableActivity {
  const WhoopImportableActivity({
    required this.externalId,
    required this.name,
    required this.typeId,
    this.startDate,
    this.durationSeconds,
    this.distanceMeters,
    this.paceSecondsPerKm,
    this.caloriesKcal,
    this.averageHeartRateBpm,
  });

  final String externalId;
  final String name;
  final String typeId;
  final DateTime? startDate;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? paceSecondsPerKm;
  final double? caloriesKcal;
  final int? averageHeartRateBpm;

  String get displayLabel {
    final parts = <String>[name];
    if (startDate != null) {
      parts.add(
        '${startDate!.day.toString().padLeft(2, '0')}/'
        '${startDate!.month.toString().padLeft(2, '0')}',
      );
    }
    if (distanceMeters != null && distanceMeters! > 0) {
      parts.add('${(distanceMeters! / 1000).toStringAsFixed(1)} km');
    } else if (averageHeartRateBpm != null && averageHeartRateBpm! > 0) {
      parts.add('${averageHeartRateBpm!} bpm');
    }
    return parts.join(' · ');
  }

  factory WhoopImportableActivity.fromMap(Map<dynamic, dynamic> map) {
    DateTime? start;
    final rawStart = map['startDate']?.toString();
    if (rawStart != null && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    return WhoopImportableActivity(
      externalId: (map['externalId'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      typeId: (map['typeId'] ?? 'entrainement').toString().trim(),
      startDate: start,
      durationSeconds: _asInt(map['durationSeconds']),
      distanceMeters: _asDouble(map['distanceMeters']),
      paceSecondsPerKm: _asInt(map['paceSecondsPerKm']),
      caloriesKcal: _asDouble(map['caloriesKcal']),
      averageHeartRateBpm: _asInt(map['averageHeartRateBpm']),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return null;
  }
}

class WhoopListActivitiesResult {
  const WhoopListActivitiesResult({
    required this.activities,
    this.fetchedFromWhoop,
    this.emptyReason,
    this.errorCode,
    this.errorMessage,
  });

  final List<WhoopImportableActivity> activities;
  final int? fetchedFromWhoop;
  final String? emptyReason;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

enum WhoopConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class WhoopSyncService {
  WhoopSyncService._();

  static final WhoopSyncService instance = WhoopSyncService._();

  final WhoopSyncRepository _repository = WhoopSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kWhoopFunctionsRegion);

  WhoopSyncRepository get repository => _repository;

  Future<WhoopConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? whoopAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return WhoopConnectResult.unauthenticated;
    }

    final hint = whoopAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return WhoopConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kWhoopOAuthStartFunctionName);
      final payload = <String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'whoopAccountHint': hint,
      };
      if (kIsWeb) {
        // Cloud Function redirects back here after OAuth (grinta:// is mobile-only).
        payload['returnTo'] = Uri.base.origin;
      }
      final result = await callable.call(payload);

      final data = result.data;
      if (data is! Map) {
        return WhoopConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return WhoopConnectResult.failed;
      }

      // Web: stay in the same tab so OAuth returns to this Flutter session.
      // Mobile: open the system browser, then return via grinta:// deep link.
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      return launched ? WhoopConnectResult.success : WhoopConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopOAuthStart failed: ${e.code} ${e.message}\n$st');
      return WhoopConnectResult.failed;
    } catch (e, st) {
      debugPrint('whoopOAuthStart error: $e\n$st');
      return WhoopConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kWhoopDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('whoopDisconnect error: $e\n$st');
      return false;
    }
  }

  /// Moves a legacy whoopSync doc onto the signed-in uid (family profiles).
  ///
  /// Safe to call repeatedly; returns whether Whoop is connected for [playerId]
  /// under the current user after repair.
  Future<bool> repairPlayerSync({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || playerId.trim().isEmpty) return false;

    try {
      final callable =
          _functions.httpsCallable(kWhoopRepairPlayerSyncFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId.trim(),
      });
      final data = result.data;
      if (data is Map && data['connected'] == true) {
        return true;
      }
      return false;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopRepairPlayerSync failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('whoopRepairPlayerSync error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required WhoopCoachVisibility visibility,
  }) async {
    try {
      await _repository.updateCoachVisibility(
        uid: uid,
        playerId: playerId,
        visibility: visibility,
      );
      return true;
    } catch (e, st) {
      debugPrint('updateCoachVisibility error: $e\n$st');
      return false;
    }
  }

  Future<WhoopListActivitiesResult> listImportableActivities({
    required String playerId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable(kWhoopListActivitiesFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
      });
      final data = result.data;
      if (data is! Map) {
        return const WhoopListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final raw = data['activities'];
      if (raw is! List) {
        return const WhoopListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final activities = <WhoopImportableActivity>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final activity = WhoopImportableActivity.fromMap(entry);
        if (activity.externalId.isEmpty) continue;
        activities.add(activity);
      }
      final diagnostics = data['diagnostics'];
      return WhoopListActivitiesResult(
        activities: activities,
        fetchedFromWhoop: diagnostics is Map
            ? _asInt(diagnostics['fetchedFromWhoop'])
            : null,
        emptyReason: diagnostics is Map
            ? diagnostics['emptyReason']?.toString()
            : null,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopListActivities failed: ${e.code} ${e.message}\n$st');
      return WhoopListActivitiesResult(
        activities: const [],
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e, st) {
      debugPrint('whoopListActivities error: $e\n$st');
      return WhoopListActivitiesResult(
        activities: const [],
        errorCode: 'unknown',
        errorMessage: e.toString(),
      );
    }
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  Future<PersonalSportActivity?> importActivity({
    required String playerId,
    required String externalId,
    String visibility = 'private',
    int? feeling,
    String? notes,
    String? typeId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable(kWhoopImportActivityFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
        'externalId': externalId,
        'visibility': visibility,
        if (feeling != null) 'feeling': feeling,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (typeId != null && typeId.trim().isNotEmpty) 'typeId': typeId.trim(),
      });
      final data = result.data;
      if (data is! Map) return null;
      final id = data['id']?.toString().trim();
      if (id == null || id.isEmpty) return null;
      return PersonalSportActivityService().getById(id);
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('whoopImportActivity failed: ${e.code} ${e.message}\n$st');
      return null;
    } catch (e, st) {
      debugPrint('whoopImportActivity error: $e\n$st');
      return null;
    }
  }
}
