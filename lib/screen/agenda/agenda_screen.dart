import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/playerService.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/agendaItem.dart';
import '../../model/non_sport_event.dart';
import '../../model/player.dart';
import '../../model/training.dart';
import '../../model/season.dart';
import '../../model/tracker/team_workload_summary.dart';
import '../../provider/appSession.dart';
import '../../util/app_theme.dart';
import '../../util/playerDisplayName.dart';
import '../../widget/activity_rings_card.dart';
import '../../widget/agendaMatchRow.dart';
import '../../widget/match_tracker_stats_table.dart';
import '../../widget/session_report_email_dialog.dart';
import '../../model/feature_discovery_ids.dart';
import '../../widget/app_shell_scope.dart';
import '../../widget/feature_discovery_random_banner.dart';
import '../../widget/alternating_monetization_banner.dart';
import '../../widget/tracker_kit_icon_pill.dart';
import '../../widget/tracker_player_analysis_widget.dart';
import '../../util/match_creation_helper.dart';
import '../../util/training_creation_helper.dart';
import '../../util/intense_live_eligibility.dart';
import '../../services/training_intense_sync_service.dart';
import '../../util/training_finish_helper.dart';
import '../intense_live/intense_live_session_screen.dart';
import '../../widget/create_match_sheet.dart';
import '../../widget/create_training_sheet.dart';
import '../match_detail_screen.dart';
import '../team_players_screen.dart';
import 'agenda_add_event_menu.dart';
import '../../widget/ask_diego/ask_diego_speed_dial.dart';
import '../../widget/agenda_training_presence_actions.dart';
import '../../widget/create_non_sport_event_sheet.dart';
import '../../widget/non_sport_event_invitees_sheet.dart';
import '../../util/non_sport_event_helper.dart';
part 'agenda_calendar_widgets.dart';
part 'agenda_list_widgets.dart';
part 'agenda_status_views.dart';

enum AgendaCalendarMode {
  day,
  week,
  month,
}

class AgendaScreen extends StatefulWidget {
  final AgendaItemsWatcher watchItems;
  final DateTime? initialDate;

  const AgendaScreen({
    super.key,
    required this.watchItems,
    this.initialDate,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const int _initialMonthPage = 1200;

  /// Keep previous + current + next month loaded so day/week/month navigation
  /// stays instant inside that window.
  static const int _windowRadiusMonths = 1;
  static const int _maxLoadedMonths = 4;

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
  bool _suppressNextMonthPageChange = false;

  final Map<int, GlobalKey> _weekKeys = <int, GlobalKey>{};

  List<AgendaItem> _items = <AgendaItem>[];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  StreamSubscription<List<AgendaItem>>? _itemsSub;
  int _subscriptionGeneration = 0;

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
    final DateTime focusMonth = DateTime(now.year, now.month, 1);
    _rangeStart = _startOfMonth(_addMonths(focusMonth, -_windowRadiusMonths));
    _rangeEnd = _endOfMonth(_addMonths(focusMonth, _windowRadiusMonths));

    _monthPagerAnchor = focusMonth;
    _displayedMonth = focusMonth;
    _monthPageController = PageController(initialPage: _initialMonthPage);

    _scrollController.addListener(_handleScroll);

    _subscribeItems();
  }

  @override
  void dispose() {
    unawaited(_itemsSub?.cancel());
    _itemsSub = null;
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

    if (mode == AgendaCalendarMode.month) {
      _ensureRangeCoversMonth(_displayedMonth);
    }
  }

  bool _rangeCovers(DateTime start, DateTime end) {
    return !_rangeStart.isAfter(start) && !_rangeEnd.isBefore(end);
  }

  bool _monthIsCoveredByRange(DateTime month) {
    return _rangeCovers(_startOfMonth(month), _endOfMonth(month));
  }

  int _loadedMonthSpan() {
    return _monthDiff(_startOfMonth(_rangeStart), _startOfMonth(_rangeEnd)) + 1;
  }

  /// Ensures [month] (and ideally M±1) is loaded. Avoids tearing down the stream
  /// when the target is already in the cached window.
  Future<void> _ensureWindowForMonth(
    DateTime month, {
    bool scrollToSelection = true,
  }) async {
    final DateTime focus = DateTime(month.year, month.month, 1);
    final DateTime desiredStart =
        _startOfMonth(_addMonths(focus, -_windowRadiusMonths));
    final DateTime desiredEnd =
        _endOfMonth(_addMonths(focus, _windowRadiusMonths));

    final bool monthCovered = _monthIsCoveredByRange(focus);
    final bool windowCovered = _rangeCovers(desiredStart, desiredEnd);

    if (monthCovered && windowCovered) {
      if (scrollToSelection && _calendarMode == AgendaCalendarMode.month) {
        await _scrollToSelectedWeek();
      }
      return;
    }

    var needsReload = false;

    if (monthCovered) {
      if (_rangeStart.isAfter(desiredStart)) {
        _rangeStart = desiredStart;
        needsReload = true;
      }
      if (_rangeEnd.isBefore(desiredEnd)) {
        _rangeEnd = desiredEnd;
        needsReload = true;
      }
      if (_loadedMonthSpan() > _maxLoadedMonths) {
        _rangeStart = desiredStart;
        _rangeEnd = desiredEnd;
        needsReload = true;
      }
    } else {
      _rangeStart = desiredStart;
      _rangeEnd = desiredEnd;
      needsReload = true;
    }

    if (!needsReload) {
      if (scrollToSelection && _calendarMode == AgendaCalendarMode.month) {
        await _scrollToSelectedWeek();
      }
      return;
    }

    await _subscribeItems(scrollToSelection: scrollToSelection);
  }

  Future<void> _ensureRangeCoversMonth(
    DateTime month, {
    bool scrollToSelection = true,
  }) {
    return _ensureWindowForMonth(
      month,
      scrollToSelection: scrollToSelection,
    );
  }

  void _jumpMonthPagerToDisplayedMonth() {
    if (!_monthPageController.hasClients) return;

    final targetPage =
        _initialMonthPage + _monthDiff(_monthPagerAnchor, _displayedMonth);

    final currentPage = _monthPageController.page?.round();
    if (currentPage == targetPage) return;

    _suppressNextMonthPageChange = true;
    _monthPageController.jumpToPage(targetPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressNextMonthPageChange = false;
    });
  }

  void _onMonthPageChanged(int page) {
    if (_suppressNextMonthPageChange) return;
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

    setState(() {
      _displayedMonth = newMonth;
      _selectedDate = newSelectedDate;
      _selectedWeekStart = newSelectedWeek;
    });

    await _ensureWindowForMonth(
      newMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
    );
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

    await _ensureWindowForMonth(
      targetMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
    );
  }

  Future<void> _subscribeItems({bool scrollToSelection = true}) async {
    final int generation = ++_subscriptionGeneration;
    await _itemsSub?.cancel();
    _itemsSub = null;

    if (mounted) {
      setState(() {
        // Keep previous items visible while the new window loads.
        _isLoading = _items.isEmpty;
        _isRefreshing = _items.isNotEmpty;
        _error = null;
      });
    }

    _itemsSub = widget
        .watchItems(
          start: DateUtils.dateOnly(_rangeStart),
          end: _endOfDay(_rangeEnd),
        )
        .listen(
      (List<AgendaItem> loadedItems) {
        if (!mounted || generation != _subscriptionGeneration) {
          return;
        }

        setState(() {
          _items = List<AgendaItem>.from(loadedItems)
            ..sort(_compareAgendaItems);
          _isLoading = false;
          _isRefreshing = false;
          _error = null;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || generation != _subscriptionGeneration) {
            return;
          }

          if (scrollToSelection && _calendarMode == AgendaCalendarMode.month) {
            await _scrollToSelectedWeek(animated: false);
          } else {
            _handleScroll();
          }
        });
      },
      onError: (Object error) {
        if (!mounted || generation != _subscriptionGeneration) {
          return;
        }

        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _error = error.toString();
        });
      },
    );
  }

  Future<void> _goToPreviousWeek() async {
    final previousWeek = _selectedWeekStart.subtract(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = previousWeek;
      _selectedDate = _dateInWeekWithSameWeekday(previousWeek);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    _jumpMonthPagerToDisplayedMonth();

    await _ensureWindowForMonth(
      _displayedMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
    );
  }

  Future<void> _goToNextWeek() async {
    final nextWeek = _selectedWeekStart.add(const Duration(days: 7));

    setState(() {
      _selectedWeekStart = nextWeek;
      _selectedDate = _dateInWeekWithSameWeekday(nextWeek);
      _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    });

    _jumpMonthPagerToDisplayedMonth();

    await _ensureWindowForMonth(
      _displayedMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
    );
  }

  Future<void> _goToPreviousMonthFromHeader() async {
    if (!_monthPageController.hasClients) return;

    await _monthPageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToNextMonthFromHeader() async {
    if (!_monthPageController.hasClients) return;

    await _monthPageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _jumpToToday() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final todayWeek = _startOfWeek(now);
    final todayMonth = DateTime(now.year, now.month, 1);

    setState(() {
      _selectedDate = now;
      _selectedWeekStart = todayWeek;
      _displayedMonth = todayMonth;
    });

    _jumpMonthPagerToDisplayedMonth();

    await _ensureWindowForMonth(
      todayMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
    );
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
      helpText: context.l10n.actionChoosePeriod,
      saveText: context.l10n.actionValidate,
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

    await _subscribeItems(scrollToSelection: true);
  }

  Future<void> _extendBefore() async {
    setState(() {
      _rangeStart = _rangeStart.subtract(const Duration(days: 28));
    });

    await _subscribeItems(scrollToSelection: false);
  }

  Future<void> _extendAfter() async {
    setState(() {
      _rangeEnd = _endOfWeek(_rangeEnd.add(const Duration(days: 28)));
    });

    await _subscribeItems(scrollToSelection: false);
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
                    periodLabel: _formatPeriodLabel(
                      _rangeStart,
                      _rangeEnd,
                      Localizations.localeOf(context).toString(),
                    ),
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

    final l10n = context.l10n;
    final bool hideAppBar = AppShellScope.hidesChildAppBar(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(l10n.navAgenda),
              actions: [
                IconButton(
                  tooltip: l10n.navOverview,
                  onPressed: _showOverviewPanel,
                  icon: const Icon(Icons.insert_chart_outlined_rounded),
                ),
              ],
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              const AlternatingMonetizationBanner(),
              const FeatureDiscoveryRandomBanner(
                parentScreenId: FeatureDiscoveryIds.tabAgenda,
                excludeCurrentBaseScreen: true,
              ),
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
                  await _goToPreviousWeek();
                },
                onNextWeek: () async {
                  await _goToNextWeek();
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
              if (_isRefreshing) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 2.5,
                    backgroundColor: colors.border.withValues(alpha: 0.35),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
              ] else
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
      floatingActionButton: AskDiegoSpeedDial(
        heroTagPrefix: 'agenda',
        primaryAction: AskDiegoPrimaryAction(
          heroTag: 'grinta-fab-agenda',
          icon: Icons.add,
          tooltip: context.l10n.agendaAddEventTitle,
          onPressed: () => showAgendaAddEventMenu(
            context,
            initialDate: _selectedDate,
            onTrainingCreated: () => _subscribeItems(),
          ),
        ),
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
        onRetry: () => _subscribeItems(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _subscribeItems(),
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
        onRetry: () => _subscribeItems(),
      );
    }

    final weekItems = <AgendaItem>[
      ...(groupedByWeek[_selectedWeekStart] ?? <AgendaItem>[]),
    ]..sort(_compareAgendaItems);

    return RefreshIndicator(
      onRefresh: () => _subscribeItems(),
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
        onRetry: () => _subscribeItems(),
      );
    }

    final dayItems = _items
        .where((e) => _agendaItemOccursOnDay(e, _selectedDate))
        .toList()
      ..sort(_compareAgendaItems);

    return RefreshIndicator(
      onRefresh: () => _subscribeItems(),
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
                child: item.allDay && item.type == AgendaItemType.nonSport
                    ? _AllDayNonSportRow(item: item)
                    : AgendaItemCard(item: item),
              ),
            ),
        ],
      ),
    );
  }
}

