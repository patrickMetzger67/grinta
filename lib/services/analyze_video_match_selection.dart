import 'package:flutter/material.dart';
import 'package:grinta/model/match.dart';
import 'package:grinta/model/matchCompo.dart';
import 'package:grinta/services/analyze_player_detection.dart';

class DebugVideoRosterPlayer {
  const DebugVideoRosterPlayer({
    required this.teamId,
    required this.displayName,
    required this.isSubstitute,
    this.playerId,
    this.number,
  });

  final String teamId;
  final String? playerId;
  final int? number;
  final String displayName;
  final bool isSubstitute;
}

DateTime debugVideoDayStart(DateTime day) => DateUtils.dateOnly(day);

DateTime debugVideoDayEnd(DateTime day) {
  final start = debugVideoDayStart(day);
  return DateTime(start.year, start.month, start.day, 23, 59, 59, 999);
}

String formatDebugVideoDate(DateTime day) {
  final d = debugVideoDayStart(day);
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

DateTime? parseDebugVideoDate(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
  if (slash != null) {
    final day = int.parse(slash.group(1)!);
    final month = int.parse(slash.group(2)!);
    final year = int.parse(slash.group(3)!);
    return _validDate(year: year, month: month, day: day);
  }

  final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(text);
  if (iso != null) {
    final year = int.parse(iso.group(1)!);
    final month = int.parse(iso.group(2)!);
    final day = int.parse(iso.group(3)!);
    return _validDate(year: year, month: month, day: day);
  }
  return null;
}

DateTime? _validDate({
  required int year,
  required int month,
  required int day,
}) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

bool matchOccursOnDebugVideoDay(Match match, DateTime day) {
  final wanted = debugVideoDayStart(day);
  final timestamp = match.timestamp?.toDate();
  if (timestamp != null) {
    return debugVideoDayStart(timestamp) == wanted;
  }
  final fromLabel = parseDebugVideoDate(match.dateCh ?? '');
  return fromLabel != null && fromLabel == wanted;
}

String debugVideoMatchLabel(Match match) {
  final home = match.team1?.trim() ?? '';
  final away = match.team2?.trim() ?? '';
  final time = match.timeCh?.trim() ?? '';
  final vs = [home, away].where((part) => part.isNotEmpty).join(' – ');
  if (time.isEmpty) return vs;
  if (vs.isEmpty) return time;
  return '$time  $vs';
}

bool _hasRosterIdentity(PlayerCompo player) {
  return (player.playerID?.trim().isNotEmpty ?? false) ||
      player.number != null ||
      (player.playerNameDisplayed?.trim().isNotEmpty ?? false);
}

String debugVideoPlayerDisplayName(PlayerCompo player) {
  final displayed = player.playerNameDisplayed?.trim() ?? '';
  if (displayed.isNotEmpty) return displayed;
  final custom = player.customName?.trim() ?? '';
  if (custom.isNotEmpty) return custom;
  return '';
}

List<DebugVideoRosterPlayer> debugVideoRosterFromCompo(MatchCompo compo) {
  final teamId = compo.teamID?.trim() ?? '';

  DebugVideoRosterPlayer toRoster(PlayerCompo player, {required bool sub}) {
    return DebugVideoRosterPlayer(
      teamId: teamId,
      playerId: player.playerID?.trim(),
      number: player.number,
      displayName: debugVideoPlayerDisplayName(player),
      isSubstitute: sub,
    );
  }

  final starters = <PlayerCompo>[
    ...?compo.goalkeeper,
    ...?compo.defender,
    ...?compo.midfielder,
    ...?compo.midfielderDefensive,
    ...?compo.midfielderAttaking,
    ...?compo.stricker,
  ].where(_hasRosterIdentity);

  final subs = (compo.substitute ?? const <PlayerCompo>[]).where(
    _hasRosterIdentity,
  );

  final roster = <DebugVideoRosterPlayer>[
    ...starters.map((player) => toRoster(player, sub: false)),
    ...subs.map((player) => toRoster(player, sub: true)),
  ];
  roster.sort((a, b) {
    final an = a.number ?? 999;
    final bn = b.number ?? 999;
    if (an != bn) return an.compareTo(bn);
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  });
  return roster;
}

/// Assigns a sheet player at most once. Already locked boxes are left untouched.
List<PlayerDetectionBox> associateUniqueRosterPlayers({
  required List<PlayerDetectionBox> boxes,
  required List<DebugVideoRosterPlayer> roster,
}) {
  if (boxes.isEmpty || roster.isEmpty) return boxes;
  final taken = associatedPlayerIds(boxes);
  final byNumber = <int, List<DebugVideoRosterPlayer>>{};
  for (final player in roster) {
    final number = player.number;
    if (number == null) continue;
    byNumber.putIfAbsent(number, () => <DebugVideoRosterPlayer>[]).add(player);
  }

  return boxes.map((box) {
    if ((box.playerId ?? '').trim().isNotEmpty) return box;
    final number = box.jerseyNumber;
    if (number == null) return box;
    final boxTeam = box.teamId?.trim() ?? '';
    if (boxTeam.isEmpty) return box;
    final forTeam = (byNumber[number] ?? const <DebugVideoRosterPlayer>[])
        .where((player) => player.teamId == boxTeam)
        .toList();
    if (forTeam.length != 1) return box;
    final pick = forTeam.first;
    final playerId = pick.playerId?.trim() ?? '';
    if (playerId.isEmpty || taken.contains(playerId)) {
      return box;
    }
    taken.add(playerId);
    return box.copyWith(
      playerId: playerId,
      teamId: pick.teamId,
      jerseyNumber: pick.number ?? box.jerseyNumber,
    );
  }).toList(growable: false);
}

Map<String, String> debugVideoMatchMetadata({
  String? matchId,
  String? teamId,
  String? seasonId,
  String? matchLabel,
  String? team1KitColor,
  String? team2KitColor,
  String? refereeKitColor,
}) {
  final metadata = <String, String>{};
  void put(String key, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) metadata[key] = trimmed;
  }

  put('matchId', matchId);
  put('teamId', teamId);
  put('seasonId', seasonId);
  put('matchLabel', matchLabel);
  put('team1KitColor', team1KitColor);
  put('team2KitColor', team2KitColor);
  put('refereeKitColor', refereeKitColor);
  return metadata;
}
