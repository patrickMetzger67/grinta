import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/tracker/trackerData.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

/// Optional match header for session share cards (logos / names / score).
class SessionShareMatchContext {
  const SessionShareMatchContext({
    required this.team1Name,
    required this.team2Name,
    required this.homeScore,
    required this.awayScore,
    required this.isStatApplied,
    this.team1LogoUrl,
    this.team2LogoUrl,
  });

  final String team1Name;
  final String team2Name;
  final int homeScore;
  final int awayScore;
  final bool isStatApplied;
  final String? team1LogoUrl;
  final String? team2LogoUrl;

  bool get showMatchHeader => isStatApplied;

  factory SessionShareMatchContext.fromMatch(models.Match match) {
    return SessionShareMatchContext(
      team1Name: (match.team1 ?? '').trim(),
      team2Name: (match.team2 ?? '').trim(),
      homeScore: match.homeScore ?? 0,
      awayScore: match.outSideScore ?? 0,
      isStatApplied: match.isStatApplied == true,
      team1LogoUrl: match.team1UrlLogo?.trim(),
      team2LogoUrl: match.team2UrlLogo?.trim(),
    );
  }
}

class _ShareMetric {
  const _ShareMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
}

/// Dark-themed share card for GPS session synthesis (match / training).
///
/// Matches in-app synthesis tiles: same Material icons, SF Pro typography,
/// and Grinta logo asset (`logoFondBlanc.png`).
class SessionPlayerSynthesisShareService {
  const SessionPlayerSynthesisShareService();

  static const String _grintaLogoAsset = 'assets/images/logoFondBlanc.png';

  String buildShareText({
    required AppLocalizations l10n,
    required String playerName,
    required TrackerAnalysisResult analysis,
    SessionShareMatchContext? matchContext,
    required bool isMatch,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Grinta Performance');
    buffer.writeln(playerName);
    if (matchContext != null &&
        matchContext.showMatchHeader &&
        matchContext.team1Name.isNotEmpty &&
        matchContext.team2Name.isNotEmpty) {
      buffer.writeln(
        '${matchContext.team1Name} ${matchContext.homeScore} - '
        '${matchContext.awayScore} ${matchContext.team2Name}',
      );
    } else {
      buffer.writeln(
        isMatch ? l10n.entityMatch : l10n.entityTraining,
      );
    }
    buffer.writeln(l10n.playerSynthesisTitle);
    buffer.writeln(
      '${l10n.statsDistance}: ${analysis.distanceKm.toStringAsFixed(2)} ${l10n.statsUnitKm}',
    );
    buffer.writeln(
      '${l10n.statsMaxSpeed}: ${analysis.maxValidatedSpeedKmh.toStringAsFixed(1)} ${l10n.statsUnitKmh}',
    );
    buffer.writeln(
      '${l10n.statsWorkload}: ${analysis.workloadScore.toStringAsFixed(0)} pts',
    );
    buffer.writeln('#GrintaPerformance');
    return buffer.toString().trim();
  }

  Future<void> share({
    required AppLocalizations l10n,
    required String playerName,
    required TrackerAnalysisResult analysis,
    SessionShareMatchContext? matchContext,
    required bool isMatch,
    Rect? sharePositionOrigin,
  }) async {
    final text = buildShareText(
      l10n: l10n,
      playerName: playerName,
      analysis: analysis,
      matchContext: matchContext,
      isMatch: isMatch,
    );

    final png = await renderShareCardPng(
      l10n: l10n,
      playerName: playerName,
      analysis: analysis,
      matchContext: matchContext,
      isMatch: isMatch,
    );

    if (png != null) {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: <XFile>[
            XFile.fromData(
              png,
              mimeType: 'image/png',
              name: 'grinta_session_synthesis.png',
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

  Future<Uint8List?> renderShareCardPng({
    required AppLocalizations l10n,
    required String playerName,
    required TrackerAnalysisResult analysis,
    SessionShareMatchContext? matchContext,
    required bool isMatch,
  }) async {
    try {
      const double width = 1080;
      const double height = 1920;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const colors = AppColors.dark;

      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()..color = colors.background,
      );

      double y = 48;

      // Grinta logo (same asset as dark-mode AppLogo).
      final grintaLogo = await _loadAssetImage(_grintaLogoAsset);
      if (grintaLogo != null) {
        const logoH = 72.0;
        final logoW = logoH * grintaLogo.width / grintaLogo.height;
        paintImage(
          canvas: canvas,
          rect: Rect.fromLTWH(64, y, logoW, logoH),
          image: grintaLogo,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
        y += logoH + 28;
      } else {
        _paintText(
          canvas,
          'Grinta Performance',
          offset: Offset(64, y),
          color: colors.primary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          maxWidth: width - 128,
        );
        y += 48;
      }

      final showMatchHeader =
          isMatch && matchContext != null && matchContext.showMatchHeader;

      if (showMatchHeader) {
        y = await _paintMatchHeader(
          canvas,
          y: y,
          width: width,
          colors: colors,
          match: matchContext,
        );
        y += 28;
      }

      _paintText(
        canvas,
        playerName,
        offset: Offset(64, y),
        color: colors.textPrimary,
        fontSize: 52,
        fontWeight: FontWeight.w700,
        maxWidth: width - 128,
      );
      y += 72;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(64, y + 6, 8, 28),
          const Radius.circular(4),
        ),
        Paint()..color = colors.primary,
      );
      _paintText(
        canvas,
        l10n.playerSynthesisTitle,
        offset: Offset(88, y),
        color: colors.textPrimary,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        maxWidth: width - 160,
      );
      y += 56;

      final metrics = _metrics(l10n, analysis, colors);
      const cols = 2;
      const gap = 20.0;
      const left = 64.0;
      final tileW = (width - left * 2 - gap) / cols;
      const tileH = 250.0;

      for (var i = 0; i < metrics.length; i++) {
        final col = i % cols;
        final row = i ~/ cols;
        final x = left + col * (tileW + gap);
        final ty = y + row * (tileH + gap);
        _paintMetricTile(
          canvas,
          rect: Rect.fromLTWH(x, ty, tileW, tileH),
          metric: metrics[i],
          colors: colors,
        );
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(width.toInt(), height.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('SessionPlayerSynthesisShareService render failed: $e\n$st');
      return null;
    }
  }

  /// Same icons / colors as synthesis MetricTiles in tracker analysis.
  List<_ShareMetric> _metrics(
    AppLocalizations l10n,
    TrackerAnalysisResult analysis,
    AppColors colors,
  ) {
    return <_ShareMetric>[
      _ShareMetric(
        icon: Icons.route_rounded,
        label: l10n.statsDistance,
        value: analysis.distanceKm.toStringAsFixed(2),
        unit: l10n.statsUnitKm,
        color: colors.primary,
      ),
      _ShareMetric(
        icon: Icons.speed_rounded,
        label: l10n.statsAvgSpeed,
        value: analysis.averageSpeedKmh.toStringAsFixed(1),
        unit: l10n.statsUnitKmh,
        color: colors.secondary,
      ),
      _ShareMetric(
        icon: Icons.bolt_rounded,
        label: l10n.statsMaxSpeed,
        value: analysis.maxValidatedSpeedKmh.toStringAsFixed(1),
        unit: l10n.statsUnitKmh,
        color: colors.success,
      ),
      _ShareMetric(
        icon: Icons.trending_up_rounded,
        label: l10n.statsMaxAccel,
        value: analysis.maxAccelerationMps2.toStringAsFixed(2),
        unit: l10n.statsUnitMps2,
        color: colors.warning,
      ),
      _ShareMetric(
        icon: Icons.directions_run_rounded,
        label: l10n.statsSprints,
        value: analysis.sprintCount.toString(),
        unit: l10n.statsUnitCount,
        color: colors.primary,
      ),
      _ShareMetric(
        icon: Icons.flash_on_rounded,
        label: l10n.statsHighAccel,
        value: analysis.highAccelerationCount.toString(),
        unit: l10n.statsUnitCount,
        color: colors.warning,
      ),
      _ShareMetric(
        icon: Icons.timer_rounded,
        label: l10n.statsHighSpeedTime,
        value: _formatDurationShort(analysis.highSpeedDuration),
        unit: '',
        color: colors.secondary,
      ),
      _ShareMetric(
        icon: Icons.fitness_center_rounded,
        label: l10n.statsWorkload,
        value: analysis.workloadScore.toStringAsFixed(0),
        unit: 'pts',
        color: colors.success,
      ),
    ];
  }

  Future<double> _paintMatchHeader(
    Canvas canvas, {
    required double y,
    required double width,
    required AppColors colors,
    required SessionShareMatchContext match,
  }) async {
    final team1 = match.team1Name.isEmpty ? '—' : match.team1Name;
    final team2 = match.team2Name.isEmpty ? '—' : match.team2Name;
    final score = '${match.homeScore}  -  ${match.awayScore}';

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(48, y, width - 96, 220),
        const Radius.circular(28),
      ),
      Paint()..color = colors.surface,
    );

    final logo1 = await _loadNetworkImage(match.team1LogoUrl);
    final logo2 = await _loadNetworkImage(match.team2LogoUrl);

    const logoSize = 88.0;
    final leftLogoX = 88.0;
    final rightLogoX = width - 88 - logoSize;
    final logoY = y + 36.0;

    _paintLogoOrPlaceholder(
      canvas,
      image: logo1,
      rect: Rect.fromLTWH(leftLogoX, logoY, logoSize, logoSize),
      colors: colors,
    );
    _paintLogoOrPlaceholder(
      canvas,
      image: logo2,
      rect: Rect.fromLTWH(rightLogoX, logoY, logoSize, logoSize),
      colors: colors,
    );

    _paintText(
      canvas,
      score,
      offset: Offset(0, y + 52),
      color: colors.textPrimary,
      fontSize: 56,
      fontWeight: FontWeight.w700,
      maxWidth: width,
      alignCenter: true,
    );

    _paintText(
      canvas,
      team1,
      offset: Offset(64, y + 140),
      color: colors.textSecondary,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      maxWidth: width / 2 - 80,
      alignCenter: true,
      centerInWidth: width / 2 - 32,
      centerOriginX: 48,
    );

    _paintText(
      canvas,
      team2,
      offset: Offset(width / 2 + 16, y + 140),
      color: colors.textSecondary,
      fontSize: 26,
      fontWeight: FontWeight.w600,
      maxWidth: width / 2 - 80,
      alignCenter: true,
      centerInWidth: width / 2 - 32,
      centerOriginX: width / 2 + 16,
    );

    return y + 220;
  }

  void _paintMetricTile(
    Canvas canvas, {
    required Rect rect,
    required _ShareMetric metric,
    required AppColors colors,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()..color = colors.surface,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(22)),
      Paint()
        ..color = colors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _paintIcon(
      canvas,
      icon: metric.icon,
      color: metric.color,
      center: Offset(rect.center.dx, rect.top + 58),
      size: 44,
    );

    final valuePainter = TextPainter(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: metric.value,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: colors.textPrimary,
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          if (metric.unit.isNotEmpty)
            TextSpan(
              text: ' ${metric.unit}',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: colors.textSecondary,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: rect.width - 24);
    valuePainter.paint(
      canvas,
      Offset(rect.center.dx - valuePainter.width / 2, rect.top + 118),
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: metric.label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: colors.textSecondary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: rect.width - 28);
    labelPainter.paint(
      canvas,
      Offset(rect.center.dx - labelPainter.width / 2, rect.top + 180),
    );
  }

  void _paintIcon(
    Canvas canvas, {
    required IconData icon,
    required Color color,
    required Offset center,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _paintText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required double maxWidth,
    bool alignCenter = false,
    double? centerInWidth,
    double? centerOriginX,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
      textAlign: alignCenter ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: maxWidth);

    double x = offset.dx;
    if (alignCenter) {
      if (centerInWidth != null && centerOriginX != null) {
        x = centerOriginX + (centerInWidth - painter.width) / 2;
      } else {
        x = (maxWidth - painter.width) / 2;
      }
    }
    painter.paint(canvas, Offset(x, offset.dy));
  }

  void _paintLogoOrPlaceholder(
    Canvas canvas, {
    required ui.Image? image,
    required Rect rect,
    required AppColors colors,
  }) {
    final path = Path()..addOval(rect);
    canvas.save();
    canvas.clipPath(path);
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      );
    } else {
      canvas.drawOval(rect, Paint()..color = colors.card);
      _paintIcon(
        canvas,
        icon: Icons.shield_rounded,
        color: colors.textSecondary,
        center: rect.center,
        size: 36,
      );
    }
    canvas.restore();
    canvas.drawOval(
      rect,
      Paint()
        ..color = colors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Future<ui.Image?> _loadAssetImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Session share asset load failed ($assetPath): $e');
      return null;
    }
  }

  Future<ui.Image?> _loadNetworkImage(String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(trimmed))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Session share logo load failed: $e');
      return null;
    }
  }

  static String _formatDurationShort(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) return '${totalSeconds}s';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (seconds == 0) return '${minutes}min';
    return '${minutes}min ${seconds}s';
  }
}
