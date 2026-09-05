import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show WebHtmlElementStrategy;
import 'package:grinta/model/match.dart' as grinta_match;
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/widget/last_results_form_guide.dart';
import 'package:intl/intl.dart';

import '../util/app_theme.dart';

class AgendaMatchRow extends StatelessWidget {
  final grinta_match.Match match;
  final bool withDateTime;

  const AgendaMatchRow({
    super.key,
    required this.match,
    required this.withDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: colors.textPrimary,
      fontWeight: FontWeight.w700,
    ) ??
        TextStyle(
          color: colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        );

    String team1 = match.team1 ?? '';
    String team2 = match.team2 ?? '';

    if (team1.contains('Exempt')) team1 = 'Exempt';
    if (team2.contains('Exempt')) team2 = 'Exempt';

    final hasTab = match.tab?.trim().isNotEmpty ?? false;
    final hasTimeCh = match.timeCh?.trim().isNotEmpty ?? false;
    final hasTerrain = match.nomDuTerrain?.trim().isNotEmpty ?? false;
    final hasAdresse = match.terrainAdresse1?.trim().isNotEmpty ?? false;

    // Mirror match detail: show score when played or live (highlights / goals).
    final bool showScore = match.isMatchPlayed == true ||
        match.isInHighLight == true ||
        (match.homeScore ?? 0) > 0 ||
        (match.outSideScore ?? 0) > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
        constraints.maxWidth > 380 ? 380.0 : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if(withDateTime) ... [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatTimestampFr(match.timestamp),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        )
                      ),
                    ],
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      match.chType!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyle,
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _teamBlock(
                        context: context,
                        side: MatchSide.team1,
                        logoUrl: match.team1UrlLogo ?? '',
                        teamName: team1,
                        isPlayed: showScore,
                        score: '${match.homeScore ?? 0}',
                        isForfeit: match.isTeam1Forfeit == true,
                        scoreFirst: false,
                        textStyle: textStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            '-',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasTab) ...[
                            const SizedBox(height: 4),
                            Text(
                              match.tab!.trim(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _teamBlock(
                        context: context,
                        side: MatchSide.team2,
                        logoUrl: match.team2UrlLogo ?? '',
                        teamName: team2,
                        isPlayed: showScore,
                        score: '${match.outSideScore ?? 0}',
                        isForfeit: match.isTeam2Forfeit == true,
                        scoreFirst: true,
                        textStyle: textStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String formatTimestampFr(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final DateTime date = timestamp.toDate();

    final String dayPart = DateFormat('EEEE d MMMM', 'fr_FR').format(date);
    final String hourPart = DateFormat('HH\'h\'mm', 'fr_FR').format(date);

    return '$dayPart - $hourPart';
  }

  Widget _teamBlock({
    required BuildContext context,
    required MatchSide side,
    required String logoUrl,
    required String teamName,
    required bool isPlayed,
    required String score,
    required bool isForfeit,
    required bool scoreFirst,
    required TextStyle textStyle,
  }) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scoreFirst && isPlayed) ...[
              SizedBox(
                height: 42,
                child: Center(child: _scoreBox(context: context, score: score)),
              ),
              const SizedBox(width: 6),
            ],
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _matchLogo(context, logoUrl),
                LastResultsFormGuide(
                  match: match,
                  side: side,
                ),
              ],
            ),
            if (!scoreFirst && isPlayed) ...[
              const SizedBox(width: 6),
              SizedBox(
                height: 42,
                child: Center(child: _scoreBox(context: context, score: score)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          teamName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
        if (isForfeit)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Forfait',
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _scoreBox({
    required BuildContext context,
    required String score,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        score,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _matchLogo(BuildContext context, String url) {
    final colors = context.appColors;
    final safeUrl = url.trim();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: safeUrl.isEmpty
              ? Icon(
            Icons.shield_outlined,
            size: 16,
            color: colors.textSecondary,
          )
              : Image.network(
            safeUrl,
            // Web HTML images keep the previous bitmap when only the URL
            // changes on a reused element (e.g. matchday navigator). Key by
            // URL so Flutter recreates the platform view — same as ClubLogo.
            key: ValueKey(safeUrl),
            fit: BoxFit.contain,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('LOGO ERROR url=$safeUrl');
              debugPrint('error=$error');
              return Icon(
                Icons.broken_image_outlined,
                size: 16,
                color: colors.textSecondary,
              );
            },
          ),
        ),
      ),
    );
  }
}