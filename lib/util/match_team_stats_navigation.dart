import 'package:flutter/material.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/screen/team_stats/team_stats_screen.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/match_outcome_helper.dart';
import 'package:grinta/util/team_stats_opponent_helper.dart';
import 'package:provider/provider.dart';

/// Which team-stats destination to open from a match (own club vs opponent).
enum MatchTeamStatsDestination {
  /// Analyse tab, with the match competition preselected when possible.
  analysis,

  /// Adversaires tab, with competition + opponent preselected when possible.
  opponents,
}

Team? teamForMatchStats(AppSession session, models.Match match) {
  final teamId = match.teamID?.trim() ?? '';
  if (teamId.isEmpty) return null;
  for (final candidate in session.teamsForAgendaSelectedSeason) {
    if (candidate.keyTeam == teamId) {
      return candidate;
    }
  }
  return null;
}

/// Returns Analyse for the user's team side, Adversaires for the opponent.
/// Returns null when the user's team side cannot be resolved.
MatchTeamStatsDestination? destinationForMatchSide({
  required models.Match match,
  required Team team,
  required MatchSide side,
}) {
  final ownSide = teamSideForMatch(
    match: match,
    teamId: team.keyTeam ?? '',
    clubId: team.clubId,
  );
  if (ownSide == null) return null;
  return ownSide == side
      ? MatchTeamStatsDestination.analysis
      : MatchTeamStatsDestination.opponents;
}

/// Opens team statistics for [match]: Analyse (own club) or Adversaires (opponent).
Future<void> openTeamStatsFromMatch({
  required BuildContext context,
  required models.Match match,
  required bool isManager,
  required MatchTeamStatsDestination destination,
}) async {
  final session = context.read<AppSession>();
  final team = teamForMatchStats(session, match);
  if (team == null) return;

  if (destination == MatchTeamStatsDestination.opponents) {
    await UserTrialService.instance.ensureInitialized();
    final canOpenOpponents =
        isManager || UserTrialService.instance.hasPremiumAccess;
    if (!canOpenOpponents) return;
  }

  final competitionUrl = await resolveTeamStatsCompetitionUrlForMatch(
    team: team,
    match: match,
    fallbackSeasonId: session.selectedSeason?.ref?.id,
  );
  if (!context.mounted) return;

  if (destination == MatchTeamStatsDestination.analysis) {
    await openTeamStatsScreen(
      context,
      team: team,
      isManager: isManager,
      initialTabIndex: 0,
      initialCompetitionUrl: competitionUrl,
    );
    return;
  }

  final opponent = opponentForMatch(
    match: match,
    teamId: team.keyTeam ?? '',
    clubId: team.clubId,
  );
  final opponentName = opponent?.displayName.trim() ?? '';
  if (opponentName.isEmpty) return;

  await openTeamStatsScreen(
    context,
    team: team,
    isManager: isManager,
    initialTabIndex: 2,
    initialCompetitionUrl: competitionUrl,
    initialOpponentKey: opponent?.key,
    initialOpponentName: opponentName,
    initialMatchIdForViewTracking: match.id,
  );
}
