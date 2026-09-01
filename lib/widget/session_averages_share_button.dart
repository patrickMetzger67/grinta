import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:grinta/services/meta_share_coordinator.dart';
import 'package:grinta/services/session_player_synthesis_share_service.dart';
import 'package:grinta/services/share_record_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/share_sheet.dart';

/// Manager-only control next to Rapport PDF: averages PNG + share sheet / Meta.
class SessionAveragesShareButton extends StatefulWidget {
  const SessionAveragesShareButton({
    super.key,
    required this.summary,
    required this.isMatch,
    this.matchContext,
    this.heading,
    this.filled = false,
    this.style,
  });

  final TeamWorkloadSummary summary;
  final bool isMatch;
  final SessionShareMatchContext? matchContext;
  final String? heading;
  final bool filled;
  final ButtonStyle? style;

  @override
  State<SessionAveragesShareButton> createState() =>
      _SessionAveragesShareButtonState();
}

class _SessionAveragesShareButtonState
    extends State<SessionAveragesShareButton> {
  bool _sharing = false;

  Future<void> _share(BuildContext buttonContext) async {
    if (_sharing) return;
    final l10n = buttonContext.l10n;
    final heading = (widget.heading ?? '').trim().isNotEmpty
        ? widget.heading!.trim()
        : l10n.navStatistics;
    final origin = shareSheetOrigin(buttonContext);

    setState(() => _sharing = true);
    try {
      final png = await const SessionPlayerSynthesisShareService()
          .renderAveragesShareCardPng(
        l10n: l10n,
        heading: heading,
        summary: widget.summary,
        matchContext: widget.matchContext,
        isMatch: widget.isMatch,
      );
      if (png == null || png.isEmpty) {
        throw StateError('Session averages PNG render failed');
      }
      if (!buttonContext.mounted) return;
      final eventId = widget.summary.eventId.trim();
      await MetaShareCoordinator().shareOrPublish(
        context: buttonContext,
        pngBytes: png,
        fileName: 'grinta_session_averages.png',
        statId: eventId.isEmpty ? heading : eventId,
        statType: ShareStatType.sessionAverages,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (buttonContext.mounted) {
        AppSnackbar.show(
          buttonContext,
          l10n.sessionSynthesisShareFailed,
          isError: true,
        );
      }
      debugPrint('Session averages share failed: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = Text(l10n.playerSeasonSummaryShareAction);
    final icon = _sharing
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.ios_share_outlined, size: 18);

    return Builder(
      builder: (buttonContext) {
        final onPressed = _sharing ? null : () => _share(buttonContext);
        if (widget.filled) {
          return FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: widget.style,
          );
        }
        return Tooltip(
          message: l10n.playerSeasonSummaryShareTooltip,
          child: FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: icon,
            label: label,
            style: widget.style,
          ),
        );
      },
    );
  }
}
