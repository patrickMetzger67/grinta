import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/match_goal_helper.dart';

bool _substitutionPlayerPresent({
  String? playerId,
  String? playerName,
  int? playerNumber,
}) {
  final String? id = playerId?.trim();
  if (id != null && id.isNotEmpty) {
    return true;
  }

  final String? name = playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return true;
  }

  return playerNumber != null;
}

bool substitutionHasAssociatedPlayers(Substitution substitution) {
  return _substitutionPlayerPresent(
        playerId: substitution.outgoingPlayerId,
        playerName: substitution.outgoingPlayerName,
        playerNumber: substitution.outgoingPlayerNumber,
      ) ||
      _substitutionPlayerPresent(
        playerId: substitution.enteringPlayerId,
        playerName: substitution.enteringPlayerName,
        playerNumber: substitution.enteringPlayerNumber,
      );
}

String substitutionPlayerLabel({
  String? playerId,
  String? playerName,
  int? playerNumber,
  required String fallback,
}) {
  final String? id = playerId?.trim();
  if (id != null && id.isNotEmpty) {
    return displayLabelForPlayerCompo(
      PlayerCompo(
        playerID: id,
        number: playerNumber,
        playerNameDisplayed: playerName,
      ),
    );
  }

  final String? name = playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }

  if (playerNumber != null) {
    return '#$playerNumber';
  }

  return fallback;
}

String? substitutionOutgoingLabel(Substitution substitution) {
  if (!_substitutionPlayerPresent(
    playerId: substitution.outgoingPlayerId,
    playerName: substitution.outgoingPlayerName,
    playerNumber: substitution.outgoingPlayerNumber,
  )) {
    return null;
  }

  return substitutionPlayerLabel(
    playerId: substitution.outgoingPlayerId,
    playerName: substitution.outgoingPlayerName,
    playerNumber: substitution.outgoingPlayerNumber,
    fallback: '',
  );
}

String? substitutionIncomingLabel(Substitution substitution) {
  if (!_substitutionPlayerPresent(
    playerId: substitution.enteringPlayerId,
    playerName: substitution.enteringPlayerName,
    playerNumber: substitution.enteringPlayerNumber,
  )) {
    return null;
  }

  return substitutionPlayerLabel(
    playerId: substitution.enteringPlayerId,
    playerName: substitution.enteringPlayerName,
    playerNumber: substitution.enteringPlayerNumber,
    fallback: '',
  );
}

Future<void> saveSubstitutionHighlight({
  required models.Match match,
  required Substitution substitution,
  required String? teamId,
  int minute = 1,
  int extraTime = 0,
}) async {
  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    throw Exception('Match id is missing');
  }

  final highlight = Highlights(
    matchCalendarId: matchId,
    teamId: teamId,
    minute: minute,
    extraTime: extraTime,
    actionType: ActionType.substitution,
    value: substitution,
    dateTime: Timestamp.now(),
  );

  await HighlightsService().addHighlight(highlight);

  if (match.isInHighLight != true) {
    await MatchService().updateHighlightStatus(
      matchId: matchId,
      isInHighLight: true,
    );
  }
}
