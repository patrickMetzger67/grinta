import 'package:grinta/model/team.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/services/teams_per_club_service.dart';

/// Loads [Equipe] entries for [teams] via [TeamsPerClub], keyed by [Team.keyTeam].
///
/// Teams without [Team.clubId], [Team.teamIdInTeamsPerClub], or a matching équipe
/// are omitted from the result.
Future<Map<String, Equipe>> loadEquipesForTeams({
  required List<Team> teams,
  required String? fallbackSeasonId,
  TeamsPerClubService? service,
}) async {
  final teamsPerClubService = service ?? TeamsPerClubService();
  final result = <String, Equipe>{};

  final teamsByClubSeason = <String, List<Team>>{};
  for (final team in teams) {
    final clubId = team.clubId?.trim() ?? '';
    final equipeId = team.teamIdInTeamsPerClub?.trim() ?? '';
    final teamKey = team.keyTeam?.trim() ?? '';
    if (clubId.isEmpty || equipeId.isEmpty || teamKey.isEmpty) continue;

    final seasonId = _seasonIdForTeam(team, fallbackSeasonId);
    if (seasonId.isEmpty) continue;

    final cacheKey = '$clubId|$seasonId';
    teamsByClubSeason.putIfAbsent(cacheKey, () => <Team>[]).add(team);
  }

  await Future.wait(
    teamsByClubSeason.entries.map((entry) async {
      final parts = entry.key.split('|');
      if (parts.length != 2) return;

      final clubId = parts[0];
      final seasonId = parts[1];

      final teamsPerClub = await teamsPerClubService.getByClubIdAndSeason(
        clubId: clubId,
        seasonId: seasonId,
      );
      if (teamsPerClub == null) return;

      final equipesById = <String, Equipe>{
        for (final equipe in teamsPerClub.equipes)
          if ((equipe.id?.trim() ?? '').isNotEmpty) equipe.id!.trim(): equipe,
      };

      for (final team in entry.value) {
        final equipeId = team.teamIdInTeamsPerClub!.trim();
        final equipe = equipesById[equipeId];
        if (equipe == null) continue;

        final teamKey = team.keyTeam!.trim();
        result[teamKey] = equipe;
      }
    }),
  );

  return result;
}

String _seasonIdForTeam(Team team, String? fallbackSeasonId) {
  final teamSeasonId = team.seasonID?.trim() ?? '';
  if (teamSeasonId.isNotEmpty) return teamSeasonId;
  return fallbackSeasonId?.trim() ?? '';
}
