import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';

/// Probable starting XI and bench for an opponent, from aggregated matchStats.
class TeamStatsTypicalTeamSection extends StatelessWidget {
  const TeamStatsTypicalTeamSection({
    super.key,
    required this.result,
  });

  final TypicalTeamResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (!result.hasSquadData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            l10n.teamStatsTypicalTeamNoData,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BasisBanner(
          label: l10n.teamStatsTypicalTeamMatchesBasis(result.matchesWithSquadData),
        ),
        const SizedBox(height: 16),
        _PlayerGroupCard(
          title: l10n.teamStatsTypicalTeamStartersSection,
          players: result.probableStarters,
          useTitularCounts: true,
          statLabelBuilder: (player) => l10n.teamStatsTypicalTeamStartsLabel(
            player.titularCount,
            player.matchesWithSquadData,
          ),
          footer: result.probableStarters.length < 11
              ? l10n.teamStatsTypicalTeamIncompleteStarters(
                  result.probableStarters.length,
                )
              : null,
        ),
        const SizedBox(height: 16),
        if (result.probableSubstitutes.isNotEmpty)
          _PlayerGroupCard(
            title: l10n.teamStatsTypicalTeamSubstitutesSection,
            players: result.probableSubstitutes,
            useTitularCounts: false,
            statLabelBuilder: (player) => l10n.teamStatsTypicalTeamSubsLabel(
              player.substituteCount,
              player.matchesWithSquadData,
            ),
          ),
      ],
    );
  }
}

class _BasisBanner extends StatelessWidget {
  const _BasisBanner({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerGroupCard extends StatelessWidget {
  const _PlayerGroupCard({
    required this.title,
    required this.players,
    required this.useTitularCounts,
    required this.statLabelBuilder,
    this.footer,
  });

  final String title;
  final List<TypicalTeamPlayerEntry> players;
  final bool useTitularCounts;
  final String Function(TypicalTeamPlayerEntry player) statLabelBuilder;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Divider(height: 1, color: colors.border),
          for (var i = 0; i < players.length; i++) ...[
            _TypicalTeamPlayerRow(
              player: players[i],
              useTitularCounts: useTitularCounts,
              statLabel: statLabelBuilder(players[i]),
            ),
            if (i < players.length - 1)
              Divider(height: 1, indent: 16, endIndent: 16, color: colors.border),
          ],
          if (footer != null) ...[
            Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Text(
                footer!,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypicalTeamPlayerRow extends StatelessWidget {
  const _TypicalTeamPlayerRow({
    required this.player,
    required this.useTitularCounts,
    required this.statLabel,
  });

  final TypicalTeamPlayerEntry player;
  final bool useTitularCounts;
  final String statLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final breakdown =
        player.shirtBreakdownLabel(useTitularCounts: useTitularCounts);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _ShirtBadge(number: player.shirtNumber, colors: colors, textTheme: textTheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (breakdown != null)
                  Text(
                    breakdown,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TrendIcon(trend: player.titularTrend, l10n: l10n, colors: colors),
          const SizedBox(width: 8),
          _StatPill(text: statLabel, colors: colors, textTheme: textTheme),
        ],
      ),
    );
  }
}

class _ShirtBadge extends StatelessWidget {
  const _ShirtBadge({
    required this.number,
    required this.colors,
    required this.textTheme,
  });

  final int? number;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final label = number?.toString() ?? '—';

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({
    required this.trend,
    required this.l10n,
    required this.colors,
  });

  final TeamWdlTrendDirection trend;
  final AppLocalizations l10n;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (trend == TeamWdlTrendDirection.insufficientData) {
      return const SizedBox.shrink();
    }

    final (IconData icon, Color color, String tooltip) = switch (trend) {
      TeamWdlTrendDirection.up => (
          Icons.trending_up,
          colors.success,
          l10n.teamStatsTrendUp,
        ),
      TeamWdlTrendDirection.down => (
          Icons.trending_down,
          colors.danger,
          l10n.teamStatsTrendDown,
        ),
      TeamWdlTrendDirection.flat => (
          Icons.trending_flat,
          colors.textSecondary,
          l10n.teamStatsTrendFlat,
        ),
      TeamWdlTrendDirection.insufficientData => (
          Icons.trending_flat,
          colors.textSecondary,
          l10n.teamStatsTrendInsufficientData,
        ),
    };

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.text,
    required this.colors,
    required this.textTheme,
  });

  final String text;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
