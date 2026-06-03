import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/tracker_player_analysis_widget.dart';

import '../model/player.dart';
import '../model/tracker/team_workload_summary.dart';
import '../services/playerService.dart';
import '../services/teamWorkloadSummaryService.dart';
import '../util/app_theme.dart';

class MatchTrackerStatsTable extends StatefulWidget {
  final String eventId;
  final String? teamId;
  final bool realtime;
  final EdgeInsetsGeometry padding;
  final TeamWorkloadSummaryService? summaryService;
  final PlayerService? playerService;
  final bool isMatch;

  const MatchTrackerStatsTable({
    super.key,
    required this.eventId,
    this.teamId,
    this.realtime = true,
    this.padding = EdgeInsets.zero,
    this.summaryService,
    this.playerService,
    this.isMatch = true,
  });

  @override
  State<MatchTrackerStatsTable> createState() => _MatchTrackerStatsTableState();
}

class _MatchTrackerStatsTableState extends State<MatchTrackerStatsTable> {
  late final TeamWorkloadSummaryService _summaryService;
  late final PlayerService _playerService;

  final Map<String, Future<Player?>> _playerFutures = {};

  int _sortColumnIndex = 1;
  bool _sortAscending = true;

  List<_MetricConfig> _metrics(AppLocalizations l10n) => [
    _MetricConfig(
      key: TeamWorkloadMetricKeys.workloadScore,
      title: l10n.statsWorkload,
      subtitle: l10n.statsScore,
      width: 140,
      formatter: (value) => value.toStringAsFixed(0),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.distanceKm,
      title: l10n.statsDistance,
      subtitle: l10n.statsUnitKm,
      width: 132,
      formatter: (value) => value.toStringAsFixed(2),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.maxValidatedSpeedKmh,
      title: l10n.statsMaxSpeed,
      subtitle: l10n.statsUnitKmh,
      width: 142,
      formatter: (value) => value.toStringAsFixed(1),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.highAccelerationCount,
      title: l10n.statsHighAccel,
      subtitle: l10n.statsUnitCount,
      width: 132,
      formatter: (value) => value.toStringAsFixed(0),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.highSpeedDuration,
      title: l10n.statsHighSpeedTime,
      subtitle: l10n.statsUnitSeconds,
      width: 142,
      formatter: (value) => value.toStringAsFixed(1),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.maxAccelerationMps2,
      title: l10n.statsMaxAccel,
      subtitle: l10n.statsUnitMps2,
      width: 132,
      formatter: (value) => value.toStringAsFixed(2),
    ),
    _MetricConfig(
      key: TeamWorkloadMetricKeys.sprintCount,
      title: l10n.statsSprints,
      subtitle: l10n.statsUnitCount,
      width: 120,
      formatter: (value) => value.toStringAsFixed(0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _summaryService = widget.summaryService ?? TeamWorkloadSummaryService();
    _playerService = widget.playerService ?? PlayerService();
  }

  @override
  void didUpdateWidget(covariant MatchTrackerStatsTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.eventId != widget.eventId) {
      _playerFutures.clear();
      _sortColumnIndex = 0;
      _sortAscending = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeEventId = widget.eventId.trim();

    if (safeEventId.isEmpty) {
      return _TrackerStatsEmptyState(
        title: context.l10n.errorMatchNotIdentified,
        message: context.l10n.errorNoTrackerStats,
      );
    }

    if (widget.realtime) {
      return StreamBuilder<TeamWorkloadSummary?>(
        stream: _summaryService.watchByEventId(safeEventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _TrackerStatsLoadingState();
          }

          if (snapshot.hasError) {
            return _TrackerStatsEmptyState(
              title: context.l10n.errorLoadingTitle,
              message: snapshot.error.toString(),
            );
          }

          final summary = snapshot.data;

          if (summary == null) {
            return _TrackerStatsEmptyState(
              title: context.l10n.emptyNoStats,
              message: context.l10n.emptyNoStatsForMatch,
            );
          }

          return _buildTableFromSummary(summary);
        },
      );
    }

    return FutureBuilder<TeamWorkloadSummary?>(
      future: _summaryService.getByEventId(safeEventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TrackerStatsLoadingState();
        }

        if (snapshot.hasError) {
          return _TrackerStatsEmptyState(
            title: context.l10n.errorLoadingTitle,
            message: snapshot.error.toString(),
          );
        }

        final summary = snapshot.data;

        if (summary == null) {
          return _TrackerStatsEmptyState(
            title: context.l10n.emptyNoStats,
            message: context.l10n.emptyNoStatsTeamAnalysis,
          );
        }

        return _buildTableFromSummary(summary);
      },
    );
  }

  Widget _buildTableFromSummary(TeamWorkloadSummary summary) {
    final metrics = _metrics(context.l10n);

    return FutureBuilder<List<_TrackerStatsRow>>(
      future: _buildRows(summary),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _TrackerStatsLoadingState();
        }

        if (snapshot.hasError) {
          return _TrackerStatsEmptyState(
            title: context.l10n.errorPlayersTitle,
            message: snapshot.error.toString(),
          );
        }

        final rows = snapshot.data ?? [];

        if (rows.isEmpty) {
          return _TrackerStatsEmptyState(
            title: context.l10n.errorNoPlayersTitle,
            message: context.l10n.emptyNoPlayersInStats,
          );
        }

        _sortRows(rows, metrics);

        return _TrackerStatsTableContent(
          summary: summary,
          rows: rows,
          metrics: metrics,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          padding: widget.padding,
          teamId: widget.teamId,
          onSort: _onSort,
          isMatch: widget.isMatch,
        );
      },
    );
  }

  Future<List<_TrackerStatsRow>> _buildRows(TeamWorkloadSummary summary) async {
    final unknownPlayer = context.l10n.entityPlayerUnknown;
    final rows = await Future.wait(
      summary.playerScores.map((playerScore) async {
        final player = await _loadPlayer(playerScore.playerId);

        return _TrackerStatsRow(
          playerId: playerScore.playerId,
          trackerId: playerScore.trackerId,
          player: player,
          scores: playerScore,
          displayName: _resolvePlayerDisplayName(
            player,
            playerScore.playerId,
            unknownPlayer,
          ),
        );
      }),
    );

    return rows;
  }

  Future<Player?> _loadPlayer(String playerId) {
    final safePlayerId = playerId.trim();

    if (safePlayerId.isEmpty) {
      return Future.value(null);
    }

    return _playerFutures.putIfAbsent(
      safePlayerId,
          () => _playerService.getPlayerById(safePlayerId).catchError((_) => null),
    );
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _sortRows(List<_TrackerStatsRow> rows, List<_MetricConfig> metrics) {
    rows.sort((a, b) {
      int result;

      if (_sortColumnIndex == 0) {
        result = a.playerName.toLowerCase().compareTo(
          b.playerName.toLowerCase(),
        );
      } else if (_sortColumnIndex == 1) {
        result = a.trackerId.toLowerCase().compareTo(
          b.trackerId.toLowerCase(),
        );
      } else {
        final metricIndex = _sortColumnIndex - 2;

        if (metricIndex < 0 || metricIndex >= metrics.length) {
          result = 0;
        } else {
          final metricKey = metrics[metricIndex].key;
          final aValue = a.metricValue(metricKey);
          final bValue = b.metricValue(metricKey);

          result = aValue.compareTo(bValue);
        }
      }

      return _sortAscending ? result : -result;
    });
  }
}

class _TrackerStatsTableContent extends StatelessWidget {
  final TeamWorkloadSummary summary;
  final List<_TrackerStatsRow> rows;
  final List<_MetricConfig> metrics;
  final int sortColumnIndex;
  final bool sortAscending;
  final EdgeInsetsGeometry padding;
  final String? teamId;
  final void Function(int columnIndex, bool ascending) onSort;
  final bool isMatch;

  const _TrackerStatsTableContent({
    required this.summary,
    required this.rows,
    required this.metrics,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.padding,
    required this.onSort,
    this.teamId,
    required this.isMatch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool hasBoundedHeight = constraints.hasBoundedHeight;

        final double minTableWidth =
        constraints.hasBoundedWidth && constraints.maxWidth > 1240
            ? constraints.maxWidth
            : 1240;

        final Widget tableWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minTableWidth,
            ),
            child: DataTable(
              showCheckboxColumn: false,
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowHeight: 58,
              dataRowMinHeight: 66,
              dataRowMaxHeight: 78,
              dividerThickness: 1,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: colors.border,
                  width: 1,
                ),
              ),
              columns: [
                DataColumn(
                  label: _TableHeaderCell(
                    title: context.l10n.entityPlayer,
                    subtitle: context.l10n.entityName,
                    width: 180,
                  ),
                  onSort: onSort,
                ),
                DataColumn(
                  label: _TableHeaderCell(
                    title: context.l10n.entityTracker,
                    subtitle: context.l10n.entityTrackerId,
                    width: 80,
                  ),
                  onSort: onSort,
                ),
                for (final metric in metrics)
                  DataColumn(
                    numeric: true,
                    label: _TableHeaderCell(
                      title: metric.title,
                      subtitle: metric.subtitle,
                      width: metric.width,
                      alignRight: true,
                    ),
                    onSort: onSort,
                  ),
              ],
              rows: rows.map((row) {
                return DataRow(
                  onSelectChanged: (_) {
                    _openPlayerTrackerAnalysis(
                      context: context,
                      summary: summary,
                      row: row,
                      teamId: teamId,
                      isMatch: isMatch
                    );
                  },
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 180,
                        child: _PlayerCell(row: row),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: Text(
                          row.trackerId.isEmpty ? '-' : row.trackerId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    for (final metric in metrics)
                      DataCell(
                        SizedBox(
                          width: metric.width,
                          child: _MetricCell(
                            metric: row.metric(metric.key),
                            formatter: metric.formatter,
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        );

        return Padding(
          padding: padding,
          child: Container(
            width: double.infinity,
            height: hasBoundedHeight ? double.infinity : null,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatsHeader(summary: summary),

                Divider(
                  color: colors.border,
                  height: 1,
                ),

                if (hasBoundedHeight)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: tableWidget,
                    ),
                  )
                else
                  tableWidget,
              ],
            ),
          ),
        );
      },
    );
  }
  void _openPlayerTrackerAnalysis({
    required BuildContext context,
    required TeamWorkloadSummary summary,
    required _TrackerStatsRow row,
    required String? teamId,
    required bool isMatch,
  }) {
    final colors = context.appColors;

    final eventId = summary.eventId.trim();
    final trackerId = row.trackerId.trim();

    if (eventId.isEmpty || trackerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.errorOpenAnalysis),
        ),
      );
      return;
    }

    final analysisDocId = '${eventId}_$trackerId';

    Navigator.of(context, rootNavigator: true).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.playerAnalysis,
        fullscreenDialog: true,
        builder: (_) {
          return Scaffold(
            backgroundColor: colors.background,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
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
                            context.l10n.entityDetails,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isLarge = constraints.maxWidth >= 900;

                        return ListView(
                          padding: EdgeInsets.all(isLarge ? 10 : 12),
                          children: [
                            TrackerPlayerAnalysisWidget(
                              analysisDocId: analysisDocId,
                              teamId: teamId,
                              playerName: row.playerName,
                              player: row.player,
                              isMatch: isMatch,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final TeamWorkloadSummary summary;

  const _StatsHeader({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.query_stats_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.navStatistics,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          _SummaryPill(
            label: context.l10n.statsPlayersCount(summary.playersCount),
            icon: Icons.groups_rounded,
          ),
          _SummaryPill(
            label: context.l10n.statsAvgWorkload(
              summary.averageWorkloadScore.toStringAsFixed(0),
            ),
            icon: Icons.bar_chart_rounded,
          ),
          _SummaryPill(
            label: context.l10n.statsAvgDistance(
              summary.metricStats['distanceKm']!.mean.toStringAsFixed(2),
            ),
            icon: Icons.map_rounded,
          ),
          _SummaryPill(
            label: context.l10n.statsAvgMaxSpeed(
              summary.metricStats['distanceKm']!.mean.toStringAsFixed(2),
            ),
            icon: Icons.directions_run_rounded,
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SummaryPill({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
            size: 15,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String title;
  final String subtitle;
  final double width;
  final bool alignRight;

  const _TableHeaderCell({
    required this.title,
    required this.subtitle,
    required this.width,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCell extends StatelessWidget {
  final _TrackerStatsRow row;

  const _PlayerCell({
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      children: [
        PlayerPhoto(player: row.player!,),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCell extends StatelessWidget {
  final PlayerMetricScore? metric;
  final String Function(double value) formatter;

  const _MetricCell({
    required this.metric,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (metric == null) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text(
          '-',
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            formatter(metric!.value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 7),
        _ZScoreBadge(zScore: metric!.zScore),
      ],
    );
  }
}

class _ZScoreBadge extends StatelessWidget {
  final double zScore;

  const _ZScoreBadge({
    required this.zScore,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final Color color = _colorForZScore(colors, zScore);
    final String sign = zScore > 0 ? '+' : '';

    return Tooltip(
      message: context.l10n.statsZScore(sign, zScore.toStringAsFixed(2)),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          '$sign${zScore.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Color _colorForZScore(AppColors colors, double value) {
    if (value > 0.0) return colors.success;
    if (value < 0.0) return colors.danger;
    return colors.textSecondary;
  }
}

class _TrackerStatsLoadingState extends StatelessWidget {
  const _TrackerStatsLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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

class _TrackerStatsEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _TrackerStatsEmptyState({
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
            Icons.query_stats_rounded,
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

class _TrackerStatsRow {
  final String playerId;
  final String trackerId;
  final Player? player;
  final TeamPlayerMetricScores scores;
  final String displayName;

  const _TrackerStatsRow({
    required this.playerId,
    required this.trackerId,
    required this.player,
    required this.scores,
    required this.displayName,
  });

  String get playerName => displayName;

  PlayerMetricScore? metric(String key) {
    return scores.getMetric(key);
  }

  double metricValue(String key) {
    return scores.getMetric(key)?.value ?? 0.0;
  }
}

class _MetricConfig {
  final String key;
  final String title;
  final String subtitle;
  final double width;
  final String Function(double value) formatter;

  const _MetricConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.width,
    required this.formatter,
  });
}

String _resolvePlayerDisplayName(
  Player? player,
  String playerId,
  String unknownPlayer,
) {
  final firstName = (player?.firstName ?? '').trim();
  final lastName = (player?.lastName ?? '').trim();

  if (firstName.isNotEmpty && lastName.isNotEmpty) {
    return '$firstName $lastName';
  }

  if (firstName.isNotEmpty) {
    return firstName;
  }

  if (lastName.isNotEmpty) {
    return lastName;
  }

  return _formatFallbackPlayerId(playerId, unknownPlayer);
}

String _formatFallbackPlayerId(String playerId, String unknownPlayer) {
  final safe = playerId.trim();

  if (safe.isEmpty) {
    return unknownPlayer;
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

  if (words.isEmpty) {
    return '?';
  }

  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }

  return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'
      .toUpperCase();
}