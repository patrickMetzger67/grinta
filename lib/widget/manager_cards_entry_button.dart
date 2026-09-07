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
/// Shown **immediately** whenever the user manages ≥1 team for the selected
/// season (sync [AppSession] check) — does **not** wait for roster or Firestore
/// cards. Badge count loads asynchronously; until it arrives the entry renders
/// without a numeric badge (optional subtle loading). Zero cards keep the
/// entry visible (badge only).
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
  int _loadGeneration = 0;

  /// Null while the first badge load for the current teams signature is
  /// in flight; then the non-purged total (may be 0).
  int? _nonPurgedCount;
  bool _badgeLoading = false;

  Future<int> _loadNonPurgedCount(List<Team> managedTeams) async {
    final playersService =
        widget.teamPlayersService ?? TeamPlayersService();
    final cardsService = widget.cardsService ?? CardsService.instance;

    final teamIds = managedTeams
        .map((t) => t.keyTeam?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (teamIds.isEmpty) {
      return 0;
    }

    // Parallel roster loads — sequential awaits were the main badge delay.
    final rosterResults = await Future.wait(
      teamIds.map((teamId) async {
        try {
          return await playersService.loadPlayers(teamId: teamId);
        } catch (_) {
          return const <Player>[];
        }
      }),
    );

    final memberIds = <String>{};
    for (final players in rosterResults) {
      for (final Player player in players) {
        final id = effectiveMemberId(player)?.trim() ?? '';
        if (id.isNotEmpty) memberIds.add(id);
      }
    }

    if (memberIds.isEmpty) {
      return 0;
    }

    final cards = await cardsService.getByMemberIds(memberIds);
    final cardsByMemberId = <String, PlayerCards?>{
      for (final id in memberIds) id: cards[id],
    };
    return countNonPurgedCardsAcrossMembers(cardsByMemberId);
  }

  void _syncBadgeLoad(List<Team> managedTeams) {
    final signature = managedTeams
        .map((t) => t.keyTeam?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .join('|');
    if (signature == _teamsSignature) {
      return;
    }

    final previousSignature = _teamsSignature;
    _teamsSignature = signature;
    final generation = ++_loadGeneration;

    // After sheet close we clear the signature only ([_invalidateBadge]) so the
    // next sync can refresh while keeping the last badge (no flicker). A real
    // teams change clears the badge until the new count arrives.
    final keepPreviousCount =
        previousSignature.isEmpty && _nonPurgedCount != null;
    _badgeLoading = true;
    if (!keepPreviousCount) {
      _nonPurgedCount = null;
    }

    unawaited(() async {
      final count = await _loadNonPurgedCount(managedTeams);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _nonPurgedCount = count;
        _badgeLoading = false;
      });
    }());
  }

  void _invalidateBadge() {
    _teamsSignature = '';
    // Keep last known count visible until the next load completes.
    _badgeLoading = true;
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
          setState(_invalidateBadge);
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
          setState(_invalidateBadge);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final managedTeams = session.managerTeamsForSelectedSeason;
    final managedIds = session.managedTeamsIdsForSelectedSeason;

    // Visibility is sync-only from AppSession — never gated on cards/roster.
    if (!shouldShowManagerCardsEntry(managedTeamIds: managedIds)) {
      return const SizedBox.shrink();
    }

    // Teams list may still be catching up; still show the entry chrome.
    if (managedTeams.isNotEmpty) {
      _syncBadgeLoad(managedTeams);
    }

    return ManagerCardsEntryContent(
      compact: widget.compact,
      bottomSpacing: widget.bottomSpacing,
      nonPurgedCount: _nonPurgedCount ?? 0,
      isBadgeLoading: _badgeLoading && _nonPurgedCount == null,
      onPressed: managedTeams.isEmpty
          ? () {}
          : () => unawaited(_open(context, managedTeams)),
    );
  }
}

/// Presentational chrome for [ManagerCardsEntryButton].
///
/// Always renders the entry; [nonPurgedCount] / [isBadgeLoading] only drive
/// the badge affordance.
@visibleForTesting
class ManagerCardsEntryContent extends StatelessWidget {
  const ManagerCardsEntryContent({
    super.key,
    required this.nonPurgedCount,
    required this.onPressed,
    this.compact = false,
    this.bottomSpacing = 0,
    this.isBadgeLoading = false,
  });

  final int nonPurgedCount;
  final VoidCallback onPressed;
  final bool compact;
  final double bottomSpacing;

  /// True while the first badge count is still loading (no number yet).
  final bool isBadgeLoading;

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
      isLoading: isBadgeLoading,
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

class _ManagerCardsCountBadge extends StatelessWidget {
  const _ManagerCardsCountBadge({
    required this.count,
    required this.iconColor,
    this.isLoading = false,
  });

  final int count;
  final Color iconColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      Icons.style_rounded,
      color: iconColor,
      size: 24,
    );

    if (isLoading) {
      return SizedBox(
        key: const Key('manager-cards-badge-loading'),
        width: 24,
        height: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            iconWidget,
            Positioned(
              right: 0,
              top: 0,
              child: SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: iconColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }

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
