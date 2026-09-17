import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/team_fine_scale.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/team_fine_scale_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_fine_access.dart';
import 'package:grinta/util/team_fine_amount.dart';
import 'package:grinta/widget/confirm_delete_dialog.dart';
import 'package:grinta/widget/create_team_fine_scale_sheet.dart';
import 'package:provider/provider.dart';

/// Opens fines management for managers and the designated fines-manager player.
Future<void> openTeamFinesScreen(BuildContext context) async {
  final List<Team> teams =
      finesManagedTeamsForSession(context.read<AppSession>());
  if (teams.isEmpty) {
    AppSnackbar.show(context, context.l10n.teamFinesNoTeams);
    return;
  }

  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.teamFines,
      builder: (_) => TeamFinesScreen(teams: teams),
    ),
  );
}

class TeamFinesScreen extends StatelessWidget {
  const TeamFinesScreen({
    super.key,
    required this.teams,
  });

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    if (teams.length == 1) {
      return TeamFineScalesScreen(
        team: teams.first,
        accessibleTeams: teams,
      );
    }

    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTeamFines,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'grinta-fab-team-fines-hub',
        tooltip: l10n.createTeamFineScaleTitle,
        onPressed: () => showCreateTeamFineScaleSheet(
          context,
          teams: teams,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: teams.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final Team team = teams[index];
          final String name = (team.name ?? '').trim().isEmpty
              ? l10n.entityTeam
              : team.name!.trim();
          return Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.of(context).push(
                  analyticsMaterialRoute<void>(
                    screenName: AnalyticsScreenNames.teamFinesScales,
                    builder: (_) => TeamFineScalesScreen(
                      team: team,
                      accessibleTeams: teams,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class TeamFineScalesScreen extends StatelessWidget {
  const TeamFineScalesScreen({
    super.key,
    required this.team,
    required this.accessibleTeams,
  });

  final Team team;
  final List<Team> accessibleTeams;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final String teamName = (team.name ?? '').trim().isEmpty
        ? l10n.entityTeam
        : team.name!.trim();
    final String? teamId = team.keyTeam;
    final bool singleTeam = accessibleTeams.length == 1;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.settingsTeamFines,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'grinta-fab-team-fines-scales-${teamId ?? 'team'}',
        tooltip: l10n.createTeamFineScaleTitle,
        onPressed: () => showCreateTeamFineScaleSheet(
          context,
          teams: singleTeam ? accessibleTeams : <Team>[team],
          lockedTeamId: teamId,
        ),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              teamName,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: _TeamFineScalesList(teamId: teamId ?? ''),
          ),
        ],
      ),
    );
  }
}

class _TeamFineScalesList extends StatelessWidget {
  const _TeamFineScalesList({required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final TeamFineScaleService service = TeamFineScaleService();

    if (teamId.isEmpty) {
      return Center(
        child: Text(
          l10n.teamFinesEmptyScales,
          style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<TeamFineScale>>(
      stream: service.watchScalesForTeam(teamId),
      builder: (BuildContext context, AsyncSnapshot<List<TeamFineScale>> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.teamFinesLoadError,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<TeamFineScale> scales =
            snapshot.data ?? const <TeamFineScale>[];
        if (scales.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.teamFinesEmptyScales,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: scales.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            final TeamFineScale scale = scales[index];
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scale.typeName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatFineAmount(scale.amount),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.deleteTeamFineScaleTooltip,
                    onPressed: () => _confirmDelete(context, service, scale),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TeamFineScaleService service,
    TeamFineScale scale,
  ) async {
    final bool? deleted = await showConfirmDeleteDialog(
      context: context,
      title: context.l10n.deleteTeamFineScaleConfirmTitle,
      message: context.l10n.deleteTeamFineScaleConfirmMessage(scale.typeName),
      onConfirm: () => service.deleteScale(scale),
    );
    if (deleted == true && context.mounted) {
      AppSnackbar.show(context, context.l10n.deleteTeamFineScaleDeleted);
    }
  }
}
