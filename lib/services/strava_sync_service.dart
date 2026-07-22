import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/config/strava_config.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class StravaImportableActivity {
  const StravaImportableActivity({
    required this.externalId,
    required this.name,
    required this.typeId,
    this.startDate,
    this.durationSeconds,
    this.distanceMeters,
    this.paceSecondsPerKm,
  });

  final String externalId;
  final String name;
  final String typeId;
  final DateTime? startDate;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? paceSecondsPerKm;

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
    }
    return parts.join(' · ');
  }

  factory StravaImportableActivity.fromMap(Map<dynamic, dynamic> map) {
    DateTime? start;
    final rawStart = map['startDate']?.toString();
    if (rawStart != null && rawStart.isNotEmpty) {
      start = DateTime.tryParse(rawStart);
    }
    return StravaImportableActivity(
      externalId: (map['externalId'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      typeId: (map['typeId'] ?? 'entrainement').toString().trim(),
      startDate: start,
      durationSeconds: _asInt(map['durationSeconds']),
      distanceMeters: _asDouble(map['distanceMeters']),
      paceSecondsPerKm: _asInt(map['paceSecondsPerKm']),
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

enum StravaConnectResult {
  success,
  cancelled,
  launchFailed,
  unauthenticated,
  failed,
}

class StravaSyncService {
  StravaSyncService._();

  static final StravaSyncService instance = StravaSyncService._();

  final StravaSyncRepository _repository = StravaSyncRepository();

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: kStravaFunctionsRegion);

  StravaSyncRepository get repository => _repository;

  Future<StravaConnectResult> startOAuth({
    required String playerId,
    required String initiatedBy,
    String? stravaAccountHint,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return StravaConnectResult.unauthenticated;
    }

    final hint = stravaAccountHint?.trim() ?? '';
    if (hint.isEmpty) {
      return StravaConnectResult.failed;
    }

    try {
      final callable = _functions.httpsCallable(kStravaOAuthStartFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
        'initiatedBy': initiatedBy,
        'stravaAccountHint': hint,
      });

      final data = result.data;
      if (data is! Map) {
        return StravaConnectResult.failed;
      }

      final authUrl = data['authUrl']?.toString().trim();
      if (authUrl == null || authUrl.isEmpty) {
        return StravaConnectResult.failed;
      }

      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      return launched
          ? StravaConnectResult.success
          : StravaConnectResult.launchFailed;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('stravaOAuthStart failed: ${e.code} ${e.message}\n$st');
      return StravaConnectResult.failed;
    } catch (e, st) {
      debugPrint('stravaOAuthStart error: $e\n$st');
      return StravaConnectResult.failed;
    }
  }

  Future<bool> disconnect({required String playerId}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    try {
      final callable = _functions.httpsCallable(kStravaDisconnectFunctionName);
      await callable.call(<String, dynamic>{'playerId': playerId});
      return true;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('stravaDisconnect failed: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('stravaDisconnect error: $e\n$st');
      return false;
    }
  }

  Future<bool> updateCoachVisibility({
    required String uid,
    required String playerId,
    required StravaCoachVisibility visibility,
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

  Future<List<StravaImportableActivity>> listImportableActivities({
    required String playerId,
  }) async {
    try {
      final callable =
          _functions.httpsCallable(kStravaListActivitiesFunctionName);
      final result = await callable.call(<String, dynamic>{
        'playerId': playerId,
        'perPage': 30,
      });
      final data = result.data;
      if (data is! Map) return const [];
      final raw = data['activities'];
      if (raw is! List) return const [];
      final activities = <StravaImportableActivity>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final activity = StravaImportableActivity.fromMap(entry);
        if (activity.externalId.isEmpty) continue;
        activities.add(activity);
      }
      return activities;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint('stravaListActivities failed: ${e.code} ${e.message}\n$st');
      return const [];
    } catch (e, st) {
      debugPrint('stravaListActivities error: $e\n$st');
      return const [];
    }
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
          _functions.httpsCallable(kStravaImportActivityFunctionName);
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
      debugPrint('stravaImportActivity failed: ${e.code} ${e.message}\n$st');
      return null;
    } catch (e, st) {
      debugPrint('stravaImportActivity error: $e\n$st');
      return null;
    }
  }
}
