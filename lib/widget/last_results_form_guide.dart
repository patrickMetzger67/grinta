import 'package:flutter/material.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/last_results.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/services/last_results_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/last_results_helper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';

/// Presentational 5-slot form guide (oldest → newest, empties on the right).
class LastResultsFormRow extends StatelessWidget {
  const LastResultsFormRow({
    super.key,
    required this.slots,
    this.highlightIndex,
    this.slotSize = 8,
    this.emptyRingColor = lastResultsEmptyStrokeColor,
  });

  static const Key guideKey = Key('lastResultsFormGuide');

  static Key slotKey(int index) => Key('lastResultsSlot_$index');

  static Key highlightKey(int index) => Key('lastResultsSlotHighlight_$index');

  final List<MatchOutcome?> slots;
  final int? highlightIndex;
  final double slotSize;
  final Color emptyRingColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = AppLocalizations.of(context);
    final visible = slots.length >= lastResultsSlotCount
        ? slots.sublist(0, lastResultsSlotCount)
        : <MatchOutcome?>[
            ...slots,
            for (var i = slots.length; i < lastResultsSlotCount; i++) null,
          ];

    return Semantics(
      container: true,
      label: l10n?.lastResultsFormGuide,
      child: Padding(
        key: guideKey,
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) SizedBox(width: slotSize * 0.22),
              _LastResultsSlot(
                outcome: visible[i],
                highlighted: highlightIndex == i,
                size: slotSize,
                colors: colors,
                emptyRingColor: emptyRingColor,
                index: i,
                semanticLabel: _slotSemanticLabel(
                  l10n: l10n,
                  outcome: visible[i],
                  highlighted: highlightIndex == i,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reads Firestore `lastResults` for one club on [match] (no recompute).
class LastResultsFormGuide extends StatelessWidget {
  const LastResultsFormGuide({
    super.key,
    required this.match,
    required this.side,
    this.compact = true,
    this.emptyRingColor = lastResultsEmptyStrokeColor,
    this.service,
    this.resultsStream,
  });

  final Match match;
  final MatchSide side;
  final bool compact;

  /// Hollow-slot stroke. White on the dark match-detail header; black on coral agenda cards.
  final Color emptyRingColor;
  final LastResultsService? service;

  /// Injected stream for tests. Production uses [LastResultsService].
  final Stream<LastResults?>? resultsStream;

  @override
  Widget build(BuildContext context) {
    final resultsKey = lastResultsKeyForMatchSide(match, side);
    if (resultsKey == null) {
      return const SizedBox.shrink();
    }

    final stream = resultsStream ??
        (service ?? LastResultsService.instance).streamLastResults(
          clubId: resultsKey.clubId,
          competitionId: resultsKey.competitionId,
        );

    return StreamBuilder<LastResults?>(
      key: ValueKey<String>(resultsKey.documentId),
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final waiting = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        if (waiting) {
          return LastResultsFormRow(
            slots: const <MatchOutcome?>[null, null, null, null, null],
            slotSize: _slotSize,
            emptyRingColor: emptyRingColor,
          );
        }

        final lastResults = snapshot.data;
        if (lastResults == null) {
          return const SizedBox.shrink();
        }

        final slots = lastResultsDisplaySlots(lastResults.results);
        final rawHighlight = lastResultsHighlightIndex(
          results: lastResults.results,
          highlightMatchId: match.id,
        );
        final highlightIndex = (rawHighlight != null &&
                rawHighlight >= 0 &&
                rawHighlight < lastResultsSlotCount)
            ? rawHighlight
            : null;

        return LastResultsFormRow(
          slots: slots,
          highlightIndex: highlightIndex,
          slotSize: _slotSize,
          emptyRingColor: emptyRingColor,
        );
      },
    );
  }

  double get _slotSize => compact ? 8 : 10;
}

/// Hollow ring for empty slots — black so it stays visible on coral cards.
const Color lastResultsEmptyStrokeColor = Color(0xFF111111);

/// Medium grey for draws (readable on coral cards and dark headers).
const Color lastResultsDrawColor = Color(0xFF6E6E73);

Color lastResultsSlotFillColor(AppColors colors, MatchOutcome outcome) {
  return switch (outcome) {
    MatchOutcome.win => colors.success,
    MatchOutcome.draw => lastResultsDrawColor,
    // Darken danger so a loss does not vanish on coral agenda cards
    // (those cards already use `colors.danger` as the background).
    MatchOutcome.loss => Color.alphaBlend(
        const Color(0x66000000),
        colors.danger,
      ),
  };
}

String? _slotSemanticLabel({
  required AppLocalizations? l10n,
  required MatchOutcome? outcome,
  required bool highlighted,
}) {
  if (l10n == null) {
    return null;
  }
  final base = switch (outcome) {
    MatchOutcome.win => l10n.statsWins,
    MatchOutcome.draw => l10n.statsDraws,
    MatchOutcome.loss => l10n.statsLosses,
    null => l10n.lastResultsSlotEmpty,
  };
  if (highlighted) {
    return '$base, ${l10n.lastResultsSlotHighlighted}';
  }
  return base;
}

class _LastResultsSlot extends StatelessWidget {
  const _LastResultsSlot({
    required this.outcome,
    required this.highlighted,
    required this.size,
    required this.colors,
    required this.emptyRingColor,
    required this.index,
    this.semanticLabel,
  });

  final MatchOutcome? outcome;
  final bool highlighted;
  final double size;
  final AppColors colors;
  final Color emptyRingColor;
  final int index;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ringGap = size * 0.22;
    final ringWidth = size * 0.16;
    final outer = size + (ringGap + ringWidth) * 2;
    final fillColor = outcome == null
        ? null
        : lastResultsSlotFillColor(colors, outcome!);
    final ringColor = fillColor ?? emptyRingColor;

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        key: LastResultsFormRow.slotKey(index),
        width: outer,
        height: outer,
        child: KeyedSubtree(
          key: highlighted ? LastResultsFormRow.highlightKey(index) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: highlighted
                  ? Border.all(color: ringColor, width: ringWidth)
                  : Border.all(color: Colors.transparent, width: ringWidth),
            ),
            child: Padding(
              padding: EdgeInsets.all(ringGap),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                  border: outcome == null
                      ? Border.all(
                          color: emptyRingColor,
                          width: size * 0.18,
                        )
                      : null,
                ),
                child: outcome == null
                    ? const SizedBox.expand()
                    : CustomPaint(
                        painter: _LastResultsGlyphPainter(outcome: outcome!),
                        child: const SizedBox.expand(),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LastResultsGlyphPainter extends CustomPainter {
  const _LastResultsGlyphPainter({required this.outcome});

  final MatchOutcome outcome;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.shortestSide * 0.18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (outcome) {
      case MatchOutcome.win:
        final path = Path()
          ..moveTo(size.width * 0.22, size.height * 0.52)
          ..lineTo(size.width * 0.42, size.height * 0.72)
          ..lineTo(size.width * 0.78, size.height * 0.28);
        canvas.drawPath(path, paint);
      case MatchOutcome.draw:
        canvas.drawLine(
          Offset(size.width * 0.26, size.height * 0.5),
          Offset(size.width * 0.74, size.height * 0.5),
          paint,
        );
      case MatchOutcome.loss:
        canvas.drawLine(
          Offset(size.width * 0.28, size.height * 0.28),
          Offset(size.width * 0.72, size.height * 0.72),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * 0.72, size.height * 0.28),
          Offset(size.width * 0.28, size.height * 0.72),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _LastResultsGlyphPainter oldDelegate) {
    return oldDelegate.outcome != outcome;
  }
}
