import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/tracker/polar_session_analysis.dart';
import 'package:grinta/services/polar_session_analysis_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/playerPhoto.dart';

/// Cardio session analysis for Polar team kits (`TRACKER_PolarAnalysis`).
///
/// Replaces [TrackerPlayerAnalysisWidget] when `typeTracker == polar`.
class PolarPlayerAnalysisWidget extends StatefulWidget {
  const PolarPlayerAnalysisWidget({
    super.key,
    this.analysis,
    this.analysisDocId,
    this.eventId,
    this.trackerId,
    this.playerId,
    this.playerName,
    this.player,
    this.showHeader = true,
  });

  final PolarSessionAnalysis? analysis;
  final String? analysisDocId;
  final String? eventId;
  final String? trackerId;
  final String? playerId;
  final String? playerName;
  final Player? player;
  final bool showHeader;

  @override
  State<PolarPlayerAnalysisWidget> createState() =>
      _PolarPlayerAnalysisWidgetState();
}

class _PolarPlayerAnalysisWidgetState extends State<PolarPlayerAnalysisWidget> {
  late Future<PolarSessionAnalysis?> _future;
  final _service = PolarSessionAnalysisService();
  int _selectedIndex = 0;
  int _lastLoggedTab = -1;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant PolarPlayerAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.analysis != widget.analysis ||
        oldWidget.analysisDocId != widget.analysisDocId ||
        oldWidget.eventId != widget.eventId ||
        oldWidget.trackerId != widget.trackerId ||
        oldWidget.playerId != widget.playerId) {
      _future = _load();
    }
  }

  Future<PolarSessionAnalysis?> _load() async {
    if (widget.analysis != null) return widget.analysis;

    final docId = (widget.analysisDocId ?? '').trim();
    if (docId.isNotEmpty) {
      return _service.getByDocId(docId);
    }

    final eventId = (widget.eventId ?? '').trim();
    final trackerId = (widget.trackerId ?? '').trim();
    if (eventId.isNotEmpty && trackerId.isNotEmpty) {
      return _service.getForEventTracker(
        eventId: eventId,
        trackerId: trackerId,
      );
    }

    final playerId = (widget.playerId ?? '').trim();
    if (eventId.isNotEmpty && playerId.isNotEmpty) {
      return _service.getForEventPlayer(eventId: eventId, playerId: playerId);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PolarSessionAnalysis?>(
      future: _future,
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
          return _PolarEmpty(
            icon: Icons.error_outline_rounded,
            title: context.l10n.errorLoadingTitle,
            message: snapshot.error.toString(),
          );
        }

        final analysis = snapshot.data;
        if (analysis == null) {
          return _PolarEmpty(
            icon: Icons.favorite_border_rounded,
            title: context.l10n.emptyNoAnalysis,
            message: context.l10n.polarAnalysisEmptyMessage,
          );
        }

        return _PolarPlayerAnalysisContent(
          analysis: analysis,
          player: widget.player,
          playerName: widget.playerName,
          showHeader: widget.showHeader,
          selectedIndex: _selectedIndex,
          onTabSelected: (i) {
            setState(() => _selectedIndex = i);
          },
          lastLoggedTab: _lastLoggedTab,
          onTabLogged: (i) => _lastLoggedTab = i,
        );
      },
    );
  }
}

class _PolarPlayerAnalysisContent extends StatelessWidget {
  const _PolarPlayerAnalysisContent({
    required this.analysis,
    required this.player,
    required this.playerName,
    required this.showHeader,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.lastLoggedTab,
    required this.onTabLogged,
  });

  final PolarSessionAnalysis analysis;
  final Player? player;
  final String? playerName;
  final bool showHeader;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int lastLoggedTab;
  final ValueChanged<int> onTabLogged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    final tabs = <_PolarTab>[
      _PolarTab(
        analyticsId: AnalyticsFeatures.playerAnalysisTabSynthesis,
        label: l10n.playerSynthesisTabTitle,
        icon: Icons.favorite_rounded,
        child: _buildSynthesis(context),
      ),
      _PolarTab(
        analyticsId: 'hr_zones',
        label: l10n.polarAnalysisHrZonesTab,
        icon: Icons.stacked_bar_chart_rounded,
        child: _buildZones(context),
      ),
    ];

    final safeIndex = selectedIndex.clamp(0, tabs.length - 1);
    if (safeIndex != lastLoggedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onTabLogged(safeIndex);
        AnalyticsInteractions.logTabSelect(
          screen: AnalyticsScreenNames.playerAnalysis,
          tab: tabs[safeIndex].analyticsId,
        );
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                _header(context, compact: compact),
                SizedBox(height: compact ? 8 : 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < tabs.length; i++)
                      Expanded(
                        child: _tabButton(
                          context,
                          tab: tabs[i],
                          selected: i == safeIndex,
                          onTap: () => onTabSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(safeIndex),
                  child: tabs[safeIndex].child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, {required bool compact}) {
    final colors = context.appColors;
    final name = (playerName ?? '').trim().isEmpty
        ? context.l10n.entityPlayer
        : playerName!.trim();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          if (player != null) ...[
            PlayerPhoto(player: player!, radius: compact ? 22 : 28),
            const SizedBox(width: 12),
          ] else ...[
            CircleAvatar(
              radius: compact ? 22 : 28,
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              child: Icon(Icons.favorite, color: colors.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: compact ? 18 : 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.polarAnalysisDeviceLine(
                    analysis.polarDeviceId.isEmpty
                        ? '—'
                        : analysis.polarDeviceId,
                    analysis.deviceType,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
    BuildContext context, {
    required _PolarTab tab,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                size: 18,
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? colors.primary : colors.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSynthesis(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final minutes = analysis.duration.inMinutes;
    final seconds = analysis.duration.inSeconds % 60;

    final tiles = <Widget>[
      _metricTile(
        context,
        icon: Icons.timer_outlined,
        label: l10n.polarAnalysisDuration,
        value: '$minutes',
        unit: l10n.polarAnalysisUnitMin,
        color: colors.primary,
      ),
      _metricTile(
        context,
        icon: Icons.favorite_rounded,
        label: l10n.polarAnalysisAvgHr,
        value: analysis.avgHrBpm?.toString() ?? '—',
        unit: l10n.polarAnalysisUnitBpm,
        color: colors.secondary,
      ),
      _metricTile(
        context,
        icon: Icons.trending_up_rounded,
        label: l10n.polarAnalysisMaxHr,
        value: analysis.maxHrBpm?.toString() ?? '—',
        unit: l10n.polarAnalysisUnitBpm,
        color: colors.warning,
      ),
      _metricTile(
        context,
        icon: Icons.trending_down_rounded,
        label: l10n.polarAnalysisMinHr,
        value: analysis.minHrBpm?.toString() ?? '—',
        unit: l10n.polarAnalysisUnitBpm,
        color: colors.textSecondary,
      ),
      _metricTile(
        context,
        icon: Icons.insights_rounded,
        label: l10n.polarAnalysisSamples,
        value: analysis.hrSamplesCount.toString(),
        unit: '',
        color: colors.primary,
      ),
      if (analysis.caloriesKcal != null)
        _metricTile(
          context,
          icon: Icons.local_fire_department_outlined,
          label: l10n.polarAnalysisCalories,
          value: analysis.caloriesKcal!.toStringAsFixed(0),
          unit: l10n.polarAnalysisUnitKcal,
          color: colors.warning,
        ),
      if (analysis.steps != null)
        _metricTile(
          context,
          icon: Icons.directions_walk_rounded,
          label: l10n.polarAnalysisSteps,
          value: analysis.steps!.toString(),
          unit: '',
          color: colors.secondary,
        ),
      if (analysis.distanceMeters != null)
        _metricTile(
          context,
          icon: Icons.route_rounded,
          label: l10n.statsDistance,
          value: (analysis.distanceMeters! / 1000).toStringAsFixed(2),
          unit: l10n.statsUnitKm,
          color: colors.primary,
        ),
    ];

    return _section(
      context,
      title: l10n.playerSynthesisTitle,
      icon: Icons.favorite_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seconds > 0 || minutes == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                l10n.polarAnalysisDurationDetail(minutes, seconds),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 560
                      ? 3
                      : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.15,
                children: tiles,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZones(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final zones = <String>['z1', 'z2', 'z3', 'z4', 'z5'];
    final totals = zones
        .map((z) => analysis.hrZoneSeconds[z] ?? 0)
        .fold<int>(0, (a, b) => a + b);
    final maxSec = zones
        .map((z) => analysis.hrZoneSeconds[z] ?? 0)
        .fold<int>(1, (a, b) => a > b ? a : b);

    final zoneColors = <Color>[
      colors.success,
      colors.secondary,
      colors.warning,
      colors.primary,
      colors.danger,
    ];

    return _section(
      context,
      title: l10n.polarAnalysisHrZonesTab,
      icon: Icons.stacked_bar_chart_rounded,
      child: Column(
        children: [
          for (var i = 0; i < zones.length; i++) ...[
            _zoneRow(
              context,
              label: l10n.polarAnalysisZoneLabel(zones[i].toUpperCase()),
              seconds: analysis.hrZoneSeconds[zones[i]] ?? 0,
              total: totals,
              maxSec: maxSec,
              color: zoneColors[i],
            ),
            if (i < zones.length - 1) const SizedBox(height: 10),
          ],
          if (totals == 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.polarAnalysisNoZones,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _zoneRow(
    BuildContext context, {
    required String label,
    required int seconds,
    required int total,
    required int maxSec,
    required Color color,
  }) {
    final colors = context.appColors;
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    final pct = total <= 0 ? 0.0 : seconds / total;
    final bar = maxSec <= 0 ? 0.0 : seconds / maxSec;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${minutes}m ${rem.toString().padLeft(2, '0')}s'
                '${total > 0 ? ' · ${(pct * 100).toStringAsFixed(0)}%' : ''}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: bar.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: colors.border.withValues(alpha: 0.5),
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
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

  Widget _metricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      unit,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
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

class _PolarTab {
  const _PolarTab({
    required this.analyticsId,
    required this.label,
    required this.icon,
    required this.child,
  });

  final String analyticsId;
  final String label;
  final IconData icon;
  final Widget child;
}

class _PolarEmpty extends StatelessWidget {
  const _PolarEmpty({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
