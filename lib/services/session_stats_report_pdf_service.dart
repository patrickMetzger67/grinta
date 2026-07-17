import 'dart:typed_data';

import 'package:grinta/model/session_stats_report.dart';
import 'package:grinta/model/tracker/team_workload_summary.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a [SessionStatsReport] to PDF bytes (Stats-tab metrics).
class SessionStatsReportPdfService {
  /// Brand colors aligned with invitation emails / AppColors.light.
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF9FAFB);

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
    final eventKind = report.isMatch ? 'Match' : 'Entraînement';
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
      ('Durée', '$durationMinutes min'),
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
    final headers = <String>[
      'Joueur',
      'Tracker',
      ...kSessionStatsReportMetrics.map(
        (m) => '${m.title}\n(${m.unit})',
      ),
    ];

    final data = report.playerRows.map((row) {
      return <String>[
        row.displayName,
        row.trackerId.isEmpty ? '-' : row.trackerId,
        ...kSessionStatsReportMetrics.map(
          (m) => m.format(row.metricValue(m.key)),
        ),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(fontSize: 8, color: _textPrimary),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        for (var i = 2; i < headers.length; i++) i: pw.Alignment.centerRight,
      },
      border: pw.TableBorder.all(color: _border, width: 0.5),
      headerAlignment: pw.Alignment.centerLeft,
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.0),
        for (var i = 2; i < headers.length; i++)
          i: const pw.FlexColumnWidth(1.1),
      },
    );
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
