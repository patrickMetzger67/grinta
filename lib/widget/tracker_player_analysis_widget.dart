import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:grinta/widget/playerPhoto.dart';

import '../model/player.dart';
import '../model/teamParam.dart';
import '../model/tracker/trackerData.dart';
import '../services/teamParamService.dart';
import '../services/trackerDataAnalysisService.dart';
import '../services/trackerSvgService.dart';
import '../util/app_theme.dart';

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
          return _TrackerPlayerEmptyCard(
            icon: Icons.error_outline_rounded,
            title: 'Erreur de chargement',
            message: snapshot.error.toString(),
          );
        }

        final payload = snapshot.data;

        if (payload == null) {
          return const _TrackerPlayerEmptyCard(
            icon: Icons.query_stats_rounded,
            title: 'Aucune analyse disponible',
            message: 'Impossible de trouver les données tracker de ce joueur.',
          );
        }

        return _TrackerPlayerAnalysisContent(
          analysis: payload.analysis,
          teamParam: payload.teamParam,
          playerName: widget.playerName,
          showHeader: widget.showHeader,
          showDistanceTimeline: widget.showDistanceTimeline,
          isMatch: widget.isMatch,
          player: widget.player,
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

  const _TrackerPlayerAnalysisContent({
    required this.analysis,
    required this.teamParam,
    required this.playerName,
    required this.showHeader,
    required this.showDistanceTimeline,
    required this.isMatch,
    required this.player,
  });

  @override
  State<_TrackerPlayerAnalysisContent> createState() =>
      _TrackerPlayerAnalysisContentState();
}

class _TrackerPlayerAnalysisContentState
    extends State<_TrackerPlayerAnalysisContent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 620;

        final int metricColumns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;

        final tabs = <_PlayerAnalysisTabDef>[
          _PlayerAnalysisTabDef(
            label: 'Synthèse',
            compactLabel: 'Synthèse',
            icon: Icons.query_stats_rounded,
            child: _buildSynthesisTab(
              context: context,
              metricColumns: metricColumns,
              compact: compact,
            ),
          ),
          _PlayerAnalysisTabDef(
            label: 'Zones de vitesse',
            compactLabel: 'Vitesse',
            icon: Icons.speed_rounded,
            child: _SectionCard(
              title: 'Zones de vitesse',
              icon: Icons.speed_rounded,
              trailing: _TeamParamBadge(teamParam: widget.teamParam),
              child: _SpeedZonesView(
                analysis: widget.analysis,
                teamParam: widget.teamParam,
              ),
            ),
          ),
          _PlayerAnalysisTabDef(
            label: 'Zones de terrain',
            compactLabel: 'Terrain',
            icon: Icons.grid_view_rounded,
            child: _SectionCard(
              title: 'Zones terrain',
              icon: Icons.grid_view_rounded,
              child: _FieldZonesView(
                zones: widget.analysis.distanceByZones,
              ),
            ),
          ),
          if (widget.isMatch)
            _PlayerAnalysisTabDef(
              label: 'Comparaison mi-temps',
              compactLabel: 'Mi-temps',
              icon: Icons.compare_arrows_rounded,
              child: _SectionCard(
                title: 'Comparaison mi-temps',
                icon: Icons.compare_arrows_rounded,
                child: _HalfStatsView(
                  analysis: widget.analysis,
                ),
              ),
            ),
          if (widget.showDistanceTimeline)
            _PlayerAnalysisTabDef(
              label: 'Timeline distance',
              compactLabel: 'Timeline',
              icon: Icons.bar_chart_rounded,
              child: _SectionCard(
                title: 'Timeline distance',
                icon: Icons.bar_chart_rounded,
                child: _DistanceTimelineView(
                  timeline: widget.analysis.distanceTimeline,
                ),
              ),
            ),
          _PlayerAnalysisTabDef(
            label: 'Heatmap',
            compactLabel: 'Heatmap',
            icon: Icons.local_fire_department_rounded,
            child: _SectionCard(
              title: 'Carte de chaleur',
              icon: Icons.local_fire_department_rounded,
              child: _TrackerHeatmapView(
                analysis: widget.analysis,
              ),
            ),
          ),
        ];

        if (_selectedIndex >= tabs.length) {
          _selectedIndex = tabs.length - 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              _PlayerAnalysisHeader(
                analysis: widget.analysis,
                teamParam: widget.teamParam,
                playerName: widget.playerName,
                compact: compact,
                player: widget.player!,
              ),
              const SizedBox(height: 12),
            ],
            _PlayerAnalysisTabSelector(
              tabs: tabs,
              selectedIndex: _selectedIndex,
              onSelected: (index) {
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
                key: ValueKey(_selectedIndex),
                child: tabs[_selectedIndex].child,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSynthesisTab({
    required BuildContext context,
    required int metricColumns,
    required bool compact,
  }) {
    final colors = context.appColors;
    final analysis = widget.analysis;

    return _SectionCard(
      title: 'Synthèse joueur',
      icon: Icons.query_stats_rounded,
      child: GridView.count(
        crossAxisCount: metricColumns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: compact ? 1.35 : 1.55,
        children: [
          _MetricTile(
            icon: Icons.route_rounded,
            label: 'Distance',
            value: analysis.distanceKm.toStringAsFixed(2),
            unit: 'km',
            color: colors.primary,
          ),
          _MetricTile(
            icon: Icons.speed_rounded,
            label: 'Vitesse moy.',
            value: analysis.averageSpeedKmh.toStringAsFixed(1),
            unit: 'km/h',
            color: colors.secondary,
          ),
          _MetricTile(
            icon: Icons.bolt_rounded,
            label: 'Vitesse max',
            value: analysis.maxValidatedSpeedKmh.toStringAsFixed(1),
            unit: 'km/h',
            color: colors.success,
          ),
          _MetricTile(
            icon: Icons.trending_up_rounded,
            label: 'Accél. max',
            value: analysis.maxAccelerationMps2.toStringAsFixed(2),
            unit: 'm/s²',
            color: colors.warning,
          ),
          _MetricTile(
            icon: Icons.directions_run_rounded,
            label: 'Sprints',
            value: analysis.sprintCount.toString(),
            unit: 'nb',
            color: colors.primary,
          ),
          _MetricTile(
            icon: Icons.flash_on_rounded,
            label: 'Acc. hautes',
            value: analysis.highAccelerationCount.toString(),
            unit: 'nb',
            color: colors.warning,
          ),
          _MetricTile(
            icon: Icons.timer_rounded,
            label: 'Haute vitesse',
            value: _durationShort(analysis.highSpeedDuration),
            unit: '',
            color: colors.secondary,
          ),
          _MetricTile(
            icon: Icons.fitness_center_rounded,
            label: 'Workload',
            value: analysis.workloadScore.toStringAsFixed(0),
            unit: 'pts',
            color: colors.success,
          ),
          _MetricTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Fatigue',
            value: analysis.fatigueIndex.toStringAsFixed(2),
            unit: '',
            color: _fatigueColor(context, analysis.fatigueIndex),
          ),
          _MetricTile(
            icon: Icons.schedule_rounded,
            label: 'Durée',
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

class _PlayerAnalysisTabDef {
  final String label;
  final String compactLabel;
  final IconData icon;
  final Widget child;

  const _PlayerAnalysisTabDef({
    required this.label,
    required this.compactLabel,
    required this.icon,
    required this.child,
  });
}

class _PlayerAnalysisTabSelector extends StatelessWidget {
  final List<_PlayerAnalysisTabDef> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _PlayerAnalysisTabSelector({
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final width = MediaQuery.of(context).size.width;
    final bool compact = width < 520;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int perRow = constraints.maxWidth >= 1050
              ? tabs.length
              : constraints.maxWidth >= 760
              ? 3
              : 2;

          final double spacing = 6;
          final double itemWidth =
              (constraints.maxWidth - ((perRow - 1) * spacing)) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int index = 0; index < tabs.length; index++)
                SizedBox(
                  width: itemWidth,
                  child: _PlayerAnalysisTabButton(
                    tab: tabs[index],
                    selected: selectedIndex == index,
                    compact: compact,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PlayerAnalysisTabButton extends StatelessWidget {
  final _PlayerAnalysisTabDef tab;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _PlayerAnalysisTabButton({
    required this.tab,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final bgColor = selected ? colors.primary : Colors.transparent;
    final fgColor = selected ? Colors.white : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tab.icon,
                color: fgColor,
                size: compact ? 17 : 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  compact ? tab.compactLabel : tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
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

class _PlayerAnalysisHeader extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;
  final String? playerName;
  final bool compact;
  final Player player;

  const _PlayerAnalysisHeader({
    required this.analysis,
    required this.teamParam,
    required this.playerName,
    required this.compact,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = _clean(playerName).isNotEmpty
        ? playerName!.trim()
        : _formatPlayerId(analysis.playerId);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderTitle(
            title: title,
            analysis: analysis,
            player: player,
          ),
          const SizedBox(height: 12),
          _HeaderBadges(
            analysis: analysis,
            teamParam: teamParam,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _HeaderTitle(
              title: title,
              analysis: analysis,
              player: player,
            ),
          ),
          const SizedBox(width: 16),
          _HeaderBadges(
            analysis: analysis,
            teamParam: teamParam,
          ),
        ],
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  final String title;
  final TrackerAnalysisResult analysis;
  final Player player;

  const _HeaderTitle({
    required this.title,
    required this.analysis,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.24),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ClipOval(
            child: PlayerPhoto(
              player: player,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tracker ${analysis.trackerId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderBadges extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _HeaderBadges({
    required this.analysis,
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        /*
        _SmallBadge(
          icon: Icons.event_rounded,
          label: analysis.eventId,
        ),
        */
        _SmallBadge(
          icon: Icons.timer_rounded,
          label: _durationLong(analysis.duration),
        ),
        _SmallBadge(
          icon: Icons.settings_rounded,
          label: teamParam.isDefault
              ? 'Param défaut'
              : 'Param équipe ${teamParam.teamId}',
        ),
      ],
    );
  }
}

class _TeamParamBadge extends StatelessWidget {
  final TeamParam teamParam;

  const _TeamParamBadge({
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Tooltip(
      message:
      'Sprint ≥ ${teamParam.sprintThresholdKmh.toStringAsFixed(1)} km/h • '
          'Accélération haute ≥ ${teamParam.highAccelerationThresholdMps2.toStringAsFixed(1)} m/s²',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          'teamParam',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 420;

              if (compact && trailing != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          color: colors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    trailing!,
                  ],
                );
              }

              return Row(
                children: [
                  Icon(
                    icon,
                    color: colors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _SpeedZonesView extends StatelessWidget {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _SpeedZonesView({
    required this.analysis,
    required this.teamParam,
  });

  @override
  Widget build(BuildContext context) {
    final zones = teamParam.orderedSpeedZones;

    if (analysis.speedZones.isEmpty) {
      return const _InlineEmptyState(
        message: 'Aucune zone de vitesse disponible.',
      );
    }

    return Column(
      children: zones.map((teamZone) {
        final stat = _findSpeedZoneStat(
          analysis.speedZones,
          teamZone.zoneId,
        );

        final duration = stat?.duration ?? Duration.zero;
        final percent = stat?.percentOfSession ?? 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ZoneProgressRow(
            icon: _speedZoneIcon(teamZone.zoneId),
            title: teamZone.label,
            subtitle: _speedZoneRange(teamZone),
            value: _durationShort(duration),
            percent: percent,
            color: _speedZoneColor(context, teamZone.zoneId),
            trailing: '${percent.toStringAsFixed(1)} %',
          ),
        );
      }).toList(),
    );
  }

  SpeedZoneStat? _findSpeedZoneStat(
      List<SpeedZoneStat> stats,
      String zoneId,
      ) {
    for (final stat in stats) {
      if (stat.zoneId == zoneId) return stat;
    }
    return null;
  }

  String _speedZoneRange(TeamSpeedZone zone) {
    if (zone.maxKmh == null) {
      return '≥ ${zone.minKmh.toStringAsFixed(1)} km/h';
    }

    return '${zone.minKmh.toStringAsFixed(1)} - ${zone.maxKmh!.toStringAsFixed(1)} km/h';
  }

  IconData _speedZoneIcon(String zoneId) {
    switch (zoneId.toUpperCase()) {
      case 'Z1':
        return Icons.directions_walk_rounded;
      case 'Z2':
      case 'Z3':
        return Icons.directions_run_rounded;
      case 'Z4':
        return Icons.bolt_rounded;
      case 'Z5':
        return Icons.flash_on_rounded;
      default:
        return Icons.speed_rounded;
    }
  }

  Color _speedZoneColor(BuildContext context, String zoneId) {
    final colors = context.appColors;

    switch (zoneId.toUpperCase()) {
      case 'Z1':
        return colors.textSecondary;
      case 'Z2':
        return colors.primary;
      case 'Z3':
        return colors.secondary;
      case 'Z4':
        return colors.warning;
      case 'Z5':
        return colors.danger;
      default:
        return colors.primary;
    }
  }
}

class _FieldZonesView extends StatelessWidget {
  final List<FieldZoneStats> zones;

  const _FieldZonesView({
    required this.zones,
  });

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return const _InlineEmptyState(
        message: 'Aucune donnée de zone terrain disponible.',
      );
    }

    final Map<String, FieldZoneStats> byId = {
      for (final zone in zones) zone.zoneId: zone,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;

        if (compact) {
          return Column(
            children: [
              _FieldZoneRow(
                left: byId['ATT_LEFT'],
                right: byId['ATT_RIGHT'],
                leftLabel: 'Att. gauche',
                rightLabel: 'Att. droite',
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['MID_LEFT'],
                right: byId['MID_RIGHT'],
                leftLabel: 'Mil. gauche',
                rightLabel: 'Mil. droite',
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['DEF_LEFT'],
                right: byId['DEF_RIGHT'],
                leftLabel: 'Déf. gauche',
                rightLabel: 'Déf. droite',
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.appColors.border),
            color: context.appColors.surface,
          ),
          child: Column(
            children: [
              _FieldZoneRow(
                left: byId['ATT_LEFT'],
                right: byId['ATT_RIGHT'],
                leftLabel: 'Attaque gauche',
                rightLabel: 'Attaque droite',
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['MID_LEFT'],
                right: byId['MID_RIGHT'],
                leftLabel: 'Milieu gauche',
                rightLabel: 'Milieu droite',
              ),
              const SizedBox(height: 8),
              _FieldZoneRow(
                left: byId['DEF_LEFT'],
                right: byId['DEF_RIGHT'],
                leftLabel: 'Défense gauche',
                rightLabel: 'Défense droite',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FieldZoneRow extends StatelessWidget {
  final FieldZoneStats? left;
  final FieldZoneStats? right;
  final String leftLabel;
  final String rightLabel;

  const _FieldZoneRow({
    required this.left,
    required this.right,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FieldZoneTile(
            label: leftLabel,
            zone: left,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FieldZoneTile(
            label: rightLabel,
            zone: right,
          ),
        ),
      ],
    );
  }
}

class _FieldZoneTile extends StatelessWidget {
  final String label;
  final FieldZoneStats? zone;

  const _FieldZoneTile({
    required this.label,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final occupancy = zone?.occupancyPercent ?? 0.0;
    final distanceKm = (zone?.distanceMeters ?? 0.0) / 1000.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(
            percent: occupancy,
            color: colors.primary,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${distanceKm.toStringAsFixed(2)} km',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${occupancy.toStringAsFixed(1)} %',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalfStatsView extends StatelessWidget {
  final TrackerAnalysisResult analysis;

  const _HalfStatsView({
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final halfStats = [...analysis.halfStats]
      ..sort((a, b) => a.halfIndex.compareTo(b.halfIndex));

    if (halfStats.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 520;

          final firstHalf = _HalfTile(
            title: '1ère mi-temps',
            distanceKm: analysis.firstHalfDistanceKm,
            averageSpeedKmh: 0,
            duration: Duration.zero,
          );

          final secondHalf = _HalfTile(
            title: '2ème mi-temps',
            distanceKm: analysis.secondHalfDistanceKm,
            averageSpeedKmh: 0,
            duration: Duration.zero,
          );

          if (compact) {
            return Column(
              children: [
                firstHalf,
                const SizedBox(height: 10),
                secondHalf,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: firstHalf),
              const SizedBox(width: 10),
              Expanded(child: secondHalf),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;

        final children = halfStats.map((half) {
          return _HalfTile(
            title: half.halfIndex == 1
                ? '1ère mi-temps'
                : '${half.halfIndex}ème mi-temps',
            distanceKm: half.distanceKm,
            averageSpeedKmh: half.averageSpeedKmh,
            duration: half.duration,
          );
        }).toList();

        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _HalfTile extends StatelessWidget {
  final String title;
  final double distanceKm;
  final double averageSpeedKmh;
  final Duration duration;

  const _HalfTile({
    required this.title,
    required this.distanceKm,
    required this.averageSpeedKmh,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          _MiniValueLine(
            label: 'Distance',
            value: '${distanceKm.toStringAsFixed(2)} km',
          ),
          _MiniValueLine(
            label: 'Vitesse moy.',
            value: averageSpeedKmh > 0
                ? '${averageSpeedKmh.toStringAsFixed(1)} km/h'
                : '-',
          ),
          _MiniValueLine(
            label: 'Durée',
            value: duration.inMilliseconds > 0 ? _durationLong(duration) : '-',
          ),
        ],
      ),
    );
  }
}

class _DistanceTimelineView extends StatelessWidget {
  final List<DistanceTimelineStat> timeline;

  const _DistanceTimelineView({
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const _InlineEmptyState(
        message: 'Aucune timeline de distance disponible.',
      );
    }

    final sorted = [...timeline]
      ..sort((a, b) => a.bucketStartMs.compareTo(b.bucketStartMs));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineChartLegend(),
        const SizedBox(height: 12),
        _DistanceTimelineBarChart(
          timeline: sorted,
        ),
      ],
    );
  }
}

class _TimelineChartLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _LegendItem(
          label: 'Marche',
          color: colors.textSecondary,
        ),
        _LegendItem(
          label: 'Jogging',
          color: colors.primary,
        ),
        _LegendItem(
          label: 'Course',
          color: colors.secondary,
        ),
        _LegendItem(
          label: 'Haute intensité',
          color: colors.warning,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DistanceTimelineBarChart extends StatelessWidget {
  final List<DistanceTimelineStat> timeline;

  const _DistanceTimelineBarChart({
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final double maxMeters = timeline.map((e) => e.totalMeters).fold<double>(
      0,
          (previous, value) => value > previous ? value : previous,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 560;

        final double chartHeight = compact ? 280 : 340;
        final double barWidth = compact ? 22 : 28;
        final double itemWidth = compact ? 54 : 64;
        final double minChartWidth = timeline.length * itemWidth;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minChartWidth < constraints.maxWidth
                  ? constraints.maxWidth
                  : minChartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: _DistanceTimelineBarChartPainter(
                  timeline: timeline,
                  maxMeters: maxMeters <= 0 ? 1 : maxMeters,
                  barWidth: barWidth,
                  textColor: colors.textSecondary,
                  gridColor: colors.border,
                  walkingColor: colors.textSecondary,
                  joggingColor: colors.primary,
                  runningColor: colors.secondary,
                  highIntensityColor: colors.warning,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DistanceTimelineBarChartPainter extends CustomPainter {
  final List<DistanceTimelineStat> timeline;
  final double maxMeters;
  final double barWidth;
  final Color textColor;
  final Color gridColor;
  final Color walkingColor;
  final Color joggingColor;
  final Color runningColor;
  final Color highIntensityColor;

  _DistanceTimelineBarChartPainter({
    required this.timeline,
    required this.maxMeters,
    required this.barWidth,
    required this.textColor,
    required this.gridColor,
    required this.walkingColor,
    required this.joggingColor,
    required this.runningColor,
    required this.highIntensityColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftAxisWidth = 42;
    const double bottomLabelHeight = 42;
    const double topPadding = 12;
    const double rightPadding = 8;

    final double chartLeft = leftAxisWidth;
    final double chartTop = topPadding;
    final double chartRight = size.width - rightPadding;
    final double chartBottom = size.height - bottomLabelHeight;
    final double chartHeight = chartBottom - chartTop;
    final double chartWidth = chartRight - chartLeft;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.75)
      ..strokeWidth = 1;

    final axisLabelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    final labelValues = <double>[
      maxMeters,
      maxMeters * 0.5,
      0,
    ];

    for (final value in labelValues) {
      final double y = chartBottom - ((value / maxMeters) * chartHeight);

      canvas.drawLine(
        Offset(chartLeft, y),
        Offset(chartRight, y),
        gridPaint,
      );

      _drawText(
        canvas: canvas,
        text: value <= 0 ? '0' : '${value.toStringAsFixed(0)}m',
        offset: Offset(0, y - 7),
        width: leftAxisWidth - 6,
        style: axisLabelStyle,
        textAlign: TextAlign.right,
      );
    }

    final double itemWidth = chartWidth / timeline.length;

    for (int i = 0; i < timeline.length; i++) {
      final item = timeline[i];

      final double xCenter = chartLeft + (i * itemWidth) + (itemWidth / 2);
      final double barLeft = xCenter - (barWidth / 2);
      final double barRight = xCenter + (barWidth / 2);

      double currentBottom = chartBottom;

      final segments = [
        _ChartSegment(item.walkingMeters, walkingColor),
        _ChartSegment(item.joggingMeters, joggingColor),
        _ChartSegment(item.runningMeters, runningColor),
        _ChartSegment(item.highIntensityMeters, highIntensityColor),
      ].where((e) => e.value > 0).toList();

      for (int s = 0; s < segments.length; s++) {
        final segment = segments[s];

        final double height = (segment.value / maxMeters) * chartHeight;
        final double top = currentBottom - height;

        final radius = Radius.circular(barWidth / 2);

        final rrect = RRect.fromRectAndCorners(
          Rect.fromLTRB(barLeft, top, barRight, currentBottom),
          topLeft: s == segments.length - 1 ? radius : Radius.zero,
          topRight: s == segments.length - 1 ? radius : Radius.zero,
          bottomLeft: s == 0 ? radius : Radius.zero,
          bottomRight: s == 0 ? radius : Radius.zero,
        );

        canvas.drawRRect(
          rrect,
          Paint()..color = segment.color,
        );

        currentBottom = top;
      }

      _drawText(
        canvas: canvas,
        text: _compactTimelineLabel(item.label),
        offset: Offset(xCenter - (itemWidth / 2), chartBottom + 9),
        width: itemWidth,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  String _compactTimelineLabel(String label) {
    return label
        .replaceAll(' min', '')
        .replaceAll(' ', '')
        .replaceAll('minutes', '');
  }

  void _drawText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double width,
    required TextStyle style,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );

    painter.layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _DistanceTimelineBarChartPainter oldDelegate) {
    return oldDelegate.timeline != timeline ||
        oldDelegate.maxMeters != maxMeters ||
        oldDelegate.barWidth != barWidth ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.walkingColor != walkingColor ||
        oldDelegate.joggingColor != joggingColor ||
        oldDelegate.runningColor != runningColor ||
        oldDelegate.highIntensityColor != highIntensityColor;
  }
}

enum _HeatmapPeriod {
  firstHalf,
  secondHalf,
  fullMatch,
}

extension _HeatmapPeriodX on _HeatmapPeriod {
  String get label {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return '1ère mi-temps';
      case _HeatmapPeriod.secondHalf:
        return '2ème mi-temps';
      case _HeatmapPeriod.fullMatch:
        return 'Match complet';
    }
  }

  String get compactLabel {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return '1ère';
      case _HeatmapPeriod.secondHalf:
        return '2ème';
      case _HeatmapPeriod.fullMatch:
        return 'Match';
    }
  }

  String get firestoreSuffix {
    switch (this) {
      case _HeatmapPeriod.firstHalf:
        return 'firstHalf';
      case _HeatmapPeriod.secondHalf:
        return 'secondHalf';
      case _HeatmapPeriod.fullMatch:
        return 'fullMatch';
    }
  }
}

class _TrackerHeatmapView extends StatefulWidget {
  final TrackerAnalysisResult analysis;

  const _TrackerHeatmapView({
    required this.analysis,
  });

  @override
  State<_TrackerHeatmapView> createState() => _TrackerHeatmapViewState();
}

class _TrackerHeatmapViewState extends State<_TrackerHeatmapView> {
  final TrackerSvgService _service = TrackerSvgService();

  _HeatmapPeriod _selectedPeriod = _HeatmapPeriod.fullMatch;
  late Future<String?> _futureSvg;

  @override
  void initState() {
    super.initState();
    _futureSvg = _loadSvg();
  }

  @override
  void didUpdateWidget(covariant _TrackerHeatmapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.analysis.eventId != widget.analysis.eventId ||
        oldWidget.analysis.trackerId != widget.analysis.trackerId) {
      _futureSvg = _loadSvg();
    }
  }

  Future<String?> _loadSvg() {
    return _service.getSvgForTrackerPeriod(
      trackerId: widget.analysis.trackerId,
      eventId: widget.analysis.eventId,
      periodSuffix: _selectedPeriod.firestoreSuffix,
    );
  }

  void _changePeriod(_HeatmapPeriod period) {
    if (_selectedPeriod == period) return;

    setState(() {
      _selectedPeriod = period;
      _futureSvg = _loadSvg();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeatmapPeriodSelector(
          selectedPeriod: _selectedPeriod,
          onChanged: _changePeriod,
        ),
        const SizedBox(height: 12),
        FutureBuilder<String?>(
          future: _futureSvg,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _HeatmapContainer(
                child: Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return _HeatmapEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Erreur de chargement',
                message: snapshot.error.toString(),
              );
            }

            final svgToDisplay = snapshot.data;

            if (svgToDisplay == null || svgToDisplay.trim().isEmpty) {
              return _HeatmapEmptyState(
                icon: Icons.image_not_supported_outlined,
                title: 'Heatmap indisponible',
                message:
                'Aucune image SVG trouvée pour ${_selectedPeriod.label}.',
              );
            }

            return _HeatmapContainer(
              child: SvgPicture.string(
                svgToDisplay,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeatmapPeriodSelector extends StatelessWidget {
  final _HeatmapPeriod selectedPeriod;
  final ValueChanged<_HeatmapPeriod> onChanged;

  const _HeatmapPeriodSelector({
    required this.selectedPeriod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final periods = _HeatmapPeriod.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 520;
        final int perRow = compact ? 1 : 3;
        final double spacing = 8;
        final double itemWidth =
            (constraints.maxWidth - ((perRow - 1) * spacing)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: periods.map((period) {
            final bool selected = selectedPeriod == period;

            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Radio<_HeatmapPeriod>(
                        value: period,
                        groupValue: selectedPeriod,
                        onChanged: (value) {
                          if (value != null) {
                            onChanged(value);
                          }
                        },
                        activeColor: colors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          compact ? period.label : period.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontSize: 13,
                            fontWeight:
                            selected ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeatmapContainer extends StatelessWidget {
  final Widget child;

  const _HeatmapContainer({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 560;
        final double height = compact ? 240 : 320;

        return Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: child,
        );
      },
    );
  }
}

class _HeatmapEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HeatmapEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return _HeatmapContainer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSegment {
  final double value;
  final Color color;

  const _ChartSegment(
      this.value,
      this.color,
      );
}

class _ZoneProgressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final double percent;
  final Color color;
  final String trailing;

  const _ZoneProgressRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.percent,
    required this.color,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 420;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressBar(
                        percent: percent,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trailing,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          value,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _ProgressBar(
                            percent: percent,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trailing,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final Color color;

  const _ProgressBar({
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final safePercent = percent.clamp(0.0, 100.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: colors.border.withValues(alpha: 0.55),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: safePercent / 100,
          child: Container(
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MiniValueLine extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            label.isEmpty ? '-' : label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  final String message;

  const _InlineEmptyState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrackerPlayerLoadingCard extends StatelessWidget {
  const _TrackerPlayerLoadingCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: colors.primary,
        ),
      ),
    );
  }
}

class _TrackerPlayerEmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TrackerPlayerEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
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
              fontWeight: FontWeight.w900,
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

class _TrackerPlayerAnalysisPayload {
  final TrackerAnalysisResult analysis;
  final TeamParam teamParam;

  const _TrackerPlayerAnalysisPayload({
    required this.analysis,
    required this.teamParam,
  });
}

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatPlayerId(String playerId) {
  final safe = playerId.trim();

  if (safe.isEmpty) {
    return 'Joueur';
  }

  final parts = safe.split('-');

  if (parts.length >= 3 && !_looksLikeUuid(safe)) {
    final lastName = parts[0].trim().toUpperCase();
    final firstName = _capitalize(parts[1].trim());

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
  }

  return safe;
}

bool _looksLikeUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;

  final lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();

  if (words.isEmpty) return '?';

  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
      .toUpperCase();
}

String _durationShort(Duration duration) {
  final totalSeconds = duration.inSeconds;

  if (totalSeconds <= 0) {
    return '0s';
  }

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;

  if (minutes <= 0) {
    return '${seconds}s';
  }

  if (seconds == 0) {
    return '${minutes}min';
  }

  return '${minutes}min ${seconds}s';
}

String _durationLong(Duration duration) {
  final totalMinutes = duration.inMinutes;

  if (totalMinutes <= 0) {
    return '0 min';
  }

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours <= 0) {
    return '$minutes min';
  }

  if (minutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${minutes}';
}