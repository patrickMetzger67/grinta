import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/highlightsService.dart';
import 'package:grinta/services/matchService.dart';
import 'package:grinta/util/match_goal_helper.dart';

CardType cardTypeForAction(ActionType actionType) {
  switch (actionType) {
    case ActionType.yellowCard:
      return CardType.yellow;
    case ActionType.redCard:
      return CardType.red;
    default:
      throw ArgumentError('Not a card action: $actionType');
  }
}

bool cardHasAssociatedPlayer(YellowRedCard card) {
  final String? playerId = card.playerId?.trim();
  if (playerId != null && playerId.isNotEmpty) {
    return true;
  }

  final String? name = card.playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return true;
  }

  return card.playerNumber != null;
}

String cardHighlightLabel({
  required YellowRedCard card,
  required String fallback,
}) {
  if (!cardHasAssociatedPlayer(card)) {
    return fallback;
  }

  final String? playerId = card.playerId?.trim();
  if (playerId != null && playerId.isNotEmpty) {
    return displayLabelForPlayerCompo(
      PlayerCompo(
        playerID: playerId,
        number: card.playerNumber,
        playerNameDisplayed: card.playerName,
      ),
    );
  }

  final String? name = card.playerName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }

  final int? number = card.playerNumber;
  if (number != null) {
    return '#$number';
  }

  return fallback;
}

Future<void> saveCardHighlight({
  required models.Match match,
  required ActionType actionType,
  required YellowRedCard card,
  required String? teamId,
  int minute = 1,
  int extraTime = 0,
}) async {
  if (actionType != ActionType.yellowCard &&
      actionType != ActionType.redCard) {
    throw ArgumentError('Not a card action: $actionType');
  }

  final String? matchId = match.id?.trim();
  if (matchId == null || matchId.isEmpty) {
    throw Exception('Match id is missing');
  }

  card.cardType = cardTypeForAction(actionType);

  final highlight = Highlights(
    matchCalendarId: matchId,
    teamId: teamId,
    minute: minute,
    extraTime: extraTime,
    actionType: actionType,
    value: card,
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
