part of 'dashboard_screen.dart';

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: selected ? colorScheme.onPrimary : colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}



class _StatCompactCard extends StatefulWidget {
  const _StatCompactCard({
    required this.icon,
    required this.stats,
    required this.label,
    required this.accentColor,
    required this.matches,
    this.minWidth = 255,
    this.fillWidth = false,
    required this.type,
    required this.where,
    required this.userId,
    required this.teamId,
    required this.managedTeamsIds,
    required this.playerId,
  });

  final IconData icon;
  final _ActivityStats stats;
  final String label;
  final Color accentColor;
  final double minWidth;
  final bool fillWidth;
  final List<match_model.Match> matches;
  final DashboardStatsType type;
  final DashboardWhereType where;
  final String userId;
  final String teamId;
  final List<String> managedTeamsIds;
  final String? playerId;

  @override
  State<_StatCompactCard> createState() => _StatCompactCardState();
}

class _StatCompactCardState extends State<_StatCompactCard> {
  MetricType _selectedTrainingMetric = MetricType.workloadScore;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final bool hasMatchOutcomes = widget.stats.hasMatchOutcomes;
    final bool hasTrainingMetrics = widget.stats.hasTrainingMetrics;
    final bool showPersonalSports =
        widget.type == DashboardStatsType.personalSports;

    final double minHeight = hasMatchOutcomes
        ? 232
        : hasTrainingMetrics || showPersonalSports
        ? 0
        : 92;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: widget.fillWidth ? 0 : widget.minWidth,
        minHeight: minHeight,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(
              context: context,
              colors: colors,
              textTheme: textTheme,
              presentPercent: widget.stats.presentPecent,
              type: widget.type,
              where: widget.where,
            ),
            const SizedBox(height: 9),
            _StatProgressBar(stats: widget.stats),
            const SizedBox(height: 7),
            _buildDonePlannedLegend(colors),

            if (hasMatchOutcomes) ...[
              const SizedBox(height: 12),
              _MatchOutcomeRingsCard(stats: widget.stats),
              const SizedBox(height: 12),
              _buildMatchesList(
                context: context,
                colors: colors,
                textTheme: textTheme,
                userId: widget.userId,
                managedTeamsIds: widget.managedTeamsIds,
                teamId: widget.teamId,
                playerId: widget.playerId,
              ),
            ],

            if (hasTrainingMetrics) ...[
              const SizedBox(height: 12),
              MetricsPanel(
                metrics: widget.stats.trainingMetrics,
                initialMetricType: MetricType.workloadScore,
                maxVisibleRows: 10,
                teamId: widget.teamId,
              ),
            ],

            if (showPersonalSports) ...[
              const SizedBox(height: 12),
              _buildPersonalSportsList(
                context: context,
                colors: colors,
                textTheme: textTheme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSportsList({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
  }) {
    final l10n = context.l10n;
    final activities = widget.stats.personalActivities;
    if (activities.isEmpty) {
      return Text(
        l10n.emptyNoPersonalSportToShow,
        style: textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardPersonalSportsListTitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return PersonalSportActivityDashboardTile(
              activity: activities[index],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatchesList({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required String? userId,
    required List<String> managedTeamsIds,
    required String teamId,
    required String? playerId,
  }) {


    final AppSession session = context.read<AppSession>();
    bool isManager = (userId != null)
        ? managedTeamsIds.contains(teamId)
        : false;
    // Roster staff get the team match-detail view even without managers[].
    if (!isManager && isStaffOnTeamId(session, teamId)) {
      isManager = true;
    }

    final l10n = context.l10n;
    if (widget.matches.isEmpty) {
      return Text(
        l10n.emptyNoMatchToShow,
        style: textTheme.bodySmall?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final List<match_model.Match> sortedMatches =
    List<match_model.Match>.from(widget.matches);

    sortedMatches.sort((a, b) {
      final DateTime? dateA = _dateFromValue(a.timestamp);
      final DateTime? dateB = _dateFromValue(b.timestamp);

      final int millisA = dateA?.millisecondsSinceEpoch ?? 0;
      final int millisB = dateB?.millisecondsSinceEpoch ?? 0;

      return millisB.compareTo(millisA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dashboardMatchListTitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedMatches.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final match = sortedMatches[index];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  AnalyticsInteractions.logFeature(
                    AnalyticsFeatures.openMatchDetail,
                    parameters: <String, Object>{
                      'has_tracker': match.withTracker == true,
                      'source': 'dashboard',
                    },
                  );
                  Navigator.of(context).push(
                    analyticsMaterialRoute<void>(
                      screenName: AnalyticsScreenNames.matchDetail,
                      fullscreenDialog: true,
                      builder: (_) => MatchDetailScreen(
                        match: match,
                        isManager: isManager,
                        playerId: playerId,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.border,
                    ),
                  ),
                  child: AgendaMatchRow(
                    match: match,
                    withDateTime: true,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  DateTime? _dateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Widget _buildHeader({
    required BuildContext context,
    required AppColors colors,
    required TextTheme textTheme,
    required double presentPercent,
    required DashboardWhereType where,
    required DashboardStatsType type,
  }) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final String formattedValue = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(presentPercent);


    return Row(
      mainAxisSize: widget.fillWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.accentColor,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${widget.stats.total}',
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.stats.total > 0 && type == DashboardStatsType.trainings && where == DashboardWhereType.player) ...[
          const SizedBox(width: 8),
          Text(
            l10n.statsPresenceRate(formattedValue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: (presentPercent > 50.0)?colors.success:colors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDonePlannedLegend(AppColors colors) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _StatLegendItem(
            value: widget.stats.done,
            singularLabel: l10n.statsDoneSingular,
            pluralLabel: l10n.statsDonePlural,
            color: colors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatLegendItem(
            value: widget.stats.planned,
            singularLabel: l10n.statsPlannedSingular,
            pluralLabel: l10n.statsPlannedPlural,
            color: colors.warning,
            alignRight: true,
          ),
        ),
      ],
    );
  }

}



class _MatchOutcomeRingsCard extends StatelessWidget {
  const _MatchOutcomeRingsCard({
    required this.stats,
  });

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    final double goal =
    stats.totalOutcomes <= 0 ? 1 : stats.totalOutcomes.toDouble();

    return Container(
      width: double.infinity,
      height: 126,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: ActivityRingsCard.compact(
              backgroundColor: colors.card,
              borderRadius: 12,
              padding: EdgeInsets.zero,
              withgoal: true,
              rings: [
                ActivityRingItem(
                  label: l10n.statsWins,
                  value: stats.won.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.success,
                  trackColor: colors.success.withValues(alpha: 0.16),
                ),
                ActivityRingItem(
                  label: l10n.statsLosses,
                  value: stats.lost.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.danger,
                  trackColor: colors.danger.withValues(alpha: 0.16),
                ),
                ActivityRingItem(
                  label: l10n.statsDraws,
                  value: stats.draw.toDouble(),
                  goal: goal,
                  unit: '',
                  color: colors.warning,
                  trackColor: colors.warning.withValues(alpha: 0.16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MatchOutcomeLegendRow(
                  label: l10n.statsWins,
                  value: stats.won,
                  total: stats.totalOutcomes,
                  color: colors.success,
                ),
                const SizedBox(height: 8),
                _MatchOutcomeLegendRow(
                  label: l10n.statsLosses,
                  value: stats.lost,
                  total: stats.totalOutcomes,
                  color: colors.danger,
                ),
                const SizedBox(height: 8),
                _MatchOutcomeLegendRow(
                  label: l10n.statsDraws,
                  value: stats.draw,
                  total: stats.totalOutcomes,
                  color: colors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchOutcomeLegendRow extends StatelessWidget {
  const _MatchOutcomeLegendRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  final String label;
  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value/$total',
          style: textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _StatProgressBar extends StatelessWidget {
  const _StatProgressBar({
    required this.stats,
  });

  final _ActivityStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: Row(
          children: [
            if (stats.total == 0)
              Expanded(
                child: Container(
                  color: colors.border.withValues(alpha: 0.65),
                ),
              ),
            if (stats.done > 0)
              Expanded(
                flex: stats.done,
                child: Container(
                  color: colors.success,
                ),
              ),
            if (stats.planned > 0)
              Expanded(
                flex: stats.planned,
                child: Container(
                  color: colors.warning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatLegendItem extends StatelessWidget {
  const _StatLegendItem({
    required this.value,
    required this.singularLabel,
    required this.pluralLabel,
    required this.color,
    this.alignRight = false,
  });

  final int value;
  final String singularLabel;
  final String pluralLabel;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final String label = value == 1 ? singularLabel : pluralLabel;

    return Row(
      mainAxisAlignment:
      alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$value $label',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({
    required this.title,
    required this.message,
    this.isError = false,
  });

  final String title;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isError ? colors.danger : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}