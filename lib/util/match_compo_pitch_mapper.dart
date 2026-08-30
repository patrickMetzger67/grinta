import 'package:flutter/material.dart';

import '../model/compoType.dart';
import '../model/match.dart' as models;
import '../model/matchCompo.dart';
import '../model/player.dart';
import '../util/app_theme.dart';
import '../widget/half_pitch_compo_widget.dart';

List<String> normalizeTeamIdList(Iterable<dynamic> rawIds) {
  return rawIds
      .map((dynamic raw) => raw?.toString().trim() ?? '')
      .where((String id) => id.isNotEmpty)
      .toList();
}

/// Équipes du profil pertinentes pour un match (intersection avec [match.teams]).
List<String> profileTeamIdsForMatch({
  required List<String> profileTeamIds,
  required models.Match match,
}) {
  final Set<String> profileIds = normalizeTeamIdList(profileTeamIds).toSet();
  if (profileIds.isEmpty) return const <String>[];

  final Set<String> matchTeamIds =
      normalizeTeamIdList(match.teams ?? const <dynamic>[]).toSet();
  if (matchTeamIds.isEmpty) return profileIds.toList();

  final List<String> intersection =
      profileIds.where(matchTeamIds.contains).toList();
  return intersection.isNotEmpty ? intersection : profileIds.toList();
}

/// Choisit la compo du match appartenant au profil (plusieurs équipes possibles).
MatchCompo? pickMatchCompoForProfileTeams(
  List<MatchCompo> compos, {
  required List<String> profileTeamIds,
  String? preferredTeamId,
}) {
  final Set<String> allowed = normalizeTeamIdList(profileTeamIds).toSet();
  if (allowed.isEmpty) return null;

  final List<MatchCompo> filtered = compos.where((MatchCompo compo) {
    final String teamId = compo.teamID?.trim() ?? '';
    return teamId.isNotEmpty && allowed.contains(teamId);
  }).toList();

  if (filtered.isEmpty) return null;
  if (filtered.length == 1) return filtered.first;

  final String? preferred = preferredTeamId?.trim();
  if (preferred != null && preferred.isNotEmpty) {
    for (final MatchCompo compo in filtered) {
      if (compo.teamID?.trim() == preferred) return compo;
    }
  }

  return filtered.first;
}

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

/// Nom affiché (team1/team2) pour un identifiant d'équipe Grinta du match.
String? teamDisplayNameForTeamId(models.Match match, String? teamId) {
  final String? id = teamId?.trim();
  if (id == null || id.isEmpty) return null;

  final String? primaryId = match.teamID?.trim();
  if (primaryId != null && primaryId.isNotEmpty && primaryId == id) {
    final String? name = match.team1?.trim();
    if (name != null && name.isNotEmpty) return name;
  }

  final List<String> linkedTeamIds =
      normalizeTeamIdList(match.teams ?? const <dynamic>[]);
  if (linkedTeamIds.isNotEmpty && linkedTeamIds.first == id) {
    final String? name = match.team1?.trim();
    if (name != null && name.isNotEmpty) return name;
  }
  if (linkedTeamIds.length > 1 && linkedTeamIds[1] == id) {
    final String? name = match.team2?.trim();
    if (name != null && name.isNotEmpty) return name;
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

/// Applies a formation change to an in-memory starters map.
///
/// When [pruneIncompatibleSlots] is false, placements are left untouched.
/// That mode is required for the *initial* default formation selection while
/// an async hydrate is still loading the saved CompoType: pruning against
/// `types.first` (e.g. a 3-defender formation) would otherwise drop a saved
/// 4-3-3 right-back (`defender_4`) before the real type arrives.
Map<String, PlayerCompo> startersAfterCompoTypeChange({
  required Map<String, PlayerCompo> starters,
  required CompoType type,
  required bool pruneIncompatibleSlots,
}) {
  if (!pruneIncompatibleSlots) {
    return Map<String, PlayerCompo>.of(starters);
  }
  final validSlotIds = buildCompoSlots(type).map((s) => s.id).toSet();
  return Map<String, PlayerCompo>.fromEntries(
    starters.entries.where((entry) => validSlotIds.contains(entry.key)),
  );
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

  for (final entry in startersBySlotId.entries) {
    final slotId = entry.key;
    final player = entry.value;
    final role = slotRoleFromSlotId(slotId);
    final slotIndex = _slotIndex(slotId);
    if (slotIndex <= 0) continue;
    _setPlayerAtRoleSlotIndex(compo, role, slotIndex, player);
  }

  _trimTrailingEmptyPlayers(compo.goalkeeper!);
  _trimTrailingEmptyPlayers(compo.defender!);
  _trimTrailingEmptyPlayers(compo.midfielder!);
  _trimTrailingEmptyPlayers(compo.midfielderAttaking!);
  _trimTrailingEmptyPlayers(compo.midfielderDefensive!);
  _trimTrailingEmptyPlayers(compo.stricker!);

  compo.substitute = List<PlayerCompo>.from(substitutes);
}

int _slotIndex(String slotId) {
  final role = slotRoleFromSlotId(slotId);
  final suffix = slotId.substring(role.length + 1);
  return int.tryParse(suffix) ?? 0;
}

List<PlayerCompo> _roleListForSlot(MatchCompo compo, String slotRole) {
  switch (matchCompoListRole(slotRole)) {
    case 'goalkeeper':
      return compo.goalkeeper!;
    case 'defender':
      return compo.defender!;
    case 'midfielder':
      return compo.midfielder!;
    case 'midfielderAttacking':
      return compo.midfielderAttaking!;
    case 'midfielderDefensive':
      return compo.midfielderDefensive!;
    case 'stricker':
      return compo.stricker!;
    default:
      return compo.midfielder!;
  }
}

void _setPlayerAtRoleSlotIndex(
  MatchCompo compo,
  String slotRole,
  int oneBasedIndex,
  PlayerCompo player,
) {
  final list = _roleListForSlot(compo, slotRole);
  final index = oneBasedIndex - 1;
  while (list.length <= index) {
    list.add(PlayerCompo());
  }
  list[index] = player;
}

void _trimTrailingEmptyPlayers(List<PlayerCompo> list) {
  while (list.isNotEmpty) {
    final id = list.last.playerID?.trim();
    if (id != null && id.isNotEmpty) break;
    list.removeLast();
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

/// Fond de carte pour un joueur convoqué (`null` = pas convoqué).
Color? convocationCardBackground(AppColors colors, PlayerConvo? convo) {
  if (convo == null) {
    return null;
  }
  if (convo.isPresent == true && convo.asAnswer == true) {
    return colors.success.withValues(alpha: 0.12);
  }
  if (convo.isPresent != true || convo.asAnswer != true) {
    return colors.warning.withValues(alpha: 0.12);
  }
  return null;
}

PlayerConvo? convocationForPlayerId(
  List<PlayerConvo>? convocations,
  String playerId,
) {
  final trimmed = playerId.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  for (final PlayerConvo convo in convocations ?? const <PlayerConvo>[]) {
    if (convo.playerID?.trim() == trimmed) {
      return convo;
    }
  }
  return null;
}

List<PlayerConvo> toggleConvocation({
  required List<PlayerConvo> convocations,
  required String playerId,
  required bool selected,
}) {
  final trimmed = playerId.trim();
  if (trimmed.isEmpty) {
    return convocations;
  }

  final updated = List<PlayerConvo>.from(convocations);
  final index = updated.indexWhere((c) => c.playerID?.trim() == trimmed);
  if (selected) {
    if (index < 0) {
      updated.add(
        PlayerConvo(playerID: trimmed, isPresent: true, asAnswer: false),
      );
    }
  } else if (index >= 0) {
    updated.removeAt(index);
  }
  return updated;
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
