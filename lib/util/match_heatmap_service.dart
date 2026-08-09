import 'package:flutter/foundation.dart';

import '../model/fieldGpsCorners.dart';
import '../model/tracker/trackerData.dart';
import '../services/sensorAnalysisService.dart';
import '../widget/proPitchView.dart';
import 'heatmap_svg_generator.dart';
import 'satellite_heatmap_svg_generator.dart';

/// Generates and optionally persists match heatmaps.
///
/// Rules:
/// - [fieldGps] present with projected heat points → schematic pitch only
///   (satellite never overwrites a geolocalized schematic).
/// - [fieldGps] absent (or geolocalized but empty projection) → try Google
///   satellite from GPS samples; if that fails, fall back to a relative
///   schematic on a virtual 105×68 pitch so personal GPS / USB still get a
///   heatmap in `TRACKER_Svg`.
class MatchHeatmapService {
  MatchHeatmapService._();

  /// Virtual pitch matching [SensorAnalysisService.buildRelativeHeatmapPoints].
  static const FootballFieldGps relativePitchField = FootballFieldGps(
    topLeft: FieldCornerGps(latitude: 0, longitude: 0),
    topRight: FieldCornerGps(latitude: 0, longitude: 0.001),
    bottomLeft: FieldCornerGps(latitude: -0.0006, longitude: 0),
    bottomRight: FieldCornerGps(latitude: -0.0006, longitude: 0.001),
    fieldLengthMeters: 105,
    fieldWidthMeters: 68,
  );

  /// Returns true when the pitch corners are available (geolocalized field).
  static bool isFieldGeolocalized(FootballFieldGps? fieldGps) =>
      fieldGps != null;

  static bool _hasUsableSvg(String? svg) =>
      svg != null && svg.trim().isNotEmpty;

  static Future<String?> generateSvg({
    required FootballFieldGps? fieldGps,
    required List<TrackerRaw> samples,
    List<HeatmapPoint> heatmapPoints = const [],
    List<PitchPolyline> sprintPolylines = const [],
    List<List<TrackerRaw>> sprintSegments = const [],
    bool flipX = false,
    bool flipY = false,
    double svgWidth = 1600,
    double svgHeight = 1000,
  }) async {
    // Geolocalized with heat: keep current schematic heatmap unchanged.
    if (isFieldGeolocalized(fieldGps) && heatmapPoints.isNotEmpty) {
      return HeatmapSvgGenerator.generateSvg(
        field: fieldGps!,
        heatmapPoints: heatmapPoints,
        sprintPolylines: sprintPolylines,
        flipX: flipX,
        flipY: flipY,
        svgWidth: svgWidth,
        svgHeight: svgHeight,
      );
    }

    // Prefer satellite when samples exist.
    if (samples.isNotEmpty) {
      final satellite = await SatelliteHeatmapSvgGenerator.generateSvg(
        samples: samples,
        sprintSegments: sprintSegments,
        svgWidth: svgWidth.round(),
        svgHeight: svgHeight.round(),
      );
      if (_hasUsableSvg(satellite)) return satellite;
    }

    // Satellite unavailable: relative schematic from heat points / samples.
    final points = heatmapPoints.isNotEmpty
        ? heatmapPoints
        : SensorAnalysisService.buildRelativeHeatmapPoints(samples);
    if (points.isEmpty) return null;

    return HeatmapSvgGenerator.generateSvg(
      field: relativePitchField,
      heatmapPoints: points,
      sprintPolylines: sprintPolylines,
      flipX: flipX,
      flipY: flipY,
      svgWidth: svgWidth,
      svgHeight: svgHeight,
    );
  }

  /// Persists full-match (+ halves when provided) heatmaps for a sensor match.
  static Future<MatchHeatmapBundle> generateAndSaveMatchHeatmaps({
    required String trackerId,
    required String eventId,
    required FootballFieldGps? fieldGps,
    required List<TrackerRaw> fullSamples,
    required List<HeatmapPoint> fullHeatmapPoints,
    List<PitchPolyline> fullSprintPolylines = const [],
    List<List<TrackerRaw>> fullSprintSegments = const [],
    List<TrackerRaw> firstHalfSamples = const [],
    List<HeatmapPoint> firstHalfHeatmapPoints = const [],
    List<PitchPolyline> firstHalfSprintPolylines = const [],
    List<List<TrackerRaw>> firstHalfSprintSegments = const [],
    List<TrackerRaw> secondHalfSamples = const [],
    List<HeatmapPoint> secondHalfHeatmapPoints = const [],
    List<PitchPolyline> secondHalfSprintPolylines = const [],
    List<List<TrackerRaw>> secondHalfSprintSegments = const [],
    bool persist = true,
    bool skipSchematicPersist = false,
  }) async {
    final geolocalized = isFieldGeolocalized(fieldGps);
    final hasProjectedHeat = fullHeatmapPoints.isNotEmpty;

    // Geolocalized field with projected points: schematic only.
    if (geolocalized && hasProjectedHeat) {
      final shouldPersist = persist && !skipSchematicPersist;
      final bundle = await _generateSchematicBundle(
        fieldGps: fieldGps!,
        fullHeatmapPoints: fullHeatmapPoints,
        fullSprintPolylines: fullSprintPolylines,
        firstHalfHeatmapPoints: firstHalfHeatmapPoints,
        firstHalfSprintPolylines: firstHalfSprintPolylines,
        secondHalfHeatmapPoints: secondHalfHeatmapPoints,
        secondHalfSprintPolylines: secondHalfSprintPolylines,
      );
      if (shouldPersist) {
        await _persistBundle(
          trackerId: trackerId,
          eventId: eventId,
          bundle: bundle,
        );
      }
      debugPrint(
        '[MatchHeatmap] schematic (geolocalized) '
        'tracker=$trackerId event=$eventId persist=$shouldPersist',
      );
      return bundle;
    }

    // Not geolocalized, or geolocalized but empty projection: satellite first.
    final satellite = await _generateSatelliteBundle(
      fullSamples: fullSamples,
      fullSprintSegments: fullSprintSegments,
      firstHalfSamples: firstHalfSamples,
      firstHalfSprintSegments: firstHalfSprintSegments,
      secondHalfSamples: secondHalfSamples,
      secondHalfSprintSegments: secondHalfSprintSegments,
    );
    if (_hasUsableSvg(satellite.fullMatch)) {
      if (persist) {
        await _persistBundle(
          trackerId: trackerId,
          eventId: eventId,
          bundle: satellite,
        );
      }
      debugPrint(
        '[MatchHeatmap] satellite '
        'tracker=$trackerId event=$eventId persist=$persist '
        'geolocalizedEmptyProjection=${geolocalized && !hasProjectedHeat}',
      );
      return satellite;
    }

    // Satellite failed (API key / Static Maps / network): relative schematic.
    final fullPoints = fullHeatmapPoints.isNotEmpty
        ? fullHeatmapPoints
        : SensorAnalysisService.buildRelativeHeatmapPoints(fullSamples);
    final firstPoints = firstHalfHeatmapPoints.isNotEmpty
        ? firstHalfHeatmapPoints
        : SensorAnalysisService.buildRelativeHeatmapPoints(firstHalfSamples);
    final secondPoints = secondHalfHeatmapPoints.isNotEmpty
        ? secondHalfHeatmapPoints
        : SensorAnalysisService.buildRelativeHeatmapPoints(secondHalfSamples);

    if (fullPoints.isEmpty) {
      debugPrint(
        '[MatchHeatmap] no heatmap writable '
        'tracker=$trackerId event=$eventId '
        'samples=${fullSamples.length} satellite=failed',
      );
      return const MatchHeatmapBundle(usedSatelliteBackground: false);
    }

    final relative = await _generateSchematicBundle(
      fieldGps: relativePitchField,
      fullHeatmapPoints: fullPoints,
      fullSprintPolylines: const [],
      firstHalfHeatmapPoints: firstPoints,
      firstHalfSprintPolylines: const [],
      secondHalfHeatmapPoints: secondPoints,
      secondHalfSprintPolylines: const [],
    );
    if (persist) {
      await _persistBundle(
        trackerId: trackerId,
        eventId: eventId,
        bundle: relative,
      );
    }
    debugPrint(
      '[MatchHeatmap] relative schematic (satellite unavailable) '
      'tracker=$trackerId event=$eventId persist=$persist '
      'points=${fullPoints.length}',
    );
    return relative;
  }

  static Future<MatchHeatmapBundle> _generateSchematicBundle({
    required FootballFieldGps fieldGps,
    required List<HeatmapPoint> fullHeatmapPoints,
    required List<PitchPolyline> fullSprintPolylines,
    required List<HeatmapPoint> firstHalfHeatmapPoints,
    required List<PitchPolyline> firstHalfSprintPolylines,
    required List<HeatmapPoint> secondHalfHeatmapPoints,
    required List<PitchPolyline> secondHalfSprintPolylines,
  }) async {
    String schematic({
      required List<HeatmapPoint> points,
      List<PitchPolyline> sprints = const [],
    }) {
      return HeatmapSvgGenerator.generateSvg(
        field: fieldGps,
        heatmapPoints: points,
        sprintPolylines: sprints,
        flipX: false,
        flipY: false,
        svgWidth: 1600,
        svgHeight: 1000,
      );
    }

    return MatchHeatmapBundle(
      fullMatch: schematic(points: fullHeatmapPoints),
      fullMatchWithSprints: schematic(
        points: fullHeatmapPoints,
        sprints: fullSprintPolylines,
      ),
      firstHalf: firstHalfHeatmapPoints.isEmpty
          ? null
          : schematic(points: firstHalfHeatmapPoints),
      firstHalfWithSprints: firstHalfHeatmapPoints.isEmpty
          ? null
          : schematic(
              points: firstHalfHeatmapPoints,
              sprints: firstHalfSprintPolylines,
            ),
      secondHalf: secondHalfHeatmapPoints.isEmpty
          ? null
          : schematic(points: secondHalfHeatmapPoints),
      secondHalfWithSprints: secondHalfHeatmapPoints.isEmpty
          ? null
          : schematic(
              points: secondHalfHeatmapPoints,
              sprints: secondHalfSprintPolylines,
            ),
      usedSatelliteBackground: false,
    );
  }

  static Future<MatchHeatmapBundle> _generateSatelliteBundle({
    required List<TrackerRaw> fullSamples,
    required List<List<TrackerRaw>> fullSprintSegments,
    required List<TrackerRaw> firstHalfSamples,
    required List<List<TrackerRaw>> firstHalfSprintSegments,
    required List<TrackerRaw> secondHalfSamples,
    required List<List<TrackerRaw>> secondHalfSprintSegments,
  }) async {
    Future<String?> satellite({
      required List<TrackerRaw> samples,
      List<List<TrackerRaw>> sprintSegments = const [],
    }) {
      if (samples.isEmpty) return Future<String?>.value(null);
      return SatelliteHeatmapSvgGenerator.generateSvg(
        samples: samples,
        sprintSegments: sprintSegments,
        svgWidth: 1280,
        svgHeight: 800,
      );
    }

    return MatchHeatmapBundle(
      fullMatch: await satellite(samples: fullSamples),
      fullMatchWithSprints: await satellite(
        samples: fullSamples,
        sprintSegments: fullSprintSegments,
      ),
      firstHalf: await satellite(samples: firstHalfSamples),
      firstHalfWithSprints: await satellite(
        samples: firstHalfSamples,
        sprintSegments: firstHalfSprintSegments,
      ),
      secondHalf: await satellite(samples: secondHalfSamples),
      secondHalfWithSprints: await satellite(
        samples: secondHalfSamples,
        sprintSegments: secondHalfSprintSegments,
      ),
      usedSatelliteBackground: true,
    );
  }

  static Future<void> _persistBundle({
    required String trackerId,
    required String eventId,
    required MatchHeatmapBundle bundle,
  }) async {
    Future<void> save(String suffix, String? svg) async {
      if (!_hasUsableSvg(svg)) return;
      await HeatmapSvgGenerator.saveSvgToFirestore(
        fileName: '$trackerId-${eventId}_$suffix',
        svg: svg!,
      );
    }

    await save('fullMatch', bundle.fullMatch);
    await save('fullMatchWithSprints', bundle.fullMatchWithSprints);
    await save('firstHalf', bundle.firstHalf);
    await save('firstHalfWithSprints', bundle.firstHalfWithSprints);
    await save('secondHalf', bundle.secondHalf);
    await save('secondHalfWithSprints', bundle.secondHalfWithSprints);
  }

  /// Extracts contiguous high-speed GPS segments (same thresholds as ASI UI).
  static List<List<TrackerRaw>> extractSprintSegments(
    List<TrackerRaw> samples, {
    double sprintThresholdMps = 5.5,
    int minDurationMs = 1000,
  }) {
    if (samples.length < 2) return const [];

    final sorted = [...samples]..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    final segments = <List<TrackerRaw>>[];
    List<TrackerRaw>? current;

    for (final sample in sorted) {
      final isSprint = sample.speedMps >= sprintThresholdMps;
      if (isSprint) {
        current ??= <TrackerRaw>[];
        current.add(sample);
      } else if (current != null) {
        if (_segmentDurationMs(current) >= minDurationMs) {
          segments.add(current);
        }
        current = null;
      }
    }
    if (current != null && _segmentDurationMs(current) >= minDurationMs) {
      segments.add(current);
    }
    return segments;
  }

  static int _segmentDurationMs(List<TrackerRaw> segment) {
    if (segment.length < 2) return 0;
    return segment.last.timeMs - segment.first.timeMs;
  }
}

class MatchHeatmapBundle {
  const MatchHeatmapBundle({
    this.fullMatch,
    this.fullMatchWithSprints,
    this.firstHalf,
    this.firstHalfWithSprints,
    this.secondHalf,
    this.secondHalfWithSprints,
    this.usedSatelliteBackground = false,
  });

  final String? fullMatch;
  final String? fullMatchWithSprints;
  final String? firstHalf;
  final String? firstHalfWithSprints;
  final String? secondHalf;
  final String? secondHalfWithSprints;
  final bool usedSatelliteBackground;
}
