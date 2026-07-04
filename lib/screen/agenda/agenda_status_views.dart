part of 'agenda_screen.dart';

class _AgendaLoadingView extends StatelessWidget {
  const _AgendaLoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AgendaErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _AgendaErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.danger,
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.errorAgendaLoad,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }
}

Map<DateTime, List<AgendaItem>> _groupItemsByWeek(List<AgendaItem> items) {
  final grouped = <DateTime, List<AgendaItem>>{};

  for (final item in items) {
    final weekStart = _startOfWeek(item.startAt);
    grouped.putIfAbsent(weekStart, () => <AgendaItem>[]);
    grouped[weekStart]!.add(item);
  }

  return grouped;
}

Map<int, List<AgendaItemType>> _headerEventTypesByDay(List<AgendaItem> items) {
  final result = <int, List<AgendaItemType>>{};

  for (final item in items) {
    final dayKey = DateUtils.dateOnly(item.startAt).millisecondsSinceEpoch;
    result.putIfAbsent(dayKey, () => <AgendaItemType>[]);
    result[dayKey]!.add(item.type);
  }

  return result;
}

List<AgendaItemType> _eventTypesForDay(
    Map<int, List<AgendaItemType>> eventTypesByDay,
    DateTime day,
    ) {
  final key = DateUtils.dateOnly(day).millisecondsSinceEpoch;
  return eventTypesByDay[key] ?? const <AgendaItemType>[];
}

List<DateTime> _generateWeeks(DateTime start, DateTime end) {
  final result = <DateTime>[];

  DateTime current = _startOfWeek(start);
  final last = _startOfWeek(end);

  while (current.millisecondsSinceEpoch <= last.millisecondsSinceEpoch) {
    result.add(current);
    current = current.add(const Duration(days: 7));
  }

  return result;
}

List<DateTime> _generateMonthGridDays(DateTime month) {
  final firstDayOfMonth = DateTime(month.year, month.month, 1);
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

  final gridStart = DateTime(
    firstDayOfMonth.year,
    firstDayOfMonth.month,
    firstDayOfMonth.day - (firstDayOfMonth.weekday - 1),
  );

  final gridEnd = DateTime(
    lastDayOfMonth.year,
    lastDayOfMonth.month,
    lastDayOfMonth.day + (7 - lastDayOfMonth.weekday),
  );

  final result = <DateTime>[];
  DateTime current = gridStart;

  while (!current.isAfter(gridEnd)) {
    result.add(DateUtils.dateOnly(current));
    current = DateTime(current.year, current.month, current.day + 1);
  }

  while (result.length % 7 != 0) {
    final last = result.last;
    result.add(DateTime(last.year, last.month, last.day + 1));
  }

  return result;
}

double _monthGridHeight(DateTime month) {
  final days = _generateMonthGridDays(month);
  final weekCount = (days.length / 7).ceil();

  const rowHeight = 64.0;
  const rowSpacing = 10.0;

  return (weekCount * rowHeight) + ((weekCount - 1) * rowSpacing);
}

int _monthDiff(DateTime from, DateTime to) {
  return ((to.year - from.year) * 12) + to.month - from.month;
}

DateTime _addMonths(DateTime date, int months) {
  return DateTime(date.year, date.month + months, 1);
}

DateTime _startOfMonth(DateTime date) {
  return DateTime(date.year, date.month, 1);
}

DateTime _endOfMonth(DateTime date) {
  return DateTime(date.year, date.month + 1, 0);
}

DateTime _startOfWeek(DateTime date) {
  final normalized = DateUtils.dateOnly(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime _endOfWeek(DateTime date) {
  final start = _startOfWeek(date);
  return start.add(const Duration(days: 6));
}

DateTime _endOfDay(DateTime date) {
  final normalized = DateUtils.dateOnly(date);
  return normalized.add(
    const Duration(hours: 23, minutes: 59, seconds: 59, milliseconds: 999),
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekdayLabel(DateTime date, String locale) {
  return DateFormat.E(locale).format(date).toUpperCase();
}

String _weekdayLabelFromIndex(int index, String locale) {
  final monday = DateTime(2024, 1, 1 + index);
  return DateFormat.E(locale).format(monday).toUpperCase();
}

String _formatMonthYear(DateTime date, String locale) {
  return DateFormat.yMMMM(locale).format(date);
}

String _formatFullDate(DateTime date, String locale) {
  return DateFormat.yMMMMd(locale).format(date);
}

String _formatWeekRange(DateTime start, DateTime end, String locale) {
  if (start.month == end.month && start.year == end.year) {
    return '${DateFormat.d(locale).format(start)} - ${DateFormat.d(locale).format(end)} ${DateFormat.MMM(locale).format(end)} ${end.year}';
  }

  if (start.year == end.year) {
    return '${DateFormat.d(locale).format(start)} ${DateFormat.MMM(locale).format(start)} - ${DateFormat.d(locale).format(end)} ${DateFormat.MMM(locale).format(end)} ${end.year}';
  }

  return '${DateFormat.yMMMd(locale).format(start)} - ${DateFormat.yMMMd(locale).format(end)}';
}

String _formatPeriodLabel(DateTime start, DateTime end, String locale) {
  if (start.day == end.day &&
      start.month == end.month &&
      start.year == end.year) {
    return DateFormat.yMMMMd(locale).format(start);
  }

  if (start.month == end.month && start.year == end.year) {
    return '${DateFormat.d(locale).format(start)} - ${DateFormat.d(locale).format(end)} ${DateFormat.yMMMM(locale).format(start)}';
  }

  if (start.year == end.year) {
    return '${DateFormat.yMMMd(locale).format(start)} - ${DateFormat.yMMMd(locale).format(end)}';
  }

  return '${DateFormat.yMMMd(locale).format(start)} - ${DateFormat.yMMMd(locale).format(end)}';
}

Color _typeColor(BuildContext context, AgendaItemType type) {
  final colors = context.appColors;

  switch (type) {
    case AgendaItemType.match:
      return colors.danger;
    case AgendaItemType.entrainement:
      return colors.primary;
    case AgendaItemType.preparationPhysique:
      return colors.success;
  }
}

IconData _typeIcon(AgendaItemType type) {
  switch (type) {
    case AgendaItemType.match:
      return Icons.sports_soccer_rounded;
    case AgendaItemType.entrainement:
      return Icons.fitness_center_rounded;
    case AgendaItemType.preparationPhysique:
      return Icons.directions_run_rounded;
  }
}

String? _formatTimeHmForLocale(String? timeHm, String locale) {
  final trimmed = timeHm?.trim() ?? '';
  if (trimmed.isEmpty) return null;

  final timeOfDay = parseMatchTimeCh(trimmed);
  if (timeOfDay == null) return trimmed;

  final dateTime = DateTime(2000, 1, 1, timeOfDay.hour, timeOfDay.minute);
  return DateFormat.Hm(locale).format(dateTime);
}

String? _agendaEventTimeLabel(AgendaItem item, String locale) {
  String? timeHm;
  switch (item.type) {
    case AgendaItemType.match:
      timeHm = item.match?.timeCh;
    case AgendaItemType.entrainement:
      timeHm = item.training?.startTime;
    case AgendaItemType.preparationPhysique:
      return null;
  }

  return _formatTimeHmForLocale(timeHm, locale) ??
      DateFormat.Hm(locale).format(item.startAt);
}