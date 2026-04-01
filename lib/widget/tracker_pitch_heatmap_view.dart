import 'package:flutter/material.dart';

import '../model/tracker/trackerData.dart';
import '../services/pitch_heatmap_builder.dart';
import 'proPitchView.dart';

class TrackerPitchHeatmapView extends StatelessWidget {
  final List<HeatmapPoint> heatmapPoints;
  final bool showRunPath;
  final PitchViewMode mode;
  final bool flipY;

  const TrackerPitchHeatmapView({
    super.key,
    required this.heatmapPoints,
    this.showRunPath = false,
    this.mode = PitchViewMode.fullLandscape,
    this.flipY = false,
  });

  @override
  Widget build(BuildContext context) {
    final heatmap = PitchHeatmapBuilder.fromHeatmapPoints(
      points: heatmapPoints,
      rows: 34,
      cols: 52,
      pitchWidthM: 105,
      pitchHeightM: 68,
      blurSigma: 10,
      opacity: 0.58,
    );

    final polyline = heatmapPoints.length >= 2 && showRunPath
        ? [
      PitchPolyline(
        pointsM: PitchHeatmapBuilder.polylineFromHeatmapPoints(
          heatmapPoints,
        ),
        segmentIntensity01:
        PitchHeatmapBuilder.segmentIntensityFromHeatmapPoints(
          heatmapPoints,
        ),
        strokeWidth: 3,
        showArrow: true,
        showStartEndDots: true,
      ),
    ]
        : const <PitchPolyline>[];

    return AspectRatio(
      aspectRatio: mode == PitchViewMode.fullPortrait
          ? 68 / 105
          : mode == PitchViewMode.topHalfPortrait
          ? 68 / 52.5
          : 105 / 68,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ProPitchView(
          pitchWidthM: 105,
          pitchHeightM: 68,
          mode: mode,
          heatmap: heatmap,
          polylines: polyline,
          padding: const EdgeInsets.all(12),
          flipY: flipY,
        ),
      ),
    );
  }
}