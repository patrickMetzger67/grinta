import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/manager_cards_helper.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/player_cards_sheet.dart';
import 'package:provider/provider.dart';

/// Player-side disciplinary cards indicator (badge = non-purged count).
///
/// Shown as soon as the selected player's member id is known (does not wait
/// for the first Firestore stream event). While the count is loading the
/// entry appears without a badge; once the stream delivers data, a badge is
/// shown if non-purged > 0, otherwise the entry is hidden.
///
/// Hidden for pure managers/coaches (no non-managed member teams). Dual-role
/// users keep this entry; coaches use [ManagerCardsEntryButton] for team
/// restitution.
class PlayerCardsEntryButton extends StatelessWidget {
  const PlayerCardsEntryButton({
    super.key,
    this.compact = false,
    this.bottomSpacing = 0,
    this.cardsService,
  });

  final bool compact;

  /// Applied under the non-compact (dashboard) entry when it is visible.
  final double bottomSpacing;

  final CardsService? cardsService;

  String? _memberId(AppSession session) {
    final player = session.selectedPlayer;
    if (player == null) return null;
    final memberId = effectiveMemberId(player)?.trim() ?? '';
    return memberId.isEmpty ? null : memberId;
  }

  Future<void> _open(BuildContext context, List<PlayerCardEntry> entries) {
    return showPlayerCardsSheet(context, entries: entries);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final managedIds = session.managedTeamsIdsForSelectedSeason;
    final memberIds = session.memberTeamsForSelectedSeason
        .map((team) => team.keyTeam?.trim() ?? '')
        .where((id) => id.isNotEmpty);
    if (!shouldShowPlayerCardsEntry(
      managedTeamIds: managedIds,
      memberTeamIds: memberIds,
    )) {
      return const SizedBox.shrink();
    }

    final memberId = _memberId(session);
    if (memberId == null) {
      return const SizedBox.shrink();
    }

    final service = cardsService ?? CardsService.instance;

    return StreamBuilder<PlayerCards?>(
      stream: service.streamByMemberId(memberId),
      builder: (context, snapshot) {
        final waitingForFirstEvent =
            snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData &&
                !snapshot.hasError;

        // Instant chrome while the stream has not delivered yet.
        if (waitingForFirstEvent) {
          return PlayerCardsEntryContent(
            compact: compact,
            bottomSpacing: bottomSpacing,
            nonPurgedCount: 0,
            isBadgeLoading: true,
            onPressed: () {},
          );
        }

        final entries = snapshot.data?.entries ?? const <PlayerCardEntry>[];
        final nonPurgedCount = countNonPurgedPlayerCards(entries);
        if (nonPurgedCount <= 0) {
          return const SizedBox.shrink();
        }

        return PlayerCardsEntryContent(
          compact: compact,
          bottomSpacing: bottomSpacing,
          nonPurgedCount: nonPurgedCount,
          onPressed: () => unawaited(_open(context, entries)),
        );
      },
    );
  }
}

/// Presentational chrome for [PlayerCardsEntryButton].
@visibleForTesting
class PlayerCardsEntryContent extends StatelessWidget {
  const PlayerCardsEntryContent({
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
  final bool isBadgeLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final icon = _CardsCountBadge(
      count: nonPurgedCount,
      iconColor: colors.warning,
      isLoading: isBadgeLoading,
    );

    if (compact) {
      return IconButton(
        key: const Key('player-cards-entry-compact'),
        tooltip: l10n.playerCardsTooltip,
        onPressed: onPressed,
        icon: icon,
      );
    }

    return Padding(
      key: const Key('player-cards-entry'),
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
                    l10n.playerCardsTitle,
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

class _CardsCountBadge extends StatelessWidget {
  const _CardsCountBadge({
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
        key: const Key('player-cards-badge-loading'),
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
