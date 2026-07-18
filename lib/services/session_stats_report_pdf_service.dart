import 'dart:math' as math;
import 'dart:typed_data';

import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [SessionStatsReport] to PDF bytes (recap table + player pages).
///
/// All pages are A4 landscape. Uses built-in Helvetica (ASCII-safe) because
/// SF Pro OTF embedding produced corrupted / unreadable glyphs.
class SessionStatsReportPdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _danger = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _warning = PdfColor.fromInt(0xFFF5A524);
  static const PdfColor _secondary = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor _white = PdfColors.white;

  Future<Uint8List> buildPdf(
    SessionStatsReport report, {
    String localeCode = 'fr',
  }) async {
    final doc = pw.Document();
    final generatedLabel = DateFormat('yyyy-MM-dd HH:mm').format(
      report.generatedAt,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(20, 16, 20, 14),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildRecapHeader(report, generatedLabel),
              pw.SizedBox(height: 10),
              _buildSummaryRow(report),
              pw.SizedBox(height: 10),
              pw.Expanded(child: _buildPlayersTable(report)),
              pw.SizedBox(height: 6),
              _buildFooter(context),
            ],
          );
        },
      ),
    );

    for (final player in report.playerDetails) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(16, 12, 16, 10),
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

  /// Helvetica has no Unicode — strip accents / replace unsupported chars.
  static String _t(String? value) {
    if (value == null || value.isEmpty) return '';
    const Map<String, String> map = <String, String>{
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ä': 'A',
      'Å': 'A',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'å': 'a',
      'È': 'E',
      'É': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'Ì': 'I',
      'Í': 'I',
      'Î': 'I',
      'Ï': 'I',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'Ò': 'O',
      'Ó': 'O',
      'Ô': 'O',
      'Ö': 'O',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'Ù': 'U',
      'Ú': 'U',
      'Û': 'U',
      'Ü': 'U',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'Ç': 'C',
      'ç': 'c',
      'Ñ': 'N',
      'ñ': 'n',
      'Œ': 'OE',
      'œ': 'oe',
      'Æ': 'AE',
      'æ': 'ae',
      '°': 'o',
      '²': '2',
      '³': '3',
      '×': 'x',
      '–': '-',
      '—': '-',
      '’': "'",
      '‘': "'",
      '“': '"',
      '”': '"',
      '…': '...',
      '·': '-',
      '€': 'EUR',
    };
    final buffer = StringBuffer();
    for (final int code in value.runes) {
      final String ch = String.fromCharCode(code);
      buffer.write(map[ch] ?? (code < 32 || code > 126 ? '?' : ch));
    }
    return buffer.toString();
  }

  pw.Widget _buildMatchPlayerBody(SessionStatsReportPlayerDetail player) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 10,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Synthese'),
              pw.SizedBox(height: 4),
              _buildSynthesisGrid(player),
              pw.SizedBox(height: 8),
              _sectionTitle('Zones de vitesse'),
              pw.SizedBox(height: 4),
              _buildSpeedZonesBlock(player),
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
              _buildTimelineChart(player.distanceTimeline),
              pw.SizedBox(height: 6),
              _sectionTitle('Zones de terrain'),
              pw.SizedBox(height: 4),
              _buildFieldZonesGrid(player.fieldZones),
              pw.SizedBox(height: 6),
              _sectionTitle('Heatmaps'),
              pw.SizedBox(height: 4),
              _buildHeatmapsRow(player.heatmaps),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTrainingPlayerBody(SessionStatsReportPlayerDetail player) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _sectionTitle('Synthese'),
              pw.SizedBox(height: 4),
              _buildSynthesisGrid(player),
              pw.SizedBox(height: 8),
              _sectionTitle('Zones de vitesse'),
              pw.SizedBox(height: 4),
              _buildSpeedZonesBlock(player),
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
              _buildTimelineChart(player.distanceTimeline),
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
    final dateTimeLine = _t(
      [
        if ((report.dateLabel ?? '').trim().isNotEmpty) report.dateLabel!.trim(),
        if ((report.timeLabel ?? '').trim().isNotEmpty) report.timeLabel!.trim(),
        if ((report.teamName ?? '').trim().isNotEmpty) report.teamName!.trim(),
      ].join(' - '),
    );

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
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (report.isMatch && match != null)
                  _buildMatchScoreline(match)
                else
                  pw.Text(
                    _t(report.title),
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
                _t(player.displayName),
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                player.trackerId.trim().isEmpty
                    ? 'Tracker -'
                    : 'Tracker ${_t(player.trackerId.trim())}',
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

  /// Plain-text scoreline used by tests and as a compact fallback label.
  static String matchScorelineLabel(SessionStatsReportMatchHeader match) {
    final home = match.homeTeamName.trim();
    final away = match.awayTeamName.trim();
    final score = match.scoreLabel.trim();
    return [home, score, away].where((p) => p.isNotEmpty).join('  ');
  }

  /// Home logo + name · score · away name + logo (next to the GRINTA badge).
  pw.Widget _buildMatchScoreline(SessionStatsReportMatchHeader match) {
    final home = _t(match.homeTeamName);
    final away = _t(match.awayTeamName);
    final score = _t(match.scoreLabel);

    return pw.Row(
      children: [
        if (match.homeLogoBytes != null && match.homeLogoBytes!.isNotEmpty) ...[
          pw.Container(
            width: 20,
            height: 20,
            child: pw.Image(
              pw.MemoryImage(match.homeLogoBytes!),
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 5),
        ],
        pw.Flexible(
          child: pw.Text(
            home,
            maxLines: 1,
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          score,
          style: pw.TextStyle(
            color: _primary,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Flexible(
          child: pw.Text(
            away,
            maxLines: 1,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        if (match.awayLogoBytes != null && match.awayLogoBytes!.isNotEmpty) ...[
          pw.SizedBox(width: 5),
          pw.Container(
            width: 20,
            height: 20,
            child: pw.Image(
              pw.MemoryImage(match.awayLogoBytes!),
              fit: pw.BoxFit.contain,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _playerAvatar(Uint8List? bytes, {double size = 28}) {
    if (bytes != null && bytes.isNotEmpty) {
      return pw.Container(
        width: size,
        height: size,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border),
        ),
        child: pw.Image(
          pw.MemoryImage(bytes),
          fit: pw.BoxFit.cover,
        ),
      );
    }

    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      color: _border,
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

  pw.Widget _buildSynthesisGrid(SessionStatsReportPlayerDetail player) {
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
              pw.Expanded(child: _metricChip(left.$1, left.$2)),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: right == null
                    ? pw.SizedBox()
                    : _metricChip(right.$1, right.$2),
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(children: rows);
  }

  pw.Widget _metricChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              _t(label),
              style: const pw.TextStyle(
                color: _textSecondary,
                fontSize: 8,
              ),
            ),
          ),
          pw.Text(
            _t(value),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 9.5,
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
    // Fixed-height rows only — nested Expanded + ClipRRect overflowed the page.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (final zone in player.speedZones) _buildSpeedZoneRow(zone),
      ],
    );
  }

  pw.Widget _buildSpeedZoneRow(SessionStatsReportSpeedZoneRow zone) {
    final double percent = zone.percent.clamp(0, 100);
    final int filled = percent.round().clamp(0, 100);
    final int empty = 100 - filled;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  _t('${zone.label} (${zone.rangeLabel})'),
                  maxLines: 1,
                  style: const pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 8,
                  ),
                ),
              ),
              pw.Text(
                _t(
                  '${_formatDurationShort(zone.duration)} - ${percent.toStringAsFixed(1)}%',
                ),
                style: pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.SizedBox(
            height: 7,
            child: pw.Row(
              children: [
                if (filled > 0)
                  pw.Expanded(
                    flex: filled,
                    child: pw.Container(color: _zoneColor(zone.zoneId)),
                  ),
                if (empty > 0)
                  pw.Expanded(
                    flex: empty,
                    child: pw.Container(color: _border),
                  ),
              ],
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

    // Keep the chart readable: show at most ~16 buckets on one landscape page.
    final List<SessionStatsReportTimelineBucket> buckets =
        timeline.length <= 16
            ? timeline
            : [
                for (var i = 0; i < 16; i++)
                  timeline[((i * timeline.length) / 16).floor()],
              ];

    final double maxMeters = buckets
        .map((e) => e.totalMeters)
        .fold<double>(0, (prev, value) => math.max(prev, value));
    final double safeMax = maxMeters <= 0 ? 1 : maxMeters;

    return pw.Container(
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
          pw.SizedBox(height: 8),
          for (final bucket in buckets)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 40,
                    child: pw.Text(
                      _t(bucket.label),
                      maxLines: 1,
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 7,
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
                    width: 36,
                    child: pw.Text(
                      '${bucket.totalMeters.toStringAsFixed(0)}m',
                      textAlign: pw.TextAlign.right,
                      style: const pw.TextStyle(
                        color: _textPrimary,
                        fontSize: 7,
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
    // Keep flex in 1..100 to avoid layout blow-ups in package:pdf.
    final int filledFlex = math.max(1, (widthFactor * 100).round());
    final int emptyFlex = math.max(0, 100 - filledFlex);
    final positiveSegments = segments.where((s) => s.$2 > 0).toList();
    final double totalPositive = positiveSegments.fold<double>(
      0,
      (sum, s) => sum + s.$2,
    );

    return pw.SizedBox(
      height: 9,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: filledFlex,
            child: pw.Row(
              children: positiveSegments.isEmpty || totalPositive <= 0
                  ? <pw.Widget>[
                      pw.Expanded(child: pw.Container(color: _border)),
                    ]
                  : positiveSegments.map((s) {
                      final int flex = math.max(
                        1,
                        ((s.$2 / totalPositive) * 100).round(),
                      );
                      return pw.Expanded(
                        flex: flex,
                        child: pw.Container(color: s.$1),
                      );
                    }).toList(),
            ),
          ),
          if (emptyFlex > 0)
            pw.Expanded(
              flex: emptyFlex,
              child: pw.Container(color: _border),
            ),
        ],
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
                _t(z?.label ?? id),
                maxLines: 1,
                style: const pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 7,
                ),
              ),
              pw.Text(
                '${(z?.distanceKm ?? 0).toStringAsFixed(2)} km - ${(z?.occupancyPercent ?? 0).toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 8,
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
      crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                    _t(heatmaps[i].periodLabel),
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.SizedBox(
                    height: 110,
                    child: _buildHeatmapVisual(heatmaps[i]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Same SVG source as the player_analysis Heatmap tab (`pw.SvgImage`).
  pw.Widget _buildHeatmapVisual(SessionStatsReportHeatmapImage heatmap) {
    final String? svg = heatmap.svg?.trim();
    if (svg != null && svg.isNotEmpty) {
      try {
        return pw.SvgImage(
          svg: svg,
          fit: pw.BoxFit.contain,
        );
      } catch (_) {
        // Fall through to PNG if SVG parsing fails in package:pdf.
      }
    }
    final Uint8List? png = heatmap.pngBytes;
    if (png != null && png.isNotEmpty) {
      return pw.Image(
        pw.MemoryImage(png),
        fit: pw.BoxFit.contain,
      );
    }
    return _emptyHint('Heatmap indisponible');
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      _t(title),
      style: pw.TextStyle(
        color: _textPrimary,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _emptyHint(String text) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        _t(text),
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
                    _t('Rapport $eventKind - statistiques tracker'),
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
        if (report.isMatch && report.matchHeader != null)
          _buildMatchScoreline(report.matchHeader!)
        else
          pw.Text(
            _t(report.title),
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
            _t(
              [
                if ((report.dateLabel ?? '').trim().isNotEmpty)
                  report.dateLabel!.trim(),
                if ((report.timeLabel ?? '').trim().isNotEmpty)
                  report.timeLabel!.trim(),
                if ((report.teamName ?? '').trim().isNotEmpty)
                  report.teamName!.trim(),
              ].join(' - '),
            ),
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
                vertical: 7,
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
                    _t(chips[i].$1),
                    style: const pw.TextStyle(
                      color: _textSecondary,
                      fontSize: 8.5,
                    ),
                  ),
                  pw.Text(
                    _t(chips[i].$2),
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 11,
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
    const metrics = kSessionStatsReportMetrics;
    final rows = report.playerRows;

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _border, width: 0.7),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 8.5,
      ),
      cellStyle: const pw.TextStyle(
        color: _textPrimary,
        fontSize: 9,
      ),
      headerAlignments: <int, pw.Alignment>{
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        for (var i = 0; i < metrics.length; i++)
          i + 2: pw.Alignment.center,
      },
      cellAlignments: <int, pw.Alignment>{
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        for (var i = 0; i < metrics.length; i++)
          i + 2: pw.Alignment.center,
      },
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.6),
        1: const pw.FixedColumnWidth(36),
        for (var i = 0; i < metrics.length; i++)
          i + 2: const pw.FlexColumnWidth(1.05),
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
      headers: <String>[
        'Joueur',
        'Tr.',
        ...metrics.map((m) => _t(m.title)),
      ],
      data: <List<String>>[
        for (final row in rows)
          <String>[
            _t(row.displayName),
            row.trackerId.isEmpty ? '-' : _t(row.trackerId),
            ...metrics.map((metric) {
              final value = metric.format(row.metricValue(metric.key));
              final z = row.zScoreValue(metric.key);
              if (z == null) return value;
              final sign = z > 0 ? '+' : '';
              return '$value\n$sign${z.toStringAsFixed(2)}';
            }),
          ],
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Grinta Performance - page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
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
        // Avoid large borderRadius values: package:pdf treats them as circle
        // radius and draws huge discs that cover the page.
        pw.Container(
          width: 7,
          height: 7,
          color: color,
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
