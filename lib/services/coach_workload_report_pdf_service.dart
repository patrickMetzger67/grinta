import 'dart:typed_data';

import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a coach workload analysis report (team × period) to PDF bytes.
class CoachWorkloadReportPdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _white = PdfColors.white;

  Future<Uint8List> buildPdf({
    required CoachTeamWorkloadReport report,
    required String teamName,
    required DateTime rangeStart,
    required DateTime rangeEndInclusive,
    String localeCode = 'fr',
  }) async {
    final doc = pw.Document();
    final generatedLabel = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final periodLabel =
        '${DateFormat.yMMMd(localeCode).format(rangeStart)} - '
        '${DateFormat.yMMMd(localeCode).format(rangeEndInclusive)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 10,
                  height: 28,
                  decoration: const pw.BoxDecoration(
                    color: _primary,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _ascii('Analyse charge - $teamName'),
                        style: pw.TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        _ascii('$periodLabel  |  gen. $generatedLabel'),
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
            pw.SizedBox(height: 10),
            pw.Divider(color: _border, thickness: 0.8),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Grinta  |  ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
        ),
        build: (context) {
          return [
            _buildTable(report),
            pw.SizedBox(height: 10),
            pw.Text(
              _ascii(
                'Charge = moyenne workload tracker. '
                'Km = total tracker + sports perso (non prives). '
                'Vert / orange = vs moyenne equipe.',
              ),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildTable(CoachTeamWorkloadReport report) {
    final headers = <String>[
      'Joueur',
      'Seances',
      'Charge',
      'Km total',
      'Volume (min)',
      'Presence',
      'Entr.',
      'Matchs',
      'Perso',
    ];

    final data = <List<String>>[
      for (final s in report.summaries)
        [
          _ascii(playerDisplayName(s.player)),
          '${s.sessionCount}',
          s.avgWorkloadScore?.toStringAsFixed(0) ?? '-',
          s.totalDistanceKm?.toStringAsFixed(1) ?? '-',
          '${s.volumeMinutes}',
          s.presencePercent == null
              ? '-'
              : '${s.presencePercent!.toStringAsFixed(0)}%',
          '${s.trainingPresent}',
          '${s.matchCount}',
          '${s.personalSportCount}',
        ],
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers.map(_ascii).toList(),
      data: data,
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(color: _textPrimary, fontSize: 9),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        for (var i = 1; i < headers.length; i++) i: pw.Alignment.center,
      },
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
      border: pw.TableBorder.all(color: _border, width: 0.4),
      headerHeight: 22,
      cellHeight: 20,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );
  }

  String _ascii(String value) {
    return value
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('À', 'A')
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-');
  }
}
