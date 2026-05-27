part of 'tracker_player_analysis_widget.dart';

class _SpeedZonesView extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _SpeedZonesView({
    required this.analysis,
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    final zones = teamParam.orderedSpeedZones;

    if (analysis.speedZones.isEmpty) {
      return _InlineEmptyState(
        message: context.l10n.emptyNoSpeedZone,
      );
    }

    return Column(
      children: zones.map((teamZone) {
        final stat = _findSpeedZoneStat(
          analysis.speedZones,
          teamZone.zoneId,
        );

        final duration = stat?.duration ?? Duration.zero;
        final percent = stat?.percentOfSession ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ZoneProgressRow(
            icon: _speedZoneIcon(teamZone.zoneId),
            title: teamZone.label,
            subtitle: _speedZoneRange(teamZone),
            value: _durationShort(duration),
            percent: percent,
            color: _speedZoneColor(context, teamZone.zoneId),
            trailing: '${percent.toStringAsFixed(1)} %',
          ),
        );
      }).toList(),
    );
  }

  SpeedZoneStat? _findSpeedZoneStat(
      List<SpeedZoneStat> stats,
      String zoneId,
      ) {
    for (final stat in stats) {
      if (stat.zoneId == zoneId) return stat;
    }
    return null;
  }

  String _speedZoneRange(TeamSpeedZone zone) {
    if (zone.maxKmh == null) {
      return '≥ ${zone.minKmh.toStringAsFixed(1)} km/h';
    }

    return '${zone.minKmh.toStringAsFixed(1)} - ${zone.maxKmh!.toStringAsFixed(1)} km/h';
  }

  IconData _speedZoneIcon(String zoneId) {
    switch (zoneId.toUpperCase()) {
      case 'Z1':
        return Icons.directions_walk_rounded;
      case 'Z2':
      case 'Z3':
        return Icons.directions_run_rounded;
      case 'Z4':
        return Icons.bolt_rounded;
      case 'Z5':
        return Icons.flash_on_rounded;
      default:
        return Icons.speed_rounded;
    }
  }

  Color _speedZoneColor(BuildContext context, String zoneId) {
    final colors = context.appColors;

    switch (zoneId.toUpperCase()) {
      case 'Z1':
        return colors.textSecondary;
      case 'Z2':
        return colors.primary;
      case 'Z3':
        return colors.secondary;
      case 'Z4':
        return colors.warning;
      case 'Z5':
        return colors.danger;
      default:
        return colors.primary;
    }
  }
}

class _FieldZonesView extends StatelessWidget {
  final List<FieldZoneStats> zones;

  const _FieldZonesView({
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (zones.isEmpty) {
      return _InlineEmptyState(
        message: l10n.emptyNoFieldZoneData,
      );
    }

    final Map<String, FieldZoneStats> byId = {
      for (final zone in zones) zone.zoneId: zone,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;

        if (compact) {
          return Column(
            children: [
              _FieldZoneRow(
                left: byId['ATT_LEFT'],
                right: byId['ATT_RIGHT'],
                leftLabel: l10n.fieldZoneAttackLeftShort,
                rightLabel: l10n.fieldZoneAttackRightShort,
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['MID_LEFT'],
                right: byId['MID_RIGHT'],
                leftLabel: l10n.fieldZoneMidLeftShort,
                rightLabel: l10n.fieldZoneMidRightShort,
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['DEF_LEFT'],
                right: byId['DEF_RIGHT'],
                leftLabel: l10n.fieldZoneDefenseLeftShort,
                rightLabel: l10n.fieldZoneDefenseRightShort,
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appColors.border),
            color: context.appColors.surface,
          ),
          child: Column(
            children: [
              _FieldZoneRow(
                left: byId['ATT_LEFT'],
                right: byId['ATT_RIGHT'],
                leftLabel: l10n.fieldZoneAttackLeft,
                rightLabel: l10n.fieldZoneAttackRight,
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['MID_LEFT'],
                right: byId['MID_RIGHT'],
                leftLabel: l10n.fieldZoneMidLeft,
                rightLabel: l10n.fieldZoneMidRight,
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['DEF_LEFT'],
                right: byId['DEF_RIGHT'],
                leftLabel: l10n.fieldZoneDefenseLeft,
                rightLabel: l10n.fieldZoneDefenseRight,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldZoneRow extends StatelessWidget {
  final FieldZoneStats? left;
  final FieldZoneStats? right;
  final String leftLabel;
  final String rightLabel;

  const _FieldZoneRow({
    required this.left,
    required this.right,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FieldZoneTile(
            label: leftLabel,
            zone: left,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FieldZoneTile(
            label: rightLabel,
            zone: right,
          ),
        ),
      ],
    );
  }
}

class _FieldZoneTile extends StatelessWidget {
  final String label;
  final FieldZoneStats? zone;

  const _FieldZoneTile({
    required this.label,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final occupancy = zone?.occupancyPercent ?? 0.0;
    final distanceKm = (zone?.distanceMeters ?? 0.0) / 1000.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            percent: occupancy,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${occupancy.toStringAsFixed(1)} %',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalfStatsView extends StatelessWidget {
  final TrackerAnalysisResult analysis;

  const _HalfStatsView({
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final halfStats = [...analysis.halfStats]
      ..sort((a, b) => a.halfIndex.compareTo(b.halfIndex));

    if (halfStats.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 520;

          final firstHalf = _HalfTile(
            title: l10n.halfFirst,
            distanceKm: analysis.firstHalfDistanceKm,
            averageSpeedKmh: 0,
            duration: Duration.zero,
          );

          final secondHalf = _HalfTile(
            title: l10n.halfSecond,
            distanceKm: analysis.secondHalfDistanceKm,
            averageSpeedKmh: 0,
            duration: Duration.zero,
          );

          if (compact) {
            return Column(
              children: [
                firstHalf,
                const SizedBox(height: 10),
                secondHalf,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: firstHalf),
              const SizedBox(width: 10),
              Expanded(child: secondHalf),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;

        final children = halfStats.map((half) {
          return _HalfTile(
            title: half.halfIndex == 1
                ? l10n.halfFirst
                : l10n.halfNth(half.halfIndex),
            distanceKm: half.distanceKm,
            averageSpeedKmh: half.averageSpeedKmh,
            duration: half.duration,
          );
        }).toList();

        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _HalfTile extends StatelessWidget {
  final String title;
  final double distanceKm;
  final double averageSpeedKmh;
  final Duration duration;

  const _HalfTile({
    required this.title,
    required this.distanceKm,
    required this.averageSpeedKmh,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _MiniValueLine(
            label: l10n.statsDistance,
            value: '${distanceKm.toStringAsFixed(2)} ${l10n.statsUnitKm}',
          ),
          _MiniValueLine(
            label: l10n.statsAvgSpeed,
            value: averageSpeedKmh > 0
                ? '${averageSpeedKmh.toStringAsFixed(1)} ${l10n.statsUnitKmh}'
                : '-',
          ),
          _MiniValueLine(
            label: l10n.statsDuration,
            value: duration.inMilliseconds > 0 ? _durationLong(duration) : '-',
          ),
        ],
      ),
    );
  }
}

class _DistanceTimelineView extends StatelessWidget {
  final List<DistanceTimelineStat> timeline;

  const _DistanceTimelineView({
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return _InlineEmptyState(
        message: context.l10n.emptyNoDistanceTimeline,
      );
    }

    final sorted = [...timeline]
      ..sort((a, b) => a.bucketStartMs.compareTo(b.bucketStartMs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineChartLegend(),
        const SizedBox(height: 12),
        _DistanceTimelineBarChart(
          timeline: sorted,
        ),
      ],
    );
  }
}

class _TimelineChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _LegendItem(
          label: context.l10n.speedZoneWalk,
          color: colors.textSecondary,
        ),
        _LegendItem(
          label: context.l10n.speedZoneJogging,
          color: colors.primary,
        ),
        _LegendItem(
          label: context.l10n.speedZoneRun,
          color: colors.secondary,
        ),
        _LegendItem(
          label: context.l10n.speedZoneHighIntensity,
          color: colors.warning,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DistanceTimelineBarChart extends StatelessWidget {
  final List<DistanceTimelineStat> timeline;

  const _DistanceTimelineBarChart({
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final double maxMeters = timeline.map((e) => e.totalMeters).fold<double>(
      0,
          (previous, value) => value > previous ? value : previous,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 560;

        final double chartHeight = compact ? 280 : 340;
        final double barWidth = compact ? 22 : 28;
        final double itemWidth = compact ? 54 : 64;
        final double minChartWidth = timeline.length * itemWidth;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minChartWidth < constraints.maxWidth
                  ? constraints.maxWidth
                  : minChartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: _DistanceTimelineBarChartPainter(
                  timeline: timeline,
                  maxMeters: maxMeters <= 0 ? 1 : maxMeters,
                  barWidth: barWidth,
                  textColor: colors.textSecondary,
                  gridColor: colors.border,
                  walkingColor: colors.textSecondary,
                  joggingColor: colors.primary,
                  runningColor: colors.secondary,
                  highIntensityColor: colors.warning,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DistanceTimelineBarChartPainter extends CustomPainter {
  final List<DistanceTimelineStat> timeline;
  final double maxMeters;
  final double barWidth;
  final Color textColor;
  final Color gridColor;
  final Color walkingColor;
  final Color joggingColor;
  final Color runningColor;
  final Color highIntensityColor;

  _DistanceTimelineBarChartPainter({
    required this.timeline,
    required this.maxMeters,
    required this.barWidth,
    required this.textColor,
    required this.gridColor,
    required this.walkingColor,
    required this.joggingColor,
    required this.runningColor,
    required this.highIntensityColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftAxisWidth = 42;
    const double bottomLabelHeight = 42;
    const double topPadding = 12;
    const double rightPadding = 8;

    final double chartLeft = leftAxisWidth;
    final double chartTop = topPadding;
    final double chartRight = size.width - rightPadding;
    final double chartBottom = size.height - bottomLabelHeight;
    final double chartHeight = chartBottom - chartTop;
    final double chartWidth = chartRight - chartLeft;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    final axisLabelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    final labelValues = <double>[
      maxMeters,
      maxMeters * 0.5,
      0,
    ];

    for (final value in labelValues) {
      final double y = chartBottom - ((value / maxMeters) * chartHeight);

      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );

      _drawText(
        canvas: canvas,
        text: value <= 0 ? '0' : '${value.toStringAsFixed(0)}m',
        offset: Offset(0, y - 7),
        width: leftAxisWidth - 6,
        style: axisLabelStyle,
        textAlign: TextAlign.right,
      );
    }

    final double itemWidth = chartWidth / timeline.length;

    for (int i = 0; i < timeline.length; i++) {
      final item = timeline[i];

      final double xCenter = chartLeft + (i * itemWidth) + (itemWidth / 2);
      final double barLeft = xCenter - (barWidth / 2);
      final double barRight = xCenter + (barWidth / 2);

      double currentBottom = chartBottom;

      final segments = [
        _ChartSegment(item.walkingMeters, walkingColor),
        _ChartSegment(item.joggingMeters, joggingColor),
        _ChartSegment(item.runningMeters, runningColor),
        _ChartSegment(item.highIntensityMeters, highIntensityColor),
      ].where((e) => e.value > 0).toList();

      for (int s = 0; s < segments.length; s++) {
        final segment = segments[s];

        final double height = (segment.value / maxMeters) * chartHeight;
        final double top = currentBottom - height;

        final radius = Radius.circular(barWidth / 2);

        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, top, barRight, currentBottom),
          topLeft: s == segments.length - 1 ? radius : Radius.zero,
          topRight: s == segments.length - 1 ? radius : Radius.zero,
          bottomLeft: s == 0 ? radius : Radius.zero,
          bottomRight: s == 0 ? radius : Radius.zero,
        );

        canvas.drawRRect(
          rrect,
          Paint()..color = segment.color,
        );

        currentBottom = top;
      }

      _drawText(
        canvas: canvas,
        text: _compactTimelineLabel(item.label),
        offset: Offset(xCenter - (itemWidth / 2), chartBottom + 9),
        width: itemWidth,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  String _compactTimelineLabel(String label) {
    return label
        .replaceAll(' min', '')
        .replaceAll(' ', '')
        .replaceAll('minutes', '');
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double width,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    painter.layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DistanceTimelineBarChartPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.maxMeters != maxMeters ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.walkingColor != walkingColor ||
        oldDelegate.joggingColor != joggingColor ||
        oldDelegate.runningColor != runningColor ||
        oldDelegate.highIntensityColor != highIntensityColor;
  }
}
