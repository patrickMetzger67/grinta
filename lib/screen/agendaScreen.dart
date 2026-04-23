import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../model/agendaItem.dart';
import '../util/app_theme.dart';
import '../widget/activity_rings_card.dart';
import '../widget/agendaMatchRow.dart';



class AgendaScreen extends StatefulWidget {
  final AgendaItemsLoader loadItems;
  final DateTime? initialDate;
  final VoidCallback? onAddEvent;

  const AgendaScreen({
    super.key,
    required this.loadItems,
    this.initialDate,
    this.onAddEvent,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final ScrollController _scrollController = ScrollController();

  late DateTime _selectedWeekStart;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  final Map<int, GlobalKey> _weekKeys = <int, GlobalKey>{};

  List<AgendaItem> _items = <AgendaItem>[];
  bool _isLoading = false;
  String? _error;



  @override
  void initState() {
    super.initState();

    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print('UID: ${user.uid}');
      print('Email: ${user.email}');
      print('Nom: ${user.displayName}');
      print('user >${user.toString()}');
    } else {
      print('Aucun utilisateur connecté');
    }


    final now = widget.initialDate ?? DateTime.now();
    _selectedWeekStart = _startOfWeek(now);
    _rangeStart = _startOfMonth(now);
    _rangeEnd = _endOfMonth(now);

    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({bool scrollToSelection = true}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final loadedItems = await widget.loadItems(
        start: DateUtils.dateOnly(_rangeStart),
        end: _endOfDay(_rangeEnd),
      );

      loadedItems.sort((a, b) => a.startAt.compareTo(b.startAt));

      if (!mounted) return;

      setState(() {
        _items = loadedItems;
        _isLoading = false;
      });

      if (scrollToSelection) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await _scrollToSelectedWeek(animated: false);
      }

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _goToPreviousWeek() async {
    final previousWeek = _selectedWeekStart.subtract(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = previousWeek;
    });

    if (previousWeek.millisecondsSinceEpoch < _rangeStart.millisecondsSinceEpoch) {
      _rangeStart = previousWeek;
      await _loadItems(scrollToSelection: true);
      return;
    }

    await _scrollToSelectedWeek();
  }

  Future<void> _goToNextWeek() async {
    final nextWeek = _selectedWeekStart.add(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = nextWeek;
    });

    if (nextWeek.millisecondsSinceEpoch > _rangeEnd.millisecondsSinceEpoch) {
      _rangeEnd = _endOfWeek(nextWeek);
      await _loadItems(scrollToSelection: true);
      return;
    }

    await _scrollToSelectedWeek();
  }

  Future<void> _jumpToToday() async {
    final now = DateTime.now();
    final todayWeek = _startOfWeek(now);
    final monthStart = _startOfMonth(now);
    final monthEnd = _endOfMonth(now);

    setState(() {
      _selectedWeekStart = todayWeek;
    });

    final mustReload =
        monthStart.millisecondsSinceEpoch != _rangeStart.millisecondsSinceEpoch ||
            monthEnd.millisecondsSinceEpoch != _rangeEnd.millisecondsSinceEpoch;

    if (mustReload) {
      _rangeStart = monthStart;
      _rangeEnd = monthEnd;
      await _loadItems(scrollToSelection: true);
      return;
    }

    await _scrollToSelectedWeek();
  }

  Future<void> _pickPeriod() async {
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: _rangeStart,
        end: _rangeEnd,
      ),
      helpText: 'Choisir une période',
      saveText: 'Valider',
    );

    if (pickedRange == null) return;

    final newRangeStart = _startOfWeek(pickedRange.start);
    final newRangeEnd = _endOfWeek(pickedRange.end);

    setState(() {
      _rangeStart = newRangeStart;
      _rangeEnd = newRangeEnd;
      _selectedWeekStart = newRangeStart;
    });

    await _loadItems(scrollToSelection: true);
  }

  Future<void> _extendBefore() async {
    setState(() {
      _rangeStart = _rangeStart.subtract(const Duration(days: 28));
    });

    await _loadItems(scrollToSelection: false);
  }

  Future<void> _extendAfter() async {
    setState(() {
      _rangeEnd = _endOfWeek(_rangeEnd.add(const Duration(days: 28)));
    });

    await _loadItems(scrollToSelection: false);
  }

  Future<void> _scrollToSelectedWeek({bool animated = true}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final key = _weekKeys[_selectedWeekStart.millisecondsSinceEpoch];
      final targetContext = key?.currentContext;

      if (targetContext == null) return;

      await Scrollable.ensureVisible(
        targetContext,
        duration: animated ? const Duration(milliseconds: 280) : Duration.zero,
        curve: Curves.easeOut,
        alignment: 0.02,
      );
    });
  }

  GlobalKey _keyForWeek(DateTime weekStart) {
    final id = weekStart.millisecondsSinceEpoch;
    return _weekKeys.putIfAbsent(id, () => GlobalKey());
  }

  void _showOverviewPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.appColors;

        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AgendaHeaderSummary(
                    items: _items,
                    compact: false,
                    periodLabel: _formatPeriodLabel(_rangeStart, _rangeEnd),
                  ),
                  const SizedBox(height: 12),
                  _AgendaLegend(compact: false),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNavigationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = sheetContext.appColors;

        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AgendaControlsCard(
                    selectedWeekStart: _selectedWeekStart,
                    rangeStart: _rangeStart,
                    rangeEnd: _rangeEnd,
                    onPreviousWeek: () async {
                      Navigator.of(sheetContext).pop();
                      await _goToPreviousWeek();
                    },
                    onNextWeek: () async {
                      Navigator.of(sheetContext).pop();
                      await _goToNextWeek();
                    },
                    onToday: () async {
                      Navigator.of(sheetContext).pop();
                      await _jumpToToday();
                    },
                    onPickPeriod: () async {
                      Navigator.of(sheetContext).pop();
                      await _pickPeriod();
                    },
                    onExtendBefore: () async {
                      Navigator.of(sheetContext).pop();
                      await _extendBefore();
                    },
                    onExtendAfter: () async {
                      Navigator.of(sheetContext).pop();
                      await _extendAfter();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final weeks = _generateWeeks(_rangeStart, _rangeEnd);
    final groupedByWeek = _groupItemsByWeek(_items);
    final compact = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(
            tooltip: 'Vue d’ensemble',
            onPressed: _showOverviewPanel,
            icon: const Icon(Icons.insert_chart_outlined_rounded),
          ),
          IconButton(
            tooltip: 'Navigation',
            onPressed: _showNavigationPanel,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              _AgendaMiniHeader(
                selectedWeekStart: _selectedWeekStart,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildMainList(
                  weeks: weeks,
                  groupedByWeek: groupedByWeek,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.onAddEvent == null
          ? null
          : FloatingActionButton(
        onPressed: widget.onAddEvent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMainList({
    required List<DateTime> weeks,
    required Map<DateTime, List<AgendaItem>> groupedByWeek,
    required bool compact,
  }) {
    if (_isLoading && _items.isEmpty) {
      return const _AgendaLoadingView();
    }

    if (_error != null && _items.isEmpty) {
      debugPrint('$_error');
      return _AgendaErrorView(
        message: _error!,
        onRetry: _loadItems,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: _AgendaWeeksList(
        controller: _scrollController,
        weeks: weeks,
        groupedByWeek: groupedByWeek,
        compact: compact,
        selectedWeekStart: _selectedWeekStart,
        keyBuilder: _keyForWeek,
        onWeekTap: (weekStart) async {
          setState(() {
            _selectedWeekStart = weekStart;
          });
          await _scrollToSelectedWeek();
        },
      ),
    );
  }
}

class _AgendaMiniHeader extends StatelessWidget {
  final DateTime selectedWeekStart;
  final DateTime rangeStart;
  final DateTime rangeEnd;

  const _AgendaMiniHeader({
    required this.selectedWeekStart,
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final weekEnd = _endOfWeek(selectedWeekStart);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_rounded,
            size: 18,
            color: colors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatWeekRange(selectedWeekStart, weekEnd),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatPeriodLabel(rangeStart, rangeEnd),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaHeaderSummary extends StatelessWidget {
  final List<AgendaItem> items;
  final bool compact;
  final String periodLabel;

  const _AgendaHeaderSummary({
    required this.items,
    required this.compact,
    required this.periodLabel,
  });

  int _countByType(AgendaItemType type) {
    return items.where((e) => e.type == type).length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final total = items.length;
    final matchs = _countByType(AgendaItemType.match);
    final entrainements = _countByType(AgendaItemType.entrainement);
    final prepas = _countByType(AgendaItemType.preparationPhysique);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d’ensemble',
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
            '$total événement${total > 1 ? 's' : ''}',
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
                label: 'Matchs',
                value: matchs,
                color: colors.danger,
                icon: Icons.sports_soccer_rounded,
              ),
              _SummaryChip(
                label: 'Entraînements',
                value: entrainements,
                color: colors.primary,
                icon: Icons.fitness_center_rounded,
              ),
              _SummaryChip(
                label: 'Prépa physique',
                value: prepas,
                color: colors.success,
                icon: Icons.directions_run_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
    final colors = context.appColors;
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
            'Navigation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Semaine sélectionnée : ${_formatWeekRange(selectedWeekStart, selectedWeekEnd)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Période chargée : ${_formatPeriodLabel(rangeStart, rangeEnd)}',
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
                label: const Text('Semaine -'),
              ),
              OutlinedButton.icon(
                onPressed: onToday,
                icon: const Icon(Icons.today_rounded),
                label: const Text('Aujourd’hui'),
              ),
              OutlinedButton.icon(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Semaine +'),
              ),
              FilledButton.icon(
                onPressed: onPickPeriod,
                icon: const Icon(Icons.date_range_rounded),
                label: const Text('Choisir une période'),
              ),
              OutlinedButton.icon(
                onPressed: onExtendBefore,
                icon: const Icon(Icons.unfold_less_double_rounded),
                label: const Text('Charger avant'),
              ),
              OutlinedButton.icon(
                onPressed: onExtendAfter,
                icon: const Icon(Icons.unfold_more_double_rounded),
                label: const Text('Charger après'),
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
  final bool compact;

  const _AgendaLegend({
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {

    final colors = context.appColors;
    return compact
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LegendItem(
            label: 'Match',
            color: _typeColor(context, AgendaItemType.match),
            icon: Icons.sports_soccer_rounded,
          ),
          const SizedBox(width: 8),
          _LegendItem(
            label: 'Entraînement',
            color: _typeColor(context, AgendaItemType.entrainement),
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(width: 8),
          _LegendItem(
            label: 'Prépa physique',
            color: _typeColor(context, AgendaItemType.preparationPhysique),
            icon: Icons.directions_run_rounded,
          ),
        ],
      ),
    )
        : Container(
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
          const Text(
            'Légende',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _LegendItem(
            label: 'Match',
            color: _typeColor(context, AgendaItemType.match),
            icon: Icons.sports_soccer_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
          _LegendItem(
            label: 'Entraînement',
            color: _typeColor(context, AgendaItemType.entrainement),
            icon: Icons.fitness_center_rounded,
            fullWidth: true,
          ),
          const SizedBox(height: 8),
           _LegendItem(
            label: 'Prépa physique',
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
  final GlobalKey Function(DateTime weekStart) keyBuilder;
  final ValueChanged<DateTime> onWeekTap;

  const _AgendaWeeksList({
    required this.controller,
    required this.weeks,
    required this.groupedByWeek,
    required this.compact,
    required this.selectedWeekStart,
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
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    key: keyBuilder(weekStart),
                    child: _WeekCard(
                      weekStart: weekStart,
                      items: weekItems,
                      compact: compact,
                      isSelected: isSelected,
                      onTap: () => onWeekTap(weekStart),
                    ),
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
  final VoidCallback onTap;

  const _WeekCard({
    required this.weekStart,
    required this.items,
    required this.compact,
    required this.isSelected,
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 14 : 18,
                  compact ? 14 : 16,
                  compact ? 14 : 18,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatWeekRange(weekStart, weekEnd),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _weekDescription(items),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.24),
                          ),
                        ),
                        child: Text(
                          'Sélectionnée',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              ...List.generate(7, (index) {
                final day = weekStart.add(Duration(days: index));
                final dayItems = items.where((e) => _isSameDay(e.startAt, day)).toList();

                return _DayRow(
                  date: day,
                  items: dayItems,
                  compact: compact,
                  isLast: index == 6,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekDescription(List<AgendaItem> items) {
    final matchs = items.where((e) => e.type == AgendaItemType.match).length;
    final trainings = items.where((e) => e.type == AgendaItemType.entrainement).length;
    final prepas =
        items.where((e) => e.type == AgendaItemType.preparationPhysique).length;

    final parts = <String>[];
    if (matchs > 0) parts.add('$matchs match${matchs > 1 ? 's' : ''}');
    if (trainings > 0) {
      parts.add('$trainings entraînement${trainings > 1 ? 's' : ''}');
    }
    if (prepas > 0) {
      parts.add('$prepas prépa${prepas > 1 ? 's' : ''}');
    }

    return parts.isEmpty ? 'Aucun événement' : parts.join(' • ');
  }
}

class _DayRow extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> items;
  final bool compact;
  final bool isLast;

  const _DayRow({
    required this.date,
    required this.items,
    required this.compact,
    required this.isLast,
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
  final bool compact;

  const _DateColumn({
    required this.date,
    required this.isToday,
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
          _weekdayLabel(date),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
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
            color: isToday ? colors.primary : Colors.transparent,
          ),
          child: Text(
            '${date.day}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isToday ? Colors.white : colors.textPrimary,
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
              'Aucun événement',
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
    final label = _typeLabel(item.type);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
    //    color: colors.card,
        color: accent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 12, 12, 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 560;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (item.withTracker) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.gps_not_fixed_rounded,
                            size: 18,
                            color: (item.areTrackersSynchronized)
                                ? colors.success
                                : colors.warning,
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
                    SizedBox(
                      width: 55,
                      height: 55,
                      child: ActivityRingsCard.compact(
                        rings: const [
                          ActivityRingItem(
                            label: 'Bouger',
                            value: 113,
                            goal: 600,
                            unit: 'KCAL',
                            color: Color(0xFFFF2D55),
                            trackColor: Color(0xFF4B1322),
                            icon: Icons.arrow_forward,
                          ),
                          ActivityRingItem(
                            label: 'M’entraîner',
                            value: 6,
                            goal: 60,
                            unit: 'MIN',
                            color: Color(0xFF9DFF00),
                            trackColor: Color(0xFF1C4312),
                            icon: Icons.fast_forward,
                          ),
                          ActivityRingItem(
                            label: 'Me lever',
                            value: 6,
                            goal: 12,
                            unit: 'H',
                            color: Color(0xFF28F0FF),
                            trackColor: Color(0xFF103845),
                            icon: Icons.north,
                          ),
                        ],
                      ),
                    ),

                    if (item.match != null) ...[
                      const SizedBox(height: 10),
                      AgendaMatchRow(
                        match: item.match!,
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fg = textColor ?? colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
            'Impossible de charger l’agenda',
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
            label: const Text('Réessayer'),
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

String _weekdayLabel(DateTime date) {
  const labels = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  return labels[date.weekday - 1];
}

String _formatWeekRange(DateTime start, DateTime end) {
  const months = [
    '',
    'janv',
    'fév',
    'mars',
    'avr',
    'mai',
    'juin',
    'juil',
    'août',
    'sept',
    'oct',
    'nov',
    'déc',
  ];

  if (start.month == end.month && start.year == end.year) {
    return '${start.day} - ${end.day} ${months[end.month]} ${end.year}';
  }

  if (start.year == end.year) {
    return '${start.day} ${months[start.month]} - ${end.day} ${months[end.month]} ${end.year}';
  }

  return '${start.day} ${months[start.month]} ${start.year} - ${end.day} ${months[end.month]} ${end.year}';
}

String _formatPeriodLabel(DateTime start, DateTime end) {
  const months = [
    '',
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  if (start.day == end.day &&
      start.month == end.month &&
      start.year == end.year) {
    return '${start.day} ${months[start.month]} ${start.year}';
  }

  if (start.month == end.month && start.year == end.year) {
    return '${start.day} - ${end.day} ${months[start.month]} ${start.year}';
  }

  if (start.year == end.year) {
    return '${start.day} ${months[start.month]} - ${end.day} ${months[end.month]} ${start.year}';
  }

  return '${start.day} ${months[start.month]} ${start.year} - ${end.day} ${months[end.month]} ${end.year}';
}

String _formatHour(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

Color _typeColor(BuildContext context, AgendaItemType type) {
  final colors = context.appColors;

  switch (type) {
    case AgendaItemType.match:
      return colors.secondary;
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

String _typeLabel(AgendaItemType type) {
  switch (type) {
    case AgendaItemType.match:
      return 'Match';
    case AgendaItemType.entrainement:
      return 'Entraînement';
    case AgendaItemType.preparationPhysique:
      return 'Prépa physique';
  }
}