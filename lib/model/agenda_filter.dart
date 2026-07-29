import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/util/match_compo_pitch_mapper.dart';

/// Local agenda filter (teams + event types).
///
/// Empty [teamIds] or [types] means "no restriction" (show all).
class AgendaFilter {
  const AgendaFilter({
    this.teamIds = const <String>{},
    this.types = const <AgendaItemType>{},
  });

  final Set<String> teamIds;
  final Set<AgendaItemType> types;

  static const AgendaFilter none = AgendaFilter();

  bool get isActive => teamIds.isNotEmpty || types.isNotEmpty;

  AgendaFilter copyWith({
    Set<String>? teamIds,
    Set<AgendaItemType>? types,
  }) {
    return AgendaFilter(
      teamIds: teamIds ?? this.teamIds,
      types: types ?? this.types,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'teamIds': teamIds.toList()..sort(),
      'types': types.map((t) => t.name).toList()..sort(),
    };
  }

  factory AgendaFilter.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AgendaFilter.none;
    final rawTeams = json['teamIds'];
    final rawTypes = json['types'];
    final teams = <String>{
      if (rawTeams is List)
        for (final raw in rawTeams)
          if ((raw?.toString().trim() ?? '').isNotEmpty) raw.toString().trim(),
    };
    final types = <AgendaItemType>{};
    if (rawTypes is List) {
      for (final raw in rawTypes) {
        final name = raw?.toString().trim() ?? '';
        for (final type in AgendaItemType.values) {
          if (type.name == name) {
            types.add(type);
            break;
          }
        }
      }
    }
    return AgendaFilter(teamIds: teams, types: types);
  }

  /// Normalize a draft selection against the available options.
  ///
  /// Selecting every available team/type collapses to "no restriction".
  static AgendaFilter normalize({
    required Set<String> selectedTeamIds,
    required Set<AgendaItemType> selectedTypes,
    required Set<String> availableTeamIds,
    required Set<AgendaItemType> availableTypes,
  }) {
    final teams = selectedTeamIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && availableTeamIds.contains(id))
        .toSet();
    final types = selectedTypes
        .where(availableTypes.contains)
        .toSet();

    return AgendaFilter(
      teamIds: teams.length >= availableTeamIds.length ? const <String>{} : teams,
      types: types.length >= availableTypes.length
          ? const <AgendaItemType>{}
          : types,
    );
  }
}

/// Team ids associated with an agenda item (may be empty for personal events).
Set<String> agendaItemTeamIds(AgendaItem item) {
  switch (item.type) {
    case AgendaItemType.match:
      return normalizeTeamIdList(item.match?.teams ?? const <dynamic>[]).toSet();
    case AgendaItemType.entrainement:
      final id = item.training?.teamId?.trim() ?? '';
      return id.isEmpty ? const <String>{} : <String>{id};
    case AgendaItemType.preparationPhysique:
      return {
        for (final id in item.personalSportActivity?.teamIds ?? const <String>[])
          if (id.trim().isNotEmpty) id.trim(),
      };
    case AgendaItemType.nonSport:
      return {
        for (final id in item.nonSportEvent?.teamIds ?? const <String>[])
          if (id.trim().isNotEmpty) id.trim(),
      };
  }
}

bool agendaItemMatchesFilter(AgendaItem item, AgendaFilter filter) {
  if (filter.types.isNotEmpty && !filter.types.contains(item.type)) {
    return false;
  }
  if (filter.teamIds.isEmpty) {
    return true;
  }
  final itemTeams = agendaItemTeamIds(item);
  // Personal / unscoped events stay visible when a team filter is active.
  if (itemTeams.isEmpty) {
    return true;
  }
  return itemTeams.any(filter.teamIds.contains);
}

List<AgendaItem> applyAgendaFilter(
  Iterable<AgendaItem> items,
  AgendaFilter filter,
) {
  if (!filter.isActive) {
    return List<AgendaItem>.from(items);
  }
  return [
    for (final item in items)
      if (agendaItemMatchesFilter(item, filter)) item,
  ];
}
