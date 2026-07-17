import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [SessionStatsReport] to PDF bytes (recap table + player pages).
///
/// All pages are A4 landscape. Each player detail fits on a single page.
class SessionStatsReportPdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _success = PdfColor.fromInt(0xFF1FA971);
  static const PdfColor _danger = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _warning = PdfColor.fromInt(0xFFF5A524);
  static const PdfColor _secondary = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _white = PdfColors.white;

  Future<Uint8List> buildPdf(
    SessionStatsReport report, {
    String localeCode = 'fr',
  }) async {
    final fonts = await _loadFonts();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
      ),
    );
    final generatedLabel = DateFormat('yyyy-MM-dd HH:mm').format(
      report.generatedAt,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 16, 18, 14),
        footer: (context) => _buildFooter(context),
        build: (context) => <pw.Widget>[
          _buildRecapHeader(report, generatedLabel),
          pw.SizedBox(height: 10),
          _buildSummaryRow(report),
          pw.SizedBox(height: 10),
          _buildPlayersTable(report),
        ],
      ),
    );

    for (final player in report.playerDetails) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(14, 12, 14, 10),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildPlayerPageHeader(report, player, generatedLabel),
                pw.SizedBox(height: 8),
                pw.Expanded(
                  child: report.isMatch
                      ? _buildMatchPlayerBody(player)
                      : _buildTrainingPlayerBody(player),
                ),
                pw.SizedBox(height: 4),
                _buildFooter(context),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  Future<({pw.Font regular, pw.Font bold})> _loadFonts() async {
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/SF-Pro-Display-Regular.otf',
      );
      final boldData = await rootBundle.load(
        'assets/fonts/SF-Pro-Display-Bold.otf',
      );
      return (
        regular: pw.Font.ttf(regularData),
        bold: pw.Font.ttf(boldData),
      );
    } catch (_) {
      return (
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      );
    }
  }

  pw.Widget _buildMatchPlayerBody(SessionStatsReportPlayerDetail player) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          flex: 11,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Synthese'),
              pw.SizedBox(height: 4),
              _buildSynthesisGrid(player, compact: true),
              pw.SizedBox(height: 8),
              _sectionTitle('Zones de vitesse'),
              pw.SizedBox(height: 4),
              pw.Expanded(child: _buildSpeedZonesBlock(player)),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 14,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Timeline distance'),
              pw.SizedBox(height: 4),
              pw.Expanded(flex: 5, child: _buildTimelineChart(player.distanceTimeline)),
              pw.SizedBox(height: 6),
              _sectionTitle('Zones de terrain'),
              pw.SizedBox(height: 4),
              _buildFieldZonesGrid(player.fieldZones),
              pw.SizedBox(height: 6),
              _sectionTitle('Heatmaps'),
              pw.SizedBox(height: 4),
              pw.Expanded(flex: 6, child: _buildHeatmapsRow(player.heatmaps)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTrainingPlayerBody(SessionStatsReportPlayerDetail player) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Synthese'),
              pw.SizedBox(height: 4),
              _buildSynthesisGrid(player, compact: false),
              pw.SizedBox(height: 8),
              _sectionTitle('Zones de vitesse'),
              pw.SizedBox(height: 4),
              pw.Expanded(child: _buildSpeedZonesBlock(player)),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Timeline distance'),
              pw.SizedBox(height: 4),
              pw.Expanded(child: _buildTimelineChart(player.distanceTimeline)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPlayerPageHeader(
    SessionStatsReport report,
    SessionStatsReportPlayerDetail player,
    String generatedLabel,
  ) {
    final match = report.matchHeader;
    final sessionLine = report.isMatch
        ? [
            if ((match?.opponentName ?? '').trim().isNotEmpty)
              'vs ${match!.opponentName!.trim()}'
            else
              report.title,
            if ((match?.scoreLabel ?? '').trim().isNotEmpty) match!.scoreLabel,
          ].join('  ·  ')
        : report.title;

    final dateTimeLine = [
      if ((report.dateLabel ?? '').trim().isNotEmpty) report.dateLabel!.trim(),
      if ((report.timeLabel ?? '').trim().isNotEmpty) report.timeLabel!.trim(),
      if ((report.teamName ?? '').trim().isNotEmpty) report.teamName!.trim(),
    ].join(' · ');

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: pw.BoxDecoration(
              color: _primary,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'GRINTA',
              style: pw.TextStyle(
                color: _white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          if (match?.opponentLogoBytes != null) ...[
            pw.Container(
              width: 22,
              height: 22,
              child: pw.Image(
                pw.MemoryImage(match!.opponentLogoBytes!),
                fit: pw.BoxFit.contain,
              ),
            ),
            pw.SizedBox(width: 6),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  sessionLine,
                  maxLines: 1,
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (dateTimeLine.isNotEmpty)
                  pw.Text(
                    dateTimeLine,
                    maxLines: 1,
                    style: const pw.TextStyle(
                      color: _textSecondary,
                      fontSize: 8.5,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          _playerAvatar(player.photoBytes, size: 28),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                player.displayName,
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                player.trackerId.trim().isEmpty
                    ? 'Tracker -'
                    : 'Tracker ${player.trackerId.trim()}',
                style: const pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            generatedLabel,
            style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _playerAvatar(Uint8List? bytes, {double size = 28}) {
    if (bytes != null && bytes.isNotEmpty) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all(color: _border),
        ),
        child: pw.ClipOval(
          child: pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.cover,
          ),
        ),
      );
    }

    return pw.Container(
      width: size,
      height: size,
      decoration: const pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: _border,
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'J',
        style: pw.TextStyle(
          color: _textSecondary,
          fontWeight: pw.FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  pw.Widget _buildSynthesisGrid(
    SessionStatsReportPlayerDetail player, {
    required bool compact,
  }) {
    final tiles = <(String, String)>[
      ('Distance', '${player.distanceKm.toStringAsFixed(2)} km'),
      ('Vitesse moy.', '${player.averageSpeedKmh.toStringAsFixed(1)} km/h'),
      ('Vitesse max', '${player.maxValidatedSpeedKmh.toStringAsFixed(1)} km/h'),
      ('Acc. max', '${player.maxAccelerationMps2.toStringAsFixed(2)} m/s2'),
      ('Sprints', '${player.sprintCount}'),
      ('Acc. hautes', '${player.highAccelerationCount}'),
      ('Haute vitesse', _formatDurationShort(player.highSpeedDuration)),
      ('Workload', '${player.workloadScore.toStringAsFixed(0)} pts'),
      ('Fatigue', player.fatigueIndex.toStringAsFixed(2)),
      ('Duree', _formatDurationLong(player.duration)),
    ];

    final rows = <pw.Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final left = tiles[i];
      final right = i + 1 < tiles.length ? tiles[i + 1] : null;
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.Expanded(child: _metricChip(left.$1, left.$2, compact: compact)),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: right == null
                    ? pw.SizedBox()
                    : _metricChip(right.$1, right.$2, compact: compact),
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(children: rows);
  }

  pw.Widget _metricChip(
    String label,
    String value, {
    required bool compact,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 4 : 6,
      ),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: _textSecondary,
                fontSize: compact ? 7.5 : 8,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSpeedZonesBlock(SessionStatsReportPlayerDetail player) {
    if (player.speedZones.isEmpty) {
      return _emptyHint('Aucune zone de vitesse');
    }
    return pw.Column(
      children: [
        for (final zone in player.speedZones)
          pw.Expanded(child: _buildSpeedZoneRow(zone)),
      ],
    );
  }

  pw.Widget _buildSpeedZoneRow(SessionStatsReportSpeedZoneRow zone) {
    final double percent = zone.percent.clamp(0, 100);
    final int filled = math.max(0, (percent * 10).round());
    final int empty = math.max(0, ((100 - percent) * 10).round());

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${zone.label} (${zone.rangeLabel})',
                  maxLines: 1,
                  style: const pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 7.5,
                  ),
                ),
              ),
              pw.Text(
                '${_formatDurationShort(zone.duration)} · ${percent.toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.ClipRRect(
            horizontalRadius: 3,
            verticalRadius: 3,
            child: pw.Container(
              height: 6,
              color: _border,
              child: pw.Row(
                children: [
                  if (filled > 0)
                    pw.Expanded(
                      flex: filled,
                      child: pw.Container(color: _zoneColor(zone.zoneId)),
                    ),
                  if (empty > 0)
                    pw.Expanded(flex: empty, child: pw.SizedBox()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _zoneColor(String zoneId) {
    switch (zoneId.toUpperCase()) {
      case 'Z1':
        return _textSecondary;
      case 'Z2':
        return _primary;
      case 'Z3':
        return _secondary;
      case 'Z4':
        return _warning;
      case 'Z5':
        return _danger;
      default:
        return _primary;
    }
  }

  pw.Widget _buildTimelineChart(
    List<SessionStatsReportTimelineBucket> timeline,
  ) {
    if (timeline.isEmpty) {
      return _emptyHint('Aucune timeline distance');
    }

    final double maxMeters = timeline
        .map((e) => e.totalMeters)
        .fold<double>(0, (prev, value) => math.max(prev, value));
    final double safeMax = maxMeters <= 0 ? 1 : maxMeters;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              _buildLegendDot(label: 'Marche', color: _textSecondary),
              _buildLegendDot(label: 'Jogging', color: _primary),
              _buildLegendDot(label: 'Course', color: _secondary),
              _buildLegendDot(label: 'Haute intensite', color: _warning),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Expanded(
            child: pw.Column(
              children: [
                for (final bucket in timeline)
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 36,
                            child: pw.Text(
                              bucket.label,
                              maxLines: 1,
                              style: const pw.TextStyle(
                                color: _textSecondary,
                                fontSize: 6.5,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            child: _stackedBar(
                              bucket: bucket,
                              maxMeters: safeMax,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.SizedBox(
                            width: 34,
                            child: pw.Text(
                              '${bucket.totalMeters.toStringAsFixed(0)}m',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(
                                color: _textPrimary,
                                fontSize: 6.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _stackedBar({
    required SessionStatsReportTimelineBucket bucket,
    required double maxMeters,
  }) {
    final segments = <(PdfColor, double)>[
      (_textSecondary, bucket.walkingMeters),
      (_primary, bucket.joggingMeters),
      (_secondary, bucket.runningMeters),
      (_warning, bucket.highIntensityMeters),
    ];
    final double widthFactor =
        (bucket.totalMeters / maxMeters).clamp(0.0, 1.0);
    final int filledFlex = math.max(1, (widthFactor * 1000).round());
    final int emptyFlex = math.max(1, ((1 - widthFactor) * 1000).round());
    final positiveSegments = segments.where((s) => s.$2 > 0).toList();

    return pw.ClipRRect(
      horizontalRadius: 2,
      verticalRadius: 2,
      child: pw.Container(
        height: 8,
        color: _border,
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: filledFlex,
              child: pw.Row(
                children: positiveSegments.isEmpty
                    ? <pw.Widget>[pw.Expanded(child: pw.SizedBox())]
                    : positiveSegments.map((s) {
                        final double flex = bucket.totalMeters <= 0
                            ? 1.0
                            : (s.$2 / bucket.totalMeters).clamp(0.001, 1.0);
                        return pw.Expanded(
                          flex: math.max(1, (flex * 1000).round()),
                          child: pw.Container(color: s.$1),
                        );
                      }).toList(),
              ),
            ),
            pw.Expanded(flex: emptyFlex, child: pw.SizedBox()),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFieldZonesGrid(List<SessionStatsReportFieldZoneCell> zones) {
    if (zones.isEmpty) {
      return _emptyHint('Aucune zone de terrain');
    }

    SessionStatsReportFieldZoneCell? byId(String id) {
      for (final z in zones) {
        if (z.zoneId == id) return z;
      }
      return null;
    }

    pw.Widget cell(String id) {
      final z = byId(id);
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.all(2),
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                z?.label ?? id,
                maxLines: 1,
                style: const pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 6.5,
                ),
              ),
              pw.Text(
                '${(z?.distanceKm ?? 0).toStringAsFixed(2)} km · ${(z?.occupancyPercent ?? 0).toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Row(children: [cell('ATT_LEFT'), cell('ATT_RIGHT')]),
        pw.Row(children: [cell('MID_LEFT'), cell('MID_RIGHT')]),
        pw.Row(children: [cell('DEF_LEFT'), cell('DEF_RIGHT')]),
      ],
    );
  }

  pw.Widget _buildHeatmapsRow(List<SessionStatsReportHeatmapImage> heatmaps) {
    if (heatmaps.isEmpty) {
      return _emptyHint('Aucune heatmap disponible');
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < heatmaps.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: _white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    heatmaps[i].periodLabel,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Expanded(
                    child: pw.Image(
                      pw.MemoryImage(heatmaps[i].pngBytes),
                      fit: pw.BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _textPrimary,
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _emptyHint(String text) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
      ),
    );
  }

  pw.Widget _buildRecapHeader(SessionStatsReport report, String generatedLabel) {
    final eventKind = report.isMatch ? 'Match' : 'Entrainement';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'GRINTA',
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  pw.Text(
                    'Rapport $eventKind - statistiques tracker',
                    style: const pw.TextStyle(color: _white, fontSize: 10),
                  ),
                ],
              ),
              pw.Text(
                generatedLabel,
                style: const pw.TextStyle(color: _white, fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          report.title,
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if ((report.dateLabel ?? '').trim().isNotEmpty ||
            (report.timeLabel ?? '').trim().isNotEmpty ||
            (report.teamName ?? '').trim().isNotEmpty)
          pw.Text(
            [
              if ((report.dateLabel ?? '').trim().isNotEmpty)
                report.dateLabel!.trim(),
              if ((report.timeLabel ?? '').trim().isNotEmpty)
                report.timeLabel!.trim(),
              if ((report.teamName ?? '').trim().isNotEmpty)
                report.teamName!.trim(),
            ].join(' · '),
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(SessionStatsReport report) {
    final durationMinutes =
        (report.sessionDuration.inMilliseconds / 60000).round();
    final chips = <(String, String)>[
      ('Joueurs', '${report.playersCount}'),
      ('Workload moy.', report.averageWorkloadScore.toStringAsFixed(0)),
      (
        'Distance moy.',
        '${(report.teamAverages[TeamWorkloadMetricKeys.distanceKm] ?? 0).toStringAsFixed(2)} km',
      ),
      ('Duree', '$durationMinutes min'),
    ];

    return pw.Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: _surface,
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    chips[i].$1,
                    style: const pw.TextStyle(
                      color: _textSecondary,
                      fontSize: 8,
                    ),
                  ),
                  pw.Text(
                    chips[i].$2,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildPlayersTable(SessionStatsReport report) {
    final metrics = kSessionStatsReportMetrics;

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.6),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.4),
        1: const pw.FixedColumnWidth(42),
        for (var i = 0; i < metrics.length; i++)
          i + 2: const pw.FlexColumnWidth(1.0),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: <pw.Widget>[
            _headerCell('Joueur'),
            _headerCell('Tr.'),
            ...metrics.map((m) => _headerCell(m.title, alignCenter: true)),
          ],
        ),
        for (var rowIndex = 0; rowIndex < report.playerRows.length; rowIndex++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowIndex.isOdd ? _surface : _white,
            ),
            children: <pw.Widget>[
              _textCell(report.playerRows[rowIndex].displayName),
              _textCell(
                report.playerRows[rowIndex].trackerId.isEmpty
                    ? '-'
                    : report.playerRows[rowIndex].trackerId,
                alignCenter: true,
              ),
              ...metrics.map(
                (metric) => _metricCell(
                  valueLabel: metric.format(
                    report.playerRows[rowIndex].metricValue(metric.key),
                  ),
                  zScore: report.playerRows[rowIndex].zScoreValue(metric.key),
                ),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _headerCell(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          color: _white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  pw.Widget _textCell(String text, {bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        maxLines: 1,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: _textPrimary,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Value on top, z-score below — avoids horizontal overflow that hid numbers.
  pw.Widget _metricCell({
    required String valueLabel,
    required double? zScore,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            valueLabel,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9,
              color: _textPrimary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (zScore != null) ...[
            pw.SizedBox(height: 2),
            _zScoreBadge(zScore),
          ],
        ],
      ),
    );
  }

  pw.Widget _zScoreBadge(double zScore) {
    final color = _colorForZScore(zScore);
    final sign = zScore > 0 ? '+' : '';
    final label = '$sign${zScore.toStringAsFixed(2)}';

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        color: color == _success
            ? const PdfColor.fromInt(0xFFE8F8F0)
            : color == _danger
                ? const PdfColor.fromInt(0xFFFDECEA)
                : _surface,
        borderRadius: pw.BorderRadius.circular(999),
        border: pw.Border.all(color: color, width: 0.7),
      ),
      child: pw.Text(
        label,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: color,
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  PdfColor _colorForZScore(double value) {
    if (value > 0) return _success;
    if (value < 0) return _danger;
    return _textSecondary;
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Grinta Performance - page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 7.5),
      ),
    );
  }

  static pw.Widget _buildLegendDot({
    required String label,
    required PdfColor color,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 7,
          height: 7,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(999),
          ),
        ),
        pw.SizedBox(width: 3),
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _textSecondary,
            fontSize: 7,
          ),
        ),
      ],
    );
  }

  String _formatDurationShort(Duration duration) {
    final int totalSeconds = duration.inSeconds;
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (seconds == 0) {
      return '${minutes}min';
    }
    return '${minutes}min ${seconds}s';
  }

  String _formatDurationLong(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    }
    if (minutes > 0) {
      return '${minutes}min ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }
}
