import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/screen/coach_workload_analysis/coach_workload_analysis_models.dart';
import 'package:grinta/services/coach_workload_analysis_service.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_age.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/svg_rasterizer.dart';
import 'package:grinta/util/whoop_hr_zones.dart';
import 'package:grinta/widget/sport_metric_pickers.dart';
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
    final sourceLogos = await _loadSourceLogos();
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
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(16, 12, 16, 10),
          header: (context) => _buildPlayerPageHeader(
            teamName: teamName,
            periodLabel: periodLabel,
            generatedLabel: generatedLabel,
            summary: summary,
            photoBytes: photo,
          ),
          footer: (context) => _reportFooter(context),
          build: (context) => [
            _sectionTitle('Recap'),
            pw.SizedBox(height: 6),
            _buildPlayerRecapGrid(summary),
            pw.SizedBox(height: 12),
            _sectionTitle('Activites'),
            pw.SizedBox(height: 6),
            if (detail.activities.isEmpty)
              pw.Text(
                _ascii('Aucune activite sur cette periode.'),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              )
            else
              _buildActivitiesList(
                activities: detail.activities,
                dateFmt: dateFmt,
                sourceLogos: sourceLogos,
                localeCode: localeCode,
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

  Future<Map<String, Uint8List>> _loadSourceLogos() async {
    final out = <String, Uint8List>{};

    Future<void> loadSvg(String key, String assetPath) async {
      try {
        final svg = await rootBundle.loadString(assetPath);
        final bytes = await brandSvgToPngBytes(svg, targetWidth: 72);
        if (bytes != null && bytes.isNotEmpty) {
          out[key] = bytes;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'CoachWorkloadReportPdfService: logo SVG load failed ($key): $e',
          );
        }
      }
    }

    Future<void> loadPng(String key, String assetPath) async {
      try {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        if (bytes.isNotEmpty) {
          out[key] = bytes;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'CoachWorkloadReportPdfService: logo PNG load failed ($key): $e',
          );
        }
      }
    }

    await Future.wait([
      loadSvg('strava', 'assets/images/strava_logo.svg'),
      loadPng('polar', 'assets/images/polar_logo.png'),
      loadSvg('whoop', 'assets/images/whoop_logo.svg'),
      loadSvg('applehealth', 'assets/images/apple_forme_logo.svg'),
      loadSvg('googlehealth', 'assets/images/google_fit_logo.svg'),
    ]);
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

  pw.Widget _buildPlayerPageHeader({
    required String teamName,
    required String periodLabel,
    required String generatedLabel,
    required CoachPlayerWorkloadSummary summary,
    required Uint8List? photoBytes,
  }) {
    final age = playerAgeYears(summary.player);
    final ageLabel = age == null ? '-' : '$age ans';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _border),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
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
                    pw.Text(
                      _ascii('Analyse charge - $teamName'),
                      maxLines: 1,
                      style: pw.TextStyle(
                        color: _textPrimary,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _ascii(periodLabel),
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
              _playerAvatar(
                photoBytes,
                initials: _initials(summary.player),
                size: 32,
              ),
              pw.SizedBox(width: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _ascii(playerDisplayName(summary.player)),
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _ascii(ageLabel),
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
        ),
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

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      _ascii(title),
      style: pw.TextStyle(
        color: _textPrimary,
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Widget _buildPlayerRecapGrid(CoachPlayerWorkloadSummary summary) {
    final presence = summary.presencePercent;
    final presenceLabel =
        presence == null ? '-' : '${presence.toStringAsFixed(0)} %';
    final loadLabel = summary.avgWorkloadScore == null
        ? '-'
        : summary.avgWorkloadScore!.toStringAsFixed(0);
    final kmLabel = summary.totalDistanceKm == null
        ? '-'
        : '${summary.totalDistanceKm!.toStringAsFixed(1)} km';

    final tiles = <(String, String)>[
      ('Charge', loadLabel),
      ('Distance', kmLabel),
      ('Presence', presenceLabel),
      ('Entrainements', '${summary.trainingPresent}'),
      ('Matchs', '${summary.matchCount}'),
      ('Sports perso', '${summary.personalSportCount}'),
      ('Volume', '${summary.volumeMinutes} min'),
      ('Seances', '${summary.sessionCount}'),
    ];

    final rows = <pw.Widget>[];
    for (var i = 0; i < tiles.length; i += 4) {
      final slice = tiles.skip(i).take(4).toList();
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            children: [
              for (var j = 0; j < 4; j++) ...[
                if (j > 0) pw.SizedBox(width: 5),
                pw.Expanded(
                  child: j < slice.length
                      ? _metricChip(slice[j].$1, slice[j].$2)
                      : pw.SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return pw.Column(children: rows);
  }

  pw.Widget _metricChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              _ascii(label),
              style: const pw.TextStyle(
                color: _textSecondary,
                fontSize: 8.5,
              ),
            ),
          ),
          pw.Text(
            _ascii(value),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildActivitiesList({
    required List<CoachWorkloadActivityItem> activities,
    required DateFormat dateFmt,
    required Map<String, Uint8List> sourceLogos,
    required String localeCode,
  }) {
    final sorted = List<CoachWorkloadActivityItem>.from(activities)
      ..sort((a, b) => b.startAt.compareTo(a.startAt));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sorted.length; i++)
          _activityRow(
            item: sorted[i],
            dateFmt: dateFmt,
            sourceLogos: sourceLogos,
            localeCode: localeCode,
            odd: i.isOdd,
          ),
      ],
    );
  }

  pw.Widget _activityRow({
    required CoachWorkloadActivityItem item,
    required DateFormat dateFmt,
    required Map<String, Uint8List> sourceLogos,
    required String localeCode,
    required bool odd,
  }) {
    final metrics = _activityMetrics(item, localeCode: localeCode);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: odd ? _surface : _white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _border, width: 0.6),
      ),
      margin: const pw.EdgeInsets.only(bottom: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              _activityLeadingIcon(item, sourceLogos),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  _ascii(_activityTypeLabel(item)),
                  maxLines: 1,
                  style: pw.TextStyle(
                    color: _textPrimary,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                _ascii(dateFmt.format(item.startAt)),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 8.5),
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Wrap(
              spacing: 4,
              runSpacing: 3,
              children: [
                for (final metric in metrics)
                  _activityMetricChip(metric.$1, metric.$2),
              ],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _activityMetricChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _border, width: 0.5),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            _ascii(label),
            style: const pw.TextStyle(color: _textSecondary, fontSize: 7.5),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            _ascii(value),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Source-aware metrics shown under each activity row.
  List<(String, String)> _activityMetrics(
    CoachWorkloadActivityItem item, {
    required String localeCode,
  }) {
    switch (item.kind) {
      case CoachWorkloadActivityKind.training:
      case CoachWorkloadActivityKind.match:
        return _sessionActivityMetrics(item);
      case CoachWorkloadActivityKind.personalSport:
        return _personalSportMetrics(
          item.personalSport,
          localeCode: localeCode,
        );
    }
  }

  List<(String, String)> _sessionActivityMetrics(
    CoachWorkloadActivityItem item,
  ) {
    final out = <(String, String)>[];
    if (item.durationMinutes != null && item.durationMinutes! > 0) {
      out.add(('Duree', '${item.durationMinutes} min'));
    }
    if (item.workloadScore != null) {
      out.add(('Charge', item.workloadScore!.toStringAsFixed(0)));
    }
    if (item.distanceKm != null && item.distanceKm! > 0) {
      out.add(('Km', item.distanceKm!.toStringAsFixed(1)));
    }
    if (item.wasPresent == false) {
      out.add(('Presence', 'Absent'));
    }
    return out;
  }

  List<(String, String)> _personalSportMetrics(
    PersonalSportActivity? activity, {
    required String localeCode,
  }) {
    if (activity == null) return const [];
    final source = (activity.externalSource ?? '').trim().toLowerCase();
    switch (source) {
      case 'whoop':
        return _whoopMetrics(activity, localeCode: localeCode);
      case 'strava':
        return _stravaMetrics(activity);
      case 'polar':
        return _polarMetrics(activity);
      default:
        return _genericPersonalMetrics(activity);
    }
  }

  /// Mirrors the in-app Whoop analysis card.
  List<(String, String)> _whoopMetrics(
    PersonalSportActivity activity, {
    required String localeCode,
  }) {
    final out = <(String, String)>[];
    if (activity.strain != null && activity.strain! > 0) {
      out.add((
        'Effort activite',
        formatWhoopStrain(activity.strain!, locale: localeCode),
      ));
    }
    if (activity.averageHeartRateBpm != null &&
        activity.averageHeartRateBpm! > 0) {
      out.add(('FC moyenne', '${activity.averageHeartRateBpm}'));
    }
    if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
      out.add(('Duree', formatWhoopDuration(activity.durationSeconds!)));
    }
    if (activity.maxHeartRateBpm != null && activity.maxHeartRateBpm! > 0) {
      out.add(('FC max', '${activity.maxHeartRateBpm} bpm'));
    }
    if (activity.caloriesKcal != null && activity.caloriesKcal! > 0) {
      out.add(('Calories', '${activity.caloriesKcal!.round()} kcal'));
    }
    if (activity.altitudeGainMeters != null &&
        activity.altitudeGainMeters! > 0) {
      out.add(('Deneivele', '+${activity.altitudeGainMeters!.round()} m'));
    }
    return out;
  }

  /// Mirrors the Strava-style personal summary (distance / duree / allure / kcal).
  List<(String, String)> _stravaMetrics(PersonalSportActivity activity) {
    final out = <(String, String)>[];
    if (activity.distanceMeters != null && activity.distanceMeters! > 0) {
      out.add((
        'Distance',
        formatSportDistanceKm(
          activity.distanceMeters! / 1000,
          activity.distanceUnit,
        ),
      ));
    }
    if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
      out.add((
        'Duree',
        formatSportDurationClock(Duration(seconds: activity.durationSeconds!)),
      ));
    }
    if (activity.paceSecondsPerKm != null && activity.paceSecondsPerKm! > 0) {
      out.add((
        'Allure moy.',
        formatSportPace(activity.paceSecondsPerKm!, activity.paceUnit),
      ));
    }
    if (activity.caloriesKcal != null && activity.caloriesKcal! > 0) {
      out.add(('Calories', '${activity.caloriesKcal!.round()} kcal'));
    }
    return out;
  }

  /// Polar personal metrics — same HR set as the Polar cards, without samples.
  List<(String, String)> _polarMetrics(PersonalSportActivity activity) {
    final out = <(String, String)>[];
    if (activity.durationSeconds != null && activity.durationSeconds! > 0) {
      final minutes = (activity.durationSeconds! / 60).round();
      if (minutes > 0) {
        out.add(('Duree', '$minutes min'));
      }
    }
    if (activity.averageHeartRateBpm != null &&
        activity.averageHeartRateBpm! > 0) {
      out.add(('FC moy.', '${activity.averageHeartRateBpm} bpm'));
    }
    if (activity.maxHeartRateBpm != null && activity.maxHeartRateBpm! > 0) {
      out.add(('FC max', '${activity.maxHeartRateBpm} bpm'));
    }
    if (activity.minHeartRateBpm != null && activity.minHeartRateBpm! > 0) {
      out.add(('FC min', '${activity.minHeartRateBpm} bpm'));
    }
    return out;
  }

  List<(String, String)> _genericPersonalMetrics(
    PersonalSportActivity activity,
  ) {
    // Manual / GPS / Health: Strava-like set when values exist.
    return _stravaMetrics(activity);
  }

  pw.Widget _activityLeadingIcon(
    CoachWorkloadActivityItem item,
    Map<String, Uint8List> sourceLogos,
  ) {
    const size = 16.0;

    if (item.kind == CoachWorkloadActivityKind.personalSport) {
      final key = (item.personalSport?.externalSource ?? '')
          .trim()
          .toLowerCase();
      final bytes = sourceLogos[key];
      if (bytes != null && bytes.isNotEmpty) {
        return pw.SizedBox(
          width: size,
          height: size,
          child: pw.Image(
            pw.MemoryImage(bytes),
            fit: pw.BoxFit.contain,
            width: size,
            height: size,
          ),
        );
      }
      return _typeBadge('P', size: size);
    }

    switch (item.kind) {
      case CoachWorkloadActivityKind.training:
        return _typeBadge('E', size: size);
      case CoachWorkloadActivityKind.match:
        return _typeBadge('M', size: size);
      case CoachWorkloadActivityKind.personalSport:
        return _typeBadge('P', size: size);
    }
  }

  pw.Widget _typeBadge(String letter, {double size = 16}) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        letter,
        style: pw.TextStyle(
          color: _white,
          fontSize: size * 0.55,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
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
