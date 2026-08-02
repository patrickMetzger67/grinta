import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';

/// Side of the match sheet: team1 is home, team2 is away.
enum MatchSide { team1, team2 }

bool isHomeSide(MatchSide side) => side == MatchSide.team1;

String teamDisplayNameForSide(models.Match match, MatchSide side) {
  final String raw = side == MatchSide.team1
      ? (match.team1?.trim() ?? '')
      : (match.team2?.trim() ?? '');
  return raw;
}

String affiliationTeamForSide(models.Match match, MatchSide side) {
  return side == MatchSide.team1
      ? (match.affiliationTeam1?.trim() ?? '')
      : (match.affiliationTeam2?.trim() ?? '');
}

/// Grinta team id linked to [side], when present in [match.teams].
String? teamIdForSide(models.Match match, MatchSide side) {
  final List<String> linked =
      normalizeTeamIdList(match.teams ?? const <dynamic>[]);

  if (side == MatchSide.team1 && linked.isNotEmpty) {
    return linked.first;
  }
  if (side == MatchSide.team2 && linked.length > 1) {
    return linked[1];
  }

  final String? primaryId = match.teamID?.trim();
  if (primaryId == null || primaryId.isEmpty) {
    return null;
  }

  if (linked.length == 1) {
    final bool ownTeamIsHome = match.isOwnClub == true;
    if (side == MatchSide.team1 && ownTeamIsHome) return linked.first;
    if (side == MatchSide.team2 && !ownTeamIsHome) return linked.first;
    return null;
  }

  if (side == MatchSide.team1 && match.isOwnClub == true) {
    return primaryId;
  }
  if (side == MatchSide.team2 && match.isOwnClub != true) {
    return primaryId;
  }

  return null;
}

bool isManagedSide(
  models.Match match,
  MatchSide side,
  List<String> managedTeamIds,
) {
  final String? teamId = teamIdForSide(match, side);
  if (teamId == null || teamId.isEmpty) {
    return false;
  }
  return managedTeamIds.contains(teamId);
}

/// Returns updated `(homeScore, outsideScore)` after one goal for [side].
///
/// Prefer [scoreFromGoalHighlights] for persisted score updates — incrementing
/// from a stale in-memory [match] races and desyncs the scoreboard.
({int homeScore, int outsideScore}) incrementedScoresForSide(
  models.Match match,
  MatchSide side,
) {
  final int home = match.homeScore ?? 0;
  final int away = match.outSideScore ?? 0;

  if (isHomeSide(side)) {
    return (homeScore: home + 1, outsideScore: away);
  }
  return (homeScore: home, outsideScore: away + 1);
}

/// Returns updated `(homeScore, outsideScore)` after removing one goal for [side].
///
/// Prefer [scoreFromGoalHighlights] for persisted score updates.
({int homeScore, int outsideScore}) decrementedScoresForSide(
  models.Match match,
  MatchSide side,
) {
  final int home = match.homeScore ?? 0;
  final int away = match.outSideScore ?? 0;

  if (isHomeSide(side)) {
    return (homeScore: home > 0 ? home - 1 : 0, outsideScore: away);
  }
  return (homeScore: home, outsideScore: away > 0 ? away - 1 : 0);
}

/// Scoreboard derived from Grinta goal highlights (source of truth).
///
/// Counts each [ActionType.goal] by [Goal.affiliationTeam] against
/// [Match.affiliationTeam1] / [Match.affiliationTeam2]. Goals with an unknown
/// affiliation are ignored.
({int homeScore, int outsideScore}) scoreFromGoalHighlights(
  models.Match match,
  Iterable<Highlights> highlights,
) {
  var home = 0;
  var away = 0;

  for (final highlight in highlights) {
    if (highlight.actionType != ActionType.goal) {
      continue;
    }
    final Goal? goal = highlight.value as Goal?;
    final MatchSide? side = sideForAffiliationTeam(
      match,
      goal?.affiliationTeam,
    );
    if (side == null) {
      continue;
    }
    if (isHomeSide(side)) {
      home += 1;
    } else {
      away += 1;
    }
  }

  return (homeScore: home, outsideScore: away);
}

/// Applies a manual ±1 score change for [side] on the match document.
///
/// Clamps at 0. Updates [match.homeScore] / [match.outSideScore] in memory.
Future<({int homeScore, int outsideScore})> adjustMatchSideScore({
  required models.Match match,
  required MatchSide side,
  required int delta,
  MatchService? matchService,
}) async {
  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    throw Exception('Match id is missing');
  }
  if (delta == 0) {
    return (
      homeScore: match.homeScore ?? 0,
      outsideScore: match.outSideScore ?? 0,
    );
  }

  var home = match.homeScore ?? 0;
  var away = match.outSideScore ?? 0;
  if (isHomeSide(side)) {
    home = (home + delta).clamp(0, 99);
  } else {
    away = (away + delta).clamp(0, 99);
  }

  final MatchService mService = matchService ?? MatchService();
  await mService.updateScore(
    matchId: matchId,
    homeScore: home,
    outsideScore: away,
    tab: match.tab,
    isMatchPlayed: match.isMatchPlayed == true,
  );

  match.homeScore = home;
  match.outSideScore = away;
  if (delta > 0 && match.isInHighLight != true) {
    await mService.updateHighlightStatus(
      matchId: matchId,
      isInHighLight: true,
    );
    match.isInHighLight = true;
  }

  return (homeScore: home, outsideScore: away);
}

/// Reloads all Grinta highlights for [match] and writes the derived score.
///
/// Updates [match.homeScore] / [match.outSideScore] in memory to match.
Future<({int homeScore, int outsideScore})> syncMatchScoreFromGoalHighlights(
  models.Match match, {
  HighlightsService? highlightsService,
  MatchService? matchService,
  List<Highlights>? highlights,
}) async {
  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    throw Exception('Match id is missing');
  }

  final HighlightsService hlService = highlightsService ?? HighlightsService();
  final MatchService mService = matchService ?? MatchService();

  final List<Highlights> allHighlights = highlights ??
      await hlService.getHighlightsByMatchCalendarId(matchId);

  final scores = scoreFromGoalHighlights(match, allHighlights);

  await mService.updateScore(
    matchId: matchId,
    homeScore: scores.homeScore,
    outsideScore: scores.outsideScore,
    tab: match.tab,
    isMatchPlayed: match.isMatchPlayed == true,
  );

  match.homeScore = scores.homeScore;
  match.outSideScore = scores.outsideScore;
  return scores;
}

String? affiliationTeamForHighlight(Highlights highlight) {
  switch (highlight.actionType) {
    case ActionType.goal:
      return (highlight.value as Goal?)?.affiliationTeam;
    case ActionType.yellowCard:
    case ActionType.redCard:
      return (highlight.value as YellowRedCard?)?.affiliationTeam;
    case ActionType.substitution:
      return (highlight.value as Substitution?)?.affiliationTeam;
    case ActionType.timeEvent:
    case null:
      return null;
  }
}

String? logoUrlForSide(models.Match match, MatchSide side) {
  final String? raw = side == MatchSide.team1
      ? match.team1UrlLogo
      : match.team2UrlLogo;
  final String trimmed = raw?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Club logo URL (when cached on the match) and display name for [highlight].
({String? logoUrl, String name})? clubInfoForHighlight(
  models.Match match,
  Highlights highlight,
) {
  final MatchSide? side = sideForAffiliationTeam(
    match,
    affiliationTeamForHighlight(highlight),
  );
  if (side == null) {
    return null;
  }

  final String name = teamDisplayNameForSide(match, side);
  final String? logoUrl = logoUrlForSide(match, side);
  if (logoUrl == null && name.isEmpty) {
    return null;
  }

  return (logoUrl: logoUrl, name: name);
}

MatchSide? sideForAffiliationTeam(
  models.Match match,
  String? affiliationTeam,
) {
  final String normalized = affiliationTeam?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized == affiliationTeamForSide(match, MatchSide.team1)) {
    return MatchSide.team1;
  }
  if (normalized == affiliationTeamForSide(match, MatchSide.team2)) {
    return MatchSide.team2;
  }

  return null;
}

List<PlayerCompo> allPlayersFromCompo(MatchCompo compo) {
  final List<PlayerCompo> players = <PlayerCompo>[];

  void addAll(List<PlayerCompo>? list) {
    if (list == null) {
      return;
    }
    for (final PlayerCompo player in list) {
      if ((player.playerID?.trim() ?? '').isEmpty) {
        continue;
      }
      players.add(player);
    }
  }

  addAll(compo.goalkeeper);
  addAll(compo.defender);
  addAll(compo.midfielder);
  addAll(compo.midfielderAttaking);
  addAll(compo.midfielderDefensive);
  addAll(compo.stricker);
  addAll(compo.substitute);

  return players;
}

String displayLabelForPlayerCompo(PlayerCompo player) {
  final String name = player.playerNameDisplayed?.trim() ??
      player.customName?.trim() ??
      '';
  final int? number = player.number;
  if (name.isNotEmpty && number != null) {
    return '#$number $name';
  }
  if (name.isNotEmpty) {
    return name;
  }
  if (number != null) {
    return '#$number';
  }
  return player.playerID?.trim() ?? '';
}

bool compoHasPlayers(MatchCompo? compo) {
  if (compo == null) {
    return false;
  }
  return allPlayersFromCompo(compo).isNotEmpty;
}

bool goalHasAssociatedPlayer(Goal goal) {
  final String? playerId = goal.playerId?.trim();
  if (playerId != null && playerId.isNotEmpty) {
    return true;
  }

  final String? name = goal.playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return true;
  }

  return goal.playerNumber != null;
}

String goalHighlightLabel({
  required Goal goal,
  required String fallback,
}) {
  if (!goalHasAssociatedPlayer(goal)) {
    return fallback;
  }

  final String? playerId = goal.playerId?.trim();
  if (playerId != null && playerId.isNotEmpty) {
    return displayLabelForPlayerCompo(
      PlayerCompo(
        playerID: playerId,
        number: goal.playerNumber,
        playerNameDisplayed: goal.playerName,
      ),
    );
  }

  final String? name = goal.playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }

  final int? number = goal.playerNumber;
  if (number != null) {
    return '#$number';
  }

  return fallback;
}

Future<void> saveGoalHighlightAndUpdateScore({
  required models.Match match,
  required MatchSide side,
  required Goal goal,
  required String? teamId,
  int minute = 1,
  int extraTime = 0,
}) async {
  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    throw Exception('Match id is missing');
  }

  // Persist affiliation from the selected side so score recomputation is exact.
  goal.affiliationTeam = affiliationTeamForSide(match, side);

  final highlight = Highlights(
    matchCalendarId: matchId,
    teamId: teamId,
    minute: minute,
    extraTime: extraTime,
    actionType: ActionType.goal,
    value: goal,
    dateTime: Timestamp.now(),
  );

  final MatchService matchService = MatchService();
  await HighlightsService().addHighlight(highlight);

  // Always recompute from all goal highlights — never increment a stale score.
  await syncMatchScoreFromGoalHighlights(match, matchService: matchService);

  if (match.isInHighLight != true) {
    await matchService.updateHighlightStatus(
      matchId: matchId,
      isInHighLight: true,
    );
  }
}

/// Shows a confirmation dialog before deleting a Grinta highlight.
Future<bool> confirmDeleteHighlight(
  BuildContext context, {
  required String highlightLabel,
}) async {
  final colors = context.appColors;
  final l10n = context.l10n;

  final confirmed = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.matchGrintaHighlightDeleteConfirmTitle),
        content: Text(
          l10n.matchGrintaHighlightDeleteConfirmMessage(highlightLabel),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext, rootNavigator: true)
                .pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext, rootNavigator: true).pop(true),
            child: Text(
              l10n.actionDelete,
              style: TextStyle(
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  return confirmed == true;
}

Future<void> deleteHighlightAndMaybeUpdateScore({
  required models.Match match,
  required Highlights highlight,
}) async {
  await HighlightsService().deleteHighlight(highlight);

  if (highlight.actionType != ActionType.goal) {
    return;
  }

  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    return;
  }

  // Recompute from remaining goals (handles multi-delete / stale match safely).
  await syncMatchScoreFromGoalHighlights(match);
}
