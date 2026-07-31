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

  Future<Uint8List> buildPdf({
    required OpponentAnalysisReportData data,
    String localeCode = 'fr',
  }) async {
    final doc = pw.Document();
    final generatedLabel =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final kickoffLabel =
        DateFormat.yMMMMEEEEd(localeCode).add_Hm().format(data.upcomingKickoff);
    final dateFmt = DateFormat.yMMMd(localeCode);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
        header: (context) => _header(
          title: 'Analyse adversaire — ${data.opponent.displayName}',
          subtitle:
              '${data.teamName}  ·  ${data.competitionLabel}  ·  Match $kickoffLabel  ·  gen. $generatedLabel',
        ),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _sectionTitle('Tendance'),
            pw.Text(
              _trendLabel(data.trend.direction),
              style: pw.TextStyle(
                color: _trendColor(data.trend.direction),
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 14),
            _wdlBlock(
              title: 'Saison complète',
              period: data.wdl.fullSeason,
            ),
            pw.SizedBox(height: 10),
            _wdlBlock(
              title: '1ère partie',
              period: data.wdl.firstHalf,
            ),
            pw.SizedBox(height: 10),
            _wdlBlock(
              title: '2ème partie',
              period: data.wdl.secondHalf,
            ),
            pw.SizedBox(height: 18),
            _sectionTitle('Résultats — Victoires'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.win,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 12),
            _sectionTitle('Résultats — Nuls'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.draw,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 12),
            _sectionTitle('Résultats — Défaites'),
            ..._matchList(
              matches: data.wdl.fullSeason.matches,
              outcome: MatchOutcome.loss,
              team: data,
              dateFmt: dateFmt,
            ),
            pw.SizedBox(height: 18),
            _sectionTitle('Évolution du classement'),
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
          title: 'Joueurs — ${data.opponent.displayName}',
          subtitle: data.competitionLabel,
        ),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            _sectionTitle('Effectif adversaire'),
            _playersTable(data.players),
            pw.SizedBox(height: 18),
            _sectionTitle('Equipe type — Titulaires probables'),
            pw.Text(
              data.typicalTeam.hasSquadData
                  ? 'Basé sur ${data.typicalTeam.matchesWithSquadData} matchs avec composition'
                  : 'Pas assez de compositions disponibles',
              style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            _typicalTeamTable(
              data.typicalTeam.probableStarters,
              startsLabel: true,
            ),
            pw.SizedBox(height: 14),
            _sectionTitle('Equipe type — Remplaçants probables'),
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
            title,
            style: pw.TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
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
        'Grinta  ·  ${context.pageNumber}/${context.pagesCount}',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
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
    final avgLabel = avg == null ? '—' : avg.toStringAsFixed(2);

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
            '$title — $total matchs — Σ $avgLabel',
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
            'Victoires ${counts.wins} (${_pct(counts.wins, total)})  ·  '
            'Nuls ${counts.draws} (${_pct(counts.draws, total)})  ·  '
            'Défaites ${counts.losses} (${_pct(counts.losses, total)})',
            style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
          ),
          if (period.matches.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Aucun match sur cette période.',
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _rankingEvolution(OpponentAnalysisReportData data) {
    if (data.rankingSeries.isEmpty || data.rankingMatchdays.isEmpty) {
      return pw.Text(
        'Aucun classement disponible pour cette compétition.',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }

    final headers = <String>['Journée'];
    for (final series in data.rankingSeries) {
      headers.add(series.label);
    }

    final rows = <List<String>>[];
    for (final day in data.rankingMatchdays) {
      final row = <String>['J$day'];
      for (final series in data.rankingSeries) {
        OpponentAnalysisRankingPoint? point;
        for (final candidate in series.points) {
          if (candidate.matchday == day) {
            point = candidate;
            break;
          }
        }
        if (point?.rank == null) {
          row.add('—');
        } else {
          final pts = point!.pts;
          row.add(pts == null ? '${point.rank}' : '${point.rank}e (${pts} pts)');
        }
      }
      rows.add(row);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          data.rankingSeries
              .map((s) => s.isOwnTeam ? '${s.label} (toi)' : s.label)
              .join('  ·  '),
          style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: rows,
          headerStyle: pw.TextStyle(
            color: _white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          headerDecoration: const pw.BoxDecoration(color: _primary),
          cellStyle: const pw.TextStyle(fontSize: 8, color: _textPrimary),
          cellAlignment: pw.Alignment.centerLeft,
        ),
      ],
    );
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
          'Aucun match.',
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
                _matchDateLabel(match, dateFmt),
                style: const pw.TextStyle(color: _textSecondary, fontSize: 9),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${match.team1 ?? '?'}  ${match.homeScore ?? '-'} - ${match.outSideScore ?? '-'}  ${match.team2 ?? '?'}',
                style: pw.TextStyle(
                  color: _textPrimary,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if ((match.chType ?? '').trim().isNotEmpty)
                pw.Text(
                  match.chType!.trim(),
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
        'Aucun joueur.',
        style: const pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }

    final rows = players.take(40).toList();
    return pw.TableHelper.fromTextArray(
      headers: const ['Joueur', 'Convo', 'Titu.', 'Tps jeu'],
      data: [
        for (final player in rows)
          [
            player.displayName,
            '${player.convocations}',
            '${player.starts}',
            '${player.minutesPlayed}',
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
      },
    );
  }

  pw.Widget _typicalTeamTable(
    List<TypicalTeamPlayerEntry> starters, {
    required bool startsLabel,
  }) {
    if (starters.isEmpty) {
      return pw.Text(
        'Aucune donnée.',
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
            starters[i].displayName,
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
        return 'Données insuffisantes';
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
}
