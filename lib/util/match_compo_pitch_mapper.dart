import '../model/compoType.dart';
import '../model/match.dart' as models;
import '../model/matchCompo.dart';
import '../model/player.dart';
import '../widget/half_pitch_compo_widget.dart';

/// Identifiant d'équipe Grinta pour un match (teamID, compo ou liste `teams`).
String? resolveTeamIdForMatch(
  models.Match match, {
  MatchCompo? matchCompo,
  List<String> managedTeamIds = const [],
}) {
  final fromCompo = matchCompo?.teamID?.trim();
  if (fromCompo != null && fromCompo.isNotEmpty) return fromCompo;

  final fromMatch = match.teamID?.trim();
  if (fromMatch != null && fromMatch.isNotEmpty) return fromMatch;

  final linkedTeams = match.teams ?? <dynamic>[];
  for (final raw in linkedTeams) {
    final id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty && managedTeamIds.contains(id)) return id;
  }
  for (final raw in linkedTeams) {
    final id = raw?.toString().trim() ?? '';
    if (id.isNotEmpty) return id;
  }

  return null;
}

/// Rôle d'un slot terrain → liste Firestore dans [MatchCompo].
String matchCompoListRole(String slotRole) {
  if (slotRole == 'striker') return 'stricker';
  return slotRole;
}

String slotRoleFromSlotId(String slotId) {
  final index = slotId.lastIndexOf('_');
  if (index <= 0) return slotId;
  return slotId.substring(0, index);
}

/// Lit les titulaires d'un [MatchCompo] vers des clés de slot (`defender_1`, …).
Map<String, PlayerCompo> startersFromMatchCompo(MatchCompo compo) {
  final map = <String, PlayerCompo>{};

  void readList(List<PlayerCompo>? list, String slotRole) {
    if (list == null) return;
    for (var i = 0; i < list.length; i++) {
      final player = list[i];
      final id = player.playerID?.trim();
      if (id == null || id.isEmpty) continue;
      map['${slotRole}_${i + 1}'] = player;
    }
  }

  readList(compo.goalkeeper, 'goalkeeper');
  readList(compo.defender, 'defender');
  readList(compo.midfielder, 'midfielder');
  readList(compo.midfielderAttaking, 'midfielderAttacking');
  readList(compo.midfielderDefensive, 'midfielderDefensive');
  readList(compo.stricker, 'striker');

  return map;
}

List<PlayerCompo> substitutesFromMatchCompo(MatchCompo compo) {
  return (compo.substitute ?? <PlayerCompo>[])
      .where((p) => (p.playerID?.trim() ?? '').isNotEmpty)
      .toList();
}

/// Construit la carte slot → joueur affiché sur le terrain.
Map<String, CompoFieldPlayer> compoFieldPlayersFromMatchCompo({
  required MatchCompo compo,
  required Map<String, Player> playersById,
  Map<String, String>? photoUrlByPlayerId,
}) {
  final starters = startersFromMatchCompo(compo);
  final result = <String, CompoFieldPlayer>{};

  for (final entry in starters.entries) {
    final playerId = entry.value.playerID?.trim();
    if (playerId == null || playerId.isEmpty) continue;

    final player = playersById[playerId];
    final displayName = _displayName(entry.value, player);
    result[entry.key] = CompoFieldPlayer(
      id: playerId,
      name: displayName,
      photoUrl: photoUrlByPlayerId?[playerId],
      shirtNumber: entry.value.number?.toString(),
    );
  }

  return result;
}

String _displayName(PlayerCompo compo, Player? player) {
  final custom = compo.playerNameDisplayed?.trim();
  if (custom != null && custom.isNotEmpty) return custom;
  if (player != null) {
    final first = player.firstName?.trim() ?? '';
    final last = player.lastName?.trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
  }
  return compo.playerID ?? '';
}

/// Applique les titulaires et remplaçants sur un [MatchCompo].
void applyAssignmentsToMatchCompo({
  required MatchCompo compo,
  required Map<String, PlayerCompo> startersBySlotId,
  required List<PlayerCompo> substitutes,
}) {
  compo.goalkeeper = [];
  compo.defender = [];
  compo.midfielder = [];
  compo.midfielderAttaking = [];
  compo.midfielderDefensive = [];
  compo.stricker = [];

  final sortedSlots = startersBySlotId.keys.toList()
    ..sort((a, b) {
      final roleCmp = slotRoleFromSlotId(a).compareTo(slotRoleFromSlotId(b));
      if (roleCmp != 0) return roleCmp;
      return _slotIndex(a).compareTo(_slotIndex(b));
    });

  for (final slotId in sortedSlots) {
    final player = startersBySlotId[slotId];
    if (player == null) continue;
    final role = slotRoleFromSlotId(slotId);
    _addToRoleList(compo, role, player);
  }

  compo.substitute = List<PlayerCompo>.from(substitutes);
}

int _slotIndex(String slotId) {
  final role = slotRoleFromSlotId(slotId);
  final suffix = slotId.substring(role.length + 1);
  return int.tryParse(suffix) ?? 0;
}

void _addToRoleList(MatchCompo compo, String slotRole, PlayerCompo player) {
  switch (matchCompoListRole(slotRole)) {
    case 'goalkeeper':
      compo.goalkeeper!.add(player);
      break;
    case 'defender':
      compo.defender!.add(player);
      break;
    case 'midfielder':
      compo.midfielder!.add(player);
      break;
    case 'midfielderAttacking':
      compo.midfielderAttaking!.add(player);
      break;
    case 'midfielderDefensive':
      compo.midfielderDefensive!.add(player);
      break;
    case 'stricker':
      compo.stricker!.add(player);
      break;
  }
}

PlayerCompo playerCompoFromPlayer(
  Player player, {
  int? number,
  String? deviceOwnerId,
  String? customName,
}) {
  final id = player.ref?.id ?? '';
  final first = player.firstName?.trim() ?? '';
  final last = player.lastName?.trim() ?? '';
  final name = '$first $last'.trim();

  final compo = PlayerCompo(
    playerID: id,
    number: number,
    playerNameDisplayed: name.isNotEmpty ? name : id,
  );
  final trackerId = deviceOwnerId?.trim();
  compo.deviceOwnerId =
      (trackerId != null && trackerId.isNotEmpty) ? trackerId : null;
  final trackerName = customName?.trim();
  compo.customName =
      (trackerName != null && trackerName.isNotEmpty) ? trackerName : null;
  return compo;
}

/// Numéros de maillot déjà attribués dans la compo (titulaires + remplaçants).
void collectUsedJerseyNumbers({
  required Map<String, PlayerCompo> startersBySlotId,
  required List<PlayerCompo> substitutes,
  String? excludeSlotId,
  required Set<int> outNumbers,
}) {
  void add(PlayerCompo compo) {
    final number = compo.number;
    if (number != null && number >= 1 && number <= 99) {
      outNumbers.add(number);
    }
  }

  for (final entry in startersBySlotId.entries) {
    if (excludeSlotId != null && entry.key == excludeSlotId) continue;
    add(entry.value);
  }
  for (final sub in substitutes) {
    add(sub);
  }
}

/// Numéros 1–99 non encore attribués ([retainAssignment] reste sélectionnable).
List<int> availableJerseyNumbers({
  required Map<String, PlayerCompo> startersBySlotId,
  required List<PlayerCompo> substitutes,
  String? excludeSlotId,
  PlayerCompo? retainAssignment,
}) {
  final used = <int>{};
  collectUsedJerseyNumbers(
    startersBySlotId: startersBySlotId,
    substitutes: substitutes,
    excludeSlotId: excludeSlotId,
    outNumbers: used,
  );

  final retainNumber = retainAssignment?.number;
  if (retainNumber != null && retainNumber >= 1 && retainNumber <= 99) {
    used.remove(retainNumber);
  }

  return [for (var n = 1; n <= 99; n++) if (!used.contains(n)) n];
}

/// Capteurs déjà affectés dans la compo courante (titulaires + remplaçants).
void collectUsedTrackerAssignments({
  required Map<String, PlayerCompo> startersBySlotId,
  required List<PlayerCompo> substitutes,
  String? excludeSlotId,
  required Set<String> outDeviceOwnerIds,
  required Set<String> outCustomNames,
}) {
  void add(PlayerCompo compo) {
    final id = compo.deviceOwnerId?.trim();
    if (id != null && id.isNotEmpty) outDeviceOwnerIds.add(id);
    final name = compo.customName?.trim();
    if (name != null && name.isNotEmpty) outCustomNames.add(name);
  }

  for (final entry in startersBySlotId.entries) {
    if (excludeSlotId != null && entry.key == excludeSlotId) continue;
    add(entry.value);
  }
  for (final sub in substitutes) {
    add(sub);
  }
}

Set<String> convokedPlayerIds(MatchCompo compo) {
  return (compo.convocation ?? <PlayerConvo>[])
      .map((c) => c.playerID?.trim())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();
}

List<PlayerConvo> convocationFromPlayerIds(Set<String> playerIds) {
  return playerIds
      .map((id) => PlayerConvo(playerID: id, isPresent: true, asAnswer: false))
      .toList();
}

String? resolveCompoTypeDocumentId(String? stored) {
  final value = stored?.trim();
  if (value == null || value.isEmpty) return null;
  if (value.contains('/')) {
    return value.split('/').last;
  }
  return value;
}

String compoTypeKey(CompoType compoType) {
  return compoType.ref?.path ?? compoType.ref?.id ?? compoType.name ?? '';
}
