part of 'agenda_screen.dart';

class _GrintaStyleCalendarHeader extends StatelessWidget {
  final PageController pageController;
  final int initialPage;
  final DateTime anchorMonth;
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final AgendaCalendarMode mode;
  final Map<int, List<AgendaItemType>> eventTypesByDay;
  final ValueChanged<AgendaCalendarMode> onModeChanged;
  final Future<void> Function() onPreviousMonth;
  final Future<void> Function() onNextMonth;
  final Future<void> Function() onPreviousWeek;
  final Future<void> Function() onNextWeek;
  final Future<void> Function() onPreviousDay;
  final Future<void> Function() onNextDay;
  final VoidCallback onTodayTap;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<DateTime> onDateTap;

  const _GrintaStyleCalendarHeader({
    required this.pageController,
    required this.initialPage,
    required this.anchorMonth,
    required this.displayedMonth,
    required this.selectedDate,
    required this.mode,
    required this.eventTypesByDay,
    required this.onModeChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onTodayTap,
    required this.onPageChanged,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).toString();
    final isMonth = mode == AgendaCalendarMode.month;
    final isWeek = mode == AgendaCalendarMode.week;
    final isDay = mode == AgendaCalendarMode.day;

    final headerTitle = isMonth
        ? _formatMonthYear(displayedMonth, locale)
        : isWeek
        ? _formatWeekRange(
      _startOfWeek(selectedDate),
      _endOfWeek(selectedDate),
      locale,
    )
        : _formatFullDate(selectedDate, locale);

    final calendarHeight = isDay
        ? 86.0
        : isMonth
        ? _monthGridHeight(displayedMonth)
        : 72.0;

    Future<void> goToPreviousHeaderPeriod() async {
      if (isMonth) {
        await onPreviousMonth();
        return;
      }

      if (isWeek) {
        await onPreviousWeek();
        return;
      }

      if (isDay) {
        await onPreviousDay();
      }
    }

    Future<void> goToNextHeaderPeriod() async {
      if (isMonth) {
        await onNextMonth();
        return;
      }

      if (isWeek) {
        await onNextWeek();
        return;
      }

      if (isDay) {
        await onNextDay();
      }
    }

    Widget headerArrow({
      required String label,
      required Future<void> Function() onTap,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // Fire-and-forget: a second tap must not wait on the previous nav.
          onTap: () {
            unawaited(onTap());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;

        if (velocity > 180) {
          onModeChanged(AgendaCalendarMode.month);
        } else if (velocity < -180 && mode == AgendaCalendarMode.month) {
          onModeChanged(AgendaCalendarMode.week);
        }
      },
      // Month uses PageView horizontal scroll. Day/week: swipe by full week.
      onHorizontalDragEnd: isMonth
          ? null
          : (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -180) {
                // Right → left: next period.
                onNextWeek();
              } else if (velocity > 180) {
                // Left → right: previous period.
                onPreviousWeek();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: (isMonth || isWeek || isDay)
                        ? Row(
                      children: [
                        headerArrow(
                          label: '<',
                          tooltip: isDay
                              ? l10n.actionDayPrevious
                              : isWeek
                              ? l10n.actionWeekPreviousLong
                              : l10n.actionMonthPrevious,
                          onTap: goToPreviousHeaderPeriod,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              headerTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        headerArrow(
                          label: '>',
                          tooltip: isDay
                              ? l10n.actionDayNext
                              : isWeek
                              ? l10n.actionWeekNextLong
                              : l10n.actionMonthNext,
                          onTap: goToNextHeaderPeriod,
                        ),
                      ],
                    )
                        : Text(
                      headerTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onTodayTap,
                    child: Text(l10n.actionToday),
                  ),
                  const SizedBox(width: 4),
                  _AgendaModeButton(
                    icon: Icons.view_day_outlined,
                    selected: isDay,
                    onTap: () => onModeChanged(AgendaCalendarMode.day),
                  ),
                  const SizedBox(width: 6),
                  _AgendaModeButton(
                    icon: Icons.view_week_outlined,
                    selected: isWeek,
                    onTap: () => onModeChanged(AgendaCalendarMode.week),
                  ),
                  const SizedBox(width: 6),
                  _AgendaModeButton(
                    icon: Icons.calendar_view_month_outlined,
                    selected: isMonth,
                    onTap: () => onModeChanged(AgendaCalendarMode.month),
                  ),

                ],
              ),
              const SizedBox(height: 10),
              if (!isDay) ...[
                SizedBox(
                  height: 28,
                  child: Row(
                    children: List.generate(7, (index) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            _weekdayLabelFromIndex(index, locale),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Week↔month must jump height instantly. Animating size reveals the
              // clipped month grid row-by-row (an "expanded week" flash).
              AnimatedSize(
                duration: (isMonth || isWeek)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: SizedBox(
                  height: calendarHeight,
                  child: isDay
                      ? _AgendaDayCalendar(
                    selectedDate: selectedDate,
                    eventTypesByDay: eventTypesByDay,
                    onDateTap: onDateTap,
                  )
                      : PageView.builder(
                    controller: pageController,
                    allowImplicitScrolling: true,
                    physics: isMonth
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final offset = index - initialPage;
                      final month = _addMonths(anchorMonth, offset);

                      return RepaintBoundary(
                        child: _MonthCalendarPage(
                          key: ValueKey<String>(
                            'month-${month.year}-${month.month}-'
                            '${isMonth ? 'full' : 'week'}',
                          ),
                          month: month,
                          selectedDate: selectedDate,
                          expanded: isMonth,
                          eventTypesByDay: eventTypesByDay,
                          onDateTap: onDateTap,
                        ),
                      );
                    },
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

class _AgendaModeButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AgendaModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: selected ? colors.primary.withOpacity(0.12) : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? colors.primary : colors.textSecondary,
        ),
      ),
    );
  }
}

class _AgendaDayCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final Map<int, List<AgendaItemType>> eventTypesByDay;
  final ValueChanged<DateTime> onDateTap;

  const _AgendaDayCalendar({
    required this.selectedDate,
    required this.eventTypesByDay,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateUtils.dateOnly(DateTime.now());
    final weekStart = _startOfWeek(selectedDate);

    return Row(
      children: List.generate(7, (index) {
        final day = DateUtils.dateOnly(
          weekStart.add(Duration(days: index)),
        );
        final isSelected = _isSameDay(day, selectedDate);
        final isToday = _isSameDay(day, today);
        final dayTypes = _eventTypesForDay(eventTypesByDay, day);

        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onDateTap(day),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(
                      day,
                      Localizations.localeOf(context).toString(),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? colors.primary : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colors.primary
                          : isToday
                          ? colors.primary.withOpacity(0.10)
                          : Colors.transparent,
                      border: !isSelected && isToday
                          ? Border.all(
                        color: colors.primary.withOpacity(0.25),
                      )
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : isToday
                            ? colors.primary
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _AgendaEventDots(
                    types: dayTypes,
                    selected: isSelected,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _MonthCalendarPage extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final bool expanded;
  final Map<int, List<AgendaItemType>> eventTypesByDay;
  final ValueChanged<DateTime> onDateTap;

  const _MonthCalendarPage({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.expanded,
    required this.eventTypesByDay,
    required this.onDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final today = DateUtils.dateOnly(DateTime.now());

    final days = _generateMonthGridDays(month);
    final weeks = <List<DateTime>>[
      for (int i = 0; i + 6 < days.length; i += 7) days.sublist(i, i + 7),
    ];

    final selectedWeekIndex = weeks.indexWhere(
          (week) => week.any((d) => _isSameDay(d, selectedDate)),
    );

    final safeSelectedWeekIndex = selectedWeekIndex < 0 ? 0 : selectedWeekIndex;

    // Reserved band for event dots under the day number — must not be clipped.
    const rowHeight = 72.0;
    const rowSpacing = 8.0;
    const dotsBandHeight = 12.0;

    final fullHeight =
        (weeks.length * rowHeight) + ((weeks.length - 1) * rowSpacing);

    final visibleHeight = expanded ? fullHeight : rowHeight;

    final translateY =
    expanded ? 0.0 : -(safeSelectedWeekIndex * (rowHeight + rowSpacing));

    return SizedBox(
      height: visibleHeight,
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: translateY,
              left: 0,
              right: 0,
              child: SizedBox(
                height: fullHeight,
                child: Column(
                  children: List.generate(weeks.length, (weekIndex) {
                    final week = weeks[weekIndex];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: weekIndex == weeks.length - 1 ? 0 : rowSpacing,
                      ),
                      child: SizedBox(
                        height: rowHeight,
                        child: Row(
                          children: week.map((day) {
                            final isSelected = _isSameDay(day, selectedDate);
                            final isToday = _isSameDay(day, today);
                            final isInMonth =
                                day.month == month.month && day.year == month.year;
                            final dayTypes = _eventTypesForDay(eventTypesByDay, day);

                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => onDateTap(day),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? colors.primary
                                                : isToday
                                                ? colors.primary.withOpacity(0.10)
                                                : Colors.transparent,
                                            border: !isSelected && isToday
                                                ? Border.all(
                                              color: colors.primary.withOpacity(0.25),
                                            )
                                                : null,
                                          ),
                                          child: Text(
                                            '${day.day}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isToday
                                                  ? colors.primary
                                                  : isInMonth
                                                  ? colors.textPrimary
                                                  : colors.textSecondary
                                                  .withOpacity(0.45),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: dotsBandHeight,
                                      child: _AgendaEventDots(
                                        types: dayTypes,
                                        selected: isSelected,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaEventDots extends StatelessWidget {
  final List<AgendaItemType> types;
  final bool selected;

  const _AgendaEventDots({
    required this.types,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return const SizedBox(height: 6);
    }

    final visible = types.take(4).toList();
    final hasMore = types.length > 4;
    final dotColorOverride = selected ? Colors.white : null;
    final plusColor = selected ? Colors.white : context.appColors.textSecondary;

    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...visible.map((type) {
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColorOverride ?? _typeColor(context, type),
              ),
            );
          }),
          if (hasMore) ...[
            const SizedBox(width: 2),
            Text(
              '+',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: plusColor,
                height: 0.9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgendaHeaderSummary extends StatelessWidget {
  final List<AgendaItem> items;
  final String periodLabel;

  const _AgendaHeaderSummary({
    required this.items,
    required this.periodLabel,
  });

  int _countByType(AgendaItemType type) {
    return items.where((e) => e.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final total = items.length;
    final matchs = _countByType(AgendaItemType.match);
    final entrainements = _countByType(AgendaItemType.entrainement);
    final prepas = _countByType(AgendaItemType.preparationPhysique);
    final nonSports = _countByType(AgendaItemType.nonSport);

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
            l10n.navOverview,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            periodLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.agendaOverviewEventsCount(total),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryChip(
                label: l10n.entityMatches,
                value: matchs,
                color: colors.danger,
                icon: Icons.sports_soccer_rounded,
              ),
              _SummaryChip(
                label: l10n.entityTrainings,
                value: entrainements,
                color: colors.primary,
                icon: Icons.fitness_center_rounded,
              ),
              _SummaryChip(
                label: l10n.periodPrep,
                value: prepas,
                color: colors.success,
                icon: Icons.directions_run_rounded,
              ),
              _SummaryChip(
                label: l10n.agendaAddEventNonSport,
                value: nonSports,
                color: colors.warning,
                icon: Icons.event_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

