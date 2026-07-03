import 'package:flutter/material.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/util/app_theme.dart';

class HighlightTypeIconStyle {
  final IconData icon;
  final Color color;

  const HighlightTypeIconStyle({
    required this.icon,
    required this.color,
  });
}

abstract final class HighlightTypeIcons {
  static HighlightTypeIconStyle forActionType(
    BuildContext context,
    ActionType actionType,
  ) {
    final colors = context.appColors;

    return switch (actionType) {
      ActionType.timeEvent => HighlightTypeIconStyle(
          icon: Icons.schedule_rounded,
          color: colors.primary,
        ),
      ActionType.goal => HighlightTypeIconStyle(
          icon: Icons.sports_soccer_rounded,
          color: colors.success,
        ),
      ActionType.yellowCard => HighlightTypeIconStyle(
          icon: Icons.style_rounded,
          color: colors.warning,
        ),
      ActionType.redCard => HighlightTypeIconStyle(
          icon: Icons.style_rounded,
          color: colors.danger,
        ),
      ActionType.substitution => HighlightTypeIconStyle(
          icon: Icons.swap_horiz_rounded,
          color: colors.primary,
        ),
    };
  }

  static HighlightTypeIconStyle forTimeType(
    BuildContext context,
    TimeType timeType,
  ) {
    final colors = context.appColors;

    return switch (timeType) {
      TimeType.kickOff => HighlightTypeIconStyle(
          icon: Icons.play_arrow_rounded,
          color: colors.primary,
        ),
      TimeType.halTime => HighlightTypeIconStyle(
          icon: Icons.pause_circle_outline_rounded,
          color: colors.textSecondary,
        ),
      TimeType.secondHalf => HighlightTypeIconStyle(
          icon: Icons.replay_rounded,
          color: colors.primary,
        ),
      TimeType.startExtraTime => HighlightTypeIconStyle(
          icon: Icons.more_time_rounded,
          color: colors.secondary,
        ),
      TimeType.end => HighlightTypeIconStyle(
          icon: Icons.sports_score_rounded,
          color: colors.textSecondary,
        ),
    };
  }

  static HighlightTypeIconStyle forHighlight(
    BuildContext context,
    Highlights highlight,
  ) {
    return switch (highlight.actionType) {
      ActionType.timeEvent => forTimeType(
          context,
          (highlight.value as TimeEvent?)?.type ?? TimeType.kickOff,
        ),
      ActionType.goal ||
      ActionType.yellowCard ||
      ActionType.redCard ||
      ActionType.substitution =>
        forActionType(context, highlight.actionType!),
      null => HighlightTypeIconStyle(
          icon: Icons.flash_on_rounded,
          color: context.appColors.secondary,
        ),
    };
  }
}

class HighlightTypeIconBadge extends StatelessWidget {
  const HighlightTypeIconBadge({
    super.key,
    required this.style,
    this.size = 29,
    this.iconSize = 17,
  });

  final HighlightTypeIconStyle style;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        style.icon,
        size: iconSize,
        color: style.color,
      ),
    );
  }
}
