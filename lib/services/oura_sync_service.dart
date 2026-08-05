import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/oura_config.dart';
import 'package:grinta/model/oura_sync_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/services/oura_sync_repository.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OuraImportableActivity {
  const OuraImportableActivity({
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

  factory OuraImportableActivity.fromMap(Map<dynamic, dynamic> map) {
    DateTime? start;
    final rawStart = map['startDate']?.toString();
    if (rawStart != null && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    return OuraImportableActivity(
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

class OuraListActivitiesResult {
  const OuraListActivitiesResult({
    required this.activities,
    this.fetchedFromOura,
    this.emptyReason,
    this.errorCode,
    this.errorMessage,
  });

  final List<OuraImportableActivity> activities;
  final int? fetchedFromOura;
  final String? emptyReason;
  final String? errorCode;
  final String? errorMessage;

  bool get hasError => errorCode != null && errorCode!.isNotEmpty;
}

enum OuraConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class OuraSyncService {
  OuraSyncService._();

  static final OuraSyncService instance = OuraSyncService._();

  final OuraSyncRepository _repository = OuraSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kOuraFunctionsRegion);

  OuraSyncRepository get repository => _repository;

  Future<OuraConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? ouraAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return OuraConnectResult.unauthenticated;
    }

    final hint = ouraAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return OuraConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kOuraOAuthStartFunctionName);
      final payload = <String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'ouraAccountHint': hint,
      };
      if (kIsWeb) {
        payload['returnTo'] = Uri.base.origin;
      }
      final result = await callable.call(payload);

      final data = result.data;
      if (data is! Map) {
        return OuraConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return OuraConnectResult.failed;
      }

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      return launched ? OuraConnectResult.success : OuraConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('ouraOAuthStart failed: ${e.code} ${e.message}\n$st');
      return OuraConnectResult.failed;
    } catch (e, st) {
      debugPrint('ouraOAuthStart error: $e\n$st');
      return OuraConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kOuraDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('ouraDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('ouraDisconnect error: $e\n$st');
      return false;
    }
  }

  /// Moves a legacy ouraSync doc onto the signed-in uid (family profiles).
  Future<bool> repairPlayerSync({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || playerId.trim().isEmpty) return false;

    try {
      final callable =
          _functions.httpsCallable(kOuraRepairPlayerSyncFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId.trim(),
      });
      final data = result.data;
      if (data is Map && data['connected'] == true) {
        return true;
      }
      return false;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('ouraRepairPlayerSync failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('ouraRepairPlayerSync error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required OuraCoachVisibility visibility,
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

  Future<OuraListActivitiesResult> listImportableActivities({
    required String playerId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable(kOuraListActivitiesFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
      });
      final data = result.data;
      if (data is! Map) {
        return const OuraListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final raw = data['activities'];
      if (raw is! List) {
        return const OuraListActivitiesResult(
          activities: [],
          errorCode: 'invalid-response',
        );
      }
      final activities = <OuraImportableActivity>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final activity = OuraImportableActivity.fromMap(entry);
        if (activity.externalId.isEmpty) continue;
        activities.add(activity);
      }
      final diagnostics = data['diagnostics'];
      return OuraListActivitiesResult(
        activities: activities,
        fetchedFromOura: diagnostics is Map
            ? _asInt(diagnostics['fetchedFromOura'])
            : null,
        emptyReason: diagnostics is Map
            ? diagnostics['emptyReason']?.toString()
            : null,
      );
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('ouraListActivities failed: ${e.code} ${e.message}\n$st');
      return OuraListActivitiesResult(
        activities: const [],
        errorCode: e.code,
        errorMessage: e.message,
      );
    } catch (e, st) {
      debugPrint('ouraListActivities error: $e\n$st');
      return OuraListActivitiesResult(
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
          _functions.httpsCallable(kOuraImportActivityFunctionName);
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
      debugPrint('ouraImportActivity failed: ${e.code} ${e.message}\n$st');
      return null;
    } catch (e, st) {
      debugPrint('ouraImportActivity error: $e\n$st');
      return null;
    }
  }
}
