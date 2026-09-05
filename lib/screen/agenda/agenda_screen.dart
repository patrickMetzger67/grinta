import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import '../../model/agenda_filter.dart';
import '../../model/highlights.dart';
import '../../model/match.dart' as models;
import '../../model/non_sport_event.dart';
import '../../model/player.dart';
import '../../model/training.dart';
import '../../model/season.dart';
import '../../model/tracker/team_workload_summary.dart';
import '../../provider/appSession.dart';
import '../../util/agenda_calendar_date.dart';
import '../../util/agenda_paint_perf.dart';
import '../../util/app_theme.dart';
import '../../util/playerDisplayName.dart';
import '../../widget/activity_rings_card.dart';
import '../../widget/agendaMatchRow.dart';
import '../../widget/session_report_email_dialog.dart';
import '../../model/feature_discovery_ids.dart';
import '../../widget/app_shell_scope.dart';
import '../../widget/feature_discovery_random_banner.dart';
import '../../widget/alternating_monetization_banner.dart';
import '../../widget/tracker_kit_icon_pill.dart';
import '../../widget/session_player_analysis_view.dart';
import '../../widget/session_tracker_stats_view.dart';
import '../../util/match_creation_helper.dart';
import '../../util/training_creation_helper.dart';
import '../../util/intense_live_eligibility.dart';
import '../../util/match_intense_finish_helper.dart';
import '../../services/agenda_filter_prefs.dart';
import '../../services/highlightsService.dart';
import '../../services/training_intense_sync_service.dart';
import '../../util/polar_import_navigation.dart';
import '../../util/training_finish_helper.dart';
import '../intense_live/intense_live_session_screen.dart';
import '../../widget/create_match_sheet.dart';
import '../../widget/create_training_sheet.dart';
import '../match_detail_screen.dart';
import '../team_players_screen.dart';
import 'agenda_add_event_menu.dart';
import 'agenda_filter_sheet.dart';
import '../../widget/ask_diego/ask_diego_speed_dial.dart';
import '../../widget/agenda_coach_players_dialog.dart';
import '../../widget/agenda_training_presence_actions.dart';
import '../../widget/coach_workload_analysis_entry_button.dart';
import '../../widget/create_non_sport_event_sheet.dart';
import '../../widget/create_personal_sport_activity_sheet.dart';
import '../../widget/session_personal_data_dialog.dart';
import '../../services/session_personal_data_service.dart';
import '../../widget/non_sport_event_invitees_sheet.dart';
import '../../widget/player_feeling_faces.dart';
import '../../widget/playerPhoto.dart';
import '../../widget/sport_metric_pickers.dart';
import '../../model/personal_sport_activity.dart';
import '../../model/player.dart';
import '../../model/player_feeling.dart';
import '../../util/non_sport_event_helper.dart';
import '../../util/personal_sport_activity_helper.dart';
import '../../util/session_report_access.dart';
import '../../util/share_player_access.dart';
import '../../util/staff_session_access.dart';
import '../../widget/session_averages_share_button.dart';
import '../../services/session_player_synthesis_share_service.dart';
part 'agenda_calendar_widgets.dart';
part 'agenda_list_widgets.dart';
part 'agenda_status_views.dart';

enum AgendaCalendarMode {
  /// First header icon (3 bars). Still shows the LUN–DIM week strip.
  day,
  week,
  month,
}

class AgendaScreen extends StatefulWidget {
  final AgendaItemsWatcher watchItems;
  final DateTime? initialDate;

  /// Invalidates cached team workload for an event and refreshes agenda cards
  /// after Intense finish / re-sync.
  final ValueChanged<String>? onTrackerWorkloadUpdated;

  const AgendaScreen({
    super.key,
    required this.watchItems,
    this.initialDate,
    this.onTrackerWorkloadUpdated,
  });

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

/// Provides [onTrackerWorkloadUpdated] to agenda cards without threading it
/// through every list/day widget.
class _AgendaWorkloadRefreshScope extends InheritedWidget {
  const _AgendaWorkloadRefreshScope({
    required this.onTrackerWorkloadUpdated,
    required super.child,
  });

  final ValueChanged<String> onTrackerWorkloadUpdated;

  static void notify(BuildContext context, String eventId) {
    final String trimmed = eventId.trim();
    if (trimmed.isEmpty) {
      return;
    }
    context
        .getInheritedWidgetOfExactType<_AgendaWorkloadRefreshScope>()
        ?.onTrackerWorkloadUpdated(trimmed);
  }

  @override
  bool updateShouldNotify(_AgendaWorkloadRefreshScope oldWidget) {
    return onTrackerWorkloadUpdated != oldWidget.onTrackerWorkloadUpdated;
  }
}

/// Provides coach-selected player avatars to agenda cards.
class _AgendaCoachPlayersScope extends InheritedWidget {
  const _AgendaCoachPlayersScope({
    required this.playersByMemberId,
    required super.child,
  });

  final Map<String, Player> playersByMemberId;

  static Player? playerFor(BuildContext context, String? memberId) {
    final trimmed = memberId?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return context
        .dependOnInheritedWidgetOfExactType<_AgendaCoachPlayersScope>()
        ?.playersByMemberId[trimmed];
  }

  @override
  bool updateShouldNotify(_AgendaCoachPlayersScope oldWidget) {
    return !mapEquals(playersByMemberId, oldWidget.playersByMemberId);
  }
}

class _AgendaScreenState extends State<AgendaScreen> {
  static const int _initialMonthPage = 1200;

  /// Keep previous + current + next month loaded so day/week/month navigation
  /// stays instant inside that window.
  static const int _windowRadiusMonths = 1;
  static const int _maxLoadedMonths = 4;
  /// Warm M±2 into the paint cache after the gesture settles.
  static const int _prefetchRadiusMonths = 2;
  /// Idle after last month page landing before Firestore hydrate (burst flings).
  static const Duration _hydrateDebounce = Duration(milliseconds: 180);
  static const Duration _prefetchSettle = Duration(milliseconds: 280);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _weeksViewportKey = GlobalKey();

  late DateTime _selectedWeekStart;
  late DateTime _selectedWeekEnd;
  late DateTime _selectedDate;
  late DateTime _rangeStart;
  late DateTime _rangeEnd;

  late final DateTime _monthPagerAnchor;
  late PageController _monthPageController;
  /// Bumped when the month PageView must remount on the focused page (e.g.
  /// after a date-picker jump while the controller was stuck on today).
  int _monthPagerRemountToken = 0;
  int _monthPagerControllerInitialPage = _initialMonthPage;

  late DateTime _displayedMonth;
  /// Day-of-month remembered across month pager moves (31 Aug → 30 Sep → 31 Aug).
  late int _preferredDayOfMonth;
  AgendaCalendarMode _calendarMode = AgendaCalendarMode.day;
  bool _suppressNextMonthPageChange = false;
  /// Ignores list-scroll selection sync while the month pager / ensureVisible runs.
  bool _suppressScrollSelectionSync = false;
  /// True while the month PageView is flinging / not settled on an integer page,
  /// or until deferred hydrate after the last landing. Blocks list sync + paints.
  bool _monthPagerBusy = false;

  final Map<int, GlobalKey> _weekKeys = <int, GlobalKey>{};

  List<AgendaItem> _items = <AgendaItem>[];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  StreamSubscription<List<AgendaItem>>? _itemsSub;
  StreamSubscription<List<AgendaItem>>? _prefetchSub;
  int _subscriptionGeneration = 0;
  int _prefetchGeneration = 0;
  /// Latest-wins gate: a newer week/month slide supersedes in-flight hydrations.
  final LatestWinsGate _hydrationGate = LatestWinsGate();
  final DebouncedLatestAction _hydrateDebouncer =
      DebouncedLatestAction(delay: _hydrateDebounce);
  final DebouncedLatestAction _prefetchDebouncer =
      DebouncedLatestAction(delay: _prefetchSettle);
  final AgendaMonthPaintCache _paintCache = AgendaMonthPaintCache(maxMonths: 8);
  late final AgendaPaintCoalescer<List<AgendaItem>> _itemsPaintCoalescer;
  String _itemsPaintFingerprint = '';

  /// Selective rebuild tick for calendar + list (avoids full Scaffold setState
  /// on every scroll sync / hydration emit).
  final ValueNotifier<int> _agendaPaintTick = ValueNotifier<int>(0);

  /// Cached derived maps — recomputed only when items/filter/range change.
  List<AgendaItem> _cachedFilteredItems = const <AgendaItem>[];
  Map<int, List<AgendaItemType>> _cachedEventTypesByDay =
      const <int, List<AgendaItemType>>{};
  Map<DateTime, List<AgendaItem>> _cachedGroupedByWeek =
      const <DateTime, List<AgendaItem>>{};
  List<DateTime> _cachedWeeks = const <DateTime>[];
  String? _derivedCacheKey;

  String? _coachViewTeamId;
  Map<String, Player> _coachViewPlayersByMemberId = <String, Player>{};

  AgendaFilter _filter = AgendaFilter.none;
  String? _filterScopeKey;

  List<AgendaItem> get _filteredItems {
    _ensureDerivedCaches();
    return _cachedFilteredItems;
  }

  void _bumpAgendaPaint() {
    _agendaPaintTick.value++;
  }

  void _ensureDerivedCaches() {
    final String filterKey =
        '${_filter.teamIds.join(",")}|${_filter.types.map((t) => t.name).join(",")}';
    final String key =
        '$_itemsPaintFingerprint|$filterKey|'
        '${_rangeStart.millisecondsSinceEpoch}|'
        '${_rangeEnd.millisecondsSinceEpoch}';
    if (_derivedCacheKey == key) return;
    _derivedCacheKey = key;
    _cachedFilteredItems = applyAgendaFilter(_items, _filter);
    _cachedEventTypesByDay = _headerEventTypesByDay(_cachedFilteredItems);
    _cachedGroupedByWeek = _groupItemsByWeek(_cachedFilteredItems);
    _cachedWeeks = _generateWeeks(_rangeStart, _rangeEnd);
  }

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
    _preferredDayOfMonth = now.day;
    _selectedWeekStart = _startOfWeek(now);
    _selectedWeekEnd = _endOfWeek(now);
    final DateTime focusMonth = DateTime(now.year, now.month, 1);
    _rangeStart = _startOfMonth(_addMonths(focusMonth, -_windowRadiusMonths));
    _rangeEnd = _endOfMonth(_addMonths(focusMonth, _windowRadiusMonths));

    _monthPagerAnchor = focusMonth;
    _displayedMonth = focusMonth;
    _monthPageController = PageController(initialPage: _initialMonthPage);
    _monthPageController.addListener(_onMonthPagerScrollActivity);

    _itemsPaintCoalescer = AgendaPaintCoalescer<List<AgendaItem>>(_paintItems);

    _scrollController.addListener(_handleScroll);

    _subscribeItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_ensureFilterLoaded());
  }

  Future<void> _ensureFilterLoaded() async {
    final session = context.read<AppSession>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final playerId = session.selectedPlayerId ?? '';
    final seasonId = session.selectedSeason?.ref?.id ?? '';
    final scopeKey = '$uid|$playerId|$seasonId';
    if (scopeKey == _filterScopeKey) return;
    _filterScopeKey = scopeKey;

    final loaded = await AgendaFilterPrefs.instance.load(
      uid: uid,
      playerId: playerId,
      seasonId: seasonId,
    );
    if (!mounted || _filterScopeKey != scopeKey) return;
    setState(() {
      _filter = loaded;
      _derivedCacheKey = null;
    });
  }

  Future<void> _openAgendaFilter() async {
    final session = context.read<AppSession>();
    final teams = session.teamsForAgendaSelectedSeason;
    final result = await showAgendaFilterSheet(
      context,
      initialFilter: _filter,
      teams: teams,
    );
    if (!mounted || result == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final playerId = session.selectedPlayerId ?? '';
    final seasonId = session.selectedSeason?.ref?.id ?? '';
    setState(() {
      _filter = result;
      _derivedCacheKey = null;
    });
    await AgendaFilterPrefs.instance.save(
      uid: uid,
      playerId: playerId,
      seasonId: seasonId,
      filter: result,
    );
  }

  Future<void> _clearAgendaFilter() async {
    final session = context.read<AppSession>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final playerId = session.selectedPlayerId ?? '';
    final seasonId = session.selectedSeason?.ref?.id ?? '';
    setState(() {
      _filter = AgendaFilter.none;
      _derivedCacheKey = null;
    });
    await AgendaFilterPrefs.instance.save(
      uid: uid,
      playerId: playerId,
      seasonId: seasonId,
      filter: AgendaFilter.none,
    );
  }

  @override
  void dispose() {
    _hydrateDebouncer.dispose();
    _prefetchDebouncer.dispose();
    _itemsPaintCoalescer.dispose();
    _agendaPaintTick.dispose();
    unawaited(_prefetchSub?.cancel());
    _prefetchSub = null;
    unawaited(_itemsSub?.cancel());
    _itemsSub = null;
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _monthPageController.removeListener(_onMonthPagerScrollActivity);
    _monthPageController.dispose();
    super.dispose();
  }

  /// Tracks fractional PageView motion so list sync / paints stay off mid-fling.
  void _onMonthPagerScrollActivity() {
    if (_calendarMode != AgendaCalendarMode.month) return;
    if (!_monthPageController.hasClients) return;

    final bool nearInteger =
        agendaPageViewNearInteger(_monthPageController.page);
    if (!nearInteger) {
      _setMonthPagerBusy(true);
      return;
    }
    // Near an integer page: stay busy until hydrate idle debounce drains so a
    // burst of landings does not hydrate / paint intermediates.
    if (_hydrateDebouncer.hasPending) {
      _setMonthPagerBusy(true);
    }
  }

  void _setMonthPagerBusy(bool busy) {
    if (_monthPagerBusy == busy) {
      if (busy) {
        _suppressScrollSelectionSync = true;
        _itemsPaintCoalescer.setPaused(true);
      }
      return;
    }
    _monthPagerBusy = busy;
    if (busy) {
      _suppressScrollSelectionSync = true;
      _itemsPaintCoalescer.setPaused(true);
    } else {
      _itemsPaintCoalescer.setPaused(false);
      // Keep list sync suppressed one frame after settle so ensureVisible /
      // layout from hydrate cannot re-drive preferred day.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _monthPagerBusy) return;
        if (_hydrateDebouncer.hasPending) return;
        _suppressScrollSelectionSync = false;
      });
    }
  }

  /// Drops queued mid-fling paints / prefetch so a superseded slide cannot
  /// jump the UI. Does not cancel the live items watch or bump its generation
  /// (that would orphan emissions until the next subscribe).
  void _discardInFlightHydrationPaint() {
    _prefetchGeneration++;
    _itemsPaintCoalescer.discardPending();
    unawaited(_prefetchSub?.cancel());
    _prefetchSub = null;
  }

  void _handleScroll() {
    if (_calendarMode != AgendaCalendarMode.month) return;
    if (_suppressScrollSelectionSync || _monthPagerBusy) return;

    final focusedWeek = _computeFocusedWeek();
    if (focusedWeek == null) return;

    if (focusedWeek.millisecondsSinceEpoch ==
        _selectedWeekStart.millisecondsSinceEpoch) {
      return;
    }

    // Month PageView owns the displayed month. List scroll may refine the
    // selected day only when the focused week still overlaps that month —
    // never jump the pager back to "today" (or another month) mid-swipe.
    if (!weekOverlapsMonth(focusedWeek, _displayedMonth)) return;

    final nextSelectedDate = _dateInWeekWithSameWeekday(focusedWeek);
    if (!mounted) return;

    // Scroll sync must stay cheap: update selection without Scaffold setState.
    // Do not overwrite preferred day from list focus while in month mode —
    // pager landings own preferredDay (31 Aug ↔ 30 Sep ↔ 31 Aug).
    _selectedWeekStart = focusedWeek;
    _selectedDate = nextSelectedDate;
    _bumpAgendaPaint();
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

    // Format change is sync so the header jumps immediately (week→month with
    // no intermediate expanded-week animation — see AnimatedSize duration).
    final LatestWinsToken token = _hydrationGate.begin();

    _calendarMode = mode;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _bumpAgendaPaint();

    // Sync pager to focused month (after date-picker jumps the controller may
    // still sit on the initial today page while selection is far away).
    _jumpMonthPagerToDisplayedMonth(forceAfterFrame: true);

    if (mode == AgendaCalendarMode.month) {
      _scheduleWindowHydration(
        _displayedMonth,
        token: token,
      );
    }
    // Leaving month: token already invalidated in-flight month hydrates/scrolls.
  }

  /// Slide/pager first: paint the new selection, then hydrate after settle.
  /// Loads are debounced; UI never waits. A newer slide bumps [LatestWinsGate]
  /// so stale loads/scrolls are ignored.
  ///
  /// Pass [token] when the caller already called [_hydrationGate.begin] so
  /// in-flight work is invalidated before paint (not only at hydrate time).
  void _scheduleWindowHydration(
    DateTime month, {
    bool scrollToSelection = true,
    LatestWinsToken? token,
  }) {
    final LatestWinsToken navToken = token ?? _hydrationGate.begin();
    // Cancel pending prefetch from a previous settle — a new gesture owns IO.
    _prefetchDebouncer.cancel();
    unawaited(_prefetchSub?.cancel());
    _prefetchSub = null;

    // While a month-mode hydrate is pending, keep pager-busy so burst swipes
    // never let list sync / Firestore paints jump the PageView.
    if (_calendarMode == AgendaCalendarMode.month) {
      _setMonthPagerBusy(true);
    }

    _hydrateDebouncer.schedule(navToken, (LatestWinsToken t) {
      if (!mounted || !t.isCurrent) return;
      unawaited(
        _hydrateWindowForMonth(
          month,
          token: t,
          scrollToSelection: scrollToSelection,
        ),
      );
    });
  }

  /// Ensures [month] (and ideally M±1) is loaded. Avoids tearing down the stream
  /// when the target is already in the cached window.
  Future<void> _hydrateWindowForMonth(
    DateTime month, {
    required LatestWinsToken token,
    bool scrollToSelection = true,
  }) async {
    if (!token.isCurrent || !mounted) return;

    // If the pager is still mid-fling, wait for the next debounce settle.
    if (_calendarMode == AgendaCalendarMode.month &&
        _monthPageController.hasClients &&
        !agendaPageViewNearInteger(_monthPageController.page)) {
      _scheduleWindowHydration(
        month,
        scrollToSelection: scrollToSelection,
        token: token,
      );
      return;
    }

    // Settled: allow THIS hydrate's paints while keeping list-sync suppressed
    // until the end of the method (_setMonthPagerBusy(false)).
    _itemsPaintCoalescer.setPaused(false);

    final AgendaWindowHydrationPlan plan = planAgendaWindowHydration(
      focusMonth: month,
      currentRangeStart: _rangeStart,
      currentRangeEnd: _rangeEnd,
      windowRadiusMonths: _windowRadiusMonths,
      maxLoadedMonths: _maxLoadedMonths,
    );

    if (!token.isCurrent || !mounted) return;

    if (plan.alreadyFullyCovered || !plan.needsReload) {
      if (scrollToSelection &&
          _calendarMode == AgendaCalendarMode.month &&
          token.isCurrent) {
        await _scrollToSelectedWeek(navigationToken: token);
      }
      if (token.isCurrent && mounted) {
        _scheduleAdjacentPrefetch(month, token);
        if (_calendarMode == AgendaCalendarMode.month) {
          _setMonthPagerBusy(false);
        }
      }
      return;
    }

    // Only the latest slide may rewrite the loaded range / start a subscribe.
    if (!token.isCurrent) return;

    _rangeStart = plan.rangeStart;
    _rangeEnd = plan.rangeEnd;
    _derivedCacheKey = null;

    // Stale-while-revalidate: paint cached months instantly if we have them.
    final List<AgendaItem>? cachedPaint = _paintCache.tryPaintRange(
      rangeStart: plan.rangeStart,
      rangeEnd: plan.rangeEnd,
    );
    if (cachedPaint != null && mounted && token.isCurrent) {
      _applyPaintedItems(
        cachedPaint,
        isRefreshing: true,
        force: true,
      );
    }

    await _subscribeItems(
      scrollToSelection: scrollToSelection,
      navigationToken: token,
    );

    if (token.isCurrent && mounted) {
      _scheduleAdjacentPrefetch(month, token);
      if (_calendarMode == AgendaCalendarMode.month) {
        _setMonthPagerBusy(false);
      }
    }
  }

  /// After settle, silently warm adjacent months into [_paintCache] (no UI jank).
  void _scheduleAdjacentPrefetch(DateTime focusMonth, LatestWinsToken token) {
    _prefetchDebouncer.schedule(token, (LatestWinsToken t) {
      if (!mounted || !t.isCurrent) return;
      unawaited(_prefetchAdjacentMonths(focusMonth, t));
    });
  }

  Future<void> _prefetchAdjacentMonths(
    DateTime focusMonth,
    LatestWinsToken token,
  ) async {
    if (!token.isCurrent || !mounted) return;

    final List<DateTime> targets = planAgendaPrefetchMonths(
      focusMonth: focusMonth,
      isCached: _paintCache.coversMonth,
      windowRadiusMonths: _windowRadiusMonths,
      prefetchRadiusMonths: _prefetchRadiusMonths,
    );
    if (targets.isEmpty) return;

    // One combined silent watch for the outermost missing span.
    DateTime prefetchStart = targets.first;
    DateTime prefetchEnd = targets.first;
    for (final DateTime m in targets) {
      if (m.isBefore(prefetchStart)) prefetchStart = m;
      if (m.isAfter(prefetchEnd)) prefetchEnd = m;
    }
    final DateTime rangeStart = _startOfMonth(prefetchStart);
    final DateTime rangeEnd = _endOfMonth(prefetchEnd);

    final int generation = ++_prefetchGeneration;
    await _prefetchSub?.cancel();
    _prefetchSub = null;

    _prefetchSub = widget
        .watchItems(
          start: DateUtils.dateOnly(rangeStart),
          end: _endOfDay(rangeEnd),
          coachVisibleMemberIds:
              _coachViewPlayersByMemberId.keys.toList(growable: false),
        )
        .listen(
      (List<AgendaItem> loadedItems) {
        if (!mounted ||
            generation != _prefetchGeneration ||
            !token.isCurrent) {
          return;
        }
        _paintCache.storeRange(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          items: loadedItems,
        );
        // First useful emit is enough for SWR; cancel to free Firestore watchers.
        unawaited(() async {
          await _prefetchSub?.cancel();
          _prefetchSub = null;
        }());
      },
      onError: (_) {
        // Prefetch is best-effort — never surface errors to the UI.
      },
    );
  }

  void _paintItems(List<AgendaItem> loadedItems) {
    if (!mounted) return;
    _applyPaintedItems(loadedItems, isRefreshing: false);
  }

  void _applyPaintedItems(
    List<AgendaItem> loadedItems, {
    required bool isRefreshing,
    bool force = false,
  }) {
    // Mid-fling: keep SWR cache warm but do not rebuild the pager/list.
    if (_monthPagerBusy && !force) {
      _paintCache.storeRange(
        rangeStart: _rangeStart,
        rangeEnd: _rangeEnd,
        items: loadedItems,
      );
      return;
    }

    final String fingerprint = agendaItemsPaintFingerprint(loadedItems);
    if (!force &&
        fingerprint == _itemsPaintFingerprint &&
        !_isLoading &&
        _isRefreshing == isRefreshing) {
      return;
    }

    _items = List<AgendaItem>.from(loadedItems)..sort(_compareAgendaItems);
    _itemsPaintFingerprint = fingerprint;
    _isLoading = false;
    _isRefreshing = isRefreshing;
    _error = null;
    _derivedCacheKey = null;
    _paintCache.storeRange(
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      items: _items,
    );
    _bumpAgendaPaint();
  }

  void _jumpMonthPagerToDisplayedMonth({bool forceAfterFrame = false}) {
    final int targetPage = agendaMonthPageIndex(
      anchorMonth: _monthPagerAnchor,
      month: _displayedMonth,
      initialPage: _initialMonthPage,
    );

    void doJump() {
      if (!mounted) return;

      if (!_monthPageController.hasClients) {
        // PageView not attached yet (day mode, or mid-rebuild). Recreate the
        // controller so the next attach opens on the focused month instead of
        // the original today page.
        if (_monthPagerControllerInitialPage != targetPage) {
          _replaceMonthPageController(initialPage: targetPage);
        }
        return;
      }

      final currentPage = _monthPageController.page?.round();
      if (currentPage == targetPage) return;

      _suppressNextMonthPageChange = true;
      _monthPageController.jumpToPage(targetPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _suppressNextMonthPageChange = false;
        // If jumpToPage did not stick (viewport resize / physics), remount.
        if (_monthPageController.hasClients &&
            _monthPageController.page?.round() != targetPage) {
          _remountMonthPagerAt(targetPage);
        }
      });
    }

    if (_monthPageController.hasClients ||
        _monthPagerControllerInitialPage != targetPage) {
      doJump();
    }

    // PageView may attach / resize on the next frame (day→week/month, or
    // week→month height change). Always retry so a date-picker jump is not
    // lost when hasClients was false, and so format switches re-sync.
    if (forceAfterFrame || !_monthPageController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        doJump();
      });
    }
  }

  void _replaceMonthPageController({required int initialPage}) {
    assert(!_monthPageController.hasClients,
        'Replace only when PageView is detached');
    _monthPageController.removeListener(_onMonthPagerScrollActivity);
    _monthPageController.dispose();
    _monthPagerControllerInitialPage = initialPage;
    _monthPageController = PageController(initialPage: initialPage);
    _monthPageController.addListener(_onMonthPagerScrollActivity);
  }

  void _remountMonthPagerAt(int targetPage) {
    // Swap controller first, remount PageView via token, dispose old after
    // detach — never dispose while still attached.
    final PageController oldController = _monthPageController;
    oldController.removeListener(_onMonthPagerScrollActivity);
    _monthPagerControllerInitialPage = targetPage;
    _monthPageController = PageController(initialPage: targetPage);
    _monthPageController.addListener(_onMonthPagerScrollActivity);
    _monthPagerRemountToken++;
    _suppressNextMonthPageChange = true;
    _bumpAgendaPaint();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      if (!mounted) return;
      _suppressNextMonthPageChange = false;
    });
  }

  void _onMonthPageChanged(int page) {
    if (_suppressNextMonthPageChange) return;
    _handleMonthPageChanged(page);
  }

  void _handleMonthPageChanged(int page) {
    final DateTime newMonth = agendaMonthForPageIndex(
      anchorMonth: _monthPagerAnchor,
      page: page,
      initialPage: _initialMonthPage,
    );

    // Keep preferred day across shorter months (31 → 30 Sep → back to 31 Aug).
    final AgendaMonthSwipeFocus focus = applyMonthPageLanding(
      targetMonth: newMonth,
      preferredDayOfMonth: _preferredDayOfMonth,
    );
    final newSelectedDate = focus.selectedDate;
    final newSelectedWeek = _startOfWeek(newSelectedDate);

    // Invalidate stale hydrates/scrolls before updating selection.
    final LatestWinsToken token = _hydrationGate.begin();
    // Drop in-flight Firestore immediately so burst flings never apply stale
    // paints that rebuild/jump the pager.
    _discardInFlightHydrationPaint();

    // Update pager selection immediately; hydrate only after settle+idle.
    _setMonthPagerBusy(true);
    _displayedMonth = focus.displayedMonth;
    _selectedDate = newSelectedDate;
    _selectedWeekStart = newSelectedWeek;
    // preferredDayOfMonth stays sticky (focus.preferredDayOfMonth).
    _bumpAgendaPaint();

    _scheduleWindowHydration(
      newMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
      token: token,
    );
  }

  AgendaHeaderPeriod get _headerPeriod {
    return agendaChevronPeriodForView(
      listWithWeekStrip: _calendarMode == AgendaCalendarMode.day,
      weekView: _calendarMode == AgendaCalendarMode.week,
      monthView: _calendarMode == AgendaCalendarMode.month,
    );
  }

  DateTime _chevronFocusedDate(int direction) {
    return agendaHeaderChevronDate(
      focusedDate: _selectedDate,
      period: _headerPeriod,
      direction: direction,
    );
  }

  /// Horizontal swipe on the events area (calendar header has its own handler).
  /// Never awaits — a second swipe must win immediately.
  void _handleHorizontalPeriodSwipe({required bool goNext}) {
    switch (_calendarMode) {
      case AgendaCalendarMode.day:
      case AgendaCalendarMode.week:
        if (goNext) {
          unawaited(_goToNextWeek());
        } else {
          unawaited(_goToPreviousWeek());
        }
      case AgendaCalendarMode.month:
        if (goNext) {
          unawaited(_goToNextMonthFromHeader());
        } else {
          unawaited(_goToPreviousMonthFromHeader());
        }
    }
  }

  Future<void> _selectDate(DateTime date) async {
    final normalizedDate = DateUtils.dateOnly(date);
    final targetWeek = _startOfWeek(normalizedDate);
    final targetMonth = DateTime(normalizedDate.year, normalizedDate.month, 1);

    final LatestWinsToken token = _hydrationGate.begin();

    _selectedDate = normalizedDate;
    _preferredDayOfMonth = normalizedDate.day;
    _selectedWeekStart = targetWeek;
    _displayedMonth = targetMonth;
    _bumpAgendaPaint();

    // After a far jump, force a post-frame pager sync so week→month does not
    // keep painting the initial today month.
    _jumpMonthPagerToDisplayedMonth(forceAfterFrame: true);

    _scheduleWindowHydration(
      targetMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
      token: token,
    );
  }

  Future<void> _subscribeItems({
    bool scrollToSelection = true,
    LatestWinsToken? navigationToken,
  }) async {
    final int generation = ++_subscriptionGeneration;
    await _itemsSub?.cancel();
    _itemsSub = null;

    if (mounted) {
      // Keep previous items visible while the new window loads.
      _isLoading = _items.isEmpty;
      _isRefreshing = _items.isNotEmpty;
      _error = null;
      _bumpAgendaPaint();
    }

    bool pendingScroll = scrollToSelection;

    _itemsSub = widget
        .watchItems(
          start: DateUtils.dateOnly(_rangeStart),
          end: _endOfDay(_rangeEnd),
          coachVisibleMemberIds:
              _coachViewPlayersByMemberId.keys.toList(growable: false),
        )
        .listen(
      (List<AgendaItem> loadedItems) {
        if (!mounted || generation != _subscriptionGeneration) {
          return;
        }
        // Mid-fling: queue silently; discardPending on the next landing drops
        // stale emits so they never rebuild the pager.
        if (_monthPagerBusy &&
            (navigationToken == null || !navigationToken.isCurrent)) {
          return;
        }

        // Coalesce progressive Firestore/enrichment emits to one paint/frame.
        _itemsPaintCoalescer.submit(List<AgendaItem>.from(loadedItems));

        if (!pendingScroll) return;
        pendingScroll = false;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || generation != _subscriptionGeneration) {
            return;
          }
          // Skip scroll if a newer slide already moved the selection.
          if (navigationToken != null && !navigationToken.isCurrent) {
            return;
          }
          if (_monthPagerBusy &&
              navigationToken != null &&
              !navigationToken.isCurrent) {
            return;
          }

          if (scrollToSelection && _calendarMode == AgendaCalendarMode.month) {
            await _scrollToSelectedWeek(
              animated: false,
              navigationToken: navigationToken,
            );
          } else if (navigationToken == null || navigationToken.isCurrent) {
            // Never let a stale load re-drive selection from list position.
            if (!_monthPagerBusy) {
              _handleScroll();
            }
          }
        });
      },
      onError: (Object error) {
        if (!mounted || generation != _subscriptionGeneration) {
          return;
        }

        _isLoading = false;
        _isRefreshing = false;
        _error = error.toString();
        _bumpAgendaPaint();
      },
    );
  }

  Future<void> _goToPreviousWeek() {
    return _selectDate(
      agendaHeaderChevronDate(
        focusedDate: _selectedDate,
        period: AgendaHeaderPeriod.week,
        direction: -1,
      ),
    );
  }

  Future<void> _goToNextWeek() {
    return _selectDate(
      agendaHeaderChevronDate(
        focusedDate: _selectedDate,
        period: AgendaHeaderPeriod.week,
        direction: 1,
      ),
    );
  }

  Future<void> _goToPreviousMonthFromHeader() async {
    // Drive from focused/displayed month — never PageController.previousPage
    // alone (controller may still sit on the initial today page after a
    // week-mode date-picker jump, which would land on the wrong month).
    final int targetPage = agendaAdjacentMonthPageFromFocus(
      displayedMonth: _displayedMonth,
      anchorMonth: _monthPagerAnchor,
      initialPage: _initialMonthPage,
      monthDelta: -1,
    );
    await _animateMonthPagerToPage(targetPage);
  }

  Future<void> _goToNextMonthFromHeader() async {
    final int targetPage = agendaAdjacentMonthPageFromFocus(
      displayedMonth: _displayedMonth,
      anchorMonth: _monthPagerAnchor,
      initialPage: _initialMonthPage,
      monthDelta: 1,
    );
    await _animateMonthPagerToPage(targetPage);
  }

  Future<void> _animateMonthPagerToPage(int targetPage) async {
    if (!_monthPageController.hasClients) {
      // Pager not mounted (e.g. day mode) — apply landing from focus math.
      _handleMonthPageChanged(targetPage);
      return;
    }

    final int? currentPage = _monthPageController.page?.round();
    if (currentPage == targetPage) return;

    // If the controller is far from the focused month, snap to the adjacent
    // target directly so chevrons never step from a stale August page to July
    // while the UI focus is December.
    unawaited(
      _monthPageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _jumpToToday() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final todayWeek = _startOfWeek(now);
    final todayMonth = DateTime(now.year, now.month, 1);
    final LatestWinsToken token = _hydrationGate.begin();

    _selectedDate = now;
    _preferredDayOfMonth = now.day;
    _selectedWeekStart = todayWeek;
    _displayedMonth = todayMonth;
    _bumpAgendaPaint();

    _jumpMonthPagerToDisplayedMonth(forceAfterFrame: true);

    _scheduleWindowHydration(
      todayMonth,
      scrollToSelection: _calendarMode == AgendaCalendarMode.month,
      token: token,
    );
  }

  /// Opens a date picker from the header title between the chevrons.
  /// UI focus updates immediately via [_selectDate]; hydrate is latest-wins.
  Future<void> _pickHeaderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.actionChooseDate,
      cancelText: context.l10n.actionCancel,
      confirmText: context.l10n.actionValidate,
    );
    if (picked == null || !mounted) return;
    await _selectDate(picked);
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

    final pickedStart = DateUtils.dateOnly(pickedRange.start);
    _rangeStart = newRangeStart;
    _rangeEnd = newRangeEnd;
    _selectedDate = pickedStart;
    _preferredDayOfMonth = pickedStart.day;
    _selectedWeekStart = _startOfWeek(pickedRange.start);
    _displayedMonth = DateTime(pickedStart.year, pickedStart.month, 1);
    _derivedCacheKey = null;
    _bumpAgendaPaint();

    _jumpMonthPagerToDisplayedMonth();

    await _subscribeItems(scrollToSelection: true);
  }

  Future<void> _extendBefore() async {
    _rangeStart = _rangeStart.subtract(const Duration(days: 28));
    _derivedCacheKey = null;
    _bumpAgendaPaint();

    await _subscribeItems(scrollToSelection: false);
  }

  Future<void> _extendAfter() async {
    _rangeEnd = _endOfWeek(_rangeEnd.add(const Duration(days: 28)));
    _derivedCacheKey = null;
    _bumpAgendaPaint();

    await _subscribeItems(scrollToSelection: false);
  }

  Future<void> _scrollToSelectedWeek({
    bool animated = true,
    LatestWinsToken? navigationToken,
  }) async {
    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;
    if (navigationToken != null && !navigationToken.isCurrent) return;

    // With ListView.builder, off-screen weeks may not be mounted yet — jump
    // near the target index first so the GlobalKey can attach.
    _ensureDerivedCaches();
    final int weekIndex = _cachedWeeks.indexWhere(
      (DateTime w) =>
          w.millisecondsSinceEpoch ==
          _selectedWeekStart.millisecondsSinceEpoch,
    );
    if (weekIndex >= 0 && _scrollController.hasClients) {
      final ScrollPosition position = _scrollController.position;
      if (position.hasContentDimensions && _cachedWeeks.isNotEmpty) {
        final double extent = position.maxScrollExtent;
        final double estimate =
            (weekIndex / _cachedWeeks.length) * extent;
        if ((position.pixels - estimate).abs() > 120) {
          _scrollController.jumpTo(estimate.clamp(0.0, extent));
          await Future<void>.delayed(Duration.zero);
          if (!mounted) return;
          if (navigationToken != null && !navigationToken.isCurrent) return;
        }
      }
    }

    final key = _weekKeys[_selectedWeekStart.millisecondsSinceEpoch];
    final targetContext = key?.currentContext;

    if (targetContext == null) return;
    if (navigationToken != null && !navigationToken.isCurrent) return;

    // Programmatic scroll must not let the scroll listener re-drive selection
    // (that was snapping month view back to "today").
    _suppressScrollSelectionSync = true;
    try {
      await Scrollable.ensureVisible(
        targetContext,
        duration: animated ? const Duration(milliseconds: 280) : Duration.zero,
        curve: Curves.easeOut,
        alignment: 0.02,
      );
    } finally {
      // A newer navigation owns suppress; don't clear it out from under them.
      if (navigationToken != null && !navigationToken.isCurrent) {
        return;
      }
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigationToken != null && !navigationToken.isCurrent) return;
          _suppressScrollSelectionSync = false;
        });
      } else {
        _suppressScrollSelectionSync = false;
      }
    }
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
                    items: _filteredItems,
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

  Future<void> _openCoachPlayersDialog() async {
    final selection = await showAgendaCoachPlayersDialog(
      context,
      initialTeamId: _coachViewTeamId,
      initiallySelectedMemberIds: _coachViewPlayersByMemberId.keys.toSet(),
    );
    if (!mounted || selection == null) return;

    setState(() {
      _coachViewTeamId = selection.teamId.trim().isEmpty
          ? _coachViewTeamId
          : selection.teamId.trim();
      _coachViewPlayersByMemberId =
          Map<String, Player>.from(selection.playersByMemberId);
    });
    await _subscribeItems(scrollToSelection: false);
  }

  Widget _buildActiveFilterBanner(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Material(
      color: colors.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => unawaited(_openAgendaFilter()),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.agendaFilterActiveBanner,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      l10n.agendaFilterActiveBannerDetail,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => unawaited(_clearAgendaFilter()),
                child: Text(l10n.agendaFilterClear),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = MediaQuery.of(context).size.width < 700;

    final l10n = context.l10n;
    final bool hideAppBar = AppShellScope.hidesChildAppBar(context);
    final bool filterActive = _filter.isActive;

    final Widget scaffold = Scaffold(
      backgroundColor: colors.background,
      appBar: hideAppBar
          ? null
          : AppBar(
              title: Text(l10n.navAgenda),
              actions: [
                if (context.watch<AppSession>().hasManagedTeamsInSelectedSeason)
                  const CoachWorkloadAnalysisEntryButton(compact: true),
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
              if (hideAppBar) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (context
                          .watch<AppSession>()
                          .hasManagedTeamsInSelectedSeason)
                        const CoachWorkloadAnalysisEntryButton(compact: true),
                      IconButton(
                        tooltip: l10n.navOverview,
                        onPressed: _showOverviewPanel,
                        icon: const Icon(Icons.insert_chart_outlined_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Selective rebuild: calendar + list listen to paint ticks so
              // scroll sync / hydration do not rebuild Scaffold chrome.
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _agendaPaintTick,
                  builder: (context, _, __) {
                    _ensureDerivedCaches();
                    final headerEventTypesByDay = _cachedEventTypesByDay;
                    final weeks = _cachedWeeks;
                    final groupedByWeek = _cachedGroupedByWeek;

                    return Column(
                      children: [
                        RepaintBoundary(
                          child: _GrintaStyleCalendarHeader(
                            pageController: _monthPageController,
                            initialPage: _initialMonthPage,
                            pagerRemountToken: _monthPagerRemountToken,
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
                              await _selectDate(_chevronFocusedDate(-1));
                            },
                            onNextDay: () async {
                              await _selectDate(_chevronFocusedDate(1));
                            },
                            onTodayTap: () {
                              unawaited(_jumpToToday());
                            },
                            onHeaderDateTap: () {
                              unawaited(_pickHeaderDate());
                            },
                            onPageChanged: _onMonthPageChanged,
                            onDateTap: (date) {
                              unawaited(_selectDate(date));
                            },
                          ),
                        ),
                        if (filterActive) ...[
                          const SizedBox(height: 8),
                          _buildActiveFilterBanner(context),
                        ],
                        SizedBox(
                          height: 12,
                          child: _isRefreshing
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      minHeight: 2.5,
                                      backgroundColor: colors.border
                                          .withValues(alpha: 0.35),
                                      color: colors.primary,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: GestureDetector(
                            // Swipe on the events list too (not only the calendar header).
                            onHorizontalDragEnd: (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity < -180) {
                                _handleHorizontalPeriodSwipe(goNext: true);
                              } else if (velocity > 180) {
                                _handleHorizontalPeriodSwipe(goNext: false);
                              }
                            },
                            child: RepaintBoundary(
                              child: Container(
                                key: _weeksViewportKey,
                                child: _buildAgendaContent(
                                  weeks: weeks,
                                  groupedByWeek: groupedByWeek,
                                  compact: compact,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AskDiegoSpeedDial(
        heroTagPrefix: 'agenda',
        showClosedBadge: filterActive,
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
        secondaryActions: [
          AskDiegoPrimaryAction(
            heroTag: 'grinta-fab-agenda-filter',
            icon: Icons.filter_alt_rounded,
            tooltip: context.l10n.agendaFilterFabTooltip,
            showBadge: filterActive,
            onPressed: () {
              unawaited(_openAgendaFilter());
            },
          ),
          if (context.watch<AppSession>().hasManagedTeamsInSelectedSeason)
            AskDiegoPrimaryAction(
              heroTag: 'grinta-fab-agenda-coach-players',
              icon: Icons.groups_outlined,
              tooltip: context.l10n.agendaCoachPlayersFabTooltip,
              onPressed: () {
                unawaited(_openCoachPlayersDialog());
              },
            ),
        ],
      ),
    );

    Widget wrapped = _AgendaCoachPlayersScope(
      playersByMemberId: _coachViewPlayersByMemberId,
      child: scaffold,
    );

    final ValueChanged<String>? onTrackerWorkloadUpdated =
        widget.onTrackerWorkloadUpdated;
    if (onTrackerWorkloadUpdated == null) {
      return wrapped;
    }

    return _AgendaWorkloadRefreshScope(
      onTrackerWorkloadUpdated: onTrackerWorkloadUpdated,
      child: wrapped,
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
          final nextSelectedDate = _dateInWeekWithSameWeekday(weekStart);
          final LatestWinsToken token = _hydrationGate.begin();
          _selectedWeekStart = weekStart;
          _selectedDate = nextSelectedDate;
          _preferredDayOfMonth = nextSelectedDate.day;
          _displayedMonth =
              DateTime(nextSelectedDate.year, nextSelectedDate.month, 1);
          _bumpAgendaPaint();

          _jumpMonthPagerToDisplayedMonth();
          await _scrollToSelectedWeek(navigationToken: token);
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

    final dayItems = _filteredItems
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
                    ? _AllDayNonSportRow(key: ValueKey(item.id), item: item)
                    : AgendaItemCard(key: ValueKey(item.id), item: item),
              ),
            ),
        ],
      ),
    );
  }
}

