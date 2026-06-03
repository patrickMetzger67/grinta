import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

void showTrackerKitDialog(BuildContext context) {
  AnalyticsInteractions.logFeature(AnalyticsFeatures.trackerKitTap);
  final colors = context.appColors;
  final l10n = context.l10n;

  showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          l10n.matchDetailTrackerKitTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.matchDetailTrackerKitComingSoon,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionClose),
          ),
        ],
      );
    },
  );
}

/// Visual treatment for [TextPillButton].
enum TextPillStyle {
  /// Tinted fill on neutral backgrounds (e.g. match detail header).
  tinted,

  /// Opaque surface pill with status-colored text on colored cards.
  onColoredBackground,
}

/// Compact tappable text control for tracker kit status.
class TextPillButton extends StatelessWidget {
  static const double _radius = 13;
  static const double _fontSize = 12.5;
  static const EdgeInsets _padding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  final String label;
  final Color color;
  final VoidCallback? onTap;
  final TextPillStyle style;

  const TextPillButton({
    super.key,
    required this.label,
    required this.color,
    this.onTap,
    this.style = TextPillStyle.tinted,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    final borderRadius = BorderRadius.circular(_radius);
    final colors = context.appColors;

    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final Color splashColor;
    final Color highlightColor;

    switch (style) {
      case TextPillStyle.tinted:
        backgroundColor = color.withValues(alpha: 0.14);
        borderColor = color.withValues(alpha: 0.5);
        textColor = color;
        splashColor = color.withValues(alpha: 0.22);
        highlightColor = color.withValues(alpha: 0.1);
      case TextPillStyle.onColoredBackground:
        backgroundColor = colors.surface;
        borderColor = color;
        textColor = color;
        splashColor = color.withValues(alpha: 0.18);
        highlightColor = color.withValues(alpha: 0.08);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: splashColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: _padding,
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the tracker kit pill is shown; drives contrast styling.
enum TrackerKitPillVariant {
  /// Neutral header (tinted pill).
  header,

  /// Agenda card on a type-colored background.
  agendaCard,
}

class TrackerKitGpsPill extends StatelessWidget {
  final bool withTracker;
  final bool isManager;
  final TrackerKitPillVariant variant;

  const TrackerKitGpsPill({
    super.key,
    required this.withTracker,
    required this.isManager,
    this.variant = TrackerKitPillVariant.header,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final statusColor = withTracker ? colors.success : colors.warning;
    return TextPillButton(
      label: l10n.matchDetailTrackerKitLabel,
      color: statusColor,
      style: variant == TrackerKitPillVariant.agendaCard
          ? TextPillStyle.onColoredBackground
          : TextPillStyle.tinted,
      onTap: isManager ? () => showTrackerKitDialog(context) : null,
    );
  }
}
