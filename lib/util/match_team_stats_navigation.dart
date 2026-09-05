import 'package:flutter/material.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/screen/team_stats/team_stats_screen.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
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

Team? teamForMatchStats(
  AppSession session,
  models.Match match, {
  String? preferClubId,
}) {
  return resolveTeamForMatchStats(
    candidates: session.teamsForAgendaSelectedSeason,
    match: match,
    preferClubId: preferClubId,
  );
}

/// FFF club ids printed on [match] (affiliations + `clubs[]`).
Set<String> clubIdsOnMatch(models.Match match) {
  final ids = <String>{};
  void add(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isNotEmpty) {
      ids.add(value);
    }
  }

  add(match.affiliationTeam1);
  add(match.affiliationTeam2);
  for (final club in match.clubs ?? const <dynamic>[]) {
    add(club?.toString());
  }
  return ids;
}

/// Club printed under [side] (affiliation, then `clubs[]`).
String? clubIdForTappedMatchSide(models.Match match, MatchSide side) {
  final affiliation = affiliationTeamForSide(match, side);
  if (affiliation.isNotEmpty) {
    return affiliation;
  }
  return clubIdForMatchSide(match: match, side: side);
}

/// Session club that owns stats for [match] (the user's team, not the opponent).
///
/// When several session teams sit on both sides of a shared match, prefer the
/// unique session club on the sheet; if both clubs are in the session, prefer
/// [Match.teamID]'s club then a linked `teams[]` id.
String? ownClubIdOnMatch({
  required List<Team> candidates,
  required models.Match match,
}) {
  final onMatch = clubIdsOnMatch(match);
  final sessionClubs = <String>{};
  for (final team in candidates) {
    final clubId = team.clubId?.trim() ?? '';
    if (clubId.isNotEmpty && onMatch.contains(clubId)) {
      sessionClubs.add(clubId);
    }
  }

  if (sessionClubs.length == 1) {
    return sessionClubs.first;
  }

  if (sessionClubs.length > 1) {
    final teamId = match.teamID?.trim() ?? '';
    if (teamId.isNotEmpty) {
      for (final team in candidates) {
        if (team.keyTeam?.trim() != teamId) {
          continue;
        }
        final clubId = team.clubId?.trim() ?? '';
        if (sessionClubs.contains(clubId)) {
          return clubId;
        }
      }
    }
    for (final linkedId
        in normalizeTeamIdList(match.teams ?? const <dynamic>[])) {
      for (final team in candidates) {
        if (team.keyTeam?.trim() != linkedId) {
          continue;
        }
        final clubId = team.clubId?.trim() ?? '';
        if (sessionClubs.contains(clubId)) {
          return clubId;
        }
      }
    }
  }

  return sessionClubs.isEmpty ? null : sessionClubs.first;
}

/// Session team used for Analyse / Adversaires of [match].
///
/// Prefers [preferClubId] (the user's club, e.g. 500554) over [Match.teamID],
/// which on shared matches may be the home Grinta team (504006).
Team? resolveTeamForMatchStats({
  required List<Team> candidates,
  required models.Match match,
  String? preferClubId,
}) {
  if (candidates.isEmpty) {
    return null;
  }

  final preferred = (preferClubId?.trim() ?? '').isNotEmpty
      ? preferClubId!.trim()
      : ownClubIdOnMatch(candidates: candidates, match: match);

  final linkedIds = <String>{
    ...normalizeTeamIdList(match.teams ?? const <dynamic>[]),
    if ((match.teamID?.trim() ?? '').isNotEmpty) match.teamID!.trim(),
  };

  Team? pickByClub(String clubId) {
    Team? linkedWithTeamId;
    Team? linked;
    Team? any;
    for (final team in candidates) {
      if (!_sameClubId(team.clubId, clubId)) {
        continue;
      }
      any ??= team;
      final key = team.keyTeam?.trim() ?? '';
      if (key.isEmpty || !linkedIds.contains(key)) {
        continue;
      }
      if (key == (match.teamID?.trim() ?? '')) {
        linkedWithTeamId = team;
      }
      linked ??= team;
    }
    return linkedWithTeamId ?? linked ?? any;
  }

  if (preferred != null && preferred.isNotEmpty) {
    final byClub = pickByClub(preferred);
    if (byClub != null) {
      return byClub;
    }
  }

  final teamId = match.teamID?.trim() ?? '';
  if (teamId.isNotEmpty) {
    for (final team in candidates) {
      if (team.keyTeam?.trim() != teamId) {
        continue;
      }
      if (preferred != null &&
          preferred.isNotEmpty &&
          (team.clubId?.trim() ?? '').isNotEmpty &&
          !_sameClubId(team.clubId, preferred)) {
        break;
      }
      return team;
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
  String? ownClubId,
}) {
  final ownClub = (ownClubId?.trim() ?? '').isNotEmpty
      ? ownClubId!.trim()
      : (team.clubId?.trim() ?? '');
  if (ownClub.isNotEmpty) {
    final tappedClub = clubIdForTappedMatchSide(match, side);
    if (_sameClubId(tappedClub, ownClub)) {
      return MatchTeamStatsDestination.analysis;
    }
    final otherClub = clubIdForTappedMatchSide(match, _otherMatchSide(side));
    if (_sameClubId(otherClub, ownClub)) {
      return MatchTeamStatsDestination.opponents;
    }
  }

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
  final inferredOwnClub = ownClubIdOnMatch(
    candidates: session.teamsForAgendaSelectedSeason,
    match: match,
  );
  final tappedOwnClub = preferClubIdForDestination(
    match: match,
    destination: destination,
    tappedSide: tappedSide,
  );
  final ownClub = destination == MatchTeamStatsDestination.analysis
      ? (tappedOwnClub ?? inferredOwnClub)
      : (inferredOwnClub ?? tappedOwnClub);
  final team = teamForMatchStats(session, match, preferClubId: ownClub);
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
      initialCompetitionId: match.competitionID,
      initialCompetitionPoule: match.poule,
      initialCompetitionStage: match.stage,
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
    initialCompetitionId: match.competitionID,
    initialCompetitionPoule: match.poule,
    initialCompetitionStage: match.stage,
    initialOpponentKey: opponent?.key,
    initialOpponentName: opponentName,
    initialMatchIdForViewTracking: match.id,
  );
}

String? preferClubIdForDestination({
  required models.Match match,
  required MatchTeamStatsDestination destination,
  MatchSide? tappedSide,
}) {
  if (tappedSide == null) {
    return null;
  }
  if (destination == MatchTeamStatsDestination.analysis) {
    return clubIdForTappedMatchSide(match, tappedSide);
  }
  return clubIdForTappedMatchSide(match, _otherMatchSide(tappedSide));
}
