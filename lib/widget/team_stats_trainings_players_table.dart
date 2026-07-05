import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/team_training_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:intl/intl.dart';

enum TeamStatsTrainingsSortColumn {
  player,
  present,
  absent,
  attendanceRate,
}

class TeamStatsTrainingsPlayersTable extends StatefulWidget {
  const TeamStatsTrainingsPlayersTable({
    super.key,
    required this.stats,
    this.visiblePlayerId,
  });

  final List<TeamTrainingPlayerStats> stats;
  final String? visiblePlayerId;

  @override
  State<TeamStatsTrainingsPlayersTable> createState() =>
      _TeamStatsTrainingsPlayersTableState();
}

class _TeamStatsTrainingsPlayersTableState
    extends State<TeamStatsTrainingsPlayersTable> {
  static const double _playerColumnWidth = 180;
  static const double _headingRowHeight = 48;
  static const double _dataRowHeight = 56;
  static const double _presentColumnWidth = 72;
  static const double _absentColumnWidth = 72;
  static const double _attendanceRateColumnWidth = 80;

  TeamStatsTrainingsSortColumn _sortColumn =
      TeamStatsTrainingsSortColumn.player;
  bool _sortAscending = true;

  List<TeamTrainingPlayerStats> get _visibleStats {
    final playerId = widget.visiblePlayerId?.trim();
    if (playerId == null || playerId.isEmpty) {
      return widget.stats;
    }
    return widget.stats
        .where((row) => row.playerId == playerId)
        .toList(growable: false);
  }

  void _onSortColumn(TeamStatsTrainingsSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<TeamTrainingPlayerStats> _sortedRows(AppLocalizations l10n) {
    final rows = List<TeamTrainingPlayerStats>.from(_visibleStats);

    rows.sort((a, b) {
      int result = 0;

      switch (_sortColumn) {
        case TeamStatsTrainingsSortColumn.player:
          result = _compareText(
            _playerLabel(a, l10n),
            _playerLabel(b, l10n),
          );
          break;
        case TeamStatsTrainingsSortColumn.present:
          result = a.presentCount.compareTo(b.presentCount);
          break;
        case TeamStatsTrainingsSortColumn.absent:
          result = a.absentCount.compareTo(b.absentCount);
          break;
        case TeamStatsTrainingsSortColumn.attendanceRate:
          result = _compareNullableDouble(a.attendanceRate, b.attendanceRate);
          break;
      }

      return _sortAscending ? result : -result;
    });

    return rows;
  }

  int _compareText(String a, String b) {
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  int _compareNullableDouble(double? a, double? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return -1;
    }
    if (b == null) {
      return 1;
    }
    return a.compareTo(b);
  }

  String _playerLabel(TeamTrainingPlayerStats row, AppLocalizations l10n) {
    final player = row.player;
    if (player == null) {
      return row.playerId;
    }
    return _formatPlayerShortNameSpaced(
      player,
      unknownLabel: l10n.entityPlayer,
    );
  }

  String _formatPlayerShortNameSpaced(
    Player player, {
    required String unknownLabel,
  }) {
    final firstName = (player.firstName ?? '').trim();
    final lastName = (player.lastName ?? '').trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0].toUpperCase()}. ${lastName.toUpperCase()}';
    }

    return formatPlayerShortName(player, unknownLabel: unknownLabel);
  }

  String _attendanceRateLabel(AppLocalizations l10n, double? rate) {
    if (rate == null) {
      return '—';
    }
    final formatted = NumberFormat.decimalPatternDigits(
      decimalDigits: 0,
    ).format(rate);
    return l10n.teamStatsTrainingsAttendanceRateValue(formatted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final rows = _sortedRows(l10n);

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.teamStatsTrainingsPlayersNoData,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final bool singleRow = widget.visiblePlayerId?.trim().isNotEmpty == true;

    if (singleRow && rows.length == 1) {
      return _TrainingPlayerStatsCard(
        row: rows.first,
        playerLabel: _playerLabel(rows.first, l10n),
        attendanceRateLabel:
            _attendanceRateLabel(l10n, rows.first.attendanceRate),
      );
    }

    final headerStyle = textTheme.labelLarge?.copyWith(
      color: colors.textSecondary,
      fontWeight: FontWeight.w700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _playerColumnWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(
                right: BorderSide(color: colors.border),
              ),
            ),
            child: Column(
              children: [
                _SortableHeaderCell(
                  height: _headingRowHeight,
                  label: l10n.teamStatsPlayersColumnPlayer,
                  labelStyle: headerStyle,
                  sortColumn: TeamStatsTrainingsSortColumn.player,
                  activeSortColumn: _sortColumn,
                  sortAscending: _sortAscending,
                  onSort: _onSortColumn,
                  showBottomBorder: true,
                  colors: colors,
                ),
                for (final row in rows)
                  _PlayerRowCell(
                    height: _dataRowHeight,
                    row: row,
                    playerLabel: _playerLabel(row, l10n),
                    colors: colors,
                    textTheme: textTheme,
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: _headingRowHeight,
                  child: Row(
                    children: [
                      _SortableHeaderCell(
                        width: _presentColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsTrainingsColumnPresent,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsTrainingsSortColumn.present,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                      _SortableHeaderCell(
                        width: _absentColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsTrainingsColumnAbsent,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsTrainingsSortColumn.absent,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                      _SortableHeaderCell(
                        width: _attendanceRateColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsTrainingsColumnAttendanceRate,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsTrainingsSortColumn.attendanceRate,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
                for (final row in rows)
                  SizedBox(
                    height: _dataRowHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: _presentColumnWidth,
                            child: _StatTrendPill(
                              text: '${row.presentCount}',
                              trend: row.trends.present,
                            ),
                          ),
                          SizedBox(
                            width: _absentColumnWidth,
                            child: _StatTrendPill(
                              text: '${row.absentCount}',
                              trend: row.trends.absent,
                            ),
                          ),
                          SizedBox(
                            width: _attendanceRateColumnWidth,
                            child: _StatTrendPill(
                              text: _attendanceRateLabel(l10n, row.attendanceRate),
                              trend: row.trends.attendanceRate,
                            ),
                          ),
                        ],
                      ),
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

class _SortableHeaderCell extends StatelessWidget {
  const _SortableHeaderCell({
    required this.height,
    required this.label,
    required this.labelStyle,
    required this.sortColumn,
    required this.activeSortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.colors,
    this.width,
    this.alignRight = false,
    this.showBottomBorder = false,
  });

  final double? width;
  final double height;
  final String label;
  final TextStyle? labelStyle;
  final TeamStatsTrainingsSortColumn sortColumn;
  final TeamStatsTrainingsSortColumn activeSortColumn;
  final bool sortAscending;
  final ValueChanged<TeamStatsTrainingsSortColumn> onSort;
  final AppColors colors;
  final bool alignRight;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final isSorted = sortColumn == activeSortColumn;

    final content = InkWell(
      onTap: () => onSort(sortColumn),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment:
              alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: alignRight ? TextAlign.right : TextAlign.left,
                style: labelStyle,
              ),
            ),
            if (isSorted) ...[
              const SizedBox(width: 4),
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );

    final cell = width == null
        ? SizedBox(height: height, child: content)
        : SizedBox(width: width, height: height, child: content);

    if (!showBottomBorder) {
      return cell;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: cell,
    );
  }
}

class _PlayerRowCell extends StatelessWidget {
  const _PlayerRowCell({
    required this.height,
    required this.row,
    required this.playerLabel,
    required this.colors,
    required this.textTheme,
  });

  final double height;
  final TeamTrainingPlayerStats row;
  final String playerLabel;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final player = row.player;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              if (player != null)
                PlayerPhoto(player: player, radius: 18)
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.surface,
                  child: Icon(
                    Icons.person_outline,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  playerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
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

class _TrainingPlayerStatsCard extends StatelessWidget {
  const _TrainingPlayerStatsCard({
    required this.row,
    required this.playerLabel,
    required this.attendanceRateLabel,
  });

  final TeamTrainingPlayerStats row;
  final String playerLabel;
  final String attendanceRateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final player = row.player;

    Widget statTile(String label, String value, TeamWdlTrendDirection trend) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _StatTrendPill(
              text: value,
              trend: trend,
              compact: false,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (player != null)
                PlayerPhoto(player: player, radius: 24)
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.background,
                  child: Icon(
                    Icons.person_outline,
                    color: colors.textSecondary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  playerLabel,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              statTile(
                l10n.teamStatsTrainingsColumnPresent,
                '${row.presentCount}',
                row.trends.present,
              ),
              statTile(
                l10n.teamStatsTrainingsColumnAbsent,
                '${row.absentCount}',
                row.trends.absent,
              ),
              statTile(
                l10n.teamStatsTrainingsAttendanceRate,
                attendanceRateLabel,
                row.trends.attendanceRate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTrendPill extends StatelessWidget {
  const _StatTrendPill({
    required this.text,
    required this.trend,
    this.compact = true,
  });

  final String text;
  final TeamWdlTrendDirection trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final Color color = switch (trend) {
      TeamWdlTrendDirection.up => colors.success,
      TeamWdlTrendDirection.down => colors.danger,
      TeamWdlTrendDirection.flat ||
      TeamWdlTrendDirection.insufficientData =>
        colors.textSecondary,
    };

    final pill = Container(
      constraints: BoxConstraints(minWidth: compact ? 48 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (compact ? textTheme.bodySmall : textTheme.titleSmall)?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 12 : 14,
        ),
      ),
    );

    if (compact) {
      return Align(
        alignment: Alignment.centerRight,
        child: pill,
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: pill,
    );
  }
}
