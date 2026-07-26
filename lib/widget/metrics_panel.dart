import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:grinta/widget/session_player_analysis_view.dart';
import 'package:grinta/widget/session_tracker_stats_view.dart';
import 'package:provider/provider.dart';

import '../model/activityMetrics.dart';
import '../model/player.dart';
import '../model/season.dart';
import '../model/tracker/trackerData.dart';
import '../provider/appSession.dart';
import '../services/playerService.dart';
import '../services/polar_session_analysis_service.dart';
import '../services/trackerDataAnalysisService.dart';
import '../core/extensions/l10n_extension.dart';
import '../util/app_theme.dart';
import '../util/playerDisplayName.dart';
import '../util/session_tracker_kit.dart';
import '../util/staff_session_access.dart';

class MetricsPanel extends StatefulWidget {
  const MetricsPanel({
    super.key,
    required this.metrics,
    this.initialMetricType = MetricType.workloadScore,
    this.maxVisibleRows = 10,
    this.spacing = 10,
    this.showSelector = true,
    this.onMetricChanged,
    required this.teamId,
  });

  final List<ActivityMetrics> metrics;
  final MetricType initialMetricType;
  final int maxVisibleRows;
  final double spacing;
  final bool showSelector;
  final ValueChanged<MetricType>? onMetricChanged;
  final String teamId;

  @override
  State<MetricsPanel> createState() => _MetricsPanelState();
}

class _MetricsPanelState extends State<MetricsPanel> {
  late MetricType _selectedMetricType;

  @override
  void initState() {
    super.initState();
    _selectedMetricType = widget.initialMetricType;
  }

  @override
  void didUpdateWidget(covariant MetricsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialMetricType != widget.initialMetricType) {
      _selectedMetricType = widget.initialMetricType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showSelector) ...[
          _buildMetricSelector(
            context: context,
            colors: colors,
            textTheme: textTheme,
          ),
          SizedBox(height: widget.spacing),
        ],
        TrainingMetricsListView(
          metrics: widget.metrics,
          metricType: _selectedMetricType,
          maxVisibleRows: widget.maxVisibleRows,
          teamId: widget.teamId,
        ),
        if (widget.metrics.isNotEmpty) ...[
          SizedBox(height: widget.spacing),
          TrainingMetricLineChart(
            metrics: widget.metrics,
            metricType: _selectedMetricType,
          ),
        ],
      ],
    );
  }

  Widget _buildMetricSelector({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
  }) {
    return DropdownButtonFormField<MetricType>(
      value: _selectedMetricType,
      isExpanded: true,
      dropdownColor: colors.surface,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.textSecondary,
        size: 22,
      ),
      decoration: InputDecoration(
        labelText: context.l10n.hintMetric,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        filled: true,
        fillColor: colors.card,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.4,
          ),
        ),
      ),
      style: textTheme.bodySmall?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      items: MetricType.values.map((metricType) {
        return DropdownMenuItem<MetricType>(
          value: metricType,
          child: Text(
            metricType.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedMetricType = value;
        });

        widget.onMetricChanged?.call(value);
      },
    );
  }
}

class TrainingMetricsListView extends StatefulWidget {
  const TrainingMetricsListView({
    super.key,
    required this.metrics,
    required this.metricType,
    this.maxVisibleRows = 10,
    required this.teamId,
  });

  final List<ActivityMetrics> metrics;
  final MetricType metricType;
  final int maxVisibleRows;
  final String teamId;

  @override
  State<TrainingMetricsListView> createState() =>
      _TrainingMetricsListViewState();
}

class _TrainingMetricsListViewState extends State<TrainingMetricsListView> {
  final ScrollController _scrollController = ScrollController();

  static const double _rowHeight = 45.0;
  static const double _separatorHeight = 1.0;

  @override
  void didUpdateWidget(covariant TrainingMetricsListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool metricChanged = oldWidget.metricType != widget.metricType;
    final bool dataChanged = oldWidget.metrics.length != widget.metrics.length;

    if ((metricChanged || dataChanged) && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (widget.metrics.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          context.l10n.emptyNoData,
          style: textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final int safeMaxVisibleRows =
    widget.maxVisibleRows <= 0 ? 10 : widget.maxVisibleRows;

    final int visibleRows = widget.metrics.length > safeMaxVisibleRows
        ? safeMaxVisibleRows
        : widget.metrics.length;

    final int visibleSeparators = visibleRows > 0 ? visibleRows - 1 : 0;

    final double listHeight =
        (visibleRows * _rowHeight) + (visibleSeparators * _separatorHeight);

    final bool canScroll = widget.metrics.length > safeMaxVisibleRows;

    return Container(
      height: listHeight,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: canScroll,
          child: ListView.separated(
            controller: _scrollController,
            primary: false,
            shrinkWrap: false,
            padding: EdgeInsets.zero,
            physics: canScroll
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            itemCount: widget.metrics.length,
            separatorBuilder: (context, index) {
              return Divider(
                height: _separatorHeight,
                thickness: _separatorHeight,
                color: colors.border,
              );
            },
            itemBuilder: (context, index) {
              final item = widget.metrics[index];

              return TrainingMetricRow(
                item: item,
                metricType: widget.metricType,
                index: index,
                teamId: widget.teamId,
              );
            },
          ),
        ),
      ),
    );
  }
}

class TrainingMetricLineChart extends StatelessWidget {
  const TrainingMetricLineChart({
    super.key,
    required this.metrics,
    required this.metricType,
    this.height = 230,
  });

  final List<ActivityMetrics> metrics;
  final MetricType metricType;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final List<ActivityMetrics> sortedMetrics = [...metrics]
      ..sort((a, b) => a.timestamp.toDate().compareTo(b.timestamp.toDate()));

    final List<ActivityMetrics> cleanMetrics = sortedMetrics.where((item) {
      final value = _metricValue(item, metricType);
      return value.isFinite;
    }).toList();

    if (cleanMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<FlSpot> spots = <FlSpot>[];

    for (int i = 0; i < cleanMetrics.length; i++) {
      final double value = _metricValue(cleanMetrics[i], metricType);

      spots.add(
        FlSpot(
          i.toDouble(),
          value,
        ),
      );
    }

    final double minValue = spots.map((spot) => spot.y).reduce(math.min);
    final double maxValue = spots.map((spot) => spot.y).reduce(math.max);

    final double rawRange = maxValue - minValue;

    final double padding = rawRange <= 0
        ? math.max(1.0, maxValue.abs() * 0.20)
        : rawRange * 0.20;

    final double minY = math.max(0.0, minValue - padding);
    final double maxY = maxValue + padding;

    final double horizontalInterval = _niceInterval((maxY - minY) / 4);

    final double verticalInterval = spots.length <= 1
        ? 1
        : math.max(1.0, (spots.length - 1) / 4);

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.metricsEvolutionTitle(metricType.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.surface,
                      colors.card,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 10, 2),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: spots.length <= 1
                          ? 1
                          : (spots.length - 1).toDouble(),
                      minY: minY,
                      maxY: maxY,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: horizontalInterval,
                        verticalInterval: verticalInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: colors.border.withValues(alpha: 0.55),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: colors.border.withValues(alpha: 0.45),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: horizontalInterval,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: Text(
                                  _formatAxisValue(value),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11,
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
                            interval: 1,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              final int index = value.round();

                              if ((value - index).abs() > 0.001 ||
                                  index < 0 ||
                                  index >= cleanMetrics.length) {
                                return const SizedBox.shrink();
                              }

                              final DateTime date =
                              cleanMetrics[index].timestamp.toDate();

                              return SideTitleWidget(
                                meta: meta,
                                space: 8,
                                child: Transform.rotate(
                                  angle: -0.45,
                                  child: Text(
                                    _formatShortDate(date),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
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
                          tooltipMargin: 12,
                          maxContentWidth: 130,
                          tooltipBorderRadius: BorderRadius.circular(12),
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          tooltipBorder: BorderSide(color: colors.border),
                          getTooltipColor: (touchedSpot) {
                            return colors.surface.withValues(alpha: 0.96);
                          },
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final String valueText = _formatMetricValue(
                                value: touchedSpot.y,
                                metricType: metricType,
                              );

                              return LineTooltipItem(
                                valueText,
                                TextStyle(
                                  color: colors.textPrimary,
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
                          curveSmoothness: 0.35,
                          preventCurveOverShooting: true,
                          barWidth: 5,
                          isStrokeCapRound: true,
                          isStrokeJoinRound: true,
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.success,
                            ],
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colors.primary.withValues(alpha: 0.28),
                                colors.success.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                          dotData: FlDotData(
                            show: spots.length == 1,
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _niceInterval(double rawInterval) {
    if (!rawInterval.isFinite || rawInterval <= 0) {
      return 1;
    }

    final double exponent =
    math.pow(10, (math.log(rawInterval) / math.ln10).floor()).toDouble();

    final double normalized = rawInterval / exponent;

    if (normalized <= 1) return exponent;
    if (normalized <= 2) return 2 * exponent;
    if (normalized <= 5) return 5 * exponent;

    return 10 * exponent;
  }

  static String _formatAxisValue(double value) {
    if (!value.isFinite) return '';

    final double absValue = value.abs();

    if (absValue >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    }

    if (absValue >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }

    if (absValue >= 100) {
      return value.toStringAsFixed(0);
    }

    if (absValue >= 10) {
      return value.toStringAsFixed(1).replaceAll('.', ',');
    }

    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}

class TrainingMetricRow extends StatelessWidget {
  const TrainingMetricRow({
    super.key,
    required this.item,
    required this.metricType,
    required this.index,
    required this.teamId,
  });

  final ActivityMetrics item;
  final MetricType metricType;
  final int index;
  final String teamId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final double value = _metricValue(item, metricType);
    final double zScore = _metricZScore(item, metricType);

    final String valueText = _formatMetricValue(
      value: value,
      metricType: metricType,
    );

    final String zScoreText = _formatZScore(zScore);

    final DateTime date = item.timestamp.toDate();


    final AppSession session = context.watch<AppSession>();
    // Managers and roster staff open the team tracker table (not player analysis).
    final bool isManager = canAccessTeamSessionDetails(session, teamId);

    String? currentPlayerId = session.selectedPlayerId;

    return SizedBox(
      height: 45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: colors.primary.withValues(alpha: 0.05),
          splashColor: colors.primary.withValues(alpha: 0.10),
          highlightColor: colors.primary.withValues(alpha: 0.06),
          onTap: () async {

            String? docId;
            Player? player;

            if(isManager == false) {
              final isPolar = await eventUsesPolarTeamKit(
                eventId: item.eventId,
              );
              if (isPolar) {
                docId = await PolarSessionAnalysisService()
                    .getDocIdByEventAndPlayerId(
                  eventId: item.eventId,
                  playerId: currentPlayerId!,
                );
              } else {
                docId = await TrackerAnalysisService
                    .getAnalysisDocIdByEventAndPlayerId(
                  item.eventId,
                  currentPlayerId!,
                );
              }
              player = await PlayerService().getPlayerById(currentPlayerId);
            }

            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: context.l10n.actionClose,
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 180),
              pageBuilder: (
                  BuildContext dialogContext,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  ) {
                return Material(
                  color: colors.background,
                  child: SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 110),
                                    child: Text(
                                     dialogContext.l10n.trainingOnDate(
                                       _formatShortDate(date),
                                     ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: colors.primary.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.close_rounded,
                                            size: 18,
                                            color: colors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dialogContext.l10n.actionClose,
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Divider(
                          height: 1,
                          color: colors.border,
                        ),

                        if(isManager) ... [
                          Expanded(
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SessionTrackerStatsView(
                                  eventId: item.eventId,
                                  teamId: teamId,
                                  realtime: true,
                                  isMatch: false,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if(isManager == false) ... [
                          Expanded(
                            child: SessionPlayerAnalysisView(
                              eventId: item.eventId,
                              analysisDocId: docId,
                              playerId: currentPlayerId,
                              teamId: '',
                              playerName: playerDisplayName(
                                player!,
                                unknownLabel: context.l10n.entityPlayer,
                              ),
                              player: player,
                              isMatch: false,
                              showHeader: false,
                            ),
                          ),
                        ],

                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _formatShortDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  valueText,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 8),

                if (zScore != 0.0)
                  ZScoreChip(
                    value: zScore,
                    text: zScoreText,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ZScoreChip extends StatelessWidget {
  const ZScoreChip({
    super.key,
    required this.value,
    required this.text,
  });

  final double value;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final Color color = value > 0
        ? colors.success
        : value < 0
        ? colors.danger
        : colors.textSecondary;

    return Container(
      constraints: const BoxConstraints(minWidth: 50),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

double _metricValue(
    ActivityMetrics item,
    MetricType metricType,
    ) {
  switch (metricType) {
    case MetricType.distanceKm:
      return item.distanceKM;

    case MetricType.highAccelerationCount:
      return item.highAccelerationCount.toDouble();

    case MetricType.highSpeedDuration:
      return item.highSpeedDuration;

    case MetricType.maxAccelerationMps2:
      return item.maxAccelerationMps2;

    case MetricType.maxValidatedSpeedKmh:
      return item.maxValidatedSpeedKmh;

    case MetricType.sprintCount:
      return item.sprintCount.toDouble();

    case MetricType.workloadScore:
      return item.workloadScore;
  }
}

double _metricZScore(
    ActivityMetrics item,
    MetricType metricType,
    ) {
  switch (metricType) {
    case MetricType.distanceKm:
      return item.distanceKMZScore;

    case MetricType.highAccelerationCount:
      return item.highAccelerationCountZScore;

    case MetricType.highSpeedDuration:
      return item.highSpeedDurationZScore;

    case MetricType.maxAccelerationMps2:
      return item.maxAccelerationMps2ZScore;

    case MetricType.maxValidatedSpeedKmh:
      return item.maxValidatedSpeedKmhZScore;

    case MetricType.sprintCount:
      return item.sprintCountZScore;

    case MetricType.workloadScore:
      return item.workloadScoreZScore;
  }
}

String _formatMetricValue({
  required double value,
  required MetricType metricType,
}) {
  final String unit = metricType.unit;

  final bool isIntegerMetric =
      metricType == MetricType.highAccelerationCount ||
          metricType == MetricType.sprintCount;

  final String formatted = isIntegerMetric
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');

  if (unit.isEmpty) {
    return formatted;
  }

  return '$formatted $unit';
}

String _formatZScore(double value) {
  final String sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatShortDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');

  return '$day/$month';
}