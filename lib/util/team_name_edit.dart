import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/club.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/clubService.dart';
import 'package:grinta/services/engagement_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/engagement_sync.dart';
import 'package:grinta/util/team_equipe_lookup.dart';
import 'package:grinta/widget/team_basics_form_dialog.dart';
import 'package:provider/provider.dart';

/// Opens the team edit dialog (same fields as creation) and persists changes.
///
/// Returns `true` when the team was updated successfully.
/// Callers must gate access (e.g. managers/owners only).
Future<bool> editTeamName(
  BuildContext context, {
  required Team team,
}) async {
  final String teamId = team.keyTeam?.trim() ?? '';
  if (teamId.isEmpty) {
    AppSnackbar.show(
      context,
      context.l10n.errorGeneric('keyTeam null ou vide'),
      isError: true,
    );
    return false;
  }

  final seasonId = (team.seasonID?.trim().isNotEmpty == true)
      ? team.seasonID!.trim()
      : (context.read<AppSession>().selectedSeason?.ref?.id.trim() ?? '');

  Club? club;
  List<Equipe> initialEquipes = const <Equipe>[];
  final clubId = team.clubId?.trim() ?? '';
  if (clubId.isNotEmpty) {
    try {
      club = await ClubService().getClubById(clubId);
      final equipesByTeam = await loadEquipesForTeams(
        teams: <Team>[team],
        fallbackSeasonId: seasonId,
      );
      final equipe = equipesByTeam[teamId];
      if (equipe != null) {
        initialEquipes = <Equipe>[equipe];
      }
    } catch (e, stackTrace) {
      debugPrint('editTeam preload club/equipe failed: $e');
      debugPrint('$stackTrace');
    }
  }

  if (!context.mounted) return false;

  final draft = await showTeamBasicsFormDialog(
    context,
    title: context.l10n.teamEditNameTitle,
    submitLabel: context.l10n.actionSave,
    initialName: team.name ?? '',
    initialSoccerType: team.soccerType ?? 11,
    initialCountry: team.resolvedCountry,
    initialClubAffiliation: clubId.isEmpty ? null : clubId,
    initialClubName: club?.name,
    initialClubLogo: club?.logo,
    initialEquipes: initialEquipes,
    warnIfNoClub: true,
  );

  if (draft == null || !context.mounted) {
    return false;
  }

  try {
    final String? clubAffiliation = draft.clubAffiliation?.trim();
    final String? firstEquipeId = _firstSelectedEquipeId(draft.selectedEquipes);

    await TeamService().updateTeamBasics(
      teamId: teamId,
      name: draft.name,
      soccerType: draft.soccerType,
      country: draft.country,
      clubId: clubAffiliation,
      teamIdInTeamsPerClub: firstEquipeId,
    );

    await EngagementService().removeTeamIdFromAllEngagements(teamId);

    if (clubAffiliation != null &&
        clubAffiliation.isNotEmpty &&
        draft.selectedEquipes.isNotEmpty &&
        seasonId.isNotEmpty) {
      await syncEngagementsForEquipes(
        grintaTeamId: teamId,
        clubId: clubAffiliation,
        seasonId: seasonId,
        equipes: draft.selectedEquipes,
      );
    }

    team.name = draft.name;
    team.soccerType = draft.soccerType;
    team.country = draft.country;
    team.clubId = clubAffiliation;
    team.teamIdInTeamsPerClub = firstEquipeId;

    if (!context.mounted) {
      return true;
    }

    AppSnackbar.show(
      context,
      context.l10n.teamEditNameSuccess,
      isError: false,
    );
    return true;
  } catch (e, stackTrace) {
    debugPrint('editTeamName failed: $e');
    debugPrint('$stackTrace');
    if (!context.mounted) {
      return false;
    }
    AppSnackbar.show(
      context,
      context.l10n.errorGeneric(e.toString()),
      isError: true,
    );
    return false;
  }
}

String? _firstSelectedEquipeId(List<Equipe> equipes) {
  if (equipes.isEmpty) return null;
  final equipeId = equipes.first.id?.trim() ?? '';
  return equipeId.isEmpty ? null : equipeId;
}
