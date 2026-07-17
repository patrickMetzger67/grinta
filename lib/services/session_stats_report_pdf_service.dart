import 'dart:math' as math;
import 'dart:typed_data';

import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [SessionStatsReport] to PDF bytes (recap table + player pages).
class SessionStatsReportPdfService {
  /// Brand colors aligned with invitation emails / AppColors.
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor _success = PdfColor.fromInt(0xFF1FA971);
  static const PdfColor _danger = PdfColor.fromInt(0xFFE53935);
  static const PdfColor _warning = PdfColor.fromInt(0xFFF5A524);
  static const PdfColor _secondary = PdfColor.fromInt(0xFF3B82F6);

  Future<Uint8List> buildPdf(
    SessionStatsReport report, {
    String localeCode = 'fr',
  }) async {
    final doc = pw.Document();
    final generatedLabel = DateFormat('yyyy-MM-dd HH:mm').format(
      report.generatedAt,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildRecapHeader(report, generatedLabel),
        footer: (context) => _buildFooter(context),
        build: (context) => <pw.Widget>[
          pw.SizedBox(height: 12),
          _buildSummaryRow(report),
          pw.SizedBox(height: 16),
          _buildPlayersTable(report),
        ],
      ),
    );

    if (report.playerDetails.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          footer: (context) => _buildFooter(context),
          build: (context) {
            final widgets = <pw.Widget>[];
            for (var i = 0; i < report.playerDetails.length; i++) {
              if (i > 0) {
                widgets.add(pw.NewPage());
              }
              widgets.addAll(
                _buildPlayerPageContent(
                  report,
                  report.playerDetails[i],
                  generatedLabel,
                ),
              );
            }
            return widgets;
          },
        ),
      );
    }

    return doc.save();
  }

  List<pw.Widget> _buildPlayerPageContent(
    SessionStatsReport report,
    SessionStatsReportPlayerDetail player,
    String generatedLabel,
  ) {
    return <pw.Widget>[
      _buildPlayerPageHeader(report, player, generatedLabel),
      pw.SizedBox(height: 14),
      _sectionTitle('Synthese'),
      pw.SizedBox(height: 8),
      _buildSynthesisGrid(player),
      pw.SizedBox(height: 14),
      _sectionTitle('Zones de vitesse'),
      pw.SizedBox(height: 8),
      if (player.speedZones.isEmpty)
        _emptyHint('Aucune zone de vitesse')
      else
        ...player.speedZones.map(_buildSpeedZoneRow),
      pw.SizedBox(height: 14),
      _sectionTitle('Timeline distance'),
      pw.SizedBox(height: 8),
      if (player.distanceTimeline.isEmpty)
        _emptyHint('Aucune timeline distance')
      else
        _buildTimelineChart(player.distanceTimeline),
      if (report.isMatch) ...[
        pw.SizedBox(height: 14),
        _sectionTitle('Zones de terrain'),
        pw.SizedBox(height: 8),
        if (player.fieldZones.isEmpty)
          _emptyHint('Aucune zone de terrain')
        else
          _buildFieldZonesGrid(player.fieldZones),
        pw.SizedBox(height: 14),
        _sectionTitle('Heatmaps'),
        pw.SizedBox(height: 8),
        if (player.heatmaps.isEmpty)
          _emptyHint('Aucune heatmap disponible')
        else
          _buildHeatmaps(player.heatmaps),
      ],
    ];
  }

  pw.Widget _buildPlayerPageHeader(
    SessionStatsReport report,
    SessionStatsReportPlayerDetail player,
    String generatedLabel,
  ) {
    final match = report.matchHeader;
    final sessionLine = <String>[
      if (report.isMatch) ...[
        if ((match?.opponentName ?? '').trim().isNotEmpty)
          'vs ${match!.opponentName!.trim()}'
        else
          report.title,
        if ((match?.scoreLabel ?? '').trim().isNotEmpty) match!.scoreLabel,
      ] else
        report.title,
    ].join('  ·  ');

    final dateTimeLine = <String>[
      if ((report.dateLabel ?? '').trim().isNotEmpty) report.dateLabel!.trim(),
      if ((report.timeLabel ?? '').trim().isNotEmpty) report.timeLabel!.trim(),
    ].join(' · ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GRINTA',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              pw.Text(
                generatedLabel,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (match?.opponentLogoBytes != null) ...[
              pw.Container(
                width: 28,
                height: 28,
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _border),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 6,
                  verticalRadius: 6,
                  child: pw.Image(
                    pw.MemoryImage(match!.opponentLogoBytes!),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    sessionLine,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (dateTimeLine.isNotEmpty)
                    pw.Text(
                      dateTimeLine,
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  if ((report.teamName ?? '').trim().isNotEmpty)
                    pw.Text(
                      report.teamName!.trim(),
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Row(
            children: [
              _playerAvatar(player.photoBytes),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      player.displayName,
                      style: pw.TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      player.trackerId.trim().isEmpty
                          ? 'Tracker -'
                          : 'Tracker ${player.trackerId.trim()}',
                      style: const pw.TextStyle(
                        color: _textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _playerAvatar(Uint8List? bytes) {
    if (bytes != null && bytes.isNotEmpty) {
      return pw.Container(
        width: 42,
        height: 42,
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
      width: 42,
      height: 42,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: _border,
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'J',
        style: pw.TextStyle(
          color: _textSecondary,
          fontWeight: pw.FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  pw.Widget _buildSynthesisGrid(SessionStatsReportPlayerDetail player) {
    final tiles = <(String, String)>[
      ('Distance', '${player.distanceKm.toStringAsFixed(2)} km'),
      ('Vitesse moy.', '${player.averageSpeedKmh.toStringAsFixed(1)} km/h'),
      (
        'Vitesse max',
        '${player.maxValidatedSpeedKmh.toStringAsFixed(1)} km/h',
      ),
      ('Acc. max', '${player.maxAccelerationMps2.toStringAsFixed(2)} m/s2'),
      ('Sprints', '${player.sprintCount}'),
      ('Acc. hautes', '${player.highAccelerationCount}'),
      ('Haute vitesse', _formatDurationShort(player.highSpeedDuration)),
      ('Workload', '${player.workloadScore.toStringAsFixed(0)} pts'),
      ('Fatigue', player.fatigueIndex.toStringAsFixed(2)),
      ('Duree', _formatDurationLong(player.duration)),
    ];

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tiles
          .map(
            (tile) => pw.Container(
              width: 118,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _surface,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tile.$1,
                    style: const pw.TextStyle(
                      color: _textSecondary,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    tile.$2,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildSpeedZoneRow(SessionStatsReportSpeedZoneRow zone) {
    final double percent = zone.percent.clamp(0, 100);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${zone.label}  (${zone.rangeLabel})',
                  style: const pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 9,
                  ),
                ),
              ),
              pw.Text(
                '${_formatDurationShort(zone.duration)}  ·  ${percent.toStringAsFixed(1)} %',
                style: pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: pw.Container(
              height: 7,
              color: _border,
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: math.max(1, (percent * 10).round()),
                    child: pw.Container(color: _zoneColor(zone.zoneId)),
                  ),
                  pw.Expanded(
                    flex: math.max(1, ((100 - percent) * 10).round()),
                    child: pw.SizedBox(),
                  ),
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
    final double maxMeters = timeline
        .map((e) => e.totalMeters)
        .fold<double>(0, (prev, value) => math.max(prev, value));
    final double safeMax = maxMeters <= 0 ? 1 : maxMeters;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Wrap(
          spacing: 10,
          runSpacing: 4,
          children: <pw.Widget>[
            _buildLegendDot(label: 'Marche', color: _textSecondary),
            _buildLegendDot(label: 'Jogging', color: _primary),
            _buildLegendDot(label: 'Course', color: _secondary),
            _buildLegendDot(label: 'Haute intensite', color: _warning),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            children: timeline.map((bucket) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  children: [
                    pw.SizedBox(
                      width: 48,
                      child: pw.Text(
                        bucket.label,
                        style: const pw.TextStyle(
                          color: _textSecondary,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: _stackedBar(
                        bucket: bucket,
                        maxMeters: safeMax,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.SizedBox(
                      width: 40,
                      child: pw.Text(
                        '${bucket.totalMeters.toStringAsFixed(0)} m',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                          color: _textPrimary,
                          fontSize: 7.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
      horizontalRadius: 3,
      verticalRadius: 3,
      child: pw.Container(
        height: 10,
        color: _border,
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: filledFlex,
              child: pw.Row(
                children: positiveSegments.isEmpty
                    ? <pw.Widget>[pw.Expanded(child: pw.SizedBox())]
                    : positiveSegments.map((s) {
                        final double flex =
                            (s.$2 / bucket.totalMeters).clamp(0.001, 1.0);
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
          margin: const pw.EdgeInsets.all(3),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                z?.label ?? id,
                style: const pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                '${(z?.distanceKm ?? 0).toStringAsFixed(2)} km',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${(z?.occupancyPercent ?? 0).toStringAsFixed(1)} %',
                style: const pw.TextStyle(
                  color: _textSecondary,
                  fontSize: 8,
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

  pw.Widget _buildHeatmaps(List<SessionStatsReportHeatmapImage> heatmaps) {
    return pw.Column(
      children: heatmaps.map((heatmap) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                heatmap.periodLabel,
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                width: double.infinity,
                height: 180,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _border),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.white,
                ),
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Image(
                    pw.MemoryImage(heatmap.pngBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        color: _textPrimary,
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _emptyHint(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
    );
  }

  pw.Widget _buildRecapHeader(SessionStatsReport report, String generatedLabel) {
    final eventKind = report.isMatch ? 'Match' : 'Entrainement';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: pw.BoxDecoration(
            color: _primary,
            borderRadius: pw.BorderRadius.circular(10),
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
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Rapport $eventKind - statistiques tracker',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              pw.Text(
                generatedLabel,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          report.title,
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if ((report.subtitle ?? '').trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              report.subtitle!.trim(),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ),
        if ((report.dateLabel ?? '').trim().isNotEmpty ||
            (report.timeLabel ?? '').trim().isNotEmpty ||
            (report.teamName ?? '').trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              [
                if ((report.dateLabel ?? '').trim().isNotEmpty)
                  report.dateLabel!.trim(),
                if ((report.timeLabel ?? '').trim().isNotEmpty)
                  report.timeLabel!.trim(),
                if ((report.teamName ?? '').trim().isNotEmpty)
                  report.teamName!.trim(),
              ].join(' · '),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
            ),
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

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips
          .map(
            (chip) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _surface,
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    chip.$1,
                    style: const pw.TextStyle(
                      color: _textSecondary,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    chip.$2,
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  pw.Widget _buildPlayersTable(SessionStatsReport report) {
    final metrics = kSessionStatsReportMetrics;

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.5),
      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(0.9),
        for (var i = 0; i < metrics.length; i++)
          i + 2: const pw.FlexColumnWidth(1.25),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: <pw.Widget>[
            _headerCell('Joueur'),
            _headerCell('Tracker'),
            ...metrics.map(
              (m) => _headerCell('${m.title}\n(${m.unit})', alignRight: true),
            ),
          ],
        ),
        for (var rowIndex = 0; rowIndex < report.playerRows.length; rowIndex++)
          pw.TableRow(
            decoration: rowIndex.isOdd
                ? const pw.BoxDecoration(color: _surface)
                : null,
            children: <pw.Widget>[
              _textCell(report.playerRows[rowIndex].displayName),
              _textCell(
                report.playerRows[rowIndex].trackerId.isEmpty
                    ? '-'
                    : report.playerRows[rowIndex].trackerId,
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

  pw.Widget _headerCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 7.5,
        ),
      ),
    );
  }

  pw.Widget _textCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: _textPrimary),
      ),
    );
  }

  pw.Widget _metricCell({
    required String valueLabel,
    required double? zScore,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            valueLabel,
            style: pw.TextStyle(
              fontSize: 8,
              color: _textPrimary,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (zScore != null) ...[
            pw.SizedBox(width: 3),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColor(color.red, color.green, color.blue, 0.12),
        borderRadius: pw.BorderRadius.circular(999),
        border: pw.Border.all(
          color: PdfColor(color.red, color.green, color.blue, 0.35),
          width: 0.6,
        ),
      ),
      child: pw.Text(
        label,
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
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Grinta Performance - page ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
      ),
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

  static pw.Widget _buildLegendDot({
    required String label,
    required PdfColor color,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(999),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            color: _textSecondary,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
