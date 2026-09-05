import 'package:grinta/model/highlights.dart';
import 'package:grinta/model/match.dart' as models;
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/model/matchStats.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_cards.dart';
import 'package:grinta/services/matchCompoService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';
import 'package:grinta/util/match_goal_helper.dart';
import 'package:grinta/util/playerDisplayName.dart';

/// Convoked player shown in the FMI card-assignment picker.
class AssignFmiCardPlayerOption {
  const AssignFmiCardPlayerOption({
    required this.memberId,
    required this.label,
  });

  /// Same id as `member` / highlight `playerID` / convocation `playerID`.
  final String memberId;
  final String label;
}

bool isGrintaCardAction(ActionType? actionType) {
  return actionType == ActionType.yellowCard ||
      actionType == ActionType.redCard;
}

String? playerCardTypeFromActionType(ActionType? actionType) {
  switch (actionType) {
    case ActionType.yellowCard:
      return playerCardTypeYellow;
    case ActionType.redCard:
      return playerCardTypeRed;
    default:
      return null;
  }
}

String? playerCardTypeFromCardType(CardType? cardType) {
  switch (cardType) {
    case CardType.yellow:
      return playerCardTypeYellow;
    case CardType.red:
      return playerCardTypeRed;
    default:
      return null;
  }
}

/// Maps highlight / FMI type strings to the `cards` type field.
///
/// Accepts Grinta `CardType.yellow` / `ActionType.yellowCard` and FMI aliases
/// (`yellowcard`, `carton_jaune`, `red_card`, …). Second-yellow / yellow-red
/// sending-off events are stored as [playerCardTypeRed].
String? parsePlayerCardType(dynamic raw) {
  var normalized = raw?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  normalized = normalized.replaceAll(' ', '').replaceAll('-', '_');
  const cardTypePrefix = 'cardtype.';
  const actionTypePrefix = 'actiontype.';
  if (normalized.startsWith(cardTypePrefix)) {
    normalized = normalized.substring(cardTypePrefix.length);
  } else if (normalized.startsWith(actionTypePrefix)) {
    normalized = normalized.substring(actionTypePrefix.length);
  }
  normalized = normalized.replaceAll('_', '');

  switch (normalized) {
    case 'yellow':
    case 'yellowcard':
    case 'cartonjaune':
      return playerCardTypeYellow;
    case 'red':
    case 'redcard':
    case 'cartonrouge':
    case 'secondyellow':
    case 'secondyellowcard':
    case 'yellowred':
    case 'yellowredcard':
    case 'cartonjaunerouge':
      return playerCardTypeRed;
    default:
      return null;
  }
}

bool isFmiCardHighlight(MatchStatHighLight highlight) {
  return parsePlayerCardType(highlight.type) != null;
}

String? playerCardTypeFromFmiHighlight(MatchStatHighLight highlight) {
  return parsePlayerCardType(highlight.type);
}

/// Builds a new [PlayerCardEntry] for a Grinta card highlight.
///
/// Returns null when there is no member id (opponent jersey-only) or the
/// action is not a card. [isPurged] defaults to false.
PlayerCardEntry? playerCardEntryFromGrintaHighlight({
  required String matchId,
  required ActionType actionType,
  String? playerId,
  int minute = 0,
  int extraTime = 0,
  CardType? cardType,
}) {
  final memberId = playerId?.trim() ?? '';
  if (memberId.isEmpty) {
    return null;
  }

  final type = playerCardTypeFromActionType(actionType) ??
      playerCardTypeFromCardType(cardType);
  if (type == null) {
    return null;
  }

  return PlayerCardEntry(
    matchId: matchId.trim(),
    time: minute,
    extraTime: extraTime,
    type: type,
    isPurged: false,
  );
}

PlayerCardEntry? playerCardEntryFromFmiHighlight({
  required String matchId,
  required MatchStatHighLight highlight,
  required String memberId,
}) {
  final trimmedMemberId = memberId.trim();
  final trimmedMatchId = matchId.trim();
  final type = playerCardTypeFromFmiHighlight(highlight);
  if (trimmedMemberId.isEmpty || trimmedMatchId.isEmpty || type == null) {
    return null;
  }

  return PlayerCardEntry(
    matchId: trimmedMatchId,
    time: highlight.time ?? 0,
    extraTime: 0,
    type: type,
    isPurged: false,
  );
}

/// Appends [incoming] unless an entry with the same match+time+type exists.
///
/// Existing [PlayerCardEntry.isPurged] is left unchanged on a duplicate.
List<PlayerCardEntry> upsertPlayerCardEntry(
  List<PlayerCardEntry> existing,
  PlayerCardEntry incoming,
) {
  for (final entry in existing) {
    if (entry.hasSameIdentityAs(incoming)) {
      return List<PlayerCardEntry>.from(existing);
    }
  }
  return <PlayerCardEntry>[...existing, incoming];
}

bool playerCardEntryExists(
  List<PlayerCardEntry> existing,
  PlayerCardEntry incoming,
) {
  return existing.any((entry) => entry.hasSameIdentityAs(incoming));
}

/// Convoked players for the FMI card picker (`MatchCompo.convocation.playerID`).
Future<List<AssignFmiCardPlayerOption>> loadConvokedPlayersForCardAssignment({
  required models.Match match,
  required List<String> managedTeamIds,
  MatchCompoService? matchCompoService,
  PlayerService? playerService,
}) async {
  final matchId = match.id?.trim() ?? '';
  if (matchId.isEmpty) {
    return const <AssignFmiCardPlayerOption>[];
  }

  final preferredTeamId = resolveTeamIdForMatch(
    match,
    managedTeamIds: managedTeamIds,
  );
  final service = matchCompoService ?? MatchCompoService();
  final MatchCompo? compo = await service.getMatchCompoForMatchAndTeamIds(
    matchId,
    profileTeamIds: managedTeamIds,
    preferredTeamId: preferredTeamId,
  );
  if (compo == null) {
    return const <AssignFmiCardPlayerOption>[];
  }

  final convokedIds = convokedPlayerIds(compo);
  if (convokedIds.isEmpty) {
    return const <AssignFmiCardPlayerOption>[];
  }

  final lineupById = <String, PlayerCompo>{};
  for (final player in allPlayersFromCompo(compo)) {
    final id = player.playerID?.trim() ?? '';
    if (id.isNotEmpty) {
      lineupById[id] = player;
    }
  }

  final members = playerService ?? PlayerService();
  final options = <AssignFmiCardPlayerOption>[];
  final seen = <String>{};

  for (final rawId in convokedIds) {
    final memberId = rawId.trim();
    if (memberId.isEmpty || !seen.add(memberId)) {
      continue;
    }

    String label = memberId;
    try {
      final Player? player = await members.getPlayerById(memberId);
      if (player != null) {
        final name = playerDisplayName(player, unknownLabel: '');
        if (name.isNotEmpty) {
          label = name;
        }
      }
    } catch (_) {
      // Fall through to lineup / raw id.
    }

    if (label == memberId) {
      final lineup = lineupById[memberId];
      if (lineup != null) {
        final lineupLabel = displayLabelForPlayerCompo(lineup);
        if (lineupLabel.isNotEmpty) {
          label = lineupLabel;
        }
      }
    }

    options.add(
      AssignFmiCardPlayerOption(memberId: memberId, label: label),
    );
  }

  options.sort(
    (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
  );
  return options;
}
