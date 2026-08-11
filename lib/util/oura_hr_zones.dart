import 'package:grinta/util/app_theme.dart';
import 'package:flutter/material.dart';

/// Oura-style HR zone keys (`z0`…`z5`) and BPM bands (% of HRmax).
const List<String> kOuraHrZoneKeys = <String>[
  'z0',
  'z1',
  'z2',
  'z3',
  'z4',
  'z5',
];

class OuraHrZoneBand {
  const OuraHrZoneBand({
    required this.zone,
    required this.minBpm,
    required this.maxBpm,
  });

  final String zone;
  final int minBpm;
  final int maxBpm;
}

/// Oura Locker %-of-max bands, or absolute fallbacks when HRmax is unknown.
List<OuraHrZoneBand> ouraHrZoneBandsBpm({int? hrMaxBpm}) {
  final max = hrMaxBpm;
  if (max == null || max <= 0) {
    return const <OuraHrZoneBand>[
      OuraHrZoneBand(zone: 'z0', minBpm: 40, maxBpm: 100),
      OuraHrZoneBand(zone: 'z1', minBpm: 100, maxBpm: 120),
      OuraHrZoneBand(zone: 'z2', minBpm: 120, maxBpm: 140),
      OuraHrZoneBand(zone: 'z3', minBpm: 140, maxBpm: 160),
      OuraHrZoneBand(zone: 'z4', minBpm: 160, maxBpm: 180),
      OuraHrZoneBand(zone: 'z5', minBpm: 180, maxBpm: 200),
    ];
  }
  final fractions = <(double, double)>[
    (0.0, 0.5),
    (0.5, 0.6),
    (0.6, 0.7),
    (0.7, 0.8),
    (0.8, 0.9),
    (0.9, 1.0),
  ];
  return [
    for (var i = 0; i < kOuraHrZoneKeys.length; i++)
      OuraHrZoneBand(
        zone: kOuraHrZoneKeys[i],
        minBpm: (max * fractions[i].$1).round(),
        maxBpm: i == fractions.length - 1
            ? (max > (max * fractions[i].$2).round()
                ? max
                : (max * fractions[i].$2).round())
            : (max * fractions[i].$2).round(),
      ),
  ];
}

/// Grinta pastel fills for Oura zones on a dark canvas (z0→z5 intensity).
List<Color> ouraGrintaZoneColors() {
  return <Color>[
    const Color(0xFF5A5A62), // z0 — muted charcoal
    const Color(0xFFD8D8DC), // z1 — soft grey
    AppColors.light.secondary, // z2 — peach
    AppColors.light.success, // z3 — green
    AppColors.light.warning, // z4 — amber
    AppColors.light.primary, // z5 — Grinta orange
  ];
}

String formatOuraDuration(int totalSeconds) {
  final safe = totalSeconds < 0 ? 0 : totalSeconds;
  final h = safe ~/ 3600;
  final m = (safe % 3600) ~/ 60;
  final s = safe % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatOuraStrain(double strain, {String locale = 'fr'}) {
  final useComma = locale.toLowerCase().startsWith('fr') ||
      locale.toLowerCase().startsWith('de') ||
      locale.toLowerCase().startsWith('es') ||
      locale.toLowerCase().startsWith('it');
  final fixed = strain.toStringAsFixed(1);
  return useComma ? fixed.replaceAll('.', ',') : fixed;
}
