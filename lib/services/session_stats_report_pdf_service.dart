import 'dart:typed_data';

import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [SessionStatsReport] to PDF bytes (Stats-tab metrics + z-scores).
class SessionStatsReportPdfService {
  /// Brand colors aligned with invitation emails / AppColors.
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor _success = PdfColor.fromInt(0xFF1FA971);
  static const PdfColor _danger = PdfColor.fromInt(0xFFE53935);

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
        header: (context) => _buildHeader(report, generatedLabel),
        footer: (context) => _buildFooter(context),
        build: (context) => <pw.Widget>[
          pw.SizedBox(height: 12),
          _buildSummaryRow(report),
          pw.SizedBox(height: 16),
          _buildPlayersTable(report),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(SessionStatsReport report, String generatedLabel) {
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
            (report.teamName ?? '').trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              [
                if ((report.dateLabel ?? '').trim().isNotEmpty)
                  report.dateLabel!.trim(),
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
}
