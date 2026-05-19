import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/services/playerService.dart';
import 'package:provider/provider.dart';

import '../model/agendaItem.dart';
import '../model/player.dart';
import '../model/season.dart';
import '../model/tracker/team_workload_summary.dart';
import '../provider/appSession.dart';
import '../util/app_theme.dart';
import '../util/playerDisplayName.dart';
import '../widget/activity_rings_card.dart';
import '../widget/agendaMatchRow.dart';
import '../widget/match_tracker_stats_table.dart';
import '../widget/tracker_player_analysis_widget.dart';
import 'match_detail_screen.dart';

enum AgendaCalendarMode {
  day,
  week,
  month,
}

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
  static const int _initialMonthPage = 1200;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _weeksViewportKey = GlobalKey();

  late DateTime _selectedWeekStart;
  late DateTime _selectedWeekEnd;
  late DateTime _selectedDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  late final DateTime _monthPagerAnchor;
  late final PageController _monthPageController;

  late DateTime _displayedMonth;
  AgendaCalendarMode _calendarMode = AgendaCalendarMode.day;
  bool _forceLoadItemsOnNextMonthPageChange = false;

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

    final now = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());

    _selectedDate = now;
    _selectedWeekStart = _startOfWeek(now);
    _selectedWeekEnd = _endOfWeek(now);
    /*
    _rangeStart = _startOfMonth(now);
    _rangeEnd = _endOfMonth(now);
     */

    _rangeStart = _selectedWeekStart;
    _rangeEnd = _selectedWeekEnd;

    _monthPagerAnchor = DateTime(now.year, now.month, 1);
    _displayedMonth = DateTime(now.year, now.month, 1);
    _monthPageController = PageController(initialPage: _initialMonthPage);

    _scrollController.addListener(_handleScroll);

    _loadItems();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _monthPageController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_calendarMode != AgendaCalendarMode.month) return;

    final focusedWeek = _computeFocusedWeek();
    if (focusedWeek == null) return;

    if (focusedWeek.millisecondsSinceEpoch !=
        _selectedWeekStart.millisecondsSinceEpoch) {
      final nextSelectedDate = _dateInWeekWithSameWeekday(focusedWeek);
      final nextDisplayedMonth =
      DateTime(nextSelectedDate.year, nextSelectedDate.month, 1);

      if (!mounted) return;

      setState(() {
        _selectedWeekStart = focusedWeek;
        _selectedDate = nextSelectedDate;
        _displayedMonth = nextDisplayedMonth;
      });

      _jumpMonthPagerToDisplayedMonth();
    }
  }

  DateTime? _computeFocusedWeek() {
    if (!mounted || _weekKeys.isEmpty) return null;

    final viewportContext = _weeksViewportKey.currentContext;
    if (viewportContext == null) return null;

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return null;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    final focusAnchor = viewportTop + 24.0;

    DateTime? focusedWeek;
    double? bestDistance;

    for (final entry in _weekKeys.entries) {
      final weekContext = entry.value.currentContext;
      if (weekContext == null) continue;

      final renderObject = weekContext.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) continue;

      final top = renderObject.localToGlobal(Offset.zero).dy;
      final bottom = top + renderObject.size.height;

      final distance = focusAnchor < top
          ? top - focusAnchor
          : focusAnchor > bottom
          ? focusAnchor - bottom
          : 0.0;

      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        focusedWeek = DateTime.fromMillisecondsSinceEpoch(entry.key);
      }
    }

    return focusedWeek;
  }

  DateTime _dateInWeekWithSameWeekday(DateTime weekStart) {
    final weekdayOffset = _selectedDate.weekday - DateTime.monday;
    return DateUtils.dateOnly(
      weekStart.add(Duration(days: weekdayOffset)),
    );
  }

  void _setCalendarMode(AgendaCalendarMode mode) {
    if (_calendarMode == mode) return;

    setState(() {
      _calendarMode = mode;
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    _jumpMonthPagerToDisplayedMonth();
  }

  void _jumpMonthPagerToDisplayedMonth() {
    if (!_monthPageController.hasClients) return;

    final targetPage =
        _initialMonthPage + _monthDiff(_monthPagerAnchor, _displayedMonth);

    final currentPage = _monthPageController.page?.round();
    if (currentPage == targetPage) return;

    _monthPageController.jumpToPage(targetPage);
  }

  void _onMonthPageChanged(int page) {
    _handleMonthPageChanged(page);
  }

  Future<void> _handleMonthPageChanged(int page) async {
    final monthOffset = page - _initialMonthPage;
    final newMonth = _addMonths(_monthPagerAnchor, monthOffset);

    final daysInMonth = DateTime(newMonth.year, newMonth.month + 1, 0).day;
    final safeDay = _selectedDate.day.clamp(1, daysInMonth);
    final newSelectedDate = DateUtils.dateOnly(
      DateTime(newMonth.year, newMonth.month, safeDay),
    );
    final newSelectedWeek = _startOfWeek(newSelectedDate);
    final forceLoadItems = _forceLoadItemsOnNextMonthPageChange;
    _forceLoadItemsOnNextMonthPageChange = false;

    setState(() {
      _displayedMonth = newMonth;
      _selectedDate = newSelectedDate;
      _selectedWeekStart = newSelectedWeek;
    });

    if (forceLoadItems) {
      _rangeStart = _startOfMonth(newMonth);
      _rangeEnd = _endOfMonth(newMonth);
      await _loadItems(scrollToSelection: true);
      return;
    }

    final isBeforeRange =
        newSelectedWeek.millisecondsSinceEpoch < _rangeStart.millisecondsSinceEpoch;
    final isAfterRange =
        newSelectedWeek.millisecondsSinceEpoch > _rangeEnd.millisecondsSinceEpoch;

    if (isBeforeRange || isAfterRange) {
      if (isBeforeRange) {
        _rangeStart = newSelectedWeek;
      }
      if (isAfterRange) {
        _rangeEnd = _endOfWeek(newSelectedWeek);
      }
      await _loadItems(scrollToSelection: true);
      return;
    }

    await _scrollToSelectedWeek();
  }

  Future<void> _selectDate(DateTime date) async {
    final normalizedDate = DateUtils.dateOnly(date);
    final targetWeek = _startOfWeek(normalizedDate);
    final targetMonth = DateTime(normalizedDate.year, normalizedDate.month, 1);

    setState(() {
      _selectedDate = normalizedDate;
      _selectedWeekStart = targetWeek;
      _displayedMonth = targetMonth;
    });

    _jumpMonthPagerToDisplayedMonth();

    final isBeforeRange =
        targetWeek.millisecondsSinceEpoch < _rangeStart.millisecondsSinceEpoch;
    final isAfterRange =
        targetWeek.millisecondsSinceEpoch > _rangeEnd.millisecondsSinceEpoch;

    if (isBeforeRange || isAfterRange) {
      if (isBeforeRange) {
        _rangeStart = targetWeek;
      }
      if (isAfterRange) {
        _rangeEnd = _endOfWeek(targetWeek);
      }
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (_calendarMode == AgendaCalendarMode.month) {
      await _scrollToSelectedWeek();
    }
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

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        if (scrollToSelection && _calendarMode == AgendaCalendarMode.month) {
          await _scrollToSelectedWeek(animated: false);
        } else {
          _handleScroll();
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _goToPreviousWeek({bool forceLoadItems = false}) async {
    final previousWeek = _selectedWeekStart.subtract(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = previousWeek;
      _selectedDate = _dateInWeekWithSameWeekday(previousWeek);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    if (forceLoadItems) {
      _rangeStart = previousWeek;
      _rangeEnd = _endOfWeek(previousWeek);
    }

    _jumpMonthPagerToDisplayedMonth();

    if (forceLoadItems) {
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (previousWeek.millisecondsSinceEpoch < _rangeStart.millisecondsSinceEpoch) {
      _rangeStart = previousWeek;
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (_calendarMode == AgendaCalendarMode.month) {
      await _scrollToSelectedWeek();
    }
  }

  Future<void> _goToNextWeek({bool forceLoadItems = false}) async {
    final nextWeek = _selectedWeekStart.add(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = nextWeek;
      _selectedDate = _dateInWeekWithSameWeekday(nextWeek);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    if (forceLoadItems) {
      _rangeStart = nextWeek;
      _rangeEnd = _endOfWeek(nextWeek);
    }

    _jumpMonthPagerToDisplayedMonth();

    if (forceLoadItems) {
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (nextWeek.millisecondsSinceEpoch > _rangeEnd.millisecondsSinceEpoch) {
      _rangeEnd = _endOfWeek(nextWeek);
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (_calendarMode == AgendaCalendarMode.month) {
      await _scrollToSelectedWeek();
    }
  }

  Future<void> _goToPreviousMonthFromHeader() async {
    if (!_monthPageController.hasClients) return;

    _forceLoadItemsOnNextMonthPageChange = true;
    await _monthPageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToNextMonthFromHeader() async {
    if (!_monthPageController.hasClients) return;

    _forceLoadItemsOnNextMonthPageChange = true;
    await _monthPageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _jumpToToday() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final todayWeek = _startOfWeek(now);
    final monthStart = _startOfMonth(now);
    final monthEnd = _endOfMonth(now);

    setState(() {
      _selectedDate = now;
      _selectedWeekStart = todayWeek;
      _displayedMonth = DateTime(now.year, now.month, 1);
    });

    _jumpMonthPagerToDisplayedMonth();

    final mustReload =
        monthStart.millisecondsSinceEpoch != _rangeStart.millisecondsSinceEpoch ||
            monthEnd.millisecondsSinceEpoch != _rangeEnd.millisecondsSinceEpoch;

    if (mustReload) {
      _rangeStart = monthStart;
      _rangeEnd = monthEnd;
      await _loadItems(scrollToSelection: true);
      return;
    }

    if (_calendarMode == AgendaCalendarMode.month) {
      await _scrollToSelectedWeek();
    }
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
      _selectedDate = DateUtils.dateOnly(pickedRange.start);
      _selectedWeekStart = _startOfWeek(pickedRange.start);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    _jumpMonthPagerToDisplayedMonth();

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
    await Future<void>.delayed(Duration.zero);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleScroll();
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
                    periodLabel: _formatPeriodLabel(_rangeStart, _rangeEnd),
                  ),
                  //      const SizedBox(height: 12),
                  //      const _AgendaLegend(),
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
    final headerEventTypesByDay = _headerEventTypesByDay(_items);

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
          /*
          IconButton(
            tooltip: 'Navigation',
            onPressed: _showNavigationPanel,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          */
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              _GrintaStyleCalendarHeader(
                pageController: _monthPageController,
                initialPage: _initialMonthPage,
                anchorMonth: _monthPagerAnchor,
                displayedMonth: _displayedMonth,
                selectedDate: _selectedDate,
                mode: _calendarMode,
                eventTypesByDay: headerEventTypesByDay,
                onModeChanged: _setCalendarMode,
                onPreviousMonth: () async {
                  await _goToPreviousMonthFromHeader();
                },
                onNextMonth: () async {
                  await _goToNextMonthFromHeader();
                },
                onPreviousWeek: () async {
                  await _goToPreviousWeek(forceLoadItems: true);
                },
                onNextWeek: () async {
                  await _goToNextWeek(forceLoadItems: true);
                },
                onPreviousDay: () async {
                  await _selectDate(
                    _selectedDate.subtract(const Duration(days: 1)),
                  );
                },
                onNextDay: () async {
                  await _selectDate(
                    _selectedDate.add(const Duration(days: 1)),
                  );
                },
                onTodayTap: () async {
                  await _jumpToToday();
                },
                onPageChanged: _onMonthPageChanged,
                onDateTap: (date) async {
                  await _selectDate(date);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  key: _weeksViewportKey,
                  child: _buildAgendaContent(
                    weeks: weeks,
                    groupedByWeek: groupedByWeek,
                    compact: compact,
                  ),
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

  Widget _buildAgendaContent({
    required List<DateTime> weeks,
    required Map<DateTime, List<AgendaItem>> groupedByWeek,
    required bool compact,
  }) {
    switch (_calendarMode) {
      case AgendaCalendarMode.month:
        return _buildMainList(
          weeks: weeks,
          groupedByWeek: groupedByWeek,
          compact: compact,
          selectedDate: _selectedDate,
        );

      case AgendaCalendarMode.week:
        return _buildSelectedWeekView(
          groupedByWeek: groupedByWeek,
          compact: compact,
        );

      case AgendaCalendarMode.day:
        return _buildSelectedDayView();
    }
  }

  Widget _buildMainList({
    required List<DateTime> weeks,
    required Map<DateTime, List<AgendaItem>> groupedByWeek,
    required bool compact,
    required DateTime selectedDate,
  }) {
    if (_isLoading && _items.isEmpty) {
      return const _AgendaLoadingView();
    }

    if (_error != null && _items.isEmpty) {
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
        selectedDate: selectedDate,
        keyBuilder: _keyForWeek,
        onWeekTap: (weekStart) async {
          setState(() {
            _selectedWeekStart = weekStart;
            _selectedDate = _dateInWeekWithSameWeekday(weekStart);
            _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
          });

          _jumpMonthPagerToDisplayedMonth();
          await _scrollToSelectedWeek();
        },
      ),
    );
  }

  Widget _buildSelectedWeekView({
    required Map<DateTime, List<AgendaItem>> groupedByWeek,
    required bool compact,
  }) {
    if (_isLoading && _items.isEmpty) {
      return const _AgendaLoadingView();
    }

    if (_error != null && _items.isEmpty) {
      return _AgendaErrorView(
        message: _error!,
        onRetry: _loadItems,
      );
    }

    final weekItems = <AgendaItem>[
      ...(groupedByWeek[_selectedWeekStart] ?? <AgendaItem>[]),
    ]..sort((a, b) => a.startAt.compareTo(b.startAt));

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _WeekCard(
            weekStart: _selectedWeekStart,
            items: weekItems,
            compact: compact,
            isSelected: true,
            selectedDate: _selectedDate,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayView() {
    if (_isLoading && _items.isEmpty) {
      return const _AgendaLoadingView();
    }

    if (_error != null && _items.isEmpty) {
      return _AgendaErrorView(
        message: _error!,
        onRetry: _loadItems,
      );
    }

    final dayItems = _items
        .where((e) => _isSameDay(e.startAt, _selectedDate))
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        children: [
          const SizedBox(height: 12),
          if (dayItems.isEmpty)
            const _EmptyDayTile()
          else
            ...dayItems.map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AgendaItemCard(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

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
    final colors = context.appColors;
    final isMonth = mode == AgendaCalendarMode.month;
    final isWeek = mode == AgendaCalendarMode.week;
    final isDay = mode == AgendaCalendarMode.day;

    final headerTitle = isMonth
        ? _formatMonthYear(displayedMonth)
        : isWeek
        ? _formatWeekRange(
      _startOfWeek(selectedDate),
      _endOfWeek(selectedDate),
    )
        : _formatFullDate(selectedDate);

    final calendarHeight = isDay
        ? 86.0
        : isMonth
        ? _monthGridHeight(displayedMonth)
        : 64.0;

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
          onTap: () async {
            await onTap();
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
                              ? 'Jour précédent'
                              : isWeek
                              ? 'Semaine précédente'
                              : 'Mois précédent',
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
                              ? 'Jour suivant'
                              : isWeek
                              ? 'Semaine suivante'
                              : 'Mois suivant',
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
                    child: const Text('Aujourd’hui'),
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
                            _weekdayLabelFromIndex(index),
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
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
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
                    physics: isMonth
                        ? const PageScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final offset = index - initialPage;
                      final month = _addMonths(anchorMonth, offset);

                      return _MonthCalendarPage(
                        month: month,
                        selectedDate: selectedDate,
                        expanded: isMonth,
                        eventTypesByDay: eventTypesByDay,
                        onDateTap: onDateTap,
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
                    _weekdayLabel(day),
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

    const rowHeight = 64.0;
    const rowSpacing = 10.0;

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
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
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
                                              .titleMedium
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
    final colors = context.appColors;
    final total = items.length;
    final matchs = _countByType(AgendaItemType.match);
    final entrainements = _countByType(AgendaItemType.entrainement);
    final prepas = _countByType(AgendaItemType.preparationPhysique);

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
  const _AgendaLegend();

  @override
  Widget build(BuildContext context) {
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
            'Légende',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  static String _weekDescription(List<AgendaItem> items) {
    final matchs = items.where((e) => e.type == AgendaItemType.match).length;
    final trainings =
        items.where((e) => e.type == AgendaItemType.entrainement).length;
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
          _weekdayLabel(date),
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

    final List<String> managedTeamsIds =
    context.select<AppSession, List<String>>(
          (session) => session.managedTeamsIdsForSelectedSeason,
    );

    Season? currentSeason = context.watch<AppSession>().selectedSeason;
    String? currentPlayerId = context.watch<AppSession>().selectedPlayerId;
    String? userId = context.watch<AppSession>().user!.uid;

    bool isManager = false;
    String teamId='';

    if(item.match != null) {
      for(var t in item.match!.teams!) {
        isManager = managedTeamsIds.contains(t);
        teamId = t;
        if(isManager) {
          break;
        }
      }
    }
    if(item.training != null) {
      isManager = managedTeamsIds.contains(item.training!.teamId!);
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
                    Icons.gps_fixed_outlined,
                    size: 18,
                    color: item.areTrackersSynchronized
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
            if(isManager == false && item.withTracker && teamPlayerMetricScores != null) ... [
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {


                  final String analysisDocId = '${item.id}_${teamPlayerMetricScores?.trackerId}';

                  final Player? player = await PlayerService().getPlayerById(currentPlayerId!);

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
                                                  'Fermer',
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
                                  playerName: playerDisplayName(player!),
                                  player: player,
                                  isMatch: (item.match == null)?false:true,
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
            if(isManager && item.withTracker && item.teamWorkloadSummary != null) ... [
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final colors = context.appColors;


                  if(item.match != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => MatchDetailScreen(
                          match: item.match!,
                          isManager: isManager,
                          playerId: currentPlayerId,
                        ),
                      ),
                    );
                  } else {
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
                                              'Statistiques tracker',
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
                                                    'Fermer',
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
            if (item.match != null) ...[
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(
                        match: item.match!,
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
        workloadLabel: 'Charge',
        workloadUnit: 'pts',
        workloadColor: Colors.orange,
        showLegend: true,
        embedded: true,
        backgroundColor: Colors.black,
        padding: const EdgeInsets.all(4),
        withgoal: false,
        rings: [
          ActivityRingItem(
            label: 'Distance',
            value: distance,
            goal: item.teamWorkloadSummary!.metricStats["distanceKm"]!.max,
            unit: 'km',
            color: colors.success,
            trackColor: Colors.greenAccent.withOpacity(0.18),
            icon: Icons.directions_run,
          ),
          ActivityRingItem(
            label: 'Tps haute vitesse',
            value: tpsHauteVitesse,
            goal: item.teamWorkloadSummary!.metricStats["highSpeedDuration"]!.max,
            unit: 's',
            color: colors.primary,
            trackColor: Colors.blueAccent.withOpacity(0.18),
            icon: Icons.timer,
          ),
          ActivityRingItem(
            label: 'Sprints',
            value: sprints,
            goal: item.teamWorkloadSummary!.metricStats["sprintCount"]!.max,
            unit: 'nb',
            color: colors.warning,
            trackColor: Colors.redAccent.withOpacity(0.18),
            icon: Icons.speed,
          ),
          ActivityRingItem(
            label: 'Accélation max: 4m/s2',
            value: ms2,
            goal: item.teamWorkloadSummary!.metricStats["maxAccelerationMps2"]!.max,
            unit: 'm/s2',
            color: colors.danger,
            trackColor: Colors.redAccent.withOpacity(0.18),
            icon: Icons.speed,
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

String _weekdayLabel(DateTime date) {
  const labels = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  return labels[date.weekday - 1];
}

String _weekdayLabelFromIndex(int index) {
  const labels = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
  return labels[index];
}

String _formatMonthYear(DateTime date) {
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

  return '${months[date.month]} ${date.year}';
}

String _formatFullDate(DateTime date) {
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

  return '${date.day} ${months[date.month]} ${date.year}';
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