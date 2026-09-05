import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grinta/config/legal_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';

/// Health Connect permissions required by declared Play features.
const _allowedHealthPermissions = {
  'android.permission.health.READ_EXERCISE',
  'android.permission.health.READ_DISTANCE',
  'android.permission.health.WRITE_EXERCISE',
  'android.permission.health.WRITE_DISTANCE',
  'android.permission.health.READ_HEALTH_DATA_HISTORY',
};

/// Types Play flagged (or that plugins may merge). Must be tools:node=remove.
const _forceRemovedHealthPermissions = {
  'android.permission.health.READ_HEART_RATE',
  'android.permission.health.WRITE_HEART_RATE',
  'android.permission.health.READ_TOTAL_CALORIES_BURNED',
  'android.permission.health.WRITE_TOTAL_CALORIES_BURNED',
  'android.permission.health.READ_ACTIVE_CALORIES_BURNED',
  'android.permission.health.WRITE_ACTIVE_CALORIES_BURNED',
  'android.permission.health.READ_SLEEP',
  'android.permission.health.WRITE_SLEEP',
  'android.permission.health.READ_STEPS',
  'android.permission.health.WRITE_STEPS',
  'android.permission.health.READ_STEPS_CADENCE',
  'android.permission.health.WRITE_STEPS_CADENCE',
};

final _usesPermissionBlock = RegExp(r'<uses-permission\b[\s\S]*?/>');
final _androidName = RegExp(r'android:name="([^"]+)"');
final _toolsNode = RegExp(r'tools:node="([^"]+)"');

File _repoFile(String relativePath) {
  final candidates = [
    File(relativePath),
    File('../$relativePath'),
  ];
  for (final file in candidates) {
    if (file.existsSync()) return file;
  }
  fail('Missing repo file: $relativePath');
}

class _ParsedPermission {
  const _ParsedPermission({
    required this.name,
    required this.removed,
  });

  final String name;
  final bool removed;
}

List<_ParsedPermission> _parseHealthPermissions(String manifest) {
  final parsed = <_ParsedPermission>[];
  for (final match in _usesPermissionBlock.allMatches(manifest)) {
    final block = match.group(0)!;
    final name = _androidName.firstMatch(block)?.group(1);
    if (name == null || !name.startsWith('android.permission.health.')) {
      continue;
    }
    final node = _toolsNode.firstMatch(block)?.group(1);
    parsed.add(_ParsedPermission(name: name, removed: node == 'remove'));
  }
  return parsed;
}

void main() {
  test('LegalConfig privacy/terms URLs are https and non-empty', () {
    expect(LegalConfig.privacyPolicyUrl.startsWith('https://'), isTrue);
    expect(LegalConfig.termsOfServiceUrl.startsWith('https://'), isTrue);
    expect(
      LegalConfig.privacyPolicyUrl.contains('politiquedeconfidentialite'),
      isTrue,
    );
    expect(
      LegalConfig.termsOfServiceUrl.contains('conditionsutilisation'),
      isTrue,
    );
  });

  test('Google Health coach visibility omits sleep from UI keys', () {
    expect(GoogleHealthCoachVisibility.metricKeys, isNot(contains('sleep')));
    expect(
      GoogleHealthCoachVisibility.metricKeys,
      containsAll(['activity', 'heartrate', 'activeEnergy']),
    );
  });

  test('AndroidManifest keeps only declared Health Connect scopes', () {
    final manifest = _repoFile('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final healthPermissions = _parseHealthPermissions(manifest);

    final kept = healthPermissions
        .where((permission) => !permission.removed)
        .map((permission) => permission.name)
        .toSet();
    final removed = healthPermissions
        .where((permission) => permission.removed)
        .map((permission) => permission.name)
        .toSet();

    expect(
      kept,
      _allowedHealthPermissions,
      reason: 'Kept Health Connect permissions must match declared features '
          '(exercise + distance read/write + history).',
    );

    expect(
      removed,
      containsAll(_forceRemovedHealthPermissions),
      reason: 'Play-flagged Health Connect types must be tools:node="remove".',
    );

    const forbiddenTokens = [
      'HEART_RATE',
      'SLEEP',
      'STEPS',
      'ACTIVE_CALORIES',
      'TOTAL_CALORIES',
    ];
    for (final permission in healthPermissions) {
      final isForbidden = forbiddenTokens.any(permission.name.contains);
      if (isForbidden) {
        expect(
          permission.removed,
          isTrue,
          reason: '${permission.name} is not a declared feature and must be '
              'declared with tools:node="remove".',
        );
      }
    }

    expect(
      manifest.contains('android.permission.ACTIVITY_RECOGNITION'),
      isTrue,
    );
  });

  test('Android Health Connect client does not request flagged types', () {
    final source = _repoFile('lib/services/google_health_platform_io.dart')
        .readAsStringSync();
    expect(source.contains('HealthDataType.HEART_RATE'), isFalse);
    expect(source.contains('HealthDataType.TOTAL_CALORIES_BURNED'), isFalse);
    expect(source.contains('HealthDataType.ACTIVE_ENERGY_BURNED'), isFalse);
    expect(source.contains('HealthDataType.SLEEP'), isFalse);
    expect(source.contains('HealthDataType.STEPS'), isFalse);
    expect(source.contains('HealthDataType.WORKOUT'), isTrue);
    expect(source.contains('HealthDataType.DISTANCE_DELTA'), isTrue);
  });
}
