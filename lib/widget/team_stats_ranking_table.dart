import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/ranking.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_ranking_helper.dart';

class TeamStatsRankingTable extends StatelessWidget {
  const TeamStatsRankingTable({
    super.key,
    required this.ranks,
    required this.teamContext,
  });

  final List<Rank> ranks;
  final TeamStatsRankingTeamContext teamContext;

  static const double _rankColumnWidth = 36;
  static const double _teamColumnWidth = 160;
  static const double _statColumnWidth = 40;
  static const double _headingRowHeight = 44;
  static const double _dataRowHeight = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (ranks.isEmpty) {
      return _emptyCard(
        context,
        message: l10n.teamStatsRankingNoData,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: MediaQuery.sizeOf(context).width - 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(l10n, colors, textTheme),
                for (final rank in ranks)
                  _dataRow(
                    rank: rank,
                    isHighlighted: teamContext.matchesRankRow(rank),
                    colors: colors,
                    textTheme: textTheme,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(
    AppLocalizations l10n,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      height: _headingRowHeight,
      color: colors.surface,
      child: Row(
        children: [
          _headerCell(
            l10n.teamStatsRankingColumnRank,
            width: _rankColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnTeam,
            width: _teamColumnWidth,
            colors: colors,
            textTheme: textTheme,
            alignLeft: true,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnPts,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnPlayed,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnWon,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnDrawn,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnLost,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
          _headerCell(
            l10n.teamStatsRankingColumnDiff,
            width: _statColumnWidth,
            colors: colors,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _dataRow({
    required Rank rank,
    required bool isHighlighted,
    required AppColors colors,
    required TextTheme textTheme,
  }) {
    final backgroundColor = isHighlighted
        ? colors.primary.withValues(alpha: 0.12)
        : colors.card;
    final textColor = isHighlighted ? colors.primary : colors.textPrimary;

    return Container(
      height: _dataRowHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: colors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          _valueCell(
            rank.rang ?? '—',
            width: _rankColumnWidth,
            color: textColor,
            textTheme: textTheme,
            bold: isHighlighted,
          ),
          _valueCell(
            rank.team ?? '—',
            width: _teamColumnWidth,
            color: textColor,
            textTheme: textTheme,
            alignLeft: true,
            bold: isHighlighted,
          ),
          _valueCell(
            rank.pts ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
            bold: isHighlighted,
          ),
          _valueCell(
            rank.jo ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
          ),
          _valueCell(
            rank.g ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
          ),
          _valueCell(
            rank.n ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
          ),
          _valueCell(
            rank.p ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
          ),
          _valueCell(
            rank.diff ?? '—',
            width: _statColumnWidth,
            color: textColor,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
    String label, {
    required double width,
    required AppColors colors,
    required TextTheme textTheme,
    bool alignLeft = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: alignLeft ? 12 : 4,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignLeft ? TextAlign.start : TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _valueCell(
    String value, {
    required double width,
    required Color color,
    required TextTheme textTheme,
    bool alignLeft = false,
    bool bold = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: alignLeft ? 12 : 4,
        ),
        child: Text(
          value,
          maxLines: alignLeft ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignLeft ? TextAlign.start : TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _emptyCard(BuildContext context, {required String message}) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
