import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/feature_discovery_ids.dart';
import 'package:grinta/feature_discovery/match_detail_tab_navigation_scope.dart';
import 'package:grinta/services/feature_discovery_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';
import 'package:grinta/widget/feature_discovery_random_banner.dart';

import '../model/highlights.dart';
import '../model/matchStats.dart';
import '../model/player.dart';
import '../model/tracker/team_workload_summary.dart';
import '../services/highlightsService.dart';
import '../services/matchStatsService.dart';
import '../services/matchService.dart';
import '../services/playerService.dart';
import '../services/teamWorkloadSummaryService.dart';
import 'package:grinta/util/app_theme.dart';
import '../util/highlight_minute_helper.dart';
import '../util/intense_live_eligibility.dart';
import '../util/match_creation_helper.dart';
import 'package:grinta/widget/create_match_sheet.dart';
import 'package:provider/provider.dart';

import '../provider/appSession.dart';
import '../model/match.dart' as models;
import '../util/playerDisplayName.dart';
import '../widget/match_compo_widget.dart';
import '../widget/match_highlights_timeline.dart';
import '../widget/match_opponent_stats_button.dart';
import '../util/session_tracker_kit.dart';
import '../widget/session_player_analysis_view.dart';
import '../widget/session_tracker_stats_view.dart';
import '../widget/tracker_kit_icon_pill.dart';
import 'intense_live/intense_live_session_screen.dart';
import 'match_detail/match_convocations_tab.dart';
import 'match_detail/match_grinta_highlights_tab.dart';
import 'match_detail/match_tactical_schema_tab.dart';

class MatchDetailScreen extends StatelessWidget {
  final models.Match match;

  /// Permet de remplacer le contenu de l’onglet Compo.
  final Widget Function(BuildContext context, models.Match match)? compoBuilder;

  /// Permet de remplacer le contenu de l’onglet Schéma tactique.
  final Widget Function(BuildContext context, models.Match match)? tacticalSchemaBuilder;

  /// Permet de remplacer le contenu de l’onglet Temps forts.
  final Widget Function(BuildContext context, models.Match match)? highlightsBuilder;

  /// Permet de remplacer le contenu de l’onglet Statistiques.
  final Widget Function(BuildContext context, models.Match match)? statsBuilder;

  final bool isManager;
  final String? playerId;

  /// Index logique de l’onglet à l’ouverture (0 = Compo si affiché, sinon Convocations).
  final int initialTabIndex;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.compoBuilder,
    this.tacticalSchemaBuilder,
    this.highlightsBuilder,
    this.statsBuilder,
    required this.isManager,
    required this.playerId,
    this.initialTabIndex = 0,
  });

  static List<String> _tabNamesForMatch(
    models.Match match, {
    required bool showCompo,
    bool showLiveTab = false,
  }) {
    final names = <String>[];
    if (showCompo) {
      names.add(AnalyticsScreenNames.matchDetailTabCompo);
    }
    names.add(AnalyticsScreenNames.matchDetailTabConvocations);
    names.addAll([
      AnalyticsScreenNames.matchDetailTabTacticalSchema,
      AnalyticsScreenNames.matchDetailTabHighlights,
    ]);
    if (showLiveTab) {
      names.add(AnalyticsScreenNames.matchDetailTabLive);
    }
    if (match.withTracker == true) {
      names.add(AnalyticsScreenNames.matchDetailTabStats);
    }
    return names;
  }

  static List<String> _featureDiscoveryIdsForMatch(
    models.Match match, {
    required bool showCompo,
    bool showLiveTab = false,
  }) {
    final ids = <String>[];
    if (showCompo) {
      ids.add(FeatureDiscoveryIds.matchDetailTabCompo);
    }
    ids.add(FeatureDiscoveryIds.matchDetailTabConvocations);
    ids.addAll([
      FeatureDiscoveryIds.matchDetailTabTacticalSchema,
      FeatureDiscoveryIds.matchDetailTabHighlights,
    ]);
    if (showLiveTab) {
      ids.add(FeatureDiscoveryIds.matchDetailTabLive);
    }
    if (match.withTracker == true) {
      ids.add(FeatureDiscoveryIds.matchDetailTabStats);
    }
    return ids;
  }

  /// Index logique de l’onglet Statistiques (4 si Compo affiché, 3 sinon).
  static int statsTabIndexFor(models.Match match, {bool showCompo = true}) {
    if (match.withTracker != true) {
      return showCompo ? 0 : 0;
    }
    return showCompo ? 4 : 3;
  }

  /// Index logique de l’onglet Convocations (1 si Compo affiché, 0 sinon).
  static int convocationsTabIndexFor({required bool showCompo}) {
    return showCompo ? 1 : 0;
  }

  static int _physicalTabIndex({
    required int logicalIndex,
    required bool showCompo,
  }) {
    if (showCompo) {
      return logicalIndex;
    }
    if (logicalIndex <= 0) {
      return 0;
    }
    return logicalIndex - 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool showStats = match.withTracker == true;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(match: match),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWebLarge = constraints.maxWidth >= 900;
                  final bool isTablet =
                      constraints.maxWidth >= 600 &&
                      constraints.maxWidth < 900;

                  final double horizontalPadding = isWebLarge
                      ? 8
                      : isTablet
                      ? 10
                      : 0;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: Column(
                      children: [
                        _MatchHeader(match: match, isManager: isManager),
                        Expanded(
                          child: StreamBuilder<MatchStats?>(
                            stream: MatchStatsService()
                                .streamMatchStatsByMatchId(match.id ?? ''),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final bool showCompo = snapshot.data != null;
                              final l10n = context.l10n;

                              return FutureBuilder<bool>(
                                future: isIntenseTrackerOwner(match.ownerId),
                                builder: (context, intenseSnapshot) {
                                  final isIntenseOwner =
                                      intenseSnapshot.data == true;

                                  return StreamBuilder<List<Highlights>>(
                                    stream: HighlightsService()
                                        .streamHighlightsByMatchCalendarId(
                                      match.id ?? '',
                                    ),
                                    builder: (context, highlightsSnapshot) {
                                      final highlights =
                                          highlightsSnapshot.data ??
                                              const <Highlights>[];
                                      final showLiveTab = isIntenseOwner &&
                                          isMatchSessionLive(
                                            match: match,
                                            highlights: highlights,
                                          );
                                      final liveSessionStart =
                                          intenseLiveMatchStartUtc(highlights);

                                      final tabs = <Widget>[
                                        if (showCompo)
                                          _MatchDetailTab(
                                            icon: Icons.groups_rounded,
                                            label: l10n.tabCompo,
                                            compactLabel: l10n.tabCompo,
                                          ),
                                        _MatchDetailTab(
                                          icon: Icons.event_available_rounded,
                                          label: l10n.tabConvocations,
                                          compactLabel:
                                              l10n.tabConvocationsShort,
                                        ),
                                        _MatchDetailTab(
                                          icon: Icons.grid_view_rounded,
                                          label: l10n.tabTacticalSchema,
                                          compactLabel:
                                              l10n.tabTacticalSchemaShort,
                                        ),
                                        _MatchDetailTab(
                                          icon: Icons.flash_on_rounded,
                                          label: l10n.tabHighlights,
                                          compactLabel: l10n.tabHighlightsShort,
                                        ),
                                        if (showLiveTab)
                                          _MatchDetailTab(
                                            icon: Icons.sensors_rounded,
                                            label: l10n.tabLive,
                                            compactLabel: l10n.tabLiveShort,
                                          ),
                                        if (showStats)
                                          _MatchDetailTab(
                                            icon: Icons.query_stats_rounded,
                                            label: l10n.navStatistics,
                                            compactLabel: l10n.tabStats,
                                          ),
                                      ];

                                      final views = <Widget>[
                                        if (showCompo)
                                          compoBuilder?.call(context, match) ??
                                              _CompoTab(match: match),
                                        MatchConvocationsTab(
                                          match: match,
                                          isManager: isManager,
                                        ),
                                        tacticalSchemaBuilder?.call(
                                              context, match) ??
                                            MatchTacticalSchemaTab(
                                              match: match,
                                              isManager: isManager,
                                            ),
                                        highlightsBuilder?.call(
                                              context, match) ??
                                            _HighlightsTab(
                                              match: match,
                                              isManager: isManager,
                                            ),
                                        if (showLiveTab &&
                                            liveSessionStart != null)
                                          _LiveTab(
                                            match: match,
                                            sessionStartUtc: liveSessionStart,
                                          ),
                                        if (showStats)
                                          statsBuilder?.call(context, match) ??
                                              _StatsTab(
                                                match: match,
                                                isManager: isManager,
                                                playerId: playerId,
                                              ),
                                      ];

                                      final int safeInitialIndex =
                                          _physicalTabIndex(
                                        logicalIndex: initialTabIndex,
                                        showCompo: showCompo,
                                      ).clamp(0, tabs.length - 1);

                                      return _MatchDetailTabShell(
                                        tabs: tabs,
                                        views: views,
                                        tabNames: _tabNamesForMatch(
                                          match,
                                          showCompo: showCompo,
                                          showLiveTab: showLiveTab,
                                        ),
                                        featureDiscoveryIds:
                                            _featureDiscoveryIdsForMatch(
                                          match,
                                          showCompo: showCompo,
                                          showLiveTab: showLiveTab,
                                        ),
                                        initialIndex: safeInitialIndex,
                                        matchHasTracker: showStats,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final models.Match match;

  const _TopBar({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final session = context.watch<AppSession>();
    final bool canManageThisMatch = canManageMatch(match, session);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.matchDetailTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (canManageThisMatch) ...[
            IconButton(
              tooltip: context.l10n.editMatchTitle,
              onPressed: () {
                showCreateMatchSheet(
                  context,
                  matchToEdit: match,
                );
              },
              icon: Icon(
                Icons.edit_outlined,
                color: colors.textPrimary,
              ),
            ),
            IconButton(
              tooltip: context.l10n.actionDelete,
              onPressed: () async {
                await deleteManagedMatch(
                  context,
                  match: match,
                  session: session,
                  onDeleted: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colors.danger,
              ),
            ),
          ],
          IconButton(
            tooltip: context.l10n.actionClose,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Match-detail tab bar + content with analytics and feature-discovery on change.
class _MatchDetailTabShell extends StatefulWidget {
  final List<Widget> tabs;
  final List<Widget> views;
  final List<String> tabNames;
  final List<String> featureDiscoveryIds;
  final int initialIndex;
  final bool matchHasTracker;

  const _MatchDetailTabShell({
    required this.tabs,
    required this.views,
    required this.tabNames,
    required this.featureDiscoveryIds,
    required this.initialIndex,
    required this.matchHasTracker,
  });

  @override
  State<_MatchDetailTabShell> createState() => _MatchDetailTabShellState();
}

class _MatchDetailTabShellState extends State<_MatchDetailTabShell>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _lastLoggedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(_onTabControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordTabVisit(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabControllerChanged() {
    if (_tabController.indexIsChanging) return;
    _recordTabVisit(_tabController.index);
  }

  void _onTabTapped(int index) {
    _recordTabVisit(index);
  }

  void _recordTabVisit(int index) {
    if (index == _lastLoggedIndex) return;
    if (index < 0 || index >= widget.tabNames.length) return;
    _lastLoggedIndex = index;

    AnalyticsInteractions.logTabSelect(
      screen: AnalyticsScreenNames.matchDetail,
      tab: widget.tabNames[index],
    );

    if (index < widget.featureDiscoveryIds.length) {
      FeatureDiscoveryService.instance
          .markFeatureVisited(widget.featureDiscoveryIds[index]);
    }
  }

  void _goToTabIndex(int index) {
    if (index < 0 || index >= widget.tabs.length) return;
    _tabController.animateTo(index);
    _recordTabVisit(index);
  }

  @override
  Widget build(BuildContext context) {
    return MatchDetailTabNavigationScope(
      featureIdsByTabIndex: widget.featureDiscoveryIds,
      onNavigateToTabIndex: _goToTabIndex,
      child: Column(
        children: [
          FeatureDiscoveryRandomBanner(
            parentScreenId: FeatureDiscoveryIds.screenMatchDetail,
            includeBaseScreens: false,
            matchHasTracker: widget.matchHasTracker,
          ),
          const SizedBox(height: 6),
          _TabsContainer(
            tabs: widget.tabs,
            controller: _tabController,
            onTap: _onTabTapped,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.views,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsContainer extends StatelessWidget {
  final List<Widget> tabs;
  final TabController controller;
  final ValueChanged<int> onTap;

  const _TabsContainer({
    required this.tabs,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: TabBar(
        controller: controller,
        onTap: onTap,
        tabs: tabs,
        isScrollable: false,
        tabAlignment: TabAlignment.fill,
        labelPadding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        indicator: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _MatchDetailTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final String compactLabel;

  const _MatchDetailTab({
    required this.icon,
    required this.label,
    required this.compactLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.sizeOf(context).width < 600;

    if (isPhone) {
      return Tab(
        height: 40,
        iconMargin: EdgeInsets.zero,
        icon: Tooltip(
          message: label,
          child: Icon(icon, size: 22),
        ),
      );
    }

    final bool useShortLabel = MediaQuery.sizeOf(context).width < 900;

    return Tab(
      height: 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              useShortLabel ? compactLabel : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchHeader extends StatefulWidget {
  final models.Match match;
  final bool isManager;

  const _MatchHeader({
    required this.match,
    required this.isManager,
  });

  @override
  State<_MatchHeader> createState() => _MatchHeaderState();
}

class _MatchHeaderState extends State<_MatchHeader> {
  late models.Match _match;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
  }

  @override
  void didUpdateWidget(covariant _MatchHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) {
      _match = widget.match;
    }
  }

  models.Match get match => _match;
  bool get isManager => widget.isManager;

  static bool _hasVenueInfo(models.Match match) {
    return _clean(match.nomDuTerrain).isNotEmpty ||
        _clean(match.terrainAdresse1).isNotEmpty ||
        _clean(match.terrainAddress2).isNotEmpty ||
        _clean(match.surfaceDeJeu).isNotEmpty;
  }

  static String _venueSummary(models.Match match) {
    final terrain = _clean(match.nomDuTerrain);
    final address = [
      _clean(match.terrainAdresse1),
      _clean(match.terrainAddress2),
    ].where((part) => part.isNotEmpty).join(' — ');

    if (terrain.isNotEmpty && address.isNotEmpty) {
      return '$terrain · $address';
    }
    if (terrain.isNotEmpty) return terrain;
    if (address.isNotEmpty) return address;
    return _clean(match.surfaceDeJeu);
  }

  static void _showVenueSheet(
    BuildContext context,
    models.Match match,
  ) {
    final colors = context.appColors;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.background,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _MatchVenueSheet(
        match: match,
        onOpenFieldGps: () async {
          Navigator.of(sheetContext).pop();
          if (!context.mounted) return;
          try {
            await FieldGpsLocalizationHelper.localizeAndSaveMatchField(
              context,
              match: match,
            );
          } catch (e, st) {
            debugPrint('match venue field GPS open failed: $e\n$st');
            if (context.mounted) {
              AppSnackbar.show(
                context,
                context.l10n.adminTrackerFieldsSaveFailed,
              );
            }
          }
        },
      ),
    );
  }

  static bool _hasFieldGps(models.Match match) {
    return FieldGpsLocalizationHelper.completeCornersOrNull(
          match.fieldGpsCorners,
        ) !=
        null;
  }

  @override
  Widget build(BuildContext context) {
    final String matchId = widget.match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return _buildHeader(context, widget.match);
    }

    return StreamBuilder<models.Match?>(
      stream: MatchService().streamMatchById(matchId),
      builder: (context, snapshot) {
        final models.Match liveMatch = snapshot.data ?? _match;
        if (snapshot.hasData && snapshot.data != null) {
          _match = snapshot.data!;
        }
        return _buildHeader(context, liveMatch);
      },
    );
  }

  Widget _buildHeader(BuildContext context, models.Match match) {
    final colors = context.appColors;

    final l10n = context.l10n;
    final String team1 = _clean(match.team1, fallback: l10n.entityTeamWithIndex(1));
    final String team2 = _clean(match.team2, fallback: l10n.entityTeamWithIndex(2));

    final bool played = match.isMatchPlayed == true;
    final bool liveScore = match.isInHighLight == true ||
        (match.homeScore ?? 0) > 0 ||
        (match.outSideScore ?? 0) > 0;
    final bool showScore = played || liveScore;
    final bool isReport = match.isReport == true;
    final bool hasVenue = _hasVenueInfo(match);

    final String score = showScore
        ? '${match.homeScore ?? 0} - ${match.outSideScore ?? 0}'
        : '-';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              if (_clean(match.chType).isNotEmpty)
                _InfoPill(
                  icon: Icons.emoji_events_outlined,
                  label: match.chType!,
                ),
              if ((match.day ?? 0) > 0)
                _InfoPill(
                  icon: Icons.calendar_view_day_rounded,
                  label: l10n.periodMatchDay(match.day.toString()),
                ),
              if (_clean(match.tour).isNotEmpty)
                _InfoPill(
                  icon: Icons.flag_outlined,
                  label: match.tour!,
                ),
              if (isReport)
                _InfoPill(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.periodPostponed,
                  color: colors.warning,
                ),
              MatchTrackerKitPillHost(
                match: match,
                isManager: isManager,
              ),
            ],
          ),
          const SizedBox(height: 6),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 360;

              if (compact) {
                return Column(
                  children: [
                    _TeamBlock(
                      name: team1,
                      logoUrl: match.team1UrlLogo,
                      affiliation: match.affiliationTeam1,
                      compact: true,
                    ),
                    const SizedBox(height: 6),
                    _ScoreBlock(
                      score: score,
                      tab: match.tab,
                      played: showScore,
                    ),
                    const SizedBox(height: 6),
                    _TeamBlock(
                      name: team2,
                      logoUrl: match.team2UrlLogo,
                      affiliation: match.affiliationTeam2,
                      compact: true,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamBlock(
                      name: team1,
                      logoUrl: match.team1UrlLogo,
                      affiliation: match.affiliationTeam1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _ScoreBlock(
                      score: score,
                      tab: match.tab,
                      played: showScore,
                    ),
                  ),
                  Expanded(
                    child: _TeamBlock(
                      name: team2,
                      logoUrl: match.team2UrlLogo,
                      affiliation: match.affiliationTeam2,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 15,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _dateTimeLabel(context, match),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasVenue) ...[
            const SizedBox(height: 6),
            Material(
              color: colors.surface,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: colors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _showVenueSheet(context, match),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.place_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _venueSummary(match),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (_hasFieldGps(match)) ...[
                        Icon(
                          Icons.gps_fixed,
                          size: 18,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          MatchOpponentStatsButton(
            match: match,
            isManager: isManager,
          ),
        ],
      ),
    );
  }

  static String _dateTimeLabel(BuildContext context, models.Match match) {
    final l10n = context.l10n;
    final date = _clean(match.dateCh);
    final time = _clean(match.timeCh);

    if (date.isEmpty && time.isEmpty) return l10n.dateUndefined;
    if (date.isNotEmpty && time.isNotEmpty) {
      return l10n.matchDateTimeAt(date, time);
    }
    if (date.isNotEmpty) return date;
    return time;
  }

}

/// Bottom sheet for match venue details + field GPS outline access.
class _MatchVenueSheet extends StatefulWidget {
  const _MatchVenueSheet({
    required this.match,
    required this.onOpenFieldGps,
  });

  final models.Match match;
  final Future<void> Function() onOpenFieldGps;

  @override
  State<_MatchVenueSheet> createState() => _MatchVenueSheetState();
}

class _MatchVenueSheetState extends State<_MatchVenueSheet> {
  bool _loadingGps = true;
  bool _hasGps = false;
  bool _openingMap = false;

  @override
  void initState() {
    super.initState();
    _resolveGps();
  }

  Future<void> _resolveGps() async {
    final fromMatch = FieldGpsLocalizationHelper.completeCornersOrNull(
      widget.match.fieldGpsCorners,
    );
    if (fromMatch != null) {
      if (!mounted) return;
      setState(() {
        _hasGps = true;
        _loadingGps = false;
      });
      return;
    }

    final stored = await FieldGpsLocalizationHelper.loadStoredFieldGpsCorners(
      widget.match,
    );
    if (!mounted) return;
    if (stored != null) {
      widget.match.fieldGpsCorners = stored;
    }
    setState(() {
      _hasGps = stored != null;
      _loadingGps = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final match = widget.match;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.matchDetailVenueTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_clean(match.nomDuTerrain).isNotEmpty)
                    _HeaderInfoLine(
                      icon: Icons.stadium_rounded,
                      value: match.nomDuTerrain!,
                      valueColor: colors.textPrimary,
                    ),
                  if (_clean(match.terrainAdresse1).isNotEmpty ||
                      _clean(match.terrainAddress2).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _HeaderInfoLine(
                      icon: Icons.place_outlined,
                      value: [
                        _clean(match.terrainAdresse1),
                        _clean(match.terrainAddress2),
                      ].where((s) => s.isNotEmpty).join(' — '),
                      valueColor: colors.textPrimary,
                    ),
                  ],
                  if (_clean(match.surfaceDeJeu).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _HeaderInfoLine(
                      icon: Icons.grass_rounded,
                      value: match.surfaceDeJeu!,
                      valueColor: colors.textPrimary,
                    ),
                  ],
                  if (!_MatchHeaderState._hasVenueInfo(match))
                    Text(
                      l10n.entityFieldUndefined,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingGps)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              FilledButton.icon(
                onPressed: _openingMap
                    ? null
                    : () async {
                        setState(() => _openingMap = true);
                        await widget.onOpenFieldGps();
                      },
                icon: Icon(
                  _hasGps ? Icons.gps_fixed : Icons.gps_not_fixed,
                ),
                label: Text(
                  _hasGps
                      ? l10n.matchVenueFieldGpsView
                      : l10n.matchVenueFieldGpsSet,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      colors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final String? affiliation;
  final bool compact;

  const _TeamBlock({
    required this.name,
    required this.logoUrl,
    required this.affiliation,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: [
        _TeamLogo(
          logoUrl: logoUrl,
          size: compact ? 40 : 48,
          imageSize: compact ? 26 : 32,
        ),
        const SizedBox(height: 4),
        Text(
          name,
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        if (_clean(affiliation).isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            affiliation!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final double imageSize;

  const _TeamLogo({
    required this.logoUrl,
    this.size = 64,
    this.imageSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safeUrl = (logoUrl ?? '').trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Container(
          width: imageSize,
          height: imageSize,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: safeUrl.isEmpty
              ? Icon(
            Icons.shield_outlined,
            size: imageSize * 0.55,
            color: colors.textSecondary,
          )
              : Image.network(
            safeUrl,
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('LOGO ERROR url=$safeUrl');
              debugPrint('error=$error');

              return Icon(
                Icons.broken_image_outlined,
                size: imageSize * 0.55,
                color: colors.textSecondary,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  final String score;
  final String? tab;
  final bool played;

  const _ScoreBlock({
    required this.score,
    required this.tab,
    required this.played,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: played ? 26 : 22,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        if (_clean(tab).isNotEmpty)
          Text(
            'TAB $tab',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
      ],
    );
  }
}

class _HeaderInfoLine extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? valueColor;

  const _HeaderInfoLine({
    required this.icon,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final pillColor = color ?? colors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pillColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: pillColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: pillColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: pillColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompoTab extends StatelessWidget {
  final models.Match match;

  const _CompoTab({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    return _TabContainer(
      children: [
        StreamBuilder<MatchStats?>(
          stream: MatchStatsService().streamMatchStatsByMatchId(match.id ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.errorCompositionTitle,
                message: snapshot.error.toString(),
              );
            }

            final matchStats = snapshot.data;

            return MatchCompoWidget(
              matchStats: matchStats,
              team1: match.team1,
              team2: match.team2,
            );
          },
        ),
      ],
    );
  }
}

enum _HighlightsSource { fmi, grinta }

class _HighlightsTab extends StatefulWidget {
  final models.Match match;
  final bool isManager;

  const _HighlightsTab({
    required this.match,
    required this.isManager,
  });

  @override
  State<_HighlightsTab> createState() => _HighlightsTabState();
}

class _HighlightsTabState extends State<_HighlightsTab> {
  _HighlightsSource? _source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return StreamBuilder<MatchStats?>(
      stream: MatchStatsService()
          .streamMatchStatsByMatchId(widget.match.id ?? ''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _source == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final matchStats = snapshot.data;
        final source = _source ??
            (matchStats != null
                ? _HighlightsSource.fmi
                : _HighlightsSource.grinta);

        final width = MediaQuery.of(context).size.width;
        final double horizontalPadding = width >= 900
            ? 8
            : width >= 600
                ? 10
                : 12;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_HighlightsSource>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _HighlightsSource.fmi,
                    label: Text(l10n.matchHighlightsSourceFmi),
                  ),
                  ButtonSegment(
                    value: _HighlightsSource.grinta,
                    label: Text(l10n.matchHighlightsSourceGrinta),
                  ),
                ],
                selected: {source},
                onSelectionChanged: (selection) {
                  setState(() => _source = selection.first);
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: source == _HighlightsSource.fmi
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: MatchHighlightsTimeline(
                          matchStats: matchStats,
                          team1: widget.match.team1,
                          team2: widget.match.team2,
                        ),
                      )
                    : MatchGrintaHighlightsTab(
                        match: widget.match,
                        isManager: widget.isManager,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveTab extends StatelessWidget {
  const _LiveTab({
    required this.match,
    required this.sessionStartUtc,
  });

  final models.Match match;
  final DateTime sessionStartUtc;

  @override
  Widget build(BuildContext context) {
    return IntenseLiveSessionPanel(
      match: match,
      sessionStartUtc: sessionStartUtc,
    );
  }
}

class _StatsTab extends StatefulWidget {
  final models.Match match;
  final bool isManager;
  final String? playerId;

  const _StatsTab({
    required this.match,
    required this.isManager,
    required this.playerId,
  });

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  late Future<Player?> _playerFuture;

  @override
  void initState() {
    super.initState();
    _playerFuture = _loadPlayer();
  }

  @override
  void didUpdateWidget(covariant _StatsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playerId != widget.playerId) {
      _playerFuture = _loadPlayer();
    }
  }

  Future<Player?> _loadPlayer() async {
    final safePlayerId = (widget.playerId ?? '').trim();

    if (safePlayerId.isEmpty) {
      return null;
    }

    return PlayerService().getPlayerById(safePlayerId);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'dans _StatsTab isManager=${widget.isManager} playerId=${widget.playerId}',
    );

    final String eventId = (widget.match.id ?? '').trim();

    if (eventId.isEmpty) {
      return _TabContainer(
        children: [
          _EmptyState(
            icon: Icons.query_stats_rounded,
            title: context.l10n.matchStatsUnavailableTitle,
            message: context.l10n.errorMatchIdMissing,
          ),
        ],
      );
    }

    if (widget.isManager) {
      return _TabContainer(
        children: [
          SessionTrackerStatsView(
            eventId: eventId,
            ownerId: widget.match.ownerId,
            teamId: widget.match.teamID,
            realtime: true,
            isMatch: true,
            reportTitle: _matchReportTitle(widget.match),
            reportSubtitle: widget.match.chType,
            reportTeamName: widget.match.team1 ?? widget.match.team2,
            reportEventDate: matchKickoffDateTime(widget.match),
            reportMatch: widget.match,
            showEmailReport: true,
          ),
        ],
      );
    }

    final String safePlayerId = (widget.playerId ?? '').trim();

    if (safePlayerId.isEmpty) {
      return _TabContainer(
        children: [
          _EmptyState(
            icon: Icons.person_off_rounded,
            title: context.l10n.errorPlayerNotIdentified,
            message: context.l10n.errorNoStatsForPlayer,
          ),
        ],
      );
    }

    return _TabContainer(
      children: [
        FutureBuilder<Player?>(
          future: _playerFuture,
          builder: (context, playerSnapshot) {
            if (playerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (playerSnapshot.hasError) {
              return _EmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.errorPlayerTitle,
                message: playerSnapshot.error.toString(),
              );
            }

            final Player? player = playerSnapshot.data;

            if (player == null) {
              return _EmptyState(
                icon: Icons.person_off_rounded,
                title: context.l10n.errorPlayerNotFound,
                message: context.l10n.errorPlayerNotFoundMessage,
              );
            }

            return FutureBuilder<bool>(
              future: eventUsesPolarTeamKit(
                eventId: eventId,
                ownerId: widget.match.ownerId,
              ),
              builder: (context, kitSnapshot) {
                if (kitSnapshot.connectionState == ConnectionState.waiting &&
                    !kitSnapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final isPolar = kitSnapshot.data == true;
                if (isPolar) {
                  return SessionPlayerAnalysisView(
                    eventId: eventId,
                    ownerId: widget.match.ownerId,
                    playerId: safePlayerId,
                    teamId: widget.match.teamID,
                    playerName: playerDisplayName(
                      player,
                      unknownLabel: context.l10n.entityPlayer,
                    ),
                    player: player,
                    isMatch: true,
                  );
                }

                return StreamBuilder<TeamWorkloadSummary?>(
                  stream: TeamWorkloadSummaryService().watchByEventId(eventId),
                  builder: (context, summarySnapshot) {
                    if (summarySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (summarySnapshot.hasError) {
                      return _EmptyState(
                        icon: Icons.error_outline_rounded,
                        title: context.l10n.errorTrackerTitle,
                        message: summarySnapshot.error.toString(),
                      );
                    }

                    final TeamWorkloadSummary? summary = summarySnapshot.data;

                    if (summary == null) {
                      return _EmptyState(
                        icon: Icons.query_stats_rounded,
                        title: context.l10n.errorNoStats,
                        message: context.l10n.errorNoTrackerData,
                      );
                    }

                    final TeamPlayerMetricScores? playerScore =
                        _findPlayerScore(
                      summary: summary,
                      playerId: safePlayerId,
                    );

                    if (playerScore == null) {
                      return _EmptyState(
                        icon: Icons.person_search_rounded,
                        title: context.l10n.errorPlayerNotFoundInMatch,
                        message: context.l10n.errorPlayerNoTrackerMatch,
                      );
                    }

                    final String trackerId = playerScore.trackerId.trim();

                    if (trackerId.isEmpty) {
                      return _EmptyState(
                        icon: Icons.sensors_off_rounded,
                        title: context.l10n.sensorNotFoundTitle,
                        message: context.l10n.sensorNotFoundMessage,
                      );
                    }

                    final String analysisDocId = '${eventId}_$trackerId';

                    return SessionPlayerAnalysisView(
                      eventId: eventId,
                      ownerId: widget.match.ownerId,
                      analysisDocId: analysisDocId,
                      trackerId: trackerId,
                      playerId: safePlayerId,
                      teamId: widget.match.teamID,
                      playerName: playerDisplayName(
                        player,
                        unknownLabel: context.l10n.entityPlayer,
                      ),
                      player: player,
                      isMatch: true,
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  static String _matchReportTitle(models.Match match) {
    final team1 = (match.team1 ?? '').trim();
    final team2 = (match.team2 ?? '').trim();
    if (team1.isNotEmpty && team2.isNotEmpty) {
      return '$team1 - $team2';
    }
    if (team1.isNotEmpty) return team1;
    if (team2.isNotEmpty) return team2;
    return 'Match';
  }

  TeamPlayerMetricScores? _findPlayerScore({
    required TeamWorkloadSummary summary,
    required String playerId,
  }) {
    for (final score in summary.playerScores) {
      if (score.playerId == playerId) {
        return score;
      }
    }

    return null;
  }
}

class _TrackerStatus extends StatelessWidget {
  final models.Match match;

  const _TrackerStatus({
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool uploaded = match.isTrackerDataUploaded == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: uploaded
            ? colors.success.withValues(alpha: 0.10)
            : colors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: uploaded
              ? colors.success.withValues(alpha: 0.25)
              : colors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            uploaded ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: uploaded ? colors.success : colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              uploaded
                  ? context.l10n.matchTrackerDataAvailable
                  : context.l10n.matchTrackerDataPending,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabContainer extends StatelessWidget {
  final List<Widget> children;

  const _TabContainer({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final double horizontalPadding = width >= 900
        ? 8
        : width >= 600
        ? 10
        : 12;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        24,
      ),
      children: children,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTeamCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniTeamCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String minute;
  final String title;
  final String subtitle;
  final IconData icon;

  const _TimelineItem({
    required this.minute,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            minute,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}