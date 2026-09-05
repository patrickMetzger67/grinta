import 'package:grinta/model/match.dart';
import 'package:grinta/util/fff_competition_url.dart';

/// Competition identity taken from match fields (never from [Match.url]).
///
/// FFF match pages often put the home club's poule in the query string
/// (`poule=1`) while [Match.poule] is the real group for the linked team.
class TeamStatsCompetitionIdentity {
  const TeamStatsCompetitionIdentity({
    required this.competitionId,
    this.poule = '',
    this.stage = '',
  });

  final String competitionId;
  final String poule;
  final String stage;
}

/// Parses a competition engagement URL into filter criteria, or null when
/// [url] is empty (meaning all competitions).
FffCompetitionInfo? competitionFilterFromUrl(String? url) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return parseFffCompetitionUrl(trimmed);
}

/// Identity from [Match.competitionID] / [Match.poule] / [Match.stage] only.
TeamStatsCompetitionIdentity? competitionIdentityFromMatch(Match match) {
  final competitionId = match.competitionID?.trim() ?? '';
  if (competitionId.isEmpty) {
    return null;
  }
  return TeamStatsCompetitionIdentity(
    competitionId: competitionId,
    poule: match.poule?.trim() ?? '',
    stage: match.stage?.trim() ?? '',
  );
}

TeamStatsCompetitionIdentity? competitionIdentityFromUrl(String? url) {
  final info = competitionFilterFromUrl(url);
  if (info == null) {
    return null;
  }
  final competitionId = info.engagementId?.trim() ?? '';
  if (competitionId.isEmpty) {
    return null;
  }
  return TeamStatsCompetitionIdentity(
    competitionId: competitionId,
    poule: info.groupe > 0 ? info.groupe.toString() : '',
    stage: info.phase > 0 ? info.phase.toString() : '',
  );
}

bool competitionIdentitiesMatch(
  TeamStatsCompetitionIdentity expected,
  TeamStatsCompetitionIdentity candidate,
) {
  if (expected.competitionId != candidate.competitionId) {
    return false;
  }
  if (expected.poule.isNotEmpty) {
    if (candidate.poule.isEmpty || candidate.poule != expected.poule) {
      return false;
    }
  }
  if (expected.stage.isNotEmpty &&
      candidate.stage.isNotEmpty &&
      candidate.stage != expected.stage) {
    return false;
  }
  return true;
}

bool urlMatchesCompetitionIdentity(
  String? url,
  TeamStatsCompetitionIdentity identity,
) {
  final candidate = competitionIdentityFromUrl(url);
  if (candidate == null) {
    return false;
  }
  return competitionIdentitiesMatch(identity, candidate);
}

/// Whether [match] belongs to the competition described by [filter].
///
/// Compares [Match.competitionID] to the URL engagement id, [Match.poule] to
/// the URL groupe, and [Match.stage] to the URL phase — same fields used when
/// loading agenda matches via engagements.
///
/// [FffCompetitionInfo.groupe] / [FffCompetitionInfo.phase] of `0` mean the
/// URL did not specify them. A match with a poule then does not match.
bool matchMatchesCompetitionFilter(Match match, FffCompetitionInfo filter) {
  final competitionId = filter.engagementId?.trim() ?? '';
  if (competitionId.isEmpty) {
    return false;
  }

  final matchCompetitionId = match.competitionID?.trim() ?? '';
  if (matchCompetitionId != competitionId) {
    return false;
  }

  final matchPoule = match.poule?.trim() ?? '';
  if (filter.groupe > 0) {
    if (matchPoule != filter.groupe.toString()) {
      return false;
    }
  } else if (matchPoule.isNotEmpty) {
    return false;
  }

  final matchStage = match.stage?.trim() ?? '';
  if (filter.phase > 0 &&
      matchStage.isNotEmpty &&
      matchStage != filter.phase.toString()) {
    return false;
  }

  return true;
}

/// Filters [matches] to those belonging to [filter], or returns all when
/// [filter] is null.
List<Match> filterMatchesByCompetition(
  List<Match> matches, {
  FffCompetitionInfo? filter,
}) {
  if (filter == null) {
    return matches;
  }
  return matches
      .where((match) => matchMatchesCompetitionFilter(match, filter))
      .toList();
}
