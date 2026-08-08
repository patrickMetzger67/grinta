import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/screen/team_stats/team_stats_screen.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:provider/provider.dart';

class MatchOpponentStatsButton extends StatelessWidget {
  const MatchOpponentStatsButton({
    super.key,
    required this.match,
    required this.isManager,
    this.dense = false,
  });

  final models.Match match;
  final bool isManager;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserTrialService.instance,
      builder: (context, _) {
        if (!UserTrialService.instance.hasPremiumAccess) {
          return const SizedBox.shrink();
        }
        if (match.isMatchPlayed == true) {
          return const SizedBox.shrink();
        }

        final session = context.read<AppSession>();
        final teamId = match.teamID?.trim() ?? '';
        Team? team;
        for (final candidate in session.teamsForAgendaSelectedSeason) {
          if (candidate.keyTeam == teamId) {
            team = candidate;
            break;
          }
        }
        if (team == null) return const SizedBox.shrink();

        final opponent = opponentForMatch(
          match: match,
          teamId: team.keyTeam ?? '',
          clubId: team.clubId,
        );
        final opponentName = opponent?.displayName;
        if (opponentName == null || opponentName.trim().isEmpty) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final colors = context.appColors;

        return FutureBuilder<String?>(
          future: resolveTeamStatsCompetitionUrlForMatch(
            team: team,
            match: match,
            fallbackSeasonId: session.selectedSeason?.ref?.id,
          ),
          builder: (context, snapshot) {
            return Padding(
              padding: EdgeInsets.only(top: dense ? 2 : 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    openTeamStatsScreen(
                      context,
                      team: team!,
                      isManager: isManager,
                      initialTabIndex: 2,
                      initialCompetitionUrl: snapshot.data,
                      initialOpponentKey: opponent?.key,
                      initialOpponentName: opponentName,
                      initialMatchIdForViewTracking: match.id,
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: dense
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    padding: dense
                        ? const EdgeInsets.symmetric(horizontal: 8)
                        : null,
                    tapTargetSize: dense
                        ? MaterialTapTargetSize.shrinkWrap
                        : MaterialTapTargetSize.padded,
                  ),
                  icon: Icon(
                    Icons.query_stats_rounded,
                    color: colors.primary,
                    size: dense ? 18 : 24,
                  ),
                  label: Text(
                    l10n.matchDetailOpponentStats,
                    style: TextStyle(fontSize: dense ? 12 : null),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
