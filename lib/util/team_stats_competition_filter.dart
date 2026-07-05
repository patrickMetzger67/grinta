import 'package:grinta/model/match.dart';
import 'package:grinta/util/fff_competition_url.dart';

/// Parses a competition engagement URL into filter criteria, or null when
/// [url] is empty (meaning all competitions).
FffCompetitionInfo? competitionFilterFromUrl(String? url) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }
  return parseFffCompetitionUrl(trimmed);
}

/// Whether [match] belongs to the competition described by [filter].
///
/// Compares [Match.competitionID] to the URL engagement id, [Match.poule] to
/// the URL groupe, and [Match.stage] to the URL phase — same fields used when
/// loading agenda matches via engagements.
bool matchMatchesCompetitionFilter(Match match, FffCompetitionInfo filter) {
  final competitionId = filter.engagementId?.trim() ?? '';
  if (competitionId.isEmpty) {
    return false;
  }

  final matchCompetitionId = match.competitionID?.trim() ?? '';
  if (matchCompetitionId != competitionId) {
    return false;
  }

  final group = filter.groupe.toString();
  if (group.isNotEmpty) {
    final matchPoule = match.poule?.trim() ?? '';
    if (matchPoule != group) {
      return false;
    }
  }

  final stage = filter.phase.toString();
  if (stage.isNotEmpty) {
    final matchStage = match.stage?.trim() ?? '';
    if (matchStage != stage) {
      return false;
    }
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
