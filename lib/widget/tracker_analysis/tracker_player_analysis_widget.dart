import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/meta_share_coordinator.dart';
import 'package:grinta/services/session_player_synthesis_share_service.dart';
import 'package:grinta/services/share_record_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/share_player_access.dart';
import 'package:grinta/util/share_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:provider/provider.dart';

import '../../model/player.dart';
import '../../model/teamParam.dart';
import '../../model/tracker/trackerData.dart';
import '../../services/teamParamService.dart';
import '../../services/trackerDataAnalysisService.dart';
import '../../services/trackerSvgService.dart';
import '../../util/app_theme.dart';
part 'tracker_analysis_tabs.dart';
part 'tracker_analysis_views.dart';
part 'tracker_analysis_heatmap.dart';

class TrackerPlayerAnalysisWidget extends StatefulWidget {
  /// Option 1 : tu fournis directement l'objet déjà chargé.
  final TrackerAnalysisResult? analysis;

  /// Option 2 : le widget charge le document Firestore.
  /// Exemple : "53514382_07"
  final String? analysisDocId;

  /// Obligatoire pour utiliser les bons paramètres d’équipe.
  /// Si vide ou null, fallback sur TeamParam.defaultTeamId.
  final String? teamId;

  /// Optionnel : nom affiché dans l’en-tête.
  final String? playerName;

  final bool showHeader;
  final bool showDistanceTimeline;

  /// Permet d’afficher ou non l’onglet "Comparaison mi-temps".
  /// Pour un entraînement, passe false.
  final bool isMatch;
  final Player? player;

  /// When set for a match with [SessionShareMatchContext.isStatApplied], the
  /// share card includes logos, team names and score.
  final SessionShareMatchContext? shareMatchContext;

  const TrackerPlayerAnalysisWidget({
    super.key,
    this.analysis,
    this.analysisDocId,
    this.teamId,
    this.playerName,
    this.showHeader = true,
    this.showDistanceTimeline = true,
    this.isMatch = true,
    required this.player,
    this.shareMatchContext,
  });

  @override
  State<TrackerPlayerAnalysisWidget> createState() =>
      _TrackerPlayerAnalysisWidgetState();
}

class _TrackerPlayerAnalysisWidgetState
    extends State<TrackerPlayerAnalysisWidget> {
  late Future<_TrackerPlayerAnalysisPayload?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TrackerPlayerAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.analysis != widget.analysis ||
        oldWidget.analysisDocId != widget.analysisDocId ||
        oldWidget.teamId != widget.teamId) {
      _future = _load();
    }
  }

  Future<_TrackerPlayerAnalysisPayload?> _load() async {
    TrackerAnalysisResult? analysis = widget.analysis;

    final docId = (widget.analysisDocId ?? '').trim();

    if (analysis == null && docId.isNotEmpty) {
      analysis = await TrackerAnalysisService.getAnalysisById(docId);
    }

    if (analysis == null) {
      return null;
    }

    final safeTeamId = (widget.teamId ?? '').trim().isEmpty
        ? TeamParam.defaultTeamId
        : widget.teamId!.trim();

    final teamParam = await TeamParamService.getEffectiveTeamParam(safeTeamId);

    return _TrackerPlayerAnalysisPayload(
      analysis: analysis,
      teamParam: teamParam,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrackerPlayerAnalysisPayload?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TrackerPlayerLoadingCard();
        }

        if (snapshot.hasError) {
          final l10n = context.l10n;
          return _TrackerPlayerEmptyCard(
            icon: Icons.error_outline_rounded,
            title: l10n.errorLoadingTitle,
            message: snapshot.error.toString(),
          );
        }

        final payload = snapshot.data;

        if (payload == null) {
          final l10n = context.l10n;
          return _TrackerPlayerEmptyCard(
            icon: Icons.query_stats_rounded,
            title: l10n.emptyNoAnalysis,
            message: l10n.errorNoTrackerAnalysis,
          );
        }

        final session = context.watch<AppSession>();
        return _TrackerPlayerAnalysisContent(
          analysis: payload.analysis,
          teamParam: payload.teamParam,
          playerName: widget.playerName,
          showHeader: widget.showHeader,
          showDistanceTimeline: widget.showDistanceTimeline,
          isMatch: widget.isMatch,
          player: widget.player,
          shareMatchContext: widget.shareMatchContext,
          showShare: canSharePlayerCardFromSession(
            session: session,
            teamId: widget.teamId,
            viewedPlayer: widget.player,
            viewedPlayerId: payload.analysis.playerId,
          ),
        );
      },
    );
  }
}

class _TrackerPlayerAnalysisContent extends StatefulWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;
  final String? playerName;
  final bool showHeader;
  final bool showDistanceTimeline;
  final bool isMatch;
  final Player? player;
  final SessionShareMatchContext? shareMatchContext;
  final bool showShare;

  const _TrackerPlayerAnalysisContent({
    required this.analysis,
    required this.teamParam,
    required this.playerName,
    required this.showHeader,
    required this.showDistanceTimeline,
    required this.isMatch,
    required this.player,
    this.shareMatchContext,
    this.showShare = false,
  });

  @override
  State<_TrackerPlayerAnalysisContent> createState() =>
      _TrackerPlayerAnalysisContentState();
}

class _TrackerPlayerAnalysisContentState
    extends State<_TrackerPlayerAnalysisContent> {
  int _selectedIndex = 0;
  int _lastLoggedTabIndex = -1;
  bool _sharing = false;

  void _logTabIfNeeded(int index, List<_PlayerAnalysisTabDef> tabs) {
    if (index == _lastLoggedTabIndex) return;
    if (index < 0 || index >= tabs.length) return;
    _lastLoggedTabIndex = index;
    AnalyticsInteractions.logTabSelect(
      screen: AnalyticsScreenNames.playerAnalysis,
      tab: tabs[index].analyticsTabId,
    );
  }

  Future<void> _shareSynthesis(BuildContext context) async {
    if (_sharing) return;
    final l10n = context.l10n;
    final playerName = (widget.playerName ?? '').trim().isNotEmpty
        ? widget.playerName!.trim()
        : l10n.entityPlayer;

    final origin = shareSheetOrigin(context);

    setState(() => _sharing = true);
    try {
      final player = widget.player;
      final playerPhotoUrl =
          player == null ? null : await resolvePlayerPhotoDownloadUrl(player);
      final png = await const SessionPlayerSynthesisShareService()
          .renderShareCardPng(
        l10n: l10n,
        playerName: playerName,
        analysis: widget.analysis,
        matchContext: widget.shareMatchContext,
        isMatch: widget.isMatch,
        playerPhotoUrl: playerPhotoUrl,
      );
      if (png == null || png.isEmpty) {
        throw StateError('Session synthesis PNG render failed');
      }
      if (!context.mounted) return;
      await MetaShareCoordinator().shareOrPublish(
        context: context,
        pngBytes: png,
        fileName: 'grinta_session_synthesis.png',
        statId: _sessionShareStatId(widget.analysis),
        statType: ShareStatType.sessionSynthesis,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          l10n.sessionSynthesisShareFailed,
          isError: true,
        );
      }
      debugPrint('Session synthesis share failed: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  String _sessionShareStatId(TrackerAnalysisResult analysis) {
    final eventId = analysis.eventId.trim();
    final playerId = analysis.playerId.trim();
    if (eventId.isNotEmpty && playerId.isNotEmpty) {
      return '${eventId}_$playerId';
    }
    if (eventId.isNotEmpty) return eventId;
    if (playerId.isNotEmpty) return playerId;
    return analysis.trackerId.trim();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 620;
        final bool isPhone = constraints.maxWidth < 600;

        final int metricColumns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;

        final l10n = context.l10n;
        final tabs = <_PlayerAnalysisTabDef>[
          _PlayerAnalysisTabDef(
            analyticsTabId: AnalyticsFeatures.playerAnalysisTabSynthesis,
            label: l10n.playerSynthesisTabTitle,
            compactLabel: l10n.playerSynthesisTabTitle,
            icon: Icons.query_stats_rounded,
            child: _buildSynthesisTab(
              context: context,
              metricColumns: metricColumns,
              compact: compact,
            ),
          ),
          _PlayerAnalysisTabDef(
            analyticsTabId: AnalyticsFeatures.playerAnalysisTabSpeedZones,
            label: l10n.tabSpeedZones,
            compactLabel: l10n.tabSpeedZonesShort,
            icon: Icons.speed_rounded,
            child: _SectionCard(
              title: l10n.tabSpeedZones,
              icon: Icons.speed_rounded,
              trailing: _TeamParamBadge(teamParam: widget.teamParam),
              child: _SpeedZonesView(
                analysis: widget.analysis,
                teamParam: widget.teamParam,
              ),
            ),
          ),
          if(widget.isMatch) ... [
            _PlayerAnalysisTabDef(
              analyticsTabId: AnalyticsFeatures.playerAnalysisTabFieldZones,
              label: l10n.tabFieldZones,
              compactLabel: l10n.entityField,
              icon: Icons.grid_view_rounded,
              child: _SectionCard(
                title: l10n.tabFieldZones,
                icon: Icons.grid_view_rounded,
                child: _FieldZonesView(
                  zones: widget.analysis.distanceByZones,
                ),
              ),
            ),
            _PlayerAnalysisTabDef(
              analyticsTabId: AnalyticsFeatures.playerAnalysisTabHalfTime,
              label: l10n.tabHalfTimeComparison,
              compactLabel: l10n.tabHalfTimeComparison,
              icon: Icons.compare_arrows_rounded,
              child: _SectionCard(
                title: l10n.tabHalfTimeComparison,
                icon: Icons.compare_arrows_rounded,
                child: _HalfStatsView(
                  analysis: widget.analysis,
                ),
              ),
            ),
          ],

          if (widget.showDistanceTimeline)
            _PlayerAnalysisTabDef(
              analyticsTabId: AnalyticsFeatures.playerAnalysisTabDistanceTimeline,
              label: l10n.tabDistanceTimeline,
              compactLabel: l10n.tabDistanceTimeline,
              icon: Icons.bar_chart_rounded,
              child: _SectionCard(
                title: l10n.tabDistanceTimeline,
                icon: Icons.bar_chart_rounded,
                child: _DistanceTimelineView(
                  timeline: widget.analysis.distanceTimeline,
                ),
              ),
            ),
          if(widget.isMatch) ... [
            _PlayerAnalysisTabDef(
              analyticsTabId: AnalyticsFeatures.playerAnalysisTabHeatmap,
              label: l10n.entityHeatmap,
              compactLabel: l10n.entityHeatmap,
              icon: Icons.local_fire_department_rounded,
              child: _SectionCard(
                title: l10n.tabHeatmap,
                icon: Icons.local_fire_department_rounded,
                child: _TrackerHeatmapView(
                  analysis: widget.analysis,
                ),
              ),
            ),
          ]

        ];

        final int safeSelectedIndex = _selectedIndex.clamp(
          0,
          tabs.length - 1,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logTabIfNeeded(safeSelectedIndex, tabs);
        });

        final double minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0;

        return Scrollbar(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showHeader && widget.player != null) ...[
                    _PlayerAnalysisHeader(
                      analysis: widget.analysis,
                      teamParam: widget.teamParam,
                      playerName: widget.playerName,
                      compact: compact,
                      isPhone: isPhone,
                      player: widget.player!,
                    ),
                    SizedBox(height: isPhone ? 8 : 12),
                  ],

                  _PlayerAnalysisTabSelector(
                    tabs: tabs,
                    selectedIndex: safeSelectedIndex,
                    onSelected: (index) {
                      _logTabIfNeeded(index, tabs);
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(safeSelectedIndex),
                      child: tabs[safeSelectedIndex].child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSynthesisTab({
    required BuildContext context,
    required int metricColumns,
    required bool compact,
  }) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final analysis = widget.analysis;

    return _SectionCard(
      title: l10n.playerSynthesisTitle,
      icon: Icons.query_stats_rounded,
      trailing: widget.showShare
          ? Builder(
              builder: (buttonContext) {
                return IconButton(
                  tooltip: l10n.sessionSynthesisShareTooltip,
                  onPressed:
                      _sharing ? null : () => _shareSynthesis(buttonContext),
                  icon: _sharing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(Icons.ios_share_outlined, color: colors.primary),
                );
              },
            )
          : null,
      child: GridView.count(
        crossAxisCount: metricColumns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 1.15 : 1.25,
        children: [
          _MetricTile(
            icon: Icons.route_rounded,
            label: l10n.statsDistance,
            value: analysis.distanceKm.toStringAsFixed(2),
            unit: l10n.statsUnitKm,
            color: colors.primary,
          ),
          _MetricTile(
            icon: Icons.speed_rounded,
            label: l10n.statsAvgSpeed,
            value: analysis.averageSpeedKmh.toStringAsFixed(1),
            unit: l10n.statsUnitKmh,
            color: colors.secondary,
          ),
          _MetricTile(
            icon: Icons.bolt_rounded,
            label: l10n.statsMaxSpeed,
            value: analysis.maxValidatedSpeedKmh.toStringAsFixed(1),
            unit: l10n.statsUnitKmh,
            color: colors.success,
          ),
          _MetricTile(
            icon: Icons.trending_up_rounded,
            label: l10n.statsMaxAccel,
            value: analysis.maxAccelerationMps2.toStringAsFixed(2),
            unit: l10n.statsUnitMps2,
            color: colors.warning,
          ),
          _MetricTile(
            icon: Icons.directions_run_rounded,
            label: l10n.statsSprints,
            value: analysis.sprintCount.toString(),
            unit: l10n.statsUnitCount,
            color: colors.primary,
          ),
          _MetricTile(
            icon: Icons.flash_on_rounded,
            label: l10n.statsHighAccel,
            value: analysis.highAccelerationCount.toString(),
            unit: l10n.statsUnitCount,
            color: colors.warning,
          ),
          _MetricTile(
            icon: Icons.timer_rounded,
            label: l10n.statsHighSpeedTime,
            value: _durationShort(analysis.highSpeedDuration),
            unit: '',
            color: colors.secondary,
          ),
          _MetricTile(
            icon: Icons.fitness_center_rounded,
            label: l10n.statsWorkload,
            value: analysis.workloadScore.toStringAsFixed(0),
            unit: 'pts',
            color: colors.success,
          ),
          _MetricTile(
            icon: Icons.local_fire_department_rounded,
            label: l10n.statsFatigue,
            value: analysis.fatigueIndex.toStringAsFixed(2),
            unit: '',
            color: _fatigueColor(context, analysis.fatigueIndex),
          ),
          _MetricTile(
            icon: Icons.schedule_rounded,
            label: l10n.statsDuration,
            value: _durationLong(analysis.duration),
            unit: '',
            color: colors.textSecondary,
          ),
        ],
      ),
    );
  }

  Color _fatigueColor(BuildContext context, double value) {
    final colors = context.appColors;

    if (value >= 1.10) return colors.danger;
    if (value >= 0.95) return colors.warning;
    return colors.success;
  }
}
