import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/services/player_season_summary_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:share_plus/share_plus.dart';

/// Builds share text / image for a player season summary card.
class PlayerSeasonSummaryShareService {
  const PlayerSeasonSummaryShareService();

  String buildShareText({
    required AppLocalizations l10n,
    required String playerName,
    required String teamName,
    required String seasonLabel,
    required PlayerSeasonSummary summary,
  }) {
    final attendance = summary.attendanceRate == null
        ? '—'
        : '${summary.attendanceRate!.round()}%';
    return l10n.playerSeasonSummaryShareText(
      playerName,
      teamName,
      seasonLabel,
      summary.convocations,
      summary.starts,
      summary.minutesPlayed,
      summary.presentCount,
      attendance,
    );
  }

  /// Shares text + a generated PNG card via the system share sheet.
  Future<void> share({
    required AppLocalizations l10n,
    required String playerName,
    required String teamName,
    required String seasonLabel,
    required PlayerSeasonSummary summary,
    Rect? sharePositionOrigin,
  }) async {
    final text = buildShareText(
      l10n: l10n,
      playerName: playerName,
      teamName: teamName,
      seasonLabel: seasonLabel,
      summary: summary,
    );

    final Uint8List? pngBytes = await renderShareCardPng(
      l10n: l10n,
      playerName: playerName,
      teamName: teamName,
      seasonLabel: seasonLabel,
      summary: summary,
    );

    if (pngBytes != null) {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: <XFile>[
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: 'grinta_season_summary.png',
            ),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// Renders the shareable season summary card (1080×1350 PNG).
  Future<Uint8List?> renderShareCardPng({
    required AppLocalizations l10n,
    required String playerName,
    required String teamName,
    required String seasonLabel,
    required PlayerSeasonSummary summary,
  }) async {
    try {
      const double width = 1080;
      const double height = 1350;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const colors = AppColors.light;

      final bg = Paint()..color = colors.background;
      canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bg);

      final header = Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(width, 280),
          <Color>[colors.primary, colors.secondary],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(48, 48, width - 96, 260),
          const Radius.circular(36),
        ),
        header,
      );

      final titlePainter = TextPainter(
        text: TextSpan(
          text: 'Grinta Performance',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: 36,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 160);
      titlePainter.paint(canvas, const Offset(80, 90));

      final namePainter = TextPainter(
        text: TextSpan(
          text: playerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: width - 160);
      namePainter.paint(canvas, const Offset(80, 150));

      final subtitlePainter = TextPainter(
        text: TextSpan(
          text: '$teamName · $seasonLabel',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 34,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: width - 160);
      subtitlePainter.paint(canvas, const Offset(80, 360));

      final attendance = summary.attendanceRate == null
          ? '—'
          : '${summary.attendanceRate!.round()}%';

      final rows = <(String, String)>[
        (
          l10n.playerSeasonSummaryShareStatConvocations,
          '${summary.convocations}'
        ),
        (l10n.playerSeasonSummaryShareStatStarts, '${summary.starts}'),
        (
          l10n.playerSeasonSummaryShareStatMinutes,
          '${summary.minutesPlayed}'
        ),
        (
          l10n.playerSeasonSummaryShareStatPresent,
          '${summary.presentCount}'
        ),
        (l10n.playerSeasonSummaryShareStatAttendance, attendance),
      ];

      double y = 460;
      for (final row in rows) {
        final cardPaint = Paint()..color = colors.surface;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(64, y, width - 128, 120),
            const Radius.circular(24),
          ),
          cardPaint,
        );

        final labelPainter = TextPainter(
          text: TextSpan(
            text: row.$1,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width - 280);
        labelPainter.paint(canvas, Offset(96, y + 40));

        final valuePainter = TextPainter(
          text: TextSpan(
            text: row.$2,
            style: TextStyle(
              color: colors.primary,
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        valuePainter.paint(
          canvas,
          Offset(width - 96 - valuePainter.width, y + 34),
        );
        y += 144;
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('PlayerSeasonSummaryShareService card render failed: $e\n$st');
      return null;
    }
  }
}
