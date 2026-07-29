import 'package:flutter/foundation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a coach workload analysis report (team × period) to PDF bytes.
class CoachWorkloadReportPdfService {
  CoachWorkloadReportPdfService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

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
    final photosByMemberId = await _loadPhotos(report.summaries);
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
            _buildTable(report, photosByMemberId),
            pw.SizedBox(height: 10),
            pw.Text(
              _ascii(
                'Charge = moyenne workload tracker. '
                'Km = total tracker + sports perso (visibilite coach/equipe, hors prive). '
                'Colonne Perso = nombre d activites sportives personnelles.',
              ),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<Map<String, Uint8List>> _loadPhotos(
    List<CoachPlayerWorkloadSummary> summaries,
  ) async {
    final out = <String, Uint8List>{};
    // Limit concurrency to avoid flooding Storage / network on large rosters.
    const batchSize = 6;
    for (var i = 0; i < summaries.length; i += batchSize) {
      final batch = summaries.skip(i).take(batchSize).toList(growable: false);
      final results = await Future.wait(
        batch.map((summary) async {
          final key = summary.memberId.trim();
          if (key.isEmpty) return null;
          final bytes = await _loadPlayerPhotoBytes(summary.player);
          if (bytes == null || bytes.isEmpty) return null;
          return MapEntry(key, bytes);
        }),
      );
      for (final entry in results) {
        if (entry == null) continue;
        out[entry.key] = entry.value;
      }
    }
    return out;
  }

  Future<Uint8List?> _loadPlayerPhotoBytes(Player player) async {
    try {
      final urls = await resolvePlayerAvatarUrls(player);
      for (final url in urls) {
        final bytes = await _downloadBytes(url);
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CoachWorkloadReportPdfService: photo load failed: $e');
      }
    }
    return null;
  }

  Future<Uint8List?> _downloadBytes(String? url) async {
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    try {
      final uri = Uri.tryParse(trimmed);
      if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
        return null;
      }
      final response = await _httpClient.get(uri);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  pw.Widget _buildTable(
    CoachTeamWorkloadReport report,
    Map<String, Uint8List> photosByMemberId,
  ) {
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

    final columnWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.6),
      for (var i = 1; i < headers.length; i++) i: const pw.FlexColumnWidth(1),
    };

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            for (final header in headers)
              _headerCell(header),
          ],
        ),
        for (var index = 0; index < report.summaries.length; index++)
          _dataRow(
            summary: report.summaries[index],
            photoBytes: photosByMemberId[report.summaries[index].memberId.trim()],
            odd: index.isOdd,
          ),
      ],
    );
  }

  pw.TableRow _dataRow({
    required CoachPlayerWorkloadSummary summary,
    required Uint8List? photoBytes,
    required bool odd,
  }) {
    final cells = <String>[
      '', // player cell built separately
      '${summary.sessionCount}',
      summary.avgWorkloadScore?.toStringAsFixed(0) ?? '-',
      summary.totalDistanceKm?.toStringAsFixed(1) ?? '-',
      '${summary.volumeMinutes}',
      summary.presencePercent == null
          ? '-'
          : '${summary.presencePercent!.toStringAsFixed(0)}%',
      '${summary.trainingPresent}',
      '${summary.matchCount}',
      '${summary.personalSportCount}',
    ];

    return pw.TableRow(
      decoration: odd ? const pw.BoxDecoration(color: _surface) : null,
      children: [
        _playerCell(
          name: playerDisplayName(summary.player),
          photoBytes: photoBytes,
          initials: _initials(summary.player),
        ),
        for (var i = 1; i < cells.length; i++)
          _valueCell(cells[i]),
      ],
    );
  }

  pw.Widget _headerCell(String label) {
    return pw.Container(
      height: 24,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        _ascii(label),
        style: pw.TextStyle(
          color: _white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget _playerCell({
    required String name,
    required Uint8List? photoBytes,
    required String initials,
  }) {
    return pw.Container(
      height: 28,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Row(
        children: [
          _playerAvatar(photoBytes, initials: initials, size: 18),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              _ascii(name),
              maxLines: 1,
              style: const pw.TextStyle(color: _textPrimary, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _valueCell(String value) {
    return pw.Container(
      height: 28,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        _ascii(value),
        style: const pw.TextStyle(color: _textPrimary, fontSize: 9),
      ),
    );
  }

  pw.Widget _playerAvatar(
    Uint8List? bytes, {
    required String initials,
    double size = 18,
  }) {
    if (bytes != null && bytes.isNotEmpty) {
      return pw.SizedBox(
        width: size,
        height: size,
        child: pw.ClipOval(
          child: pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.cover,
            width: size,
            height: size,
          ),
        ),
      );
    }

    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: _surface,
        border: pw.Border.all(color: _border),
      ),
      child: pw.Text(
        _ascii(initials),
        style: pw.TextStyle(
          color: _textSecondary,
          fontWeight: pw.FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  String _initials(Player player) {
    final first = (player.firstName ?? '').trim();
    final last = (player.lastName ?? '').trim();
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final value = ('$a$b').toUpperCase();
    return value.isEmpty ? 'J' : value;
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
