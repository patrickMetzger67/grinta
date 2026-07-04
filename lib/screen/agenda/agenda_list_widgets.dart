part of 'agenda_screen.dart';

class _AgendaControlsCard extends StatelessWidget {
  final DateTime selectedWeekStart;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final Future<void> Function() onPreviousWeek;
  final Future<void> Function() onNextWeek;
  final Future<void> Function() onToday;
  final Future<void> Function() onPickPeriod;
  final Future<void> Function() onExtendBefore;
  final Future<void> Function() onExtendAfter;

  const _AgendaControlsCard({
    required this.selectedWeekStart,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onToday,
    required this.onPickPeriod,
    required this.onExtendBefore,
    required this.onExtendAfter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).toString();
    final selectedWeekEnd = _endOfWeek(selectedWeekStart);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.navNavigation,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.periodSelectedWeek(
              _formatWeekRange(selectedWeekStart, selectedWeekEnd, locale),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.periodLoaded(_formatPeriodLabel(rangeStart, rangeEnd, locale)),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onPreviousWeek,
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(l10n.actionWeekPrevious),
              ),
              OutlinedButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded),
                label: Text(l10n.actionToday),
              ),
              OutlinedButton.icon(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                label: Text(l10n.actionWeekNext),
              ),
              FilledButton.icon(
                onPressed: onPickPeriod,
                icon: const Icon(Icons.date_range_rounded),
                label: Text(l10n.actionChoosePeriod),
              ),
              OutlinedButton.icon(
                onPressed: onExtendBefore,
                icon: const Icon(Icons.unfold_less_double_rounded),
                label: Text(l10n.actionLoadBefore),
              ),
              OutlinedButton.icon(
                onPressed: onExtendAfter,
                icon: const Icon(Icons.unfold_more_double_rounded),
                label: Text(l10n.actionLoadAfter),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaLegend extends StatelessWidget {
  const _AgendaLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.agendaLegend,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _LegendItem(
            label: l10n.entityMatch,
            color: _typeColor(context, AgendaItemType.match),
            icon: Icons.sports_soccer_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
          _LegendItem(
            label: l10n.entityTraining,
            color: _typeColor(context, AgendaItemType.entrainement),
            icon: Icons.fitness_center_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
          _LegendItem(
            label: l10n.periodPrep,
            color: _typeColor(context, AgendaItemType.preparationPhysique),
            icon: Icons.directions_run_rounded,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool fullWidth;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaWeeksList extends StatelessWidget {
  final ScrollController controller;
  final List<DateTime> weeks;
  final Map<DateTime, List<AgendaItem>> groupedByWeek;
  final bool compact;
  final DateTime selectedWeekStart;
  final DateTime selectedDate;
  final GlobalKey Function(DateTime weekStart) keyBuilder;
  final ValueChanged<DateTime> onWeekTap;

  const _AgendaWeeksList({
    required this.controller,
    required this.weeks,
    required this.groupedByWeek,
    required this.compact,
    required this.selectedWeekStart,
    required this.selectedDate,
    required this.keyBuilder,
    required this.onWeekTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(weeks.length, (index) {
              final weekStart = weeks[index];
              final weekItems = <AgendaItem>[
                ...(groupedByWeek[weekStart] ?? <AgendaItem>[]),
              ]..sort((a, b) => a.startAt.compareTo(b.startAt));

              final isSelected =
                  weekStart.millisecondsSinceEpoch ==
                      selectedWeekStart.millisecondsSinceEpoch;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == weeks.length - 1 ? 0 : 14,
                ),
                child: Container(
                  key: keyBuilder(weekStart),
                  child: _WeekCard(
                    weekStart: weekStart,
                    items: weekItems,
                    compact: compact,
                    isSelected: isSelected,
                    selectedDate: selectedDate,
                    onTap: () => onWeekTap(weekStart),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final DateTime weekStart;
  final List<AgendaItem> items;
  final bool compact;
  final bool isSelected;
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _WeekCard({
    required this.weekStart,
    required this.items,
    required this.compact,
    required this.isSelected,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final weekEnd = weekStart.add(const Duration(days: 6));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              ...List.generate(7, (index) {
                final day = weekStart.add(Duration(days: index));
                final dayItems =
                items.where((e) => _isSameDay(e.startAt, day)).toList();

                return _DayRow(
                  date: day,
                  items: dayItems,
                  compact: compact,
                  isLast: index == 6,
                  isSelected: _isSameDay(day, selectedDate),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekDescription(
    List<AgendaItem> items,
    AppLocalizations l10n,
  ) {
    final matchs = items.where((e) => e.type == AgendaItemType.match).length;
    final trainings =
        items.where((e) => e.type == AgendaItemType.entrainement).length;
    final prepas =
        items.where((e) => e.type == AgendaItemType.preparationPhysique).length;

    final parts = <String>[];
    if (matchs > 0) parts.add(l10n.agendaEventSummaryMatches(matchs));
    if (trainings > 0) {
      parts.add(l10n.agendaEventSummaryTrainings(trainings));
    }
    if (prepas > 0) {
      parts.add(l10n.agendaEventSummaryPrepas(prepas));
    }

    return parts.isEmpty ? l10n.emptyNoEvent : parts.join(' • ');
  }
}

class _DayRow extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> items;
  final bool compact;
  final bool isLast;
  final bool isSelected;

  const _DayRow({
    required this.date,
    required this.items,
    required this.compact,
    required this.isLast,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateUtils.dateOnly(DateTime.now());
    final currentDay = DateUtils.dateOnly(date);
    final isToday =
        currentDay.millisecondsSinceEpoch == today.millisecondsSinceEpoch;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final veryNarrow = constraints.maxWidth < 430;

          if (veryNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateColumn(
                  date: date,
                  isToday: isToday,
                  isSelected: isSelected,
                  compact: compact,
                ),
                const SizedBox(height: 10),
                _DayContent(items: items),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 62 : 72,
                child: _DateColumn(
                  date: date,
                  isToday: isToday,
                  isSelected: isSelected,
                  compact: compact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DayContent(items: items),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool compact;

  const _DateColumn({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment:
      compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          _weekdayLabel(date, Localizations.localeOf(context).toString()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? colors.primary
                : isToday
                ? colors.primary.withOpacity(0.10)
                : Colors.transparent,
            border: !isSelected && isToday
                ? Border.all(color: colors.primary.withOpacity(0.25))
                : null,
          ),
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isSelected
                  ? Colors.white
                  : isToday
                  ? colors.primary
                  : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DayContent extends StatelessWidget {
  final List<AgendaItem> items;

  const _DayContent({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyDayTile();
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AgendaItemCard(item: item),
        ),
      )
          .toList(),
    );
  }
}

class _EmptyDayTile extends StatelessWidget {
  const _EmptyDayTile();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 18,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.emptyNoEvent,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItemCard extends StatelessWidget {
  final AgendaItem item;

  const _AgendaItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = _typeColor(context, item.type);
    final icon = _typeIcon(item.type);
    final locale = Localizations.localeOf(context).toString();
    final timeLabel = _agendaEventTimeLabel(item, locale);

    final List<String> managedTeamsIds =
    context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );

    Season? currentSeason = context.watch<AppSession>().selectedSeason;
    String? currentPlayerId = context.watch<AppSession>().selectedPlayerId;
    String? userId = context.watch<AppSession>().user!.uid;

    bool isManager = false;
    String teamId='';
    bool canManageThisMatch = false;
    bool canManageThisTraining = false;

    if(item.match != null) {
      final AppSession session = context.watch<AppSession>();
      canManageThisMatch = canManageMatch(item.match!, session);
      final String? managedTeamId = singleManagedMatchTeamId(item.match!);
      if (managedTeamId != null) {
        isManager = session.managedTeamsIdsForSelectedSeason.contains(managedTeamId);
        teamId = managedTeamId;
      } else {
        for (var t in item.match!.teams!) {
          isManager = managedTeamsIds.contains(t);
          teamId = t;
          if(isManager) {
            break;
          }
        }
      }
    }
    if (item.training != null) {
      final AppSession session = context.watch<AppSession>();
      canManageThisTraining = canManageTraining(item.training!, session);
      final String? managedTeamId = managedTrainingTeamId(item.training!);
      if (managedTeamId != null) {
        isManager = session.managedTeamsIdsForSelectedSeason.contains(managedTeamId);
        teamId = managedTeamId;
      } else {
        isManager = managedTeamsIds.contains(item.training!.teamId!);
        teamId = item.training!.teamId ?? '';
      }
    }

    TeamPlayerMetricScores? teamPlayerMetricScores;
    if(item.teamWorkloadSummary != null ) {
      for(var pm in item.teamWorkloadSummary!.playerScores) {
        if(pm.playerId == currentPlayerId) {
          teamPlayerMetricScores = pm;
        }
      }
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: colors.textPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (canManageThisMatch) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.editMatchTitle,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    onPressed: () {
                      showCreateMatchSheet(
                        context,
                        matchToEdit: item.match!,
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.actionDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    onPressed: () async {
                      await deleteManagedMatch(
                        context,
                        match: item.match!,
                        session: context.read<AppSession>(),
                      );
                    },
                  ),
                ],
                if (canManageThisTraining) ...[
                  if (item.training!.trainingEndAt == null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: context.l10n.finishTrainingTitle,
                      icon: Icon(
                        Icons.sports_score_rounded,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      onPressed: () async {
                        await finishManagedTraining(
                          context,
                          training: item.training!,
                        );
                      },
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.editTrainingTitle,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    onPressed: () {
                      showCreateTrainingSheet(
                        context,
                        trainingToEdit: item.training!,
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.actionDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    onPressed: () async {
                      await deleteManagedTraining(
                        context,
                        training: item.training!,
                      );
                    },
                  ),
                ],
                if (item.type == AgendaItemType.match &&
                    item.match != null) ...[
                  const SizedBox(width: 8),
                  MatchTrackerKitPillHost(
                    match: item.match!,
                    isManager: isManager,
                    variant: TrackerKitPillVariant.agendaCard,
                    showForNonManagerWithTracker: true,
                  ),
                ] else if (item.type == AgendaItemType.entrainement &&
                    item.withTracker == true) ...[
                  const SizedBox(width: 8),
                  TrackerKitGpsPill(
                    withTracker: true,
                    isManager: isManager,
                    variant: TrackerKitPillVariant.agendaCard,
                  ),
                ],
                if (item.isDone) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.success,
                  ),
                ],
              ],
            ),
            if (timeLabel != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if(isManager == false && item.withTracker == true && teamPlayerMetricScores != null) ... [
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  if (item.match != null) {
                    final match = item.match!;
                    AnalyticsInteractions.logFeature(
                      AnalyticsFeatures.openMatchDetail,
                      parameters: <String, Object>{
                        'has_tracker': match.withTracker == true,
                        'source': 'agenda_stats_ring',
                      },
                    );
                    Navigator.of(context).push(
                      analyticsMaterialRoute<void>(
                        screenName: AnalyticsScreenNames.matchDetail,
                        fullscreenDialog: true,
                        builder: (_) => MatchDetailScreen(
                          match: match,
                          isManager: false,
                          playerId: currentPlayerId,
                          initialTabIndex: MatchDetailScreen.statsTabIndexFor(
                            match,
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  AnalyticsInteractions.logFeature(
                    AnalyticsFeatures.openPlayerAnalysis,
                    parameters: const <String, Object>{
                      'source': 'agenda_stats_ring',
                      'is_match': false,
                    },
                  );

                  final String analysisDocId =
                      '${item.id}_${teamPlayerMetricScores?.trackerId}';

                  final Player? player =
                      await PlayerService().getPlayerById(currentPlayerId!);

                  if (!context.mounted) {
                    return;
                  }

                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: colors.background,
                    barrierColor: Colors.black54,
                    builder: (BuildContext bottomSheetContext) {
                      return Scaffold(
                        backgroundColor: colors.background,
                        body: SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () {
                                            Navigator.of(bottomSheetContext).pop();
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
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                  color: colors.primary,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  context.l10n.actionClose,
                                                  textAlign: TextAlign.center,
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
                                    ),

                                  ],
                                ),
                              ),

                              const Divider(height: 1),


                              Expanded(
                                child: TrackerPlayerAnalysisWidget(
                                  analysisDocId: analysisDocId,
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
                          ),
                        ),
                      );
                    },
                  );
                },
                child: activityRing(
                  context: context,
                  teamPlayerMetricScores: teamPlayerMetricScores,
                  teamWorkloadSummary: item.teamWorkloadSummary!,
                ),
              ),
            ],
            if(isManager && item.withTracker == true && item.teamWorkloadSummary != null) ... [
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final colors = context.appColors;


                  if(item.match != null) {
                    final match = item.match!;
                    AnalyticsInteractions.logFeature(
                      AnalyticsFeatures.openMatchDetail,
                      parameters: <String, Object>{
                        'has_tracker': match.withTracker == true,
                        'source': 'agenda_manager_ring',
                      },
                    );
                    Navigator.of(context).push(
                      analyticsMaterialRoute<void>(
                        screenName: AnalyticsScreenNames.matchDetail,
                        fullscreenDialog: true,
                        builder: (_) => MatchDetailScreen(
                          match: match,
                          isManager: isManager,
                          playerId: currentPlayerId,
                        ),
                      ),
                    );
                  } else {
                    AnalyticsInteractions.logFeature(
                      AnalyticsFeatures.openTrackerStats,
                      parameters: const <String, Object>{
                        'source': 'agenda_manager_ring',
                        'is_match': false,
                      },
                    );
                    showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
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
                                              context.l10n.agendaTrackerStatsTitle,
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
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                    color: colors.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    context.l10n.actionClose,
                                                    textAlign: TextAlign.center,
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
                                Expanded(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: MatchTrackerStatsTable(
                                        eventId: item.id,
                                        teamId: (item.training != null)?item.training!.teamId!:teamId,
                                        realtime: true,
                                        isMatch: (item.match == null)?false:true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
                child: activityRing(
                  context: context,
                  teamPlayerMetricScores: teamPlayerMetricScores,
                  teamWorkloadSummary: item.teamWorkloadSummary!,
                ),
              ),
            ],
            if (item.training != null && isManager == true) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final training = item.training!;
                  final teamId = training.teamId?.trim() ?? '';
                  if (teamId.isEmpty) return;

                  AnalyticsInteractions.logFeature(
                    AnalyticsFeatures.openTeamPlayers,
                    parameters: const <String, Object>{'source': 'agenda'},
                  );

                  TeamPlayersScreen.open(
                    context,
                    training: training,
                    title: context.l10n.entityPlayers,
                    subtitle: item.title,
                  );
                },
                child: _AgendaTrainingPlayersRow(
                  training: item.training!,
                ),
              ),
            ],
            if (item.match != null) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final match = item.match!;
                  AnalyticsInteractions.logFeature(
                    AnalyticsFeatures.openMatchDetail,
                    parameters: <String, Object>{
                      'has_tracker': match.withTracker == true,
                      'source': 'agenda_match_row',
                    },
                  );
                  Navigator.push(
                    context,
                    analyticsMaterialRoute<void>(
                      screenName: AnalyticsScreenNames.matchDetail,
                      builder: (_) => MatchDetailScreen(
                        match: match,
                        isManager: isManager,
                        playerId: currentPlayerId,
                      ),
                    ),
                  );
                },
                child: AgendaMatchRow(
                  match: item.match!,
                  withDateTime: false,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget activityRing({required BuildContext context,
    required TeamPlayerMetricScores? teamPlayerMetricScores,
    required TeamWorkloadSummary? teamWorkloadSummary,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;

    double charge = 0.0;
    double distance = 0.0;
    double tpsHauteVitesse = 0.0;
    double sprints = 0.0;
    double ms2 = 0.0;


    if(teamPlayerMetricScores != null) {
      charge = teamPlayerMetricScores.getMetric("workloadScore")!.value;
      distance = teamPlayerMetricScores.getMetric("distanceKm")!.value;
      tpsHauteVitesse = teamPlayerMetricScores.getMetric("highSpeedDuration")!.value;
      sprints = teamPlayerMetricScores.getMetric("sprintCount")!.value;
      ms2 = teamPlayerMetricScores.getMetric("maxAccelerationMps2")!.value;
    } else {
      charge = teamWorkloadSummary!.averageWorkloadScore;
      distance = teamWorkloadSummary.metricStats['distanceKm']!.mean;
      tpsHauteVitesse = teamWorkloadSummary.metricStats['highSpeedDuration']!.mean;
      sprints = teamWorkloadSummary.metricStats['sprintCount']!.mean;
      ms2 = teamWorkloadSummary.metricStats['maxAccelerationMps2']!.mean;
    }

    print('charge = $charge');


    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ActivityRingsCard.detailed(
        showWorkload: true,
        workloadScore: charge,
        workloadLabel: l10n.statsWorkload,
        workloadUnit: 'pts',
        workloadColor: Colors.orange,
        showLegend: true,
        embedded: true,
        backgroundColor: Colors.black,
        padding: const EdgeInsets.all(4),
        withgoal: false,
        rings: [
          ActivityRingItem(
            label: l10n.statsDistance,
            value: distance,
            goal: item.teamWorkloadSummary!.metricStats["distanceKm"]!.max,
            unit: l10n.statsUnitKm,
            color: colors.success,
            trackColor: Colors.greenAccent.withOpacity(0.18),
            icon: Icons.directions_run,
          ),
          ActivityRingItem(
            label: l10n.statsHighSpeedTimeShort,
            value: tpsHauteVitesse,
            goal: item.teamWorkloadSummary!.metricStats["highSpeedDuration"]!.max,
            unit: l10n.statsUnitSeconds,
            color: colors.primary,
            trackColor: Colors.blueAccent.withOpacity(0.18),
            icon: Icons.timer,
          ),
          ActivityRingItem(
            label: l10n.statsSprints,
            value: sprints,
            goal: item.teamWorkloadSummary!.metricStats["sprintCount"]!.max,
            unit: l10n.statsUnitCount,
            color: colors.warning,
            trackColor: Colors.redAccent.withOpacity(0.18),
            icon: Icons.speed,
          ),
          ActivityRingItem(
            label: l10n.statsMaxAccelSample,
            value: ms2,
            goal: item.teamWorkloadSummary!.metricStats["maxAccelerationMps2"]!.max,
            unit: l10n.statsUnitMps2,
            color: colors.danger,
            trackColor: Colors.redAccent.withOpacity(0.18),
            icon: Icons.speed,
          ),
        ],
      ),
    );
  }
}

class _AgendaTrainingPlayersRow extends StatelessWidget {
  final Training training;

  const _AgendaTrainingPlayersRow({
    required this.training,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.groups_2_outlined,
            size: 20,
            color: colors.textPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.entityPlayers,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }
}
