import 'dart:math';
import 'package:flutter/material.dart';
import '../model/tracker/trackerData.dart';
import '../widget/proPitchView.dart';

class PitchHeatmapBuilder {
  static PitchHeatmap fromHeatmapPoints({
    required List<HeatmapPoint> points,
    int rows = 34,
    int cols = 52,
    double pitchWidthM = 105,
    double pitchHeightM = 68,
    double blurSigma = 10,
    double opacity = 0.55,
    bool useIntensity = true,
    double fieldStartXM = 0.0,
    double fieldLengthXM = 105.0,
  }) {
    final values = List<double>.filled(rows * cols, 0);

    if (points.isEmpty) {
      return PitchHeatmap(
        rows: rows,
        cols: cols,
        values: values,
        blurSigma: blurSigma,
        opacity: opacity,
      );
    }

    for (final p in points) {
      if (p.xMeters < fieldStartXM || p.xMeters > fieldStartXM + fieldLengthXM) {
        continue;
      }

      final xLocal = (p.xMeters - fieldStartXM).clamp(0.0, fieldLengthXM);
      final y = p.yMeters.clamp(0.0, pitchHeightM);

      final col = min(cols - 1, max(0, (y / pitchHeightM * cols).floor()));
      final row = min(rows - 1, max(0, (xLocal / fieldLengthXM * rows).floor()));

      final idx = row * cols + col;
      values[idx] += useIntensity ? max(0.1, p.intensity) : 1.0;
    }

    return PitchHeatmap(
      rows: rows,
      cols: cols,
      values: values,
      blurSigma: blurSigma,
      opacity: opacity,
    );
  }

  static List<Offset> polylineFromHeatmapPoints(
      List<HeatmapPoint> points, {
        double fieldStartXM = 0.0,
        double fieldLengthXM = 105.0,
      }) {
    return points
        .where(
          (p) =>
      p.xMeters >= fieldStartXM &&
          p.xMeters <= fieldStartXM + fieldLengthXM,
    )
        .map((p) => Offset(p.xMeters, p.yMeters))
        .toList(growable: false);
  }

  static List<double> segmentIntensityFromHeatmapPoints(
      List<HeatmapPoint> points,
      ) {
    if (points.length < 2) return const [];

    final values = <double>[];
    double maxIntensity = 0;

    for (final p in points) {
      if (p.intensity > maxIntensity) {
        maxIntensity = p.intensity;
      }
    }

    final denom = maxIntensity <= 0 ? 1.0 : maxIntensity;

    for (int i = 0; i < points.length - 1; i++) {
      values.add((points[i].intensity / denom).clamp(0.0, 1.0));
    }

    return values;
  }
}