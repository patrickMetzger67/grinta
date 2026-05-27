part of 'tracker_player_analysis_widget.dart';

class _PlayerAnalysisTabDef {
  final String label;
  final String compactLabel;
  final IconData icon;
  final Widget child;

  const _PlayerAnalysisTabDef({
    required this.label,
    required this.compactLabel,
    required this.icon,
    required this.child,
  });
}

class _PlayerAnalysisTabSelector extends StatelessWidget {
  final List<_PlayerAnalysisTabDef> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PlayerAnalysisTabSelector({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.of(context).size.width;
    final bool compact = width < 520;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int perRow = constraints.maxWidth >= 1050
              ? tabs.length
              : constraints.maxWidth >= 760
              ? 3
              : 2;

          final double spacing = 6;
          final double itemWidth =
              (constraints.maxWidth - ((perRow - 1) * spacing)) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int index = 0; index < tabs.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: _PlayerAnalysisTabButton(
                    tab: tabs[index],
                    selected: selectedIndex == index,
                    compact: compact,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerAnalysisTabButton extends StatelessWidget {
  final _PlayerAnalysisTabDef tab;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _PlayerAnalysisTabButton({
    required this.tab,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final bgColor = selected ? colors.primary : Colors.transparent;
    final fgColor = selected ? Colors.white : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                color: fgColor,
                size: compact ? 17 : 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  compact ? tab.compactLabel : tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerAnalysisHeader extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;
  final String? playerName;
  final bool compact;
  final Player player;

  const _PlayerAnalysisHeader({
    required this.analysis,
    required this.teamParam,
    required this.playerName,
    required this.compact,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = _clean(playerName).isNotEmpty
        ? playerName!.trim()
        : _formatPlayerId(analysis.playerId);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderTitle(
            title: title,
            analysis: analysis,
            player: player,
          ),
          const SizedBox(height: 12),
          _HeaderBadges(
            analysis: analysis,
            teamParam: teamParam,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _HeaderTitle(
              title: title,
              analysis: analysis,
              player: player,
            ),
          ),
          const SizedBox(width: 16),
          _HeaderBadges(
            analysis: analysis,
            teamParam: teamParam,
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String title;
  final TrackerAnalysisResult analysis;
  final Player player;

  const _HeaderTitle({
    required this.title,
    required this.analysis,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipOval(
            child: PlayerPhoto(
              player: player,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tracker ${analysis.trackerId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBadges extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _HeaderBadges({
    required this.analysis,
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        /*
        _SmallBadge(
          icon: Icons.event_rounded,
          label: analysis.eventId,
        ),
        */
        _SmallBadge(
          icon: Icons.timer_rounded,
          label: _durationLong(analysis.duration),
        ),
        _SmallBadge(
          icon: Icons.settings_rounded,
          label: teamParam.isDefault
              ? l10n.trackerParamDefault
              : l10n.trackerParamTeam(teamParam.teamId),
        ),
      ],
    );
  }
}

class _TeamParamBadge extends StatelessWidget {
  final TeamParam teamParam;

  const _TeamParamBadge({
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message:
      'Sprint ≥ ${teamParam.sprintThresholdKmh.toStringAsFixed(1)} km/h • '
          'Accélération haute ≥ ${teamParam.highAccelerationThresholdMps2.toStringAsFixed(1)} m/s²',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          'teamParam',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 420;

              if (compact && trailing != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    trailing!,
                  ],
                );
              }

              return Row(
                children: [
                  Icon(
                    icon,
                    color: colors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

