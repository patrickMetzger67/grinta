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
///
/// FFF / calendar imports often store only our team id in [Match.teams].
/// Index 0 is then our club, **not** necessarily home — [Match.isOwnClub]
/// places it on team1 (home) or team2 (away). Returning [linked.first] for
/// every team1 selection wrongly shows our roster under the opponent name
/// when we play away (jersey-only on our side if [Match.teamID] is missing).
String? teamIdForSide(models.Match match, MatchSide side) {
  final List<String> linked =
      normalizeTeamIdList(match.teams ?? const <dynamic>[]);

  // Two linked teams: array order is home then away.
  if (linked.length >= 2) {
    if (side == MatchSide.team1) return linked[0];
    if (side == MatchSide.team2) return linked[1];
  }

  // Single linked id = our team only. Place it with isOwnClub, not index 0.
  if (linked.length == 1) {
    final String onlyId = linked.first;
    if (match.isOwnClub == true && side == MatchSide.team1) {
      return onlyId;
    }
    if (match.isOwnClub == false && side == MatchSide.team2) {
      return onlyId;
    }
    // isOwnClub unknown: do not guess home from index 0.
  }

  final String? primaryId = match.teamID?.trim();
  if (primaryId == null || primaryId.isEmpty) {
    return null;
  }

  if (side == MatchSide.team1 && match.isOwnClub == true) {
    return primaryId;
  }
  if (side == MatchSide.team2 && match.isOwnClub == false) {
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
/// Clamps at 0. Updates [match.homeScore] / [match.outSideScore] in memory
/// before the network write so the UI can refresh immediately via
/// [onLocalScoreApplied].
Future<({int homeScore, int outsideScore})> adjustMatchSideScore({
  required models.Match match,
  required MatchSide side,
  required int delta,
  MatchService? matchService,
  VoidCallback? onLocalScoreApplied,
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

  // Optimistic in-memory update first (single Firestore write below).
  final bool markInHighlight = delta > 0 && match.isInHighLight != true;
  match.homeScore = home;
  match.outSideScore = away;
  if (markInHighlight) {
    match.isInHighLight = true;
  }
  onLocalScoreApplied?.call();

  final MatchService mService = matchService ?? MatchService();
  await mService.updateScore(
    matchId: matchId,
    homeScore: home,
    outsideScore: away,
    tab: match.tab,
    isMatchPlayed: match.isMatchPlayed == true,
    isInHighLight: markInHighlight ? true : null,
  );

  return (homeScore: home, outsideScore: away);
}

/// Reloads all Grinta highlights for [match] and writes the derived score.
///
/// Updates [match.homeScore] / [match.outSideScore] in memory to match.
/// When [isInHighLight] is non-null, it is included in the same score write.
Future<({int homeScore, int outsideScore})> syncMatchScoreFromGoalHighlights(
  models.Match match, {
  HighlightsService? highlightsService,
  MatchService? matchService,
  List<Highlights>? highlights,
  bool? isInHighLight,
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
    isInHighLight: isInHighLight,
  );

  match.homeScore = scores.homeScore;
  match.outSideScore = scores.outsideScore;
  if (isInHighLight != null) {
    match.isInHighLight = isInHighLight;
  }
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
  // Fold isInHighLight into the same score write when needed.
  final bool markInHighlight = match.isInHighLight != true;
  await syncMatchScoreFromGoalHighlights(
    match,
    matchService: matchService,
    isInHighLight: markInHighlight ? true : null,
  );
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
