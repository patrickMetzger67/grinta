import 'package:grinta/model/engagement.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/services/engagement_service.dart';
import 'package:grinta/util/fff_competition_url.dart';

/// Upserts `engagement` documents for each FFF competition URL on [equipes],
/// adding [grintaTeamId] to the document's `teamIds` array.
///
/// Document id format: `{clubId}-{competitionId}-{group}-{stage}`.
Future<void> syncEngagementsForEquipes({
  required String grintaTeamId,
  required String clubId,
  required String seasonId,
  required List<Equipe> equipes,
}) async {
  final trimmedClubId = clubId.trim();
  final trimmedSeasonId = seasonId.trim();
  final trimmedTeamId = grintaTeamId.trim();

  if (trimmedClubId.isEmpty ||
      trimmedSeasonId.isEmpty ||
      trimmedTeamId.isEmpty ||
      equipes.isEmpty) {
    return;
  }

  final engagementService = EngagementService();
  var isFirst = true;

  for (final equipe in equipes) {
    for (final competitionUrl in equipe.competitions) {
      final info = parseFffCompetitionUrl(competitionUrl);
      final competitionId = info?.engagementId?.trim() ?? '';
      if (info == null || competitionId.isEmpty) continue;

      final documentId = buildEngagementDocumentId(
        clubId: trimmedClubId,
        competitionId: competitionId,
        group: info.groupe.toString(),
        stage: info.phase.toString(),
      );

      final engagement = Engagement(
        clubId: trimmedClubId,
        seasonId: trimmedSeasonId,
        name: info.name,
        competitionId: competitionId,
        group: info.groupe.toString(),
        stage: info.phase.toString(),
        isDefault: isFirst,
      );

      await engagementService.upsertEngagementWithTeamId(
        documentId: documentId,
        engagement: engagement,
        grintaTeamId: trimmedTeamId,
      );

      isFirst = false;
    }
  }
}
