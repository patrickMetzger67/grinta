import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_cards_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/player_cards_sheet.dart';
import 'package:provider/provider.dart';

/// Player-side disciplinary cards indicator (badge = non-purged count).
///
/// Hidden when the selected player has no non-purged cards. Coach restitution
/// is intentionally not implemented yet.
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
    final memberId = _memberId(session);
    if (memberId == null) {
      return const SizedBox.shrink();
    }

    final service = cardsService ?? CardsService.instance;

    return StreamBuilder<PlayerCards?>(
      stream: service.streamByMemberId(memberId),
      builder: (context, snapshot) {
        final entries = snapshot.data?.entries ?? const <PlayerCardEntry>[];
        final nonPurgedCount = countNonPurgedPlayerCards(entries);
        if (nonPurgedCount <= 0) {
          return const SizedBox.shrink();
        }

        final colors = context.appColors;
        final l10n = context.l10n;
        final icon = _CardsCountBadge(
          count: nonPurgedCount,
          iconColor: colors.warning,
        );

        if (compact) {
          return IconButton(
            tooltip: l10n.playerCardsTooltip,
            onPressed: () => unawaited(_open(context, entries)),
            icon: icon,
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: bottomSpacing),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => unawaited(_open(context, entries)),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      },
    );
  }
}

class _CardsCountBadge extends StatelessWidget {
  const _CardsCountBadge({
    required this.count,
    required this.iconColor,
  });

  final int count;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    // Same layout as [NavIconCountBadge], but warning-colored for cards.
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
