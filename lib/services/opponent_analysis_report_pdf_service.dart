import 'dart:math' as math;
import 'dart:typed_data';

import 'package:grinta/model/match.dart';
import 'package:grinta/services/opponent_analysis_report_data_service.dart';
import 'package:grinta/services/team_competition_stats_service.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_player_match_stats_helper.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders opponent analysis (Adversaires screens) as a Grinta-branded PDF.
class OpponentAnalysisReportPdfService {
  static const PdfColor _primary = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF111214);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _border = PdfColor.fromInt(0xFFD1D5DB);
  static const PdfColor _surface = PdfColor.fromInt(0xFFF3F4F6);
  static const PdfColor _white = PdfColors.white;
  static const PdfColor _win = PdfColor.fromInt(0xFF22C55E);
  static const PdfColor _draw = PdfColor.fromInt(0xFFF59E0B);
  static const PdfColor _loss = PdfColor.fromInt(0xFFEF4444);
  static const PdfColor _seriesOrange = PdfColor.fromInt(0xFFF95C1B);
  static const PdfColor _seriesGreen = PdfColor.fromInt(0xFF22C55E);
  static const PdfColor _seriesCyan = PdfColor.fromInt(0xFF26C6DA);
  static const PdfColor _seriesPurple = PdfColor.fromInt(0xFFAB47BC);

  Future<Uint8List> buildPdf({
    required OpponentAnalysisReportData data,
    String localeCode = 'fr',
  }) async {
    final doc = pw.Document();
    final generatedLabel =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final kickoffLabel =
        DateFormat('yyyy-MM-dd HH:mm').format(data.upcomingKickoff);
    final dateFmt = DateFormat('yyyy-MM-dd');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
        header: (context) => _header(
          title: 'Analyse adversaire - ${data.opponent.displayName}',
          subtitle:
              '${data.teamName}  |  ${data.competitionLabel}  |  Match $kickoffLabel  |  gen. $generatedLabel',
        ),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _sectionTitle('Tendance'),
            pw.Text(
              _ascii(_trendLabel(data.trend.direction)),
              style: pw.TextStyle(
                color: _trendColor(data.trend.direction),
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 14),
            _wdlBlock(
              title: 'Saison complete',
              period: data.wdl.fullSeason,
            ),
            pw.SizedBox(height: 10),
            _wdlBlock(
              title: '1ere partie',
              period: data.wdl.firstHalf,
            ),
            pw.SizedBox(height: 10),
            _wdlBlock(
              title: '2eme partie',
              period: data.wdl.secondHalf,
            ),
            pw.SizedBox(height: 18),
            _sectionTitle('Resultats - Victoires'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.win,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 12),
            _sectionTitle('Resultats - Nuls'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.draw,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 12),
            _sectionTitle('Resultats - Defaites'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.loss,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 18),
            _sectionTitle('Buts'),
            ..._goalsSection(data),
            pw.SizedBox(height: 18),
            _sectionTitle('Evolution du classement'),
            _rankingEvolution(data),
          ];
        },
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
        header: (context) => _header(
          title: 'Joueurs - ${data.opponent.displayName}',
          subtitle: data.competitionLabel,
        ),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _sectionTitle('Effectif adversaire'),
            _playersTable(data.players),
            pw.SizedBox(height: 18),
            _sectionTitle('Equipe type - Titulaires probables'),
            pw.Text(
              _ascii(
                data.typicalTeam.hasSquadData
                    ? 'Base sur ${data.typicalTeam.matchesWithSquadData} matchs avec composition'
                    : 'Pas assez de compositions disponibles',
              ),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            _typicalTeamTable(
              data.typicalTeam.probableStarters,
              startsLabel: true,
            ),
            pw.SizedBox(height: 14),
            _sectionTitle('Equipe type - Remplacants probables'),
            _typicalTeamTable(
              data.typicalTeam.probableSubstitutes,
              startsLabel: false,
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _header({required String title, required String subtitle}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
      ),
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
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        _ascii('Grinta  |  ${context.pageNumber}/${context.pagesCount}'),
        style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        _ascii(title),
        style: pw.TextStyle(
          color: _primary,
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _wdlBlock({
    required String title,
    required TeamWdlPeriodData period,
  }) {
    final counts = period.counts;
    final total = counts.total;
    final avg = counts.avgPointsPerMatch;
    final avgLabel = avg == null ? '-' : avg.toStringAsFixed(2);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _ascii('$title - $total matchs - moy. $avgLabel'),
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: _textPrimary,
            ),
          ),
          pw.SizedBox(height: 8),
          _wdlBar(counts),
          pw.SizedBox(height: 6),
          pw.Text(
            _ascii(
              'Victoires ${counts.wins} (${_pct(counts.wins, total)})  |  '
              'Nuls ${counts.draws} (${_pct(counts.draws, total)})  |  '
              'Defaites ${counts.losses} (${_pct(counts.losses, total)})',
            ),
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
          if (period.matches.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                _ascii('Aucun match sur cette periode.'),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  List<pw.Widget> _goalsSection(OpponentAnalysisReportData data) {
    return [
      _goalsTrendBlock(data.goalsTrend),
      pw.SizedBox(height: 10),
      _goalsPeriodBlock(title: 'Saison complete', counts: data.goals.fullSeason),
      pw.SizedBox(height: 10),
      _goalsPeriodBlock(title: '1ere partie', counts: data.goals.firstHalf),
      pw.SizedBox(height: 10),
      _goalsPeriodBlock(title: '2eme partie', counts: data.goals.secondHalf),
    ];
  }

  pw.Widget _goalsTrendBlock(TeamGoalsHalfTrends trends) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _ascii('Tendance'),
            style: pw.TextStyle(
              color: _textSecondary,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _goalsTrendRow(
            label: 'Buts marques',
            direction: trends.scored.direction,
          ),
          pw.SizedBox(height: 6),
          _goalsTrendRow(
            label: 'Buts encaisses',
            direction: trends.conceded.direction,
          ),
        ],
      ),
    );
  }

  pw.Widget _goalsTrendRow({
    required String label,
    required TeamWdlTrendDirection direction,
  }) {
    final color = _trendColor(direction);
    return pw.Row(
      children: [
        pw.Text(
          _ascii(_trendArrow(direction)),
          style: pw.TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _ascii(label),
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                _ascii(_goalsTrendStatusLabel(direction)),
                style: pw.TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _trendArrow(TeamWdlTrendDirection direction) {
    switch (direction) {
      case TeamWdlTrendDirection.up:
        return '/\\';
      case TeamWdlTrendDirection.down:
        return '\\/';
      case TeamWdlTrendDirection.flat:
      case TeamWdlTrendDirection.insufficientData:
        return '--';
    }
  }

  String _goalsTrendStatusLabel(TeamWdlTrendDirection direction) {
    switch (direction) {
      case TeamWdlTrendDirection.up:
        return 'En progression';
      case TeamWdlTrendDirection.down:
        return 'En baisse';
      case TeamWdlTrendDirection.flat:
        return 'Stable';
      case TeamWdlTrendDirection.insufficientData:
        return 'Donnees insuffisantes';
    }
  }

  pw.Widget _goalsPeriodBlock({
    required String title,
    required TeamGoalsCounts counts,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _ascii(title),
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          if (counts.isEmpty)
            pw.Text(
              _ascii('Aucun match sur cette periode.'),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
            )
          else ...[
            pw.Container(
              width: double.infinity,
              height: 120,
              child: pw.CustomPaint(
                size: const PdfPoint(500, 110),
                painter: (PdfGraphics canvas, PdfPoint size) {
                  _paintGoalsBars(canvas: canvas, size: size, counts: counts);
                },
              ),
            ),
            pw.SizedBox(height: 8),
            _goalsLegendRow(
              label: 'Buts marques',
              value: counts.scored,
              avg: counts.avgScoredPerMatch,
              color: _win,
            ),
            pw.SizedBox(height: 4),
            _goalsLegendRow(
              label: 'Buts encaisses',
              value: counts.conceded,
              avg: counts.avgConcededPerMatch,
              color: _primary,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _ascii('${counts.matchCount} matchs'),
              style: const pw.TextStyle(color: _textSecondary, fontSize: 8),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _goalsLegendRow({
    required String label,
    required int value,
    required double? avg,
    required PdfColor color,
  }) {
    final avgLabel = avg == null ? '-' : avg.toStringAsFixed(2).replaceAll('.', ',');
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            _ascii(label),
            style: const pw.TextStyle(color: _textPrimary, fontSize: 9),
          ),
        ),
        pw.Text(
          _ascii('$value · $avgLabel/match'),
          style: pw.TextStyle(
            color: _textPrimary,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _paintGoalsBars({
    required PdfGraphics canvas,
    required PdfPoint size,
    required TeamGoalsCounts counts,
  }) {
    const left = 28.0;
    const right = 12.0;
    const topPad = 6.0;
    const bottomPad = 28.0;
    final chartW = size.x - left - right;
    final chartH = size.y - topPad - bottomPad;
    if (chartW <= 0 || chartH <= 0) return;

    final maxValue =
        counts.scored > counts.conceded ? counts.scored : counts.conceded;
    final maxY = maxValue <= 0 ? 1.0 : (maxValue + 1).toDouble();
    final interval = maxY <= 5
        ? 1.0
        : maxY <= 12
            ? 2.0
            : (maxY / 5).ceilToDouble();
    final plotBottom = bottomPad;
    final font = canvas.defaultFont;

    double yForValue(double value) {
      return plotBottom + (value / maxY) * chartH;
    }

    for (var v = 0.0; v <= maxY + 0.001; v += interval) {
      final yy = yForValue(v);
      canvas
        ..setStrokeColor(PdfColor.fromInt(0xFFD1D5DB))
        ..setLineWidth(0.5)
        ..moveTo(left, yy)
        ..lineTo(left + chartW, yy)
        ..strokePath();
      if (font != null) {
        canvas
          ..setFillColor(_textSecondary)
          ..drawString(font, 7, '${v.round()}', left - 18, yy - 2);
      }
    }

    final barWidth = chartW * 0.22;
    final firstCenter = left + chartW * 0.32;
    final secondCenter = left + chartW * 0.68;

    void drawBar({
      required double centerX,
      required double value,
      required PdfColor color,
      required String label,
    }) {
      final barH = (value / maxY) * chartH;
      final x = centerX - barWidth / 2;
      canvas
        ..setFillColor(color)
        ..drawRRect(x, plotBottom, barWidth, barH, 3, 3)
        ..fillPath();
      if (font != null) {
        canvas
          ..setFillColor(_textSecondary)
          ..drawString(
            font,
            7,
            label,
            centerX - 18,
            plotBottom - 16,
          );
      }
    }

    drawBar(
      centerX: firstCenter,
      value: counts.scored.toDouble(),
      color: _win,
      label: 'Marques',
    );
    drawBar(
      centerX: secondCenter,
      value: counts.conceded.toDouble(),
      color: _primary,
      label: 'Encaisses',
    );
  }

  pw.Widget _rankingEvolution(OpponentAnalysisReportData data) {
    if (data.rankingSeries.isEmpty || data.rankingMatchdays.isEmpty) {
      return pw.Text(
        _ascii('Aucun classement disponible pour cette competition.'),
        style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }

    final matchdays = data.rankingMatchdays;
    var maxRank = 1;
    for (final series in data.rankingSeries) {
      for (final point in series.points) {
        final rank = point.rank;
        if (rank != null && rank > maxRank) maxRank = rank;
      }
    }

    final palette = <PdfColor>[
      _seriesOrange,
      _seriesGreen,
      _seriesCyan,
      _seriesPurple,
      _draw,
      _loss,
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          height: 210,
          decoration: pw.BoxDecoration(
            color: _surface,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _border),
          ),
          padding: const pw.EdgeInsets.fromLTRB(8, 8, 10, 6),
          child: pw.CustomPaint(
            size: const PdfPoint(520, 190),
            painter: (PdfGraphics canvas, PdfPoint size) {
              _paintRankingChart(
                canvas: canvas,
                size: size,
                matchdays: matchdays,
                series: data.rankingSeries,
                maxRank: maxRank,
                palette: palette,
              );
            },
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (var i = 0; i < data.rankingSeries.length; i++)
              pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: palette[i % palette.length],
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    _ascii(
                      data.rankingSeries[i].isOwnTeam
                          ? '${data.rankingSeries[i].label} (toi)'
                          : data.rankingSeries[i].label,
                    ),
                    style: pw.TextStyle(
                      color: _textPrimary,
                      fontSize: 9,
                      fontWeight: data.rankingSeries[i].isOwnTeam
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _paintRankingChart({
    required PdfGraphics canvas,
    required PdfPoint size,
    required List<int> matchdays,
    required List<OpponentAnalysisRankingSeries> series,
    required int maxRank,
    required List<PdfColor> palette,
  }) {
    // PdfGraphics origin is bottom-left; rank 1 must sit at the top.
    const left = 28.0;
    const right = 8.0;
    const topPad = 8.0;
    const bottomPad = 22.0;
    final chartW = size.x - left - right;
    final chartH = size.y - topPad - bottomPad;
    if (chartW <= 0 || chartH <= 0 || matchdays.isEmpty) return;

    final plotBottom = bottomPad;
    final plotTop = bottomPad + chartH;
    final yInterval = _rankingHorizontalInterval(maxRank);
    final xStep = matchdays.length <= 1
        ? 0.0
        : chartW / (matchdays.length - 1);
    final font = canvas.defaultFont;

    double yForRank(int rank) {
      if (maxRank <= 1) return plotBottom + chartH / 2;
      return plotTop - ((rank - 1) / (maxRank - 1)) * chartH;
    }

    // Horizontal grid + Y labels.
    for (var rank = 1; rank <= maxRank; rank += yInterval) {
      final yy = yForRank(rank);
      canvas
        ..setStrokeColor(PdfColor.fromInt(0xFFD1D5DB))
        ..setLineWidth(0.6)
        ..moveTo(left, yy)
        ..lineTo(left + chartW, yy)
        ..strokePath();
      if (font != null) {
        canvas
          ..setFillColor(_textSecondary)
          ..drawString(font, 8, '$rank', left - 16, yy - 3);
      }
    }

    // Vertical grid + X labels.
    final labelStep = _rankingBottomLabelStep(matchdays.length);
    for (var i = 0; i < matchdays.length; i++) {
      final x = left + i * xStep;
      if (i % labelStep != 0 && i != matchdays.length - 1) continue;
      canvas
        ..setStrokeColor(PdfColor.fromInt(0xFFE5E7EB))
        ..setLineWidth(0.5)
        ..moveTo(x, plotBottom)
        ..lineTo(x, plotTop)
        ..strokePath();
      if (font != null) {
        canvas
          ..setFillColor(_textSecondary)
          ..drawString(font, 8, '${matchdays[i]}', x - 4, bottomPad - 14);
      }
    }

    for (var s = 0; s < series.length; s++) {
      final color = palette[s % palette.length];
      final points = <PdfPoint>[];
      for (var i = 0; i < matchdays.length; i++) {
        final day = matchdays[i];
        int? rank;
        for (final p in series[s].points) {
          if (p.matchday == day) {
            rank = p.rank;
            break;
          }
        }
        if (rank == null) continue;
        points.add(PdfPoint(left + i * xStep, yForRank(rank)));
      }
      if (points.isEmpty) continue;

      canvas
        ..setStrokeColor(color)
        ..setLineWidth(2.2)
        ..setLineCap(PdfLineCap.round)
        ..setLineJoin(PdfLineJoin.round)
        ..moveTo(points.first.x, points.first.y);
      if (points.length == 1) {
        canvas
          ..lineTo(points.first.x + 0.1, points.first.y)
          ..strokePath()
          ..setFillColor(color)
          ..drawEllipse(points.first.x - 2.5, points.first.y - 2.5, 5, 5)
          ..fillPath();
      } else {
        for (var i = 1; i < points.length; i++) {
          final prev = points[i - 1];
          final curr = points[i];
          final dx = (curr.x - prev.x) * 0.35;
          canvas.curveTo(
            prev.x + dx,
            prev.y,
            curr.x - dx,
            curr.y,
            curr.x,
            curr.y,
          );
        }
        canvas.strokePath();
      }
    }
  }

  int _rankingHorizontalInterval(int maxRank) {
    if (maxRank <= 4) return 1;
    if (maxRank <= 10) return 2;
    return math.max(1, (maxRank / 5).ceil());
  }

  int _rankingBottomLabelStep(int matchdayCount) {
    if (matchdayCount <= 8) return 1;
    if (matchdayCount <= 16) return 2;
    if (matchdayCount <= 24) return 3;
    return math.max(1, (matchdayCount / 6).ceil());
  }

  pw.Widget _wdlBar(TeamWdlCounts counts) {
    final total = counts.total;
    if (total == 0) {
      return pw.Container(height: 10, color: _border);
    }
    return pw.Row(
      children: [
        if (counts.wins > 0)
          pw.Expanded(
            flex: counts.wins,
            child: pw.Container(height: 10, color: _win),
          ),
        if (counts.draws > 0)
          pw.Expanded(
            flex: counts.draws,
            child: pw.Container(height: 10, color: _draw),
          ),
        if (counts.losses > 0)
          pw.Expanded(
            flex: counts.losses,
            child: pw.Container(height: 10, color: _loss),
          ),
      ],
    );
  }

  List<pw.Widget> _matchList({
    required List<Match> matches,
    required MatchOutcome outcome,
    required OpponentAnalysisReportData team,
    required DateFormat dateFmt,
  }) {
    final filtered = <Match>[];
    for (final match in matches) {
      final result = matchOutcomeForTeam(
        match: match,
        teamId: team.wdl.teamId,
        clubId: team.wdl.clubId,
        clubAffiliation: team.wdl.clubAffiliation,
        displayName: team.wdl.perspectiveDisplayName,
      );
      if (result == outcome) {
        filtered.add(match);
      }
    }
    if (filtered.isEmpty) {
      return [
        pw.Text(
          _ascii('Aucun match.'),
          style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
        ),
      ];
    }

    filtered.sort((a, b) {
      final aTs = a.timestamp?.toDate() ?? DateTime(1970);
      final bTs = b.timestamp?.toDate() ?? DateTime(1970);
      return aTs.compareTo(bTs);
    });

    final cardColor = switch (outcome) {
      MatchOutcome.win => PdfColor.fromInt(0xFFDCFCE7),
      MatchOutcome.draw => PdfColor.fromInt(0xFFFEF3C7),
      MatchOutcome.loss => PdfColor.fromInt(0xFFFEE2E2),
    };

    return [
      for (final match in filtered)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: cardColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _ascii(_matchDateLabel(match, dateFmt)),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                _ascii(
                  '${match.team1 ?? '?'}  ${match.homeScore ?? '-'} - ${match.outSideScore ?? '-'}  ${match.team2 ?? '?'}',
                ),
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if ((match.chType ?? '').trim().isNotEmpty)
                pw.Text(
                  _ascii(match.chType!.trim()),
                  style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
                ),
            ],
          ),
        ),
    ];
  }

  String _matchDateLabel(Match match, DateFormat dateFmt) {
    final date = match.timestamp?.toDate();
    if (date == null) return match.dateCh?.trim() ?? '';
    return dateFmt.format(date);
  }

  pw.Widget _playersTable(List<OpponentAnalysisPlayerRow> players) {
    if (players.isEmpty) {
      return pw.Text(
        _ascii('Aucun joueur.'),
        style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }

    final rows = players.take(40).toList();
    return pw.TableHelper.fromTextArray(
      headers: const ['Joueur', 'Convo', 'Titu.', 'Tps jeu', 'CJ', 'CR'],
      data: [
        for (final player in rows)
          [
            _ascii(player.displayName),
            '${player.convocations}',
            '${player.starts}',
            '${player.minutesPlayed}',
            '${player.yellowCards}',
            '${player.redCards}',
          ],
      ],
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _textPrimary),
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(0.8),
      },
    );
  }

  pw.Widget _typicalTeamTable(
    List<TypicalTeamPlayerEntry> starters, {
    required bool startsLabel,
  }) {
    if (starters.isEmpty) {
      return pw.Text(
        _ascii('Aucune donnee.'),
        style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: startsLabel
          ? const ['#', 'Joueur', 'Titularisations']
          : const ['#', 'Joueur', 'Remplacements'],
      data: [
        for (var i = 0; i < starters.length; i++)
          [
            '${i + 1}',
            _ascii(starters[i].displayName),
            startsLabel
                ? '${starters[i].titularCount}/${starters[i].matchesWithSquadData}'
                : '${starters[i].substituteCount}/${starters[i].matchesWithSquadData}',
          ],
      ],
      headerStyle: pw.TextStyle(
        color: _white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _textPrimary),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.4),
      },
    );
  }

  String _pct(int value, int total) {
    if (total <= 0) return '0%';
    return '${((value / total) * 100).round()}%';
  }

  String _trendLabel(TeamWdlTrendDirection direction) {
    switch (direction) {
      case TeamWdlTrendDirection.up:
        return 'En hausse';
      case TeamWdlTrendDirection.down:
        return 'En baisse';
      case TeamWdlTrendDirection.flat:
        return 'Stable';
      case TeamWdlTrendDirection.insufficientData:
        return 'Donnees insuffisantes';
    }
  }

  PdfColor _trendColor(TeamWdlTrendDirection direction) {
    switch (direction) {
      case TeamWdlTrendDirection.up:
        return _win;
      case TeamWdlTrendDirection.down:
        return _loss;
      case TeamWdlTrendDirection.flat:
        return _draw;
      case TeamWdlTrendDirection.insufficientData:
        return _textSecondary;
    }
  }

  /// Helvetica / WinAnsi-safe text (strip anything outside basic ASCII).
  String _ascii(String value) {
    const map = <String, String>{
      'À': 'A',
      'Á': 'A',
      'Â': 'A',
      'Ä': 'A',
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
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
      'Σ': 'moy.',
      '·': '|',
      '–': '-',
      '—': '-',
      '’': "'",
      '‘': "'",
      '“': '"',
      '”': '"',
      '…': '...',
      '€': 'EUR',
    };
    final buffer = StringBuffer();
    for (final code in value.runes) {
      final ch = String.fromCharCode(code);
      buffer.write(map[ch] ?? (code < 32 || code > 126 ? '?' : ch));
    }
    return buffer.toString();
  }
}
