import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/polar_hr_stats.dart';

/// Polar-style training-zones chart (HR over time on coloured zone bands).
///
/// Uses Grinta brand colours on a dark canvas, matching the Flow / Verity Sense
/// “Zones d'entraînement” view. Expects a 5-minute [timeline] synthesis.
class PolarHrZonesChart extends StatelessWidget {
  const PolarHrZonesChart({
    super.key,
    required this.timeline,
    this.hrMaxBpm,
    this.bucketMinutes = 5,
    this.height = 280,
  });

  final List<PolarHrTimelinePoint> timeline;
  final int? hrMaxBpm;
  final int bucketMinutes;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (timeline.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.dark.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.dark.border),
        ),
        child: Text(
          l10n.polarAnalysisHrTimelineEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.dark.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final bands = polarHrZoneBandsBpm(hrMaxBpm: hrMaxBpm);
    final minY = bands.first.y1;
    var maxY = bands.last.y2;
    for (final point in timeline) {
      if (point.avgBpm > maxY) maxY = point.avgBpm.toDouble();
      final pointMax = point.maxBpm;
      if (pointMax != null && pointMax > maxY) maxY = pointMax.toDouble();
    }
    maxY = math.max(maxY, minY + 20);

    final spots = timeline
        .map(
          (p) => FlSpot(
            p.offsetMinutes.toDouble(),
            p.avgBpm.toDouble().clamp(minY, maxY),
          ),
        )
        .toList(growable: false);

    final maxX = math.max(
      spots.last.x,
      (timeline.last.offsetMinutes + bucketMinutes).toDouble(),
    );

    final zoneFill = _grintaZoneFills();
    final tickBpms = <double>{
      for (final band in bands) ...[band.y1, band.y2],
    }.toList()
      ..sort();

    final showPercent = hrMaxBpm != null && hrMaxBpm! > 0;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.dark.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.dark.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.polarAnalysisTrainingZonesTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dark.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.polarAnalysisHrTimelineHint(bucketMinutes),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dark.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX <= 0 ? 1 : maxX,
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    for (final band in bands)
                      HorizontalRangeAnnotation(
                        y1: band.y1,
                        y2: math.min(band.y2, maxY),
                        color: zoneFill[band.zone] ??
                            colors.border.withValues(alpha: 0.25),
                      ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameSize: 18,
                    axisNameWidget: Text(
                      l10n.polarAnalysisUnitBpm,
                      style: TextStyle(
                        color: AppColors.dark.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (!_isNearTick(value, tickBpms)) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            value.round().toString(),
                            style: TextStyle(
                              color: AppColors.dark.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    axisNameSize: showPercent ? 18 : 0,
                    axisNameWidget: showPercent
                        ? Text(
                            l10n.polarAnalysisAxisPercent,
                            style: TextStyle(
                              color: AppColors.dark.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : const SizedBox.shrink(),
                    sideTitles: SideTitles(
                      showTitles: showPercent,
                      reservedSize: showPercent ? 34 : 8,
                      getTitlesWidget: (value, meta) {
                        if (!showPercent || !_isNearTick(value, tickBpms)) {
                          return const SizedBox.shrink();
                        }
                        final pct = ((value / hrMaxBpm!) * 100).round();
                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Text(
                            '$pct',
                            style: TextStyle(
                              color: AppColors.dark.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: _bottomInterval(maxX),
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > maxX + 0.01) {
                          return const SizedBox.shrink();
                        }
                        if (value != 0 &&
                            value != maxX &&
                            (value % _bottomInterval(maxX)).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Text(
                            '${value.round()}${l10n.polarAnalysisUnitMin}',
                            style: TextStyle(
                              color: AppColors.dark.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) =>
                        AppColors.dark.card.withValues(alpha: 0.96),
                    tooltipBorder: BorderSide(color: AppColors.dark.border),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.x.round()} ${l10n.polarAnalysisUnitMin}\n'
                          '${spot.y.round()} ${l10n.polarAnalysisUnitBpm}',
                          TextStyle(
                            color: AppColors.dark.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    preventCurveOverShooting: true,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    isStrokeJoinRound: true,
                    color: AppColors.light.primary,
                    dotData: FlDotData(
                      show: spots.length <= 2,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.light.primary,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, Color> _grintaZoneFills() {
    // Pastel Grinta bands on dark canvas (primary / secondary / success / warning).
    return <String, Color>{
      'z1': const Color(0xFFD8D8DC).withValues(alpha: 0.55),
      'z2': const Color(0xFFFFC9B0).withValues(alpha: 0.55),
      'z3': const Color(0xFF9FDFBF).withValues(alpha: 0.55),
      'z4': const Color(0xFFFFD89A).withValues(alpha: 0.55),
      'z5': const Color(0xFFFFB0A0).withValues(alpha: 0.55),
    };
  }

  static bool _isNearTick(double value, List<double> ticks) {
    for (final tick in ticks) {
      if ((value - tick).abs() < 0.51) return true;
    }
    return false;
  }

  static double _bottomInterval(double maxX) {
    if (maxX <= 20) return 5;
    if (maxX <= 60) return 10;
    if (maxX <= 120) return 15;
    return 30;
  }
}
