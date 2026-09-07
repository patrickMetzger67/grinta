import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/manager_cards_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/manager_team_cards_sheet.dart';
import 'package:provider/provider.dart';

/// Coach/manager disciplinary cards entry on Agenda / Dashboard.
///
/// Shown whenever the user manages ≥1 team for the selected season (including
/// when the non-purged count is 0). Badge = non-purged total across managed
/// team rosters when that total is > 0.
///
/// Tap: one managed team → team Cartons list; several → pick team then list.
class ManagerCardsEntryButton extends StatefulWidget {
  const ManagerCardsEntryButton({
    super.key,
    this.compact = false,
    this.bottomSpacing = 0,
    this.cardsService,
    this.teamPlayersService,
  });

  final bool compact;

  /// Applied under the non-compact (dashboard) entry when it is visible.
  final double bottomSpacing;

  final CardsService? cardsService;
  final TeamPlayersService? teamPlayersService;

  @override
  State<ManagerCardsEntryButton> createState() =>
      _ManagerCardsEntryButtonState();
}

class _ManagerCardsEntryButtonState extends State<ManagerCardsEntryButton> {
  String _teamsSignature = '';
  Future<_ManagerCardsBadgeData>? _badgeFuture;

  Future<_ManagerCardsBadgeData> _loadBadge(List<Team> managedTeams) async {
    final playersService =
        widget.teamPlayersService ?? TeamPlayersService();
    final cardsService = widget.cardsService ?? CardsService.instance;

    final memberIds = <String>{};
    for (final team in managedTeams) {
      final teamId = team.keyTeam?.trim() ?? '';
      if (teamId.isEmpty) continue;
      try {
        final players = await playersService.loadPlayers(teamId: teamId);
        for (final Player player in players) {
          final id = effectiveMemberId(player)?.trim() ?? '';
          if (id.isNotEmpty) memberIds.add(id);
        }
      } catch (_) {
        // Skip team on load failure; others still contribute to the badge.
      }
    }

    if (memberIds.isEmpty) {
      return const _ManagerCardsBadgeData(nonPurgedCount: 0);
    }

    final cards = await cardsService.getByMemberIds(memberIds);
    final cardsByMemberId = <String, PlayerCards?>{
      for (final id in memberIds) id: cards[id],
    };
    return _ManagerCardsBadgeData(
      nonPurgedCount: countNonPurgedCardsAcrossMembers(cardsByMemberId),
    );
  }

  void _ensureBadgeFuture(List<Team> managedTeams) {
    final signature = managedTeams
        .map((t) => t.keyTeam?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .join('|');
    if (_badgeFuture != null && signature == _teamsSignature) {
      return;
    }
    _teamsSignature = signature;
    _badgeFuture = _loadBadge(managedTeams);
  }

  Future<void> _open(BuildContext context, List<Team> managedTeams) async {
    final plan = ManagerCardsOpenPlan.fromManagedTeams(managedTeams);
    switch (plan.mode) {
      case ManagerCardsOpenMode.none:
        return;
      case ManagerCardsOpenMode.singleTeam:
        final team = plan.singleTeam;
        if (team == null) return;
        context.read<AppSession>().setSelectedManagedTeamId(team.keyTeam);
        await showManagerTeamCardsSheet(
          context,
          team: team,
          cardsService: widget.cardsService,
          teamPlayersService: widget.teamPlayersService,
        );
        if (mounted) {
          setState(() {
            _teamsSignature = '';
            _badgeFuture = null;
          });
        }
        return;
      case ManagerCardsOpenMode.pickTeam:
        final selected = await showManagedTeamPickerSheet(
          context,
          teams: plan.teams,
        );
        if (selected == null || !context.mounted) return;
        context.read<AppSession>().setSelectedManagedTeamId(selected.keyTeam);
        await showManagerTeamCardsSheet(
          context,
          team: selected,
          cardsService: widget.cardsService,
          teamPlayersService: widget.teamPlayersService,
        );
        if (mounted) {
          setState(() {
            _teamsSignature = '';
            _badgeFuture = null;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final managedTeams = session.managerTeamsForSelectedSeason;
    final managedIds = session.managedTeamsIdsForSelectedSeason;

    if (!shouldShowManagerCardsEntry(managedTeamIds: managedIds) ||
        managedTeams.isEmpty) {
      return const SizedBox.shrink();
    }

    _ensureBadgeFuture(managedTeams);

    return FutureBuilder<_ManagerCardsBadgeData>(
      future: _badgeFuture,
      builder: (context, snapshot) {
        final nonPurgedCount = snapshot.data?.nonPurgedCount ?? 0;
        return ManagerCardsEntryContent(
          compact: widget.compact,
          bottomSpacing: widget.bottomSpacing,
          nonPurgedCount: nonPurgedCount,
          onPressed: () => unawaited(_open(context, managedTeams)),
        );
      },
    );
  }
}

/// Presentational chrome for [ManagerCardsEntryButton].
///
/// Always renders the entry; [nonPurgedCount] only drives the badge.
@visibleForTesting
class ManagerCardsEntryContent extends StatelessWidget {
  const ManagerCardsEntryContent({
    super.key,
    required this.nonPurgedCount,
    required this.onPressed,
    this.compact = false,
    this.bottomSpacing = 0,
  });

  final int nonPurgedCount;
  final VoidCallback onPressed;
  final bool compact;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final showBadge = shouldShowManagerCardsBadge(
      nonPurgedCount: nonPurgedCount,
    );
    final icon = _ManagerCardsCountBadge(
      count: showBadge ? nonPurgedCount : 0,
      iconColor: colors.warning,
    );

    if (compact) {
      return IconButton(
        key: const Key('manager-cards-entry-compact'),
        tooltip: l10n.managerCardsTooltip,
        onPressed: onPressed,
        icon: icon,
      );
    }

    return Padding(
      key: const Key('manager-cards-entry'),
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.warning.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.managerCardsTitle,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerCardsBadgeData {
  const _ManagerCardsBadgeData({required this.nonPurgedCount});

  final int nonPurgedCount;
}

class _ManagerCardsCountBadge extends StatelessWidget {
  const _ManagerCardsCountBadge({
    required this.count,
    required this.iconColor,
  });

  final int count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      Icons.style_rounded,
      color: iconColor,
      size: 24,
    );

    if (count <= 0) {
      return iconWidget;
    }

    final colors = context.appColors;
    final label = count > 99 ? '99+' : '$count';

    return Badge(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: colors.warning,
      child: iconWidget,
    );
  }
}
