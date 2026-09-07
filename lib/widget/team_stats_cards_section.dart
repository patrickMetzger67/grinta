import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/highlight_type_icons.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/team_stats_cards_helper.dart';
import 'package:grinta/widget/playerPhoto.dart';
import 'package:grinta/widget/team_stats_player_cards_sheet.dart';
import 'package:grinta/model/highlights.dart';

/// Team Stats → Analyse → Cartons: per-player card counts for the team roster.
class TeamStatsCardsSection extends StatefulWidget {
  const TeamStatsCardsSection({
    super.key,
    required this.team,
    required this.isManager,
    this.teamPlayersService,
    this.cardsService,
  });

  final Team team;
  final bool isManager;
  final TeamPlayersService? teamPlayersService;
  final CardsService? cardsService;

  @override
  State<TeamStatsCardsSection> createState() => _TeamStatsCardsSectionState();
}

class _TeamStatsCardsSectionState extends State<TeamStatsCardsSection> {
  bool _loading = true;
  Object? _error;

  /// Default: non-purged only (`isPurged != true`).
  bool _includePurged = false;

  List<Player> _players = const [];
  Map<String, PlayerCards?> _cardsByMemberId = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TeamStatsCardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.team.keyTeam != widget.team.keyTeam) {
      _load();
    }
  }

  Future<void> _load() async {
    final teamId = widget.team.keyTeam?.trim() ?? '';
    if (teamId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _players = const [];
        _cardsByMemberId = const {};
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final playersService =
          widget.teamPlayersService ?? TeamPlayersService();
      final cardsService = widget.cardsService ?? CardsService.instance;

      final players = await playersService.loadPlayers(teamId: teamId);
      final memberIds = players
          .map((player) => effectiveMemberId(player)?.trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      final cards = await cardsService.getByMemberIds(memberIds);
      final cardsByMemberId = <String, PlayerCards?>{
        for (final id in memberIds) id: cards[id],
      };

      if (!mounted) return;
      setState(() {
        _players = players;
        _cardsByMemberId = cardsByMemberId;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<TeamStatsPlayerCardsRow> _rows() {
    return buildTeamStatsCardsRows(
      players: _players,
      cardsByMemberId: _cardsByMemberId,
      includePurged: _includePurged,
      unknownPlayerLabel: context.l10n.entityPlayer,
    );
  }

  void _openPlayer(TeamStatsPlayerCardsRow row) {
    final allEntries =
        _cardsByMemberId[row.memberId]?.entries ?? row.entries;
    unawaited(
      showTeamStatsPlayerCardsSheet(
        context,
        memberId: row.memberId,
        playerName: row.displayName,
        entries: allEntries,
        isManager: widget.isManager,
        cardsService: widget.cardsService,
        onChanged: () => unawaited(_load()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.teamStatsCardsLoadError(_error.toString()),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.danger),
        ),
      );
    }

    final rows = _rows();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: Text(l10n.teamStatsCardsIncludePurged),
            selected: _includePurged,
            showCheckmark: true,
            checkmarkColor: colors.primary,
            selectedColor: colors.primary.withValues(alpha: 0.18),
            side: BorderSide(
              color: _includePurged ? colors.primary : colors.border,
            ),
            labelStyle: TextStyle(
              color: _includePurged ? colors.primary : colors.textPrimary,
            ),
            onSelected: (selected) {
              setState(() => _includePurged = selected);
            },
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.teamStatsCardsEmpty,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          )
        else
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TeamStatsCardsPlayerTile(
                row: row,
                onTap: () => _openPlayer(row),
              ),
            );
          }),
      ],
    );
  }
}

class _TeamStatsCardsPlayerTile extends StatelessWidget {
  const _TeamStatsCardsPlayerTile({
    required this.row,
    required this.onTap,
  });

  final TeamStatsPlayerCardsRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final yellowCount = row.entries
        .where((e) => parsePlayerCardType(e.type) == playerCardTypeYellow)
        .length;
    final redCount = row.entries
        .where((e) => parsePlayerCardType(e.type) == playerCardTypeRed)
        .length;

    final yellowStyle =
        HighlightTypeIcons.forActionType(context, ActionType.yellowCard);
    final redStyle =
        HighlightTypeIcons.forActionType(context, ActionType.redCard);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              PlayerPhoto(player: row.player, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.teamStatsCardsCount(row.count),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (yellowCount > 0) ...[
                HighlightTypeIconBadge(style: yellowStyle),
                const SizedBox(width: 4),
                Text(
                  '$yellowCount',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (redCount > 0) ...[
                HighlightTypeIconBadge(style: redStyle),
                const SizedBox(width: 4),
                Text(
                  '$redCount',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
