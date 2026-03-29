import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../model/tracker/trackerData.dart';

class TrackerTimelineChart extends StatelessWidget {
  final List<TimelinePoint> points;

  const TrackerTimelineChart({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final minX = points.first.timeSec;
    final maxX = points.last.timeSec;

    final speedSpots = points
        .map((p) => FlSpot(p.timeSec, p.speedKmh))
        .toList();

    final accelSpots = points
        .map((p) => FlSpot(p.timeSec, p.accelerationMps2))
        .toList();

    final sprintRanges = _extractSprintRanges(points);

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: _computeMaxSpeed(points),
                  gridData: const FlGridData(show: true),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toStringAsFixed(1)} s\n${spot.y.toStringAsFixed(1)} km/h',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Vitesse (km/h)'),
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Text('Temps (s)'),
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: sprintRanges.map((range) {
                      return VerticalRangeAnnotation(
                        x1: range.$1,
                        x2: range.$2,
                        color: Colors.red.withValues(alpha: 0.15),
                      );
                    }).toList(),
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: 20,
                        y2: 20,
                        color: Colors.orange.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: speedSpots,
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: _computeMinAccel(points),
                  maxY: _computeMaxAccel(points),
                  gridData: const FlGridData(show: true),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toStringAsFixed(1)} s\n${spot.y.toStringAsFixed(2)} m/s²',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text('Accélération (m/s²)'),
                      sideTitles: const SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Temps (s)'),
                      sideTitles: const SideTitles(showTitles: true),
                    ),
                  ),
                  rangeAnnotations: RangeAnnotations(
                    verticalRangeAnnotations: sprintRanges.map((range) {
                      return VerticalRangeAnnotation(
                        x1: range.$1,
                        x2: range.$2,
                        color: Colors.red.withValues(alpha: 0.15),
                      );
                    }).toList(),
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: 2.5,
                        y2: 2.5,
                        color: Colors.green.withValues(alpha: 0.7),
                      ),
                      HorizontalRangeAnnotation(
                        y1: -2.5,
                        y2: -2.5,
                        color: Colors.deepOrange.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: accelSpots,
                      isCurved: true,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendItem(Colors.blue, 'Vitesse'),
              _legendItem(Colors.red.withValues(alpha: 0.35), 'Sprint'),
              _legendItem(Colors.orange, 'Seuil 20 km/h'),
              _legendItem(Colors.green, 'Accel +2.5'),
              _legendItem(Colors.deepOrange, 'Decel -2.5'),
            ],
          ),
        ),
      ],
    );
  }

  static List<(double, double)> _extractSprintRanges(List<TimelinePoint> points) {
    final ranges = <(double, double)>[];
    bool inSprint = false;
    double? start;

    for (final p in points) {
      if (p.isSprint && !inSprint) {
        start = p.timeSec;
        inSprint = true;
      } else if (!p.isSprint && inSprint) {
        ranges.add((start!, p.timeSec));
        start = null;
        inSprint = false;
      }
    }

    if (inSprint && start != null) {
      ranges.add((start, points.last.timeSec));
    }

    return ranges;
  }

  static double _computeMaxSpeed(List<TimelinePoint> points) {
    final maxValue = points
        .map((e) => e.speedKmh)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 5).clamp(10, 50).toDouble();
  }

  static double _computeMinAccel(List<TimelinePoint> points) {
    final minValue = points
        .map((e) => e.accelerationMps2)
        .reduce((a, b) => a < b ? a : b);
    return (minValue - 1).clamp(-8, 0).toDouble();
  }

  static double _computeMaxAccel(List<TimelinePoint> points) {
    final maxValue = points
        .map((e) => e.accelerationMps2)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue + 1).clamp(2, 8).toDouble();
  }

  static Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}