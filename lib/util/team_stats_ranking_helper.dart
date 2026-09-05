import 'package:grinta/model/ranking.dart';
import 'package:grinta/model/rankingPerDay.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/screen/team_stats/team_stats_competition_selector.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/util/fff_competition_url.dart';

/// Parsed competition filter for ranking Firestore queries.
class TeamStatsRankingCompetitionFilter {
  const TeamStatsRankingCompetitionFilter({
    required this.competitionId,
    required this.poule,
  });

  final String competitionId;
  final String poule;
}

TeamStatsRankingCompetitionFilter? teamStatsRankingFilterFromSelection(
  String selectedValue,
) {
  if (selectedValue == kTeamStatsAllCompetitionsValue) {
    return null;
  }

  final info = parseFffCompetitionUrl(selectedValue);
  if (info == null) {
    return null;
  }

  final competitionId = info.engagementId?.trim() ?? '';
  if (competitionId.isEmpty || info.groupe <= 0) {
    return null;
  }

  return TeamStatsRankingCompetitionFilter(
    competitionId: competitionId,
    poule: info.groupe.toString(),
  );
}

/// Resolved identifiers used to match [RankingPerDay.teamAffiliate] and
/// highlight the user's club in standings.
class TeamStatsRankingTeamContext {
  const TeamStatsRankingTeamContext({
    required this.teamId,
    required this.clubId,
    required this.teamName,
    required this.primaryAffiliate,
    this.clubAffiliation,
  });

  final String teamId;
  final String clubId;
  final String? clubAffiliation;
  final String teamName;
  final String primaryAffiliate;

  bool matchesAffiliate(String? affiliate) {
    final normalized = affiliate?.trim() ?? '';
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized == primaryAffiliate) {
      return true;
    }
    if (teamId.isNotEmpty && normalized == teamId) {
      return true;
    }
    if (clubId.isNotEmpty && normalized == clubId) {
      return true;
    }
    final affiliation = clubAffiliation?.trim() ?? '';
    return affiliation.isNotEmpty && normalized == affiliation;
  }

  bool matchesRankRow(Rank rank) {
    final label = rank.team?.trim() ?? '';
    if (label.isEmpty || teamName.isEmpty) {
      return false;
    }
    return label.toLowerCase() == teamName.toLowerCase();
  }
}

Future<TeamStatsRankingTeamContext> resolveTeamStatsRankingTeamContext(
  Team team, {
  ClubService? clubService,
}) async {
  final clubId = team.clubId?.trim() ?? '';
  final teamId = team.keyTeam?.trim() ?? '';
  final teamName = team.name?.trim() ?? '';

  String? clubAffiliation;
  if (clubId.isNotEmpty) {
    final club = await (clubService ?? ClubService()).getClubById(clubId);
    clubAffiliation = club?.affiliation?.trim();
  }

  final primaryAffiliate = (clubAffiliation != null && clubAffiliation.isNotEmpty)
      ? clubAffiliation
      : (teamId.isNotEmpty ? teamId : clubId);

  return TeamStatsRankingTeamContext(
    teamId: teamId,
    clubId: clubId,
    clubAffiliation: clubAffiliation,
    teamName: teamName,
    primaryAffiliate: primaryAffiliate,
  );
}

class TeamStatsRankingClubOption {
  const TeamStatsRankingClubOption({
    required this.affiliateKey,
    required this.displayName,
    required this.isOwnTeam,
  });

  final String affiliateKey;
  final String displayName;
  final bool isOwnTeam;
}

List<TeamStatsRankingClubOption> buildRankingClubOptions(
  List<RankingPerDay> entries,
  TeamStatsRankingTeamContext teamContext,
) {
  final namesByAffiliate = <String, String>{};

  for (final entry in entries) {
    final affiliate = entry.teamAffiliate?.trim() ?? '';
    if (affiliate.isEmpty) {
      continue;
    }

    final teamName = entry.teamName?.trim();
    namesByAffiliate.putIfAbsent(
      affiliate,
      () => (teamName != null && teamName.isNotEmpty) ? teamName : affiliate,
    );
  }

  final options = namesByAffiliate.entries
      .map(
        (entry) => TeamStatsRankingClubOption(
          affiliateKey: entry.key,
          displayName: entry.value,
          isOwnTeam: teamContext.matchesAffiliate(entry.key),
        ),
      )
      .toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );

  return options;
}

Map<String, List<RankingPerDay>> groupRankingPerDayByAffiliate(
  List<RankingPerDay> entries,
) {
  final grouped = <String, List<RankingPerDay>>{};

  for (final entry in entries) {
    final affiliate = entry.teamAffiliate?.trim() ?? '';
    if (affiliate.isEmpty) {
      continue;
    }
    grouped.putIfAbsent(affiliate, () => []).add(entry);
  }

  for (final series in grouped.values) {
    series.sort((a, b) => (a.day ?? 0).compareTo(b.day ?? 0));
  }

  return grouped;
}

List<int> sortedMatchdaysFromRankingPerDay(List<RankingPerDay> entries) {
  final days = entries
      .map((entry) => entry.day)
      .whereType<int>()
      .where((day) => day > 0)
      .toSet()
      .toList()
    ..sort();
  return days;
}

int rankingTeamCountFromEntries(List<RankingPerDay> entries) {
  for (final entry in entries) {
    final nbTeams = entry.nbTeams;
    if (nbTeams != null && nbTeams > 0) {
      return nbTeams;
    }
  }

  var maxRank = 0;
  for (final entry in entries) {
    final rank = entry.rank;
    if (rank != null && rank > maxRank) {
      maxRank = rank;
    }
  }
  return maxRank > 0 ? maxRank : 1;
}

Ranking? pickBestRankingDocument(List<Ranking> rankings) {
  if (rankings.isEmpty) {
    return null;
  }

  rankings.sort((a, b) {
    final aCount = a.ranks?.length ?? 0;
    final bCount = b.ranks?.length ?? 0;
    return bCount.compareTo(aCount);
  });
  return rankings.first;
}
