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

MatchSide _otherMatchSide(MatchSide side) {
  return side == MatchSide.team1 ? MatchSide.team2 : MatchSide.team1;
}

bool _sameClubId(String? left, String? right) {
  final a = left?.trim() ?? '';
  final b = right?.trim() ?? '';
  return a.isNotEmpty && a == b;
}

/// True when the tapped logo is the user's club, not the opponent.
///
/// Affiliation / `match.clubs` win over `teams[]` index and a missing/wrong
/// [Match.isOwnClub]: FFF imports often store only our team id at index 0
/// even when we play away, which inverted Analyse vs Adversaires.
bool isUsersClubMatchSide({
  required models.Match match,
  required Team team,
  required MatchSide side,
}) {
  final clubId = team.clubId?.trim() ?? '';
  final otherSide = _otherMatchSide(side);

  final sideAffiliation = affiliationTeamForSide(match, side);
  final otherAffiliation = affiliationTeamForSide(match, otherSide);
  if (clubId.isNotEmpty) {
    if (_sameClubId(sideAffiliation, clubId)) return true;
    if (_sameClubId(otherAffiliation, clubId)) return false;
  }

  final sideClubId = clubIdForMatchSide(match: match, side: side);
  final otherClubId = clubIdForMatchSide(match: match, side: otherSide);
  if (clubId.isNotEmpty) {
    if (_sameClubId(sideClubId, clubId)) return true;
    if (_sameClubId(otherClubId, clubId)) return false;
  }

  final ownSide = teamSideForMatch(
    match: match,
    teamId: team.keyTeam ?? '',
    clubId: clubId,
    clubAffiliation: clubId,
  );
  if (ownSide != null) return ownSide == side;

  if (match.isOwnClub == true) return side == MatchSide.team1;
  if (match.isOwnClub == false) return side == MatchSide.team2;
  return false;
}

/// Returns Analyse for the user's team side, Adversaires for the opponent.
/// Returns null when the user's team side cannot be resolved.
MatchTeamStatsDestination? destinationForMatchSide({
  required models.Match match,
  required Team team,
  required MatchSide side,
}) {
  if (isUsersClubMatchSide(match: match, team: team, side: side)) {
    return MatchTeamStatsDestination.analysis;
  }

  final otherSide = _otherMatchSide(side);
  if (isUsersClubMatchSide(match: match, team: team, side: otherSide)) {
    return MatchTeamStatsDestination.opponents;
  }

  final ownSide = teamSideForMatch(
    match: match,
    teamId: team.keyTeam ?? '',
    clubId: team.clubId,
    clubAffiliation: team.clubId,
  );
  if (ownSide == null) return null;
  return ownSide == side
      ? MatchTeamStatsDestination.analysis
      : MatchTeamStatsDestination.opponents;
}

/// Opens team statistics for [match]: Analyse (own club) or Adversaires (opponent).
///
/// When [tappedSide] is set and [destination] is Adversaires, the opponent is
/// the club on that side (the logo the user tapped), not a re-derived side.
Future<void> openTeamStatsFromMatch({
  required BuildContext context,
  required models.Match match,
  required bool isManager,
  required MatchTeamStatsDestination destination,
  MatchSide? tappedSide,
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

  final opponent = tappedSide != null
      ? opponentFromMatchSide(match: match, side: tappedSide)
      : opponentForMatch(
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
