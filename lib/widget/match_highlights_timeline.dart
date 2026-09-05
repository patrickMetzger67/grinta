import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';

import '../util/app_theme.dart';
import '../model/matchStats.dart';
import '../util/player_cards_helper.dart';

class MatchHighlightsTimeline extends StatelessWidget {
  final MatchStats? matchStats;
  final List<MatchStatHighLight>? highlights;

  /// Équipe à gauche dans la timeline.
  final String? team1;

  /// Équipe à droite dans la timeline.
  final String? team2;

  final bool showStartAndEnd;

  /// Manager-only: tap a card-type FMI highlight to assign a convoked player.
  final ValueChanged<MatchStatHighLight>? onCardHighlightTap;

  const MatchHighlightsTimeline({
    super.key,
    this.matchStats,
    this.highlights,
    this.team1,
    this.team2,
    this.showStartAndEnd = true,
    this.onCardHighlightTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final items = List<MatchStatHighLight>.from(
      highlights ?? matchStats?.highlights ?? [],
    )..sort((a, b) => (a.time ?? 0).compareTo(b.time ?? 0));

    if (items.isEmpty) {
      return _TimelineEmptyState(
        title: context.l10n.emptyNoHighlights,
        message: context.l10n.emptyNoHighlightsMessage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 560;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 12 : 16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              if (showStartAndEnd) ...[
                _TimelineMatchMarker(
                  label: context.l10n.highlightKickoff,
                  icon: Icons.play_arrow_rounded,
                  color: colors.primary,
                ),
                const SizedBox(height: 8),
              ],

              for (int index = 0; index < items.length; index++)
                _FootballTimelineItem(
                  highlight: items[index],
                  team1: team1,
                  team2: team2,
                  isFirst: index == 0,
                  isLast: index == items.length - 1,
                  compact: compact,
                  onCardTap: onCardHighlightTap != null &&
                          isFmiCardHighlight(items[index])
                      ? () => onCardHighlightTap!(items[index])
                      : null,
                ),

              if (showStartAndEnd) ...[
                const SizedBox(height: 8),
                _TimelineMatchMarker(
                  label: context.l10n.highlightFullTime,
                  icon: Icons.sports_score_rounded,
                  color: colors.textSecondary,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FootballTimelineItem extends StatelessWidget {
  final MatchStatHighLight highlight;
  final String? team1;
  final String? team2;
  final bool isFirst;
  final bool isLast;
  final bool compact;
  final VoidCallback? onCardTap;

  const _FootballTimelineItem({
    required this.highlight,
    required this.team1,
    required this.team2,
    required this.isFirst,
    required this.isLast,
    required this.compact,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final eventStyle = _HighlightStyle.fromType(
      context,
      highlight.type,
    );

    final bool isLeft = _isTeam1Event(
      highlight.team,
      team1,
      team2,
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CompactTimelineAxis(
              minute: highlight.time ?? 0,
              icon: eventStyle.icon,
              color: eventStyle.color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _HighlightCard(
                highlight: highlight,
                style: eventStyle,
                alignRight: false,
                onTap: onCardTap,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: isLeft
                ? Align(
                    alignment: Alignment.topRight,
                    child: _HighlightCard(
                      highlight: highlight,
                      style: eventStyle,
                      alignRight: true,
                      onTap: onCardTap,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          _TimelineAxis(
            minute: highlight.time ?? 0,
            icon: eventStyle.icon,
            color: eventStyle.color,
            showTopLine: !isFirst,
            showBottomLine: !isLast,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: !isLeft
                ? Align(
                    alignment: Alignment.topLeft,
                    child: _HighlightCard(
                      highlight: highlight,
                      style: eventStyle,
                      alignRight: false,
                      onTap: onCardTap,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isTeam1Event(String? eventTeam, String? firstTeam, String? secondTeam) {
    final event = _normalize(eventTeam);
    final left = _normalize(firstTeam);
    final right = _normalize(secondTeam);

    if (event.isEmpty) return true;
    if (left.isNotEmpty && event == left) return true;
    if (right.isNotEmpty && event == right) return false;

    return true;
  }
}

class _HighlightCard extends StatelessWidget {
  final MatchStatHighLight highlight;
  final _HighlightStyle style;
  final bool alignRight;
  final VoidCallback? onTap;

  const _HighlightCard({
    required this.highlight,
    required this.style,
    required this.alignRight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final title = _titleForType(context.l10n, highlight.type);
    final description = _descriptionForHighlight(context.l10n, highlight);
    final team = _clean(highlight.team);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: style.color.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (!alignRight) ...[
                _EventIcon(
                  icon: style.icon,
                  color: style.color,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  textAlign: alignRight ? TextAlign.right : TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ],
              if (alignRight) ...[
                const SizedBox(width: 8),
                _EventIcon(
                  icon: style.icon,
                  color: style.color,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            softWrap: true,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (team.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment:
                  alignRight ? Alignment.centerRight : Alignment.centerLeft,
              heightFactor: 1,
              child: _TeamChip(
                team: team,
                color: style.color,
              ),
            ),
          ],
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 330),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: content,
              ),
            ),
    );
  }

  String _titleForType(AppLocalizations l10n, String? type) {
    switch (_normalize(type)) {
      case 'goal':
      case 'but':
        return l10n.highlightTypeGoal;

      case 'replacement':
      case 'substitution':
      case 'change':
      case 'changement':
        return l10n.highlightTypeSubstitution;

      case 'yellowcard':
      case 'yellow_card':
      case 'carton_jaune':
        return l10n.highlightTypeYellowCard;

      case 'redcard':
      case 'red_card':
      case 'carton_rouge':
        return l10n.highlightTypeRedCard;

      case 'own_goal':
      case 'owngoal':
        return l10n.highlightTypeOwnGoal;

      case 'penalty':
        return l10n.highlightTypePenalty;

      default:
        final safeType = _clean(type);
        return safeType.isEmpty ? l10n.highlightTypeGeneric : safeType;
    }
  }

  String _descriptionForHighlight(
    AppLocalizations l10n,
    MatchStatHighLight highlight,
  ) {
    final type = _normalize(highlight.type);
    final player = _clean(highlight.player, fallback: l10n.entityPlayerNotSet);
    final incomingPlayer = _clean(highlight.incomingPlayer);

    switch (type) {
      case 'goal':
      case 'but':
        return player;

      case 'replacement':
      case 'substitution':
      case 'change':
      case 'changement':
        if (incomingPlayer.isEmpty) {
          return l10n.highlightSubstitutionOut(player);
        }

        return l10n.highlightSubstitutionIn(incomingPlayer, player);

      case 'yellowcard':
      case 'yellow_card':
      case 'carton_jaune':
        return player;

      case 'redcard':
      case 'red_card':
      case 'carton_rouge':
        return player;

      case 'own_goal':
      case 'owngoal':
        return player;

      case 'penalty':
        return player;

      default:
        return player;
    }
  }
}

class _TimelineAxis extends StatelessWidget {
  final int minute;
  final IconData icon;
  final Color color;
  final bool showTopLine;
  final bool showBottomLine;

  const _TimelineAxis({
    required this.minute,
    required this.icon,
    required this.color,
    required this.showTopLine,
    required this.showBottomLine,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTopLine)
            Container(
              width: 2,
              height: 12,
              color: colors.border,
            )
          else
            const SizedBox(height: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              "$minute'",
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (showBottomLine)
            Container(
              width: 2,
              height: 12,
              color: colors.border,
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CompactTimelineAxis extends StatelessWidget {
  final int minute;
  final IconData icon;
  final Color color;

  const _CompactTimelineAxis({
    required this.minute,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Text(
            "$minute'",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineMatchMarker extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _TimelineMatchMarker({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _EventIcon({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 29,
      height: 29,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 17,
        color: color,
      ),
    );
  }
}

class _TeamChip extends StatelessWidget {
  final String team;
  final Color color;

  const _TeamChip({
    required this.team,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        team,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TimelineEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _TimelineEmptyState({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flash_on_rounded,
            color: colors.textSecondary,
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightStyle {
  final IconData icon;
  final Color color;

  const _HighlightStyle({
    required this.icon,
    required this.color,
  });

  factory _HighlightStyle.fromType(
      BuildContext context,
      String? type,
      ) {
    final colors = context.appColors;

    switch (_normalize(type)) {
      case 'goal':
      case 'but':
        return _HighlightStyle(
          icon: Icons.sports_soccer_rounded,
          color: colors.success,
        );

      case 'replacement':
      case 'substitution':
      case 'change':
      case 'changement':
        return _HighlightStyle(
          icon: Icons.swap_horiz_rounded,
          color: colors.primary,
        );

      case 'yellowcard':
      case 'yellow_card':
      case 'carton_jaune':
        return _HighlightStyle(
          icon: Icons.style_rounded,
          color: colors.warning,
        );

      case 'redcard':
      case 'red_card':
      case 'carton_rouge':
        return _HighlightStyle(
          icon: Icons.style_rounded,
          color: colors.danger,
        );

      case 'own_goal':
      case 'owngoal':
        return _HighlightStyle(
          icon: Icons.sports_soccer_rounded,
          color: colors.danger,
        );

      case 'penalty':
        return _HighlightStyle(
          icon: Icons.adjust_rounded,
          color: colors.success,
        );

      default:
        return _HighlightStyle(
          icon: Icons.flash_on_rounded,
          color: colors.secondary,
        );
    }
  }
}

String _clean(String? value, {String fallback = ''}) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _normalize(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll('-', '_');
}