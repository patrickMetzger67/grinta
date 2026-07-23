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
          const SizedBox(height: 8),
          _LegendItem(
            label: l10n.agendaAddEventNonSport,
            color: _typeColor(context, AgendaItemType.nonSport),
            icon: Icons.event_rounded,
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
              ]..sort(_compareAgendaItems);

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
                final dayItems = items
                    .where((e) => _agendaItemOccursOnDay(e, day))
                    .toList()
                  ..sort(_compareAgendaItems);

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
    final nonSports =
        items.where((e) => e.type == AgendaItemType.nonSport).length;

    final parts = <String>[];
    if (matchs > 0) parts.add(l10n.agendaEventSummaryMatches(matchs));
    if (trainings > 0) {
      parts.add(l10n.agendaEventSummaryTrainings(trainings));
    }
    if (prepas > 0) {
      parts.add(l10n.agendaEventSummaryPrepas(prepas));
    }
    if (nonSports > 0) {
      parts.add(l10n.agendaEventSummaryNonSport(nonSports));
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

    final sortedItems = List<AgendaItem>.from(items)..sort(_compareAgendaItems);

    return Column(
      children: sortedItems
          .map(
            (item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: item.allDay && item.type == AgendaItemType.nonSport
              ? _AllDayNonSportRow(item: item)
              : AgendaItemCard(item: item),
        ),
      )
          .toList(),
    );
  }
}

class _AllDayNonSportRow extends StatelessWidget {
  const _AllDayNonSportRow({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = _typeColor(context, AgendaItemType.nonSport);
    final NonSportEvent? event = item.nonSportEvent;
    final bool canManage = event != null &&
        canManageNonSportEvent(event, context.read<AppSession>());

    return Material(
      color: accent.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: event == null
            ? null
            : () => showNonSportEventInviteesSheet(
                  context,
                  event: event,
                ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: colors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                context.l10n.agendaAllDayLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.textPrimary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (canManage) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: context.l10n.editNonSportEventTitle,
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  onPressed: () {
                    showCreateNonSportEventSheet(
                      context,
                      eventToEdit: event,
                    );
                  },
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: context.l10n.actionDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  onPressed: () async {
                    await deleteManagedNonSportEvent(
                      context,
                      event: event,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
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

class AgendaItemCard extends StatelessWidget {
  final AgendaItem item;

  const AgendaItemCard({
    super.key,
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
    /// Manager/owner or roster staff — unlocks training/match detail views.
    bool canAccessSessionDetails = false;
    String teamId='';
    bool canManageThisMatch = false;
    bool canManageThisTraining = false;

    if(item.match != null) {
      final AppSession session = context.watch<AppSession>();
      canManageThisMatch = canManageMatch(item.match!, session);
      canAccessSessionDetails =
          canAccessMatchSessionDetails(item.match!, session);
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
        if (teamId.isEmpty) {
          teamId = item.match!.teamID?.trim() ?? '';
        }
      }
      // Staff without managers still get the team detail view.
      if (!isManager && canAccessSessionDetails) {
        isManager = true;
      }
    }
    if (item.training != null) {
      final AppSession session = context.watch<AppSession>();
      canManageThisTraining = canManageTraining(item.training!, session);
      canAccessSessionDetails =
          canAccessTrainingSessionDetails(item.training!, session);
      final String? managedTeamId = managedTrainingTeamId(item.training!);
      if (managedTeamId != null) {
        isManager =
            session.managedTeamsIdsForSelectedSeason.contains(managedTeamId);
        teamId = managedTeamId;
      } else {
        isManager = managedTeamsIds.contains(item.training!.teamId!);
        teamId = item.training!.teamId ?? '';
      }
      // Staff without managers still get team rings + detail view.
      if (!isManager && canAccessSessionDetails) {
        isManager = true;
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
                if (item.type == AgendaItemType.preparationPhysique &&
                    item.personalSportActivity != null) ...[
                  Builder(
                    builder: (context) {
                      final owner = _AgendaCoachPlayersScope.playerFor(
                        context,
                        item.personalSportActivity!.memberId,
                      );
                      if (owner == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PlayerPhoto(player: owner, radius: 14),
                      );
                    },
                  ),
                ],
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (item.type == AgendaItemType.preparationPhysique &&
                          item.personalSportActivity != null &&
                          PlayerFeeling.fromValue(
                                item.personalSportActivity!.feeling,
                              ) !=
                              null) ...[
                        const SizedBox(width: 8),
                        CustomPaint(
                          size: const Size(22, 22),
                          painter: FeelingFacePainter(
                            feeling: PlayerFeeling.fromValue(
                              item.personalSportActivity!.feeling,
                            )!,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ],
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
                ],
                if (item.type == AgendaItemType.nonSport &&
                    item.nonSportEvent != null) ...[
                  if (canManageNonSportEvent(
                    item.nonSportEvent!,
                    context.read<AppSession>(),
                  )) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: context.l10n.editNonSportEventTitle,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      onPressed: () {
                        showCreateNonSportEventSheet(
                          context,
                          eventToEdit: item.nonSportEvent!,
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
                        await deleteManagedNonSportEvent(
                          context,
                          event: item.nonSportEvent!,
                        );
                      },
                    ),
                  ],
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: context.l10n.nonSportEventInviteesTitle,
                    icon: Icon(
                      Icons.groups_outlined,
                      size: 20,
                      color: colors.textPrimary,
                    ),
                    onPressed: () {
                      showNonSportEventInviteesSheet(
                        context,
                        event: item.nonSportEvent!,
                      );
                    },
                  ),
                ],
                if (item.type == AgendaItemType.preparationPhysique &&
                    item.personalSportActivity != null) ...[
                  if (item.personalSportActivity!.externalSource ==
                      'strava') ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: context.l10n.wearableDeviceStrava,
                      child: SvgPicture.asset(
                        'assets/images/strava_logo.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  if (item.personalSportActivity!.externalSource ==
                      'polar') ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: context.l10n.wearableDevicePolar,
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/polar_logo.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  if (item.personalSportActivity!.externalSource ==
                      'whoop') ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: context.l10n.wearableDeviceWhoop,
                      child: SvgPicture.asset(
                        'assets/images/whoop_logo.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  if (item.personalSportActivity!.externalSource ==
                      'appleHealth') ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: context.l10n.wearableDeviceAppleHealth,
                      child: SvgPicture.asset(
                        'assets/images/apple_forme_logo.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  if (item.personalSportActivity!.externalSource ==
                      'googleHealth') ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: context.l10n.wearableDeviceGoogleHealthConnect,
                      child: SvgPicture.asset(
                        'assets/images/google_fit_logo.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                  if (item.personalSportActivity!.visibility ==
                      PersonalSportVisibility.private) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message:
                          context.l10n.createPersonalSportVisibilityPrivate,
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                  if (canManagePersonalSportActivity(
                    item.personalSportActivity!,
                    context.read<AppSession>(),
                  )) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: context.l10n.editPersonalSportTitle,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                      onPressed: () {
                        showCreatePersonalSportActivitySheet(
                          context,
                          activityToEdit: item.personalSportActivity!,
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
                        await deleteManagedPersonalSportActivity(
                          context,
                          activity: item.personalSportActivity!,
                        );
                      },
                    ),
                  ],
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
            if (item.allDay) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.agendaAllDayLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            if ((item.subtitle ?? '').trim().isNotEmpty &&
                item.type == AgendaItemType.nonSport) ...[
              const SizedBox(height: 6),
              Text(
                item.subtitle!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textPrimary.withValues(alpha: 0.9),
                    ),
              ),
            ],
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
                    if (SessionPersonalDataService.isEligibleAgendaItem(item) &&
                        (currentPlayerId?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: context.l10n.sessionPersonalDataTitle,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              showSessionPersonalDataDialog(
                                context,
                                item: item,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.sensors_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (item.type == AgendaItemType.preparationPhysique &&
                item.personalSportActivity != null) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final activity = item.personalSportActivity!;
                  final canManage = canManagePersonalSportActivity(
                    activity,
                    context.read<AppSession>(),
                  );
                  showCreatePersonalSportActivitySheet(
                    context,
                    activityToEdit: activity,
                    readOnly: !canManage,
                  );
                },
                child: personalSportMetrics(
                  context: context,
                  activity: item.personalSportActivity!,
                ),
              ),
            ],
            // Player rings: personal scores only (not managers/staff).
            if(!canAccessSessionDetails && item.withTracker == true && teamPlayerMetricScores != null) ... [
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
            // Team rings: managers and roster staff (team averages).
            if(canAccessSessionDetails && item.withTracker == true && item.teamWorkloadSummary != null) ... [
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
                          initialTabIndex: MatchDetailScreen.statsTabIndexFor(
                            match,
                          ),
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 96,
                                            ),
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
                                        teamId: (item.training != null)
                                            ? item.training!.teamId!
                                            : teamId,
                                        realtime: true,
                                        isMatch: item.match != null,
                                        reportTitle: item.title,
                                        reportSubtitle: item.subtitle,
                                        reportEventDate: item.startAt,
                                        reportMatch: item.match,
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
            if (item.training != null) ...[
              _AgendaIntenseLiveButton(
                training: item.training!,
                scheduledStart: item.startAt,
                scheduledEnd: item.endAt,
                title: item.title,
                showFinish: canManageThisTraining &&
                    item.training!.withTracker == true &&
                    item.startAt.isBefore(DateTime.now()) &&
                    !isTrainingFinished(item.training!),
                showResync: canManageThisTraining &&
                    canResyncTrainingIntense(item.training!),
              ),
            ],
            if (item.teamWorkloadSummary != null &&
                canSendSessionPdfReport(
                  session: context.read<AppSession>(),
                  teamId: teamId,
                  canManageEvent:
                      canManageThisTraining || canManageThisMatch,
                )) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    showSessionReportEmailDialog(
                      context: context,
                      eventId: item.id,
                      isMatch: item.match != null,
                      summary: item.teamWorkloadSummary,
                      title: item.title,
                      subtitle: item.subtitle,
                      teamId: teamId.isEmpty ? null : teamId,
                      eventDate: item.startAt,
                      match: item.match,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(context.l10n.sessionReportEmailActionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.card.withValues(alpha: 0.92),
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (item.training != null && canAccessSessionDetails) ...[
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
                    // Staff can open details; only managers edit présences.
                    readOnly: !canManageThisTraining,
                  );
                },
                child: _AgendaTrainingPlayersRow(
                  training: item.training!,
                ),
              ),
            ],
            if (item.training != null &&
                !canAccessSessionDetails &&
                !item.isDone &&
                !item.startAt.isBefore(DateUtils.dateOnly(DateTime.now()))) ...[
              const SizedBox(height: 10),
              AgendaTrainingPresenceActions(
                training: item.training!,
                trainingDate: item.startAt,
                seasonId: context.read<AppSession>().selectedSeason?.ref?.id,
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


  Widget personalSportMetrics({
    required BuildContext context,
    required PersonalSportActivity activity,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        );
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.textPrimary.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        );

    String? distanceValue;
    if (activity.distanceMeters != null && activity.distanceMeters! > 0) {
      distanceValue = formatSportDistanceKm(
        activity.distanceMeters! / 1000,
        activity.distanceUnit,
      );
    }

    String? paceValue;
    if (activity.paceSecondsPerKm != null &&
        activity.paceSecondsPerKm! > 0) {
      paceValue = formatSportPace(
        activity.paceSecondsPerKm!,
        activity.paceUnit,
      );
    }

    String? durationValue;
    if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
      durationValue = formatSportDurationClock(
        Duration(seconds: activity.durationSeconds!),
      );
    }

    String? caloriesValue;
    if (activity.caloriesKcal != null && activity.caloriesKcal! > 0) {
      caloriesValue =
          '${activity.caloriesKcal!.round()} ${l10n.personalSportUnitKcal}';
    }

    String? hrValue;
    if (activity.averageHeartRateBpm != null &&
        activity.averageHeartRateBpm! > 0) {
      hrValue =
          '${activity.averageHeartRateBpm} ${l10n.personalSportUnitBpm}';
    }

    if (distanceValue == null &&
        paceValue == null &&
        durationValue == null &&
        caloriesValue == null &&
        hrValue == null) {
      return const SizedBox.shrink();
    }

    Widget cell(String label, String? value) {
      if (value == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(text: '$label ', style: labelStyle),
              TextSpan(text: value, style: valueStyle),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: cell(l10n.personalSportMetricDistance, distanceValue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: cell(l10n.personalSportMetricAvgPace, paceValue),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: cell(l10n.personalSportMetricDuration, durationValue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: cell(l10n.personalSportMetricCalories, caloriesValue),
              ),
            ],
          ),
          if (hrValue != null)
            cell(l10n.personalSportMetricAvgHeartRate, hrValue),
        ],
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

void _notifyAgendaWorkloadUpdated(BuildContext context, {Training? training}) {
  final String eventId = training?.docId?.trim() ??
      training?.trainingId?.trim() ??
      '';
  if (eventId.isEmpty) {
    return;
  }
  _AgendaWorkloadRefreshScope.notify(context, eventId);
}

class _AgendaIntenseLiveButton extends StatefulWidget {
  const _AgendaIntenseLiveButton({
    required this.training,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.title,
    required this.showFinish,
    required this.showResync,
  });

  final Training training;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String title;
  final bool showFinish;
  final bool showResync;

  @override
  State<_AgendaIntenseLiveButton> createState() =>
      _AgendaIntenseLiveButtonState();
}

class _AgendaIntenseLiveButtonState extends State<_AgendaIntenseLiveButton> {
  Timer? _slotTimer;
  Future<bool>? _intenseOwnerFuture;
  String? _ownerIdForFuture;

  @override
  void initState() {
    super.initState();
    _ensureIntenseOwnerFuture();
    _slotTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AgendaIntenseLiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.training.ownerId != widget.training.ownerId) {
      _ensureIntenseOwnerFuture();
    }
  }

  @override
  void dispose() {
    _slotTimer?.cancel();
    super.dispose();
  }

  void _ensureIntenseOwnerFuture() {
    final ownerId = widget.training.ownerId?.trim() ?? '';
    if (ownerId.isEmpty) {
      _intenseOwnerFuture = null;
      _ownerIdForFuture = null;
      return;
    }
    if (_ownerIdForFuture == ownerId && _intenseOwnerFuture != null) {
      return;
    }
    _ownerIdForFuture = ownerId;
    // Live only for Intense cloud owners (withSyncing == false).
    _intenseOwnerFuture = isIntenseTrackerOwner(ownerId);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.training.withTracker != true) {
      return const SizedBox.shrink();
    }

    final ownerId = widget.training.ownerId?.trim() ?? '';
    if (ownerId.isEmpty) {
      return const SizedBox.shrink();
    }

    final isLiveSlot = isTrainingSessionLive(
      training: widget.training,
      scheduledStart: widget.scheduledStart,
      scheduledEnd: widget.scheduledEnd,
    );

    return FutureBuilder<bool>(
      future: _intenseOwnerFuture,
      builder: (context, intenseSnapshot) {
        // USB-sync owners (withSyncing == true) cannot stream live.
        final canStreamLive = intenseSnapshot.data == true;
        final showLive = canStreamLive && isLiveSlot;

        if (kDebugMode) {
          final end =
              trainingScheduledEndAt(widget.training, widget.scheduledStart) ??
                  widget.scheduledEnd;
          debugPrint(
            '[IntenseLive] agenda training=${widget.training.docId} '
            'ownerId=$ownerId withTracker=${widget.training.withTracker} '
            'duration=${widget.training.duration} liveSlot=$isLiveSlot '
            'canStreamLive=$canStreamLive '
            'start=${widget.scheduledStart} end=$end now=${DateTime.now()}',
          );
        }

        // Resync only for Intense cloud owners (same eligibility as Live).
        final showResync = widget.showResync && canStreamLive;

        if (!showLive && !widget.showFinish && !showResync) {
          return const SizedBox.shrink();
        }

        final colors = context.appColors;

        return Column(
          children: [
            if (showLive) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    IntenseLiveSessionScreen.openForTraining(
                      context,
                      training: widget.training,
                      title: widget.title,
                      scheduledStart: widget.scheduledStart,
                    );
                  },
                  icon: const Icon(Icons.sensors_rounded, size: 18),
                  label: Text(context.l10n.intenseLiveTitle),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (widget.showFinish) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final bool finished = await finishManagedTraining(
                      context,
                      training: widget.training,
                    );
                    if (!finished || !context.mounted) {
                      return;
                    }
                    _notifyAgendaWorkloadUpdated(
                      context,
                      training: widget.training,
                    );
                  },
                  icon: const Icon(Icons.sports_score_rounded, size: 18),
                  label: Text(context.l10n.finishTrainingTitle),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.card.withValues(alpha: 0.55),
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if (showResync) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final bool synced = await resyncManagedTrainingIntense(
                      context,
                      training: widget.training,
                    );
                    if (!synced || !context.mounted) {
                      return;
                    }
                    _notifyAgendaWorkloadUpdated(
                      context,
                      training: widget.training,
                    );
                  },
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: Text(context.l10n.trainingIntenseResyncButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
