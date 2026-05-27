part of 'tracker_player_analysis_widget.dart';

enum _HeatmapPeriod {
  firstHalf,
  secondHalf,
  fullMatch,
}

extension _HeatmapPeriodX on _HeatmapPeriod {
  String label(AppLocalizations l10n) {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return l10n.halfFirst;
      case _HeatmapPeriod.secondHalf:
        return l10n.halfSecond;
      case _HeatmapPeriod.fullMatch:
        return l10n.entityFullMatchShort;
    }
  }

  String compactLabel(AppLocalizations l10n) {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return l10n.halfFirstShort;
      case _HeatmapPeriod.secondHalf:
        return l10n.halfSecondShort;
      case _HeatmapPeriod.fullMatch:
        return l10n.halfMatchShort;
    }
  }

  String get firestoreSuffix {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return 'firstHalf';
      case _HeatmapPeriod.secondHalf:
        return 'secondHalf';
      case _HeatmapPeriod.fullMatch:
        return 'fullMatch';
    }
  }
}

class _TrackerHeatmapView extends StatefulWidget {
  final TrackerAnalysisResult analysis;

  const _TrackerHeatmapView({
    required this.analysis,
  });

  @override
  State<_TrackerHeatmapView> createState() => _TrackerHeatmapViewState();
}

class _TrackerHeatmapViewState extends State<_TrackerHeatmapView> {
  final TrackerSvgService _service = TrackerSvgService();

  _HeatmapPeriod _selectedPeriod = _HeatmapPeriod.fullMatch;
  late Future<String?> _futureSvg;

  @override
  void initState() {
    super.initState();
    _futureSvg = _loadSvg();
  }

  @override
  void didUpdateWidget(covariant _TrackerHeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.analysis.eventId != widget.analysis.eventId ||
        oldWidget.analysis.trackerId != widget.analysis.trackerId) {
      _futureSvg = _loadSvg();
    }
  }

  Future<String?> _loadSvg() {
    return _service.getSvgForTrackerPeriod(
      trackerId: widget.analysis.trackerId,
      eventId: widget.analysis.eventId,
      periodSuffix: _selectedPeriod.firestoreSuffix,
    );
  }

  void _changePeriod(_HeatmapPeriod period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _futureSvg = _loadSvg();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeatmapPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onChanged: _changePeriod,
        ),
        const SizedBox(height: 12),
        FutureBuilder<String?>(
          future: _futureSvg,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _HeatmapContainer(
                child: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              final l10n = context.l10n;
              return _HeatmapEmptyState(
                icon: Icons.error_outline_rounded,
                title: l10n.errorLoadingTitle,
                message: snapshot.error.toString(),
              );
            }

            final svgToDisplay = snapshot.data;

            if (svgToDisplay == null || svgToDisplay.trim().isEmpty) {
              final l10n = context.l10n;
              return _HeatmapEmptyState(
                icon: Icons.image_not_supported_outlined,
                title: l10n.emptyHeatmap,
                message: l10n.emptyNoSvgForPeriod(
                  _selectedPeriod.label(l10n),
                ),
              );
            }

            return _HeatmapContainer(
              child: SvgPicture.string(
                svgToDisplay,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeatmapPeriodSelector extends StatelessWidget {
  final _HeatmapPeriod selectedPeriod;
  final ValueChanged<_HeatmapPeriod> onChanged;

  const _HeatmapPeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final periods = _HeatmapPeriod.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;
        final int perRow = compact ? 1 : 3;
        final double spacing = 8;
        final double itemWidth =
            (constraints.maxWidth - ((perRow - 1) * spacing)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: periods.map((period) {
            final bool selected = selectedPeriod == period;

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<_HeatmapPeriod>(
                        value: period,
                        groupValue: selectedPeriod,
                        onChanged: (value) {
                          if (value != null) {
                            onChanged(value);
                          }
                        },
                        activeColor: colors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          compact
                              ? period.compactLabel(l10n)
                              : period.label(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 13,
                            fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeatmapContainer extends StatelessWidget {
  final Widget child;

  const _HeatmapContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 560;
        final double height = compact ? 240 : 320;

        return Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: child,
        );
      },
    );
  }
}

class _HeatmapEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HeatmapEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _HeatmapContainer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colors.textSecondary,
              size: 34,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSegment {
  final double value;
  final Color color;

  const _ChartSegment(
      this.value,
      this.color,
      );
}

class _ZoneProgressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final double percent;
  final Color color;
  final String trailing;

  const _ZoneProgressRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.percent,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 420;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(
                        percent: percent,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trailing,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ProgressBar(
                            percent: percent,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trailing,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final Color color;

  const _ProgressBar({
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safePercent = percent.clamp(0.0, 100.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: colors.border.withValues(alpha: 0.55),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: safePercent / 100,
          child: Container(
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MiniValueLine extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label.isEmpty ? '-' : label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrackerPlayerLoadingCard extends StatelessWidget {
  const _TrackerPlayerLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      ),
    );
  }
}

class _TrackerPlayerEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TrackerPlayerEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackerPlayerAnalysisPayload {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _TrackerPlayerAnalysisPayload({
    required this.analysis,
    required this.teamParam,
  });
}

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatPlayerId(String playerId) {
  final safe = playerId.trim();

  if (safe.isEmpty) {
    return 'Joueur';
  }

  final parts = safe.split('-');

  if (parts.length >= 3 && !_looksLikeUuid(safe)) {
    final lastName = parts[0].trim().toUpperCase();
    final firstName = _capitalize(parts[1].trim());

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
  }

  return safe;
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  final lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) return '?';

  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
      .toUpperCase();
}

String _durationShort(Duration duration) {
  final totalSeconds = duration.inSeconds;

  if (totalSeconds <= 0) {
    return '0s';
  }

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes <= 0) {
    return '${seconds}s';
  }

  if (seconds == 0) {
    return '${minutes}min';
  }

  return '${minutes}min ${seconds}s';
}

String _durationLong(Duration duration) {
  final totalMinutes = duration.inMinutes;

  if (totalMinutes <= 0) {
    return '0 min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '$minutes min';
  }

  if (minutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${minutes}';
}