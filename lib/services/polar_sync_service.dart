import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/polar_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class PolarImportableActivity {
  const PolarImportableActivity({
    required this.externalId,
    required this.name,
    required this.typeId,
    this.device,
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
  final String? device;
  final DateTime? startDate;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? paceSecondsPerKm;
  final double? caloriesKcal;
  final int? averageHeartRateBpm;

  String get displayLabel {
    final parts = <String>[name];
    if (device != null && device!.trim().isNotEmpty) {
      parts.add(device!.trim());
    }
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

  factory PolarImportableActivity.fromMap(Map<dynamic, dynamic> map) {
    DateTime? start;
    final rawStart = map['startDate']?.toString();
    if (rawStart != null && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    return PolarImportableActivity(
      externalId: (map['externalId'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      typeId: (map['typeId'] ?? 'entrainement').toString().trim(),
      device: () {
        final value = (map['device'] ?? '').toString().trim();
        return value.isEmpty ? null : value;
      }(),
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

class PolarListActivitiesResult {
  const PolarListActivitiesResult({
    required this.activities,
    this.fetchedFromPolar,
    this.emptyReason,
    this.errorCode,
    this.errorMessage,
  });

  final List<PolarImportableActivity> activities;
  final int? fetchedFromPolar;
  final String? emptyReason;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

enum PolarConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class PolarSyncService {
  PolarSyncService._();

  static final PolarSyncService instance = PolarSyncService._();

  final PolarSyncRepository _repository = PolarSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kPolarFunctionsRegion);

  PolarSyncRepository get repository => _repository;

  Future<PolarConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? polarAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return PolarConnectResult.unauthenticated;
    }

    final hint = polarAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return PolarConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kPolarOAuthStartFunctionName);
      final payload = <String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'polarAccountHint': hint,
      };
      if (kIsWeb) {
        // Cloud Function redirects back here after OAuth (grinta:// is mobile-only).
        payload['returnTo'] = Uri.base.origin;
      }
      final result = await callable.call(payload);

      final data = result.data;
      if (data is! Map) {
        return PolarConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return PolarConnectResult.failed;
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
      return launched
          ? PolarConnectResult.success
          : PolarConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('polarOAuthStart failed: ${e.code} ${e.message}\n$st');
      return PolarConnectResult.failed;
    } catch (e, st) {
      debugPrint('polarOAuthStart error: $e\n$st');
      return PolarConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kPolarDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('polarDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('polarDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required PolarCoachVisibility visibility,
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

  Future<PolarListActivitiesResult> listImportableActivities({
    required String playerId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable(kPolarListActivitiesFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
      });
      final data = result.data;
      if (data is! Map) {
        return const PolarListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final raw = data['activities'];
      if (raw is! List) {
        return const PolarListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final activities = <PolarImportableActivity>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final activity = PolarImportableActivity.fromMap(entry);
        if (activity.externalId.isEmpty) continue;
        activities.add(activity);
      }
      final diagnostics = data['diagnostics'];
      return PolarListActivitiesResult(
        activities: activities,
        fetchedFromPolar: diagnostics is Map
            ? _asInt(diagnostics['fetchedFromPolar'])
            : null,
        emptyReason: diagnostics is Map
            ? diagnostics['emptyReason']?.toString()
            : null,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('polarListActivities failed: ${e.code} ${e.message}\n$st');
      return PolarListActivitiesResult(
        activities: const [],
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e, st) {
      debugPrint('polarListActivities error: $e\n$st');
      return PolarListActivitiesResult(
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
          _functions.httpsCallable(kPolarImportActivityFunctionName);
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
      debugPrint('polarImportActivity failed: ${e.code} ${e.message}\n$st');
      return null;
    } catch (e, st) {
      debugPrint('polarImportActivity error: $e\n$st');
      return null;
    }
  }
}
