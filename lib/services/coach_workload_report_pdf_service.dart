import 'package:flutter/foundation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/coach_workload_analysis_service.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a coach workload analysis report (team × period) to PDF bytes.
class CoachWorkloadReportPdfService {
  CoachWorkloadReportPdfService({
    http.Client? httpClient,
    CoachWorkloadAnalysisService? analysisService,
  })  : _httpClient = httpClient ?? http.Client(),
        _analysisService = analysisService ?? CoachWorkloadAnalysisService();

  final http.Client _httpClient;
  final CoachWorkloadAnalysisService _analysisService;

  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _white = PdfColors.white;
  static const int _detailBatchSize = 4;

  Future<Uint8List> buildPdf({
    required CoachTeamWorkloadReport report,
    required Team team,
    required String seasonId,
    required String teamName,
    required DateTime rangeStart,
    required DateTime rangeEndInclusive,
    String localeCode = 'fr',
  }) async {
    final photosByMemberId = await _loadPhotos(report.summaries);
    final details = await _loadPlayerDetails(
      report: report,
      team: team,
      seasonId: seasonId,
      rangeStart: rangeStart,
      rangeEndInclusive: rangeEndInclusive,
    );
    final doc = pw.Document();
    final generatedLabel = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final periodLabel =
        '${DateFormat.yMMMd(localeCode).format(rangeStart)} - '
        '${DateFormat.yMMMd(localeCode).format(rangeEndInclusive)}';
    final dateFmt = DateFormat.yMMMd(localeCode).add_Hm();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(18, 14, 18, 14),
        header: (context) => _reportHeader(
          title: 'Analyse charge - $teamName',
          subtitle: '$periodLabel  |  gen. $generatedLabel',
        ),
        footer: (context) => _reportFooter(context),
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

    for (final detail in details) {
      final summary = detail.summary;
      final photo = photosByMemberId[summary.memberId.trim()];
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(22, 18, 22, 18),
          header: (context) => _reportHeader(
            title: playerDisplayName(summary.player),
            subtitle: 'Analyse charge - $teamName  |  $periodLabel',
          ),
          footer: (context) => _reportFooter(context),
          build: (context) => [
            _buildPlayerRecap(
              summary: summary,
              photoBytes: photo,
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              _ascii('Activites'),
              style: pw.TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (detail.activities.isEmpty)
              pw.Text(
                _ascii('Aucune activite sur cette periode.'),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
              )
            else
              _buildActivitiesTable(
                activities: detail.activities,
                dateFmt: dateFmt,
              ),
          ],
        ),
      );
    }

    return doc.save();
  }

  Future<List<CoachPlayerWorkloadDetail>> _loadPlayerDetails({
    required CoachTeamWorkloadReport report,
    required Team team,
    required String seasonId,
    required DateTime rangeStart,
    required DateTime rangeEndInclusive,
  }) async {
    final endExclusive =
        rangeEndInclusive.add(const Duration(days: 1));
    final out = <CoachPlayerWorkloadDetail>[];
    final summaries = report.summaries;
    for (var i = 0; i < summaries.length; i += _detailBatchSize) {
      final batch = summaries.skip(i).take(_detailBatchSize).toList();
      final results = await Future.wait(
        batch.map((summary) async {
          try {
            return await _analysisService.loadPlayerDetail(
              team: team,
              seasonId: seasonId,
              start: rangeStart,
              end: endExclusive,
              player: summary.player,
            );
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                'CoachWorkloadReportPdfService: detail load failed '
                'for ${summary.memberId}: $e',
              );
            }
            return CoachPlayerWorkloadDetail(
              summary: summary,
              activities: const [],
              teamAverages: report.teamAverages,
            );
          }
        }),
      );
      out.addAll(results);
    }
    return out;
  }

  pw.Widget _reportHeader({
    required String title,
    required String subtitle,
  }) {
    return pw.Column(
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
                    _ascii(title),
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _ascii(subtitle),
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
    );
  }

  pw.Widget _reportFooter(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Grinta  |  ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
      ),
    );
  }

  pw.Widget _buildPlayerRecap({
    required CoachPlayerWorkloadSummary summary,
    required Uint8List? photoBytes,
  }) {
    final presence = summary.presencePercent;
    final presenceLabel =
        presence == null ? '-' : '${presence.toStringAsFixed(0)} %';
    final loadLabel = summary.avgWorkloadScore == null
        ? '-'
        : summary.avgWorkloadScore!.toStringAsFixed(0);
    final kmLabel = summary.totalDistanceKm == null
        ? '-'
        : summary.totalDistanceKm!.toStringAsFixed(1);

    final chips = <String>[
      'Charge $loadLabel',
      '$kmLabel km',
      '${summary.trainingPresent} entrainements',
      '${summary.personalSportCount} perso',
      '${summary.matchCount} matchs',
      'Presence $presenceLabel',
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              _playerAvatar(
                photoBytes,
                initials: _initials(summary.player),
                size: 34,
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  _ascii(playerDisplayName(summary.player)),
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final chip in chips) _pdfChip(chip),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _ascii(
              '${summary.trainingPresent} entrainements · '
              '${summary.matchCount} matchs · '
              '${summary.personalSportCount} sports perso · '
              '${summary.volumeMinutes} min',
            ),
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfChip(String label) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(999)),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      child: pw.Text(
        _ascii(label),
        style: pw.TextStyle(
          color: _textPrimary,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _buildActivitiesTable({
    required List<CoachWorkloadActivityItem> activities,
    required DateFormat dateFmt,
  }) {
    final sorted = List<CoachWorkloadActivityItem>.from(activities)
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(1.1),
        3: pw.FlexColumnWidth(1.0),
        4: pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primary),
          children: [
            for (final header in const [
              'Type',
              'Date',
              'Duree',
              'Charge',
              'Km',
            ])
              _headerCell(header),
          ],
        ),
        for (var i = 0; i < sorted.length; i++)
          pw.TableRow(
            decoration: i.isOdd ? const pw.BoxDecoration(color: _surface) : null,
            children: [
              _valueCell(
                _activityTypeLabel(sorted[i]),
                align: pw.Alignment.centerLeft,
              ),
              _valueCell(
                dateFmt.format(sorted[i].startAt),
                align: pw.Alignment.centerLeft,
              ),
              _valueCell(
                sorted[i].durationMinutes == null ||
                        sorted[i].durationMinutes! <= 0
                    ? '-'
                    : '${sorted[i].durationMinutes} min',
              ),
              _valueCell(
                sorted[i].workloadScore == null
                    ? '-'
                    : sorted[i].workloadScore!.toStringAsFixed(0),
              ),
              _valueCell(
                sorted[i].distanceKm == null || sorted[i].distanceKm! <= 0
                    ? '-'
                    : sorted[i].distanceKm!.toStringAsFixed(1),
              ),
            ],
          ),
      ],
    );
  }

  String _activityTypeLabel(CoachWorkloadActivityItem item) {
    switch (item.kind) {
      case CoachWorkloadActivityKind.training:
        final absent = item.wasPresent == false ? ' (absent)' : '';
        return 'Entrainement$absent';
      case CoachWorkloadActivityKind.match:
        final home = (item.match?.team1 ?? '').trim();
        final away = (item.match?.team2 ?? '').trim();
        if (home.isNotEmpty && away.isNotEmpty) {
          return 'Match $home - $away';
        }
        return 'Match';
      case CoachWorkloadActivityKind.personalSport:
        final title = (item.personalSport?.title ?? '').trim();
        return title.isEmpty ? 'Sport perso' : title;
    }
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

  pw.Widget _valueCell(
    String value, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 22),
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        _ascii(value),
        maxLines: 2,
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
