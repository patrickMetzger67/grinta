import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/team_player_stats_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/playerPhoto.dart';

enum TeamStatsPlayersSortColumn {
  player,
  convocations,
  starts,
  playTime,
  goals,
}

class TeamStatsPlayersTable extends StatefulWidget {
  const TeamStatsPlayersTable({
    super.key,
    required this.stats,
    this.visiblePlayerId,
  });

  final List<TeamPlayerSeasonStats> stats;
  final String? visiblePlayerId;

  @override
  State<TeamStatsPlayersTable> createState() => _TeamStatsPlayersTableState();
}

class _TeamStatsPlayersTableState extends State<TeamStatsPlayersTable> {
  static const double _playerColumnWidth = 180;
  static const double _headingRowHeight = 48;
  static const double _dataRowHeight = 56;
  static const double _convocationsColumnWidth = 64;
  static const double _startsColumnWidth = 64;
  static const double _playTimeColumnWidth = 88;
  static const double _goalsColumnWidth = 64;

  TeamStatsPlayersSortColumn _sortColumn = TeamStatsPlayersSortColumn.player;
  bool _sortAscending = true;

  List<TeamPlayerSeasonStats> get _visibleStats {
    final playerId = widget.visiblePlayerId?.trim();
    if (playerId == null || playerId.isEmpty) {
      return widget.stats;
    }
    return widget.stats
        .where((row) => row.playerId == playerId)
        .toList(growable: false);
  }

  void _onSortColumn(TeamStatsPlayersSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<TeamPlayerSeasonStats> _sortedRows(AppLocalizations l10n) {
    final rows = List<TeamPlayerSeasonStats>.from(_visibleStats);

    rows.sort((a, b) {
      int result = 0;

      switch (_sortColumn) {
        case TeamStatsPlayersSortColumn.player:
          result = _compareText(
            playerSortKey(a),
            playerSortKey(b),
          );
          break;
        case TeamStatsPlayersSortColumn.convocations:
          result = a.convocations.compareTo(b.convocations);
          break;
        case TeamStatsPlayersSortColumn.starts:
          result = a.starts.compareTo(b.starts);
          break;
        case TeamStatsPlayersSortColumn.playTime:
          result = a.minutesPlayed.compareTo(b.minutesPlayed);
          break;
        case TeamStatsPlayersSortColumn.goals:
          result = a.goals.compareTo(b.goals);
          break;
      }

      if (result == 0 && _sortColumn != TeamStatsPlayersSortColumn.player) {
        result = _compareText(
          playerSortKey(a),
          playerSortKey(b),
        );
      }

      return _sortAscending ? result : -result;
    });

    return rows;
  }

  /// Sort key that works for roster ids and matchStats name-based keys.
  static String playerSortKey(TeamPlayerSeasonStats row) {
    final player = row.player;
    if (player != null) {
      final lastName = (player.lastName ?? '').trim().toLowerCase();
      final firstName = (player.firstName ?? '').trim().toLowerCase();
      if (lastName.isNotEmpty || firstName.isNotEmpty) {
        return '$lastName\t$firstName';
      }
    }

    return row.playerId.trim().toLowerCase();
  }

  int _compareText(String a, String b) {
    return a.compareTo(b);
  }

  String _playerLabel(TeamPlayerSeasonStats row, AppLocalizations l10n) {
    final externalName = row.displayName?.trim();
    if (externalName != null && externalName.isNotEmpty) {
      return externalName;
    }

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

  String _playTimeLabel(AppLocalizations l10n, int minutes) {
    return l10n.teamStatsPlayersPlayTimeMinutes(minutes);
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
            l10n.teamStatsPlayersNoData,
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
      return _PlayerStatsCard(
        row: rows.first,
        playerLabel: _playerLabel(rows.first, l10n),
        playTimeLabel: _playTimeLabel(l10n, rows.first.minutesPlayed),
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
                  sortColumn: TeamStatsPlayersSortColumn.player,
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
                        width: _convocationsColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsPlayersColumnConvocations,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsPlayersSortColumn.convocations,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                      _SortableHeaderCell(
                        width: _startsColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsPlayersColumnStarts,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsPlayersSortColumn.starts,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                      _SortableHeaderCell(
                        width: _playTimeColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsPlayersColumnPlayTime,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsPlayersSortColumn.playTime,
                        activeSortColumn: _sortColumn,
                        sortAscending: _sortAscending,
                        onSort: _onSortColumn,
                        alignRight: true,
                        showBottomBorder: true,
                        colors: colors,
                      ),
                      _SortableHeaderCell(
                        width: _goalsColumnWidth,
                        height: _headingRowHeight,
                        label: l10n.teamStatsPlayersColumnGoals,
                        labelStyle: headerStyle,
                        sortColumn: TeamStatsPlayersSortColumn.goals,
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
                            width: _convocationsColumnWidth,
                            child: _StatTrendPill(
                              text: '${row.convocations}',
                              trend: row.trends.convocations,
                            ),
                          ),
                          SizedBox(
                            width: _startsColumnWidth,
                            child: _StatTrendPill(
                              text: '${row.starts}',
                              trend: row.trends.starts,
                            ),
                          ),
                          SizedBox(
                            width: _playTimeColumnWidth,
                            child: _StatTrendPill(
                              text: _playTimeLabel(l10n, row.minutesPlayed),
                              trend: row.trends.playTime,
                            ),
                          ),
                          SizedBox(
                            width: _goalsColumnWidth,
                            child: _StatTrendPill(
                              text: '${row.goals}',
                              trend: row.trends.goals,
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
  final TeamStatsPlayersSortColumn sortColumn;
  final TeamStatsPlayersSortColumn activeSortColumn;
  final bool sortAscending;
  final ValueChanged<TeamStatsPlayersSortColumn> onSort;
  final AppColors colors;
  final bool alignRight;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final isSorted = sortColumn == activeSortColumn;

    final content = InkWell(
      onTap: () => onSort(sortColumn),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: alignRight ? 8 : 8,
          vertical: 12,
        ),
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
  final TeamPlayerSeasonStats row;
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

class _PlayerStatsCard extends StatelessWidget {
  const _PlayerStatsCard({
    required this.row,
    required this.playerLabel,
    required this.playTimeLabel,
  });

  final TeamPlayerSeasonStats row;
  final String playerLabel;
  final String playTimeLabel;

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
                l10n.teamStatsPlayersColumnConvocations,
                '${row.convocations}',
                row.trends.convocations,
              ),
              statTile(
                l10n.teamStatsPlayersColumnStarts,
                '${row.starts}',
                row.trends.starts,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              statTile(
                l10n.teamStatsPlayersColumnPlayTime,
                playTimeLabel,
                row.trends.playTime,
              ),
              statTile(
                l10n.teamStatsPlayersColumnGoals,
                '${row.goals}',
                row.trends.goals,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Colored pill for a stat value, styled like tracker z-score badges.
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
