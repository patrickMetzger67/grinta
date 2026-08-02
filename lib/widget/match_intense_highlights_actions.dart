import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/screen/intense_live/intense_live_session_screen.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/training_intense_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/intense_live_eligibility.dart';
import 'package:grinta/util/match_intense_finish_helper.dart';

/// Live + Re-sync actions for Intense cloud (noSync) match kits.
///
/// Shown under the match header. Requires no Temps forts kick-off — only a
/// noSync owner + scheduled kick-off / resync window.
class MatchIntenseHighlightsActions extends StatefulWidget {
  const MatchIntenseHighlightsActions({
    super.key,
    required this.match,
    required this.isManager,
  });

  final models.Match match;
  final bool isManager;

  @override
  State<MatchIntenseHighlightsActions> createState() =>
      _MatchIntenseHighlightsActionsState();
}

class _MatchIntenseHighlightsActionsState
    extends State<MatchIntenseHighlightsActions> {
  Future<bool>? _intenseOwnerFuture;
  String? _ownerIdForFuture;
  bool _busy = false;

  void _ensureIntenseOwnerFuture() {
    final ownerId = widget.match.ownerId?.trim() ?? '';
    if (ownerId.isEmpty || widget.match.withTracker != true) {
      _intenseOwnerFuture = null;
      _ownerIdForFuture = null;
      return;
    }
    if (_ownerIdForFuture == ownerId && _intenseOwnerFuture != null) {
      return;
    }
    _ownerIdForFuture = ownerId;
    _intenseOwnerFuture = isIntenseTrackerOwner(ownerId);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isManager || widget.match.withTracker != true) {
      return const SizedBox.shrink();
    }

    final matchId = widget.match.id?.trim() ?? '';
    if (matchId.isEmpty) return const SizedBox.shrink();

    _ensureIntenseOwnerFuture();

    return FutureBuilder<bool>(
      future: _intenseOwnerFuture,
      builder: (context, intenseSnapshot) {
        final isIntenseOwner = intenseSnapshot.data == true;
        if (kDebugMode) {
          debugPrint(
            '[MatchIntenseActions] match=$matchId '
            'ownerId=${widget.match.ownerId} '
            'withTracker=${widget.match.withTracker} '
            'isMatchPlayed=${widget.match.isMatchPlayed} '
            'intenseLoading=${intenseSnapshot.connectionState} '
            'isIntenseOwner=$isIntenseOwner',
          );
        }
        if (!isIntenseOwner) {
          return const SizedBox.shrink();
        }

        // Unfiltered by team — eligibility must see kick-off / full-time.
        return StreamBuilder<List<Highlights>>(
          stream: HighlightsService().streamHighlightsByMatchCalendarId(
            matchId,
          ),
          builder: (context, highlightsSnapshot) {
            final highlights =
                highlightsSnapshot.data ?? const <Highlights>[];
            final showLive = isMatchSessionLive(
              match: widget.match,
              highlights: highlights,
            );
            final showResync = canResyncMatchIntense(
              match: widget.match,
              highlights: highlights,
            );
            final liveStart = intenseLiveMatchStartUtc(
              highlights,
              match: widget.match,
            );

            if (kDebugMode) {
              debugPrint(
                '[MatchIntenseActions] highlights=${highlights.length} '
                'showLive=$showLive showResync=$showResync '
                'liveStart=$liveStart',
              );
            }

            if (!showLive && !showResync) {
              return const SizedBox.shrink();
            }

            final colors = context.appColors;
            final l10n = context.l10n;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  if (showLive && liveStart != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () {
                                IntenseLiveSessionScreen.openForMatch(
                                  context,
                                  match: widget.match,
                                  title: l10n.intenseLiveTitle,
                                  sessionStartUtc: liveStart,
                                );
                              },
                        icon: const Icon(Icons.sensors_rounded, size: 18),
                        label: Text(l10n.intenseLiveTitle),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (showResync) ...[
                    if (showLive && liveStart != null)
                      const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  await resyncManagedMatchIntense(
                                    context,
                                    match: widget.match,
                                    highlights: highlights,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _busy = false);
                                  }
                                }
                              },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: Text(l10n.trainingIntenseResyncButton),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
