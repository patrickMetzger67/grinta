import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/cards_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/manager_cards_helper.dart';
import 'package:grinta/widget/team_stats_cards_section.dart';

/// Picks one managed team when the coach manages several.
Future<Team?> showManagedTeamPickerSheet(
  BuildContext context, {
  required List<Team> teams,
}) {
  Widget buildSheet() {
    return _ManagedTeamPickerSheet(teams: teams);
  }

  if (kIsWeb) {
    return showDialog<Team>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: buildSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet<Team>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => buildSheet(),
  );
}

class _ManagedTeamPickerSheet extends StatelessWidget {
  const _ManagedTeamPickerSheet({required this.teams});

  final List<Team> teams;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.managerCardsPickTeamTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.managerCardsPickTeamSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final label = managerTeamDisplayName(
                    team,
                    fallback: l10n.entityTeam,
                  );
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(team),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: colors.textPrimary,
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
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.actionClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Team Stats Cartons list for one managed team (purge enabled for managers).
Future<void> showManagerTeamCardsSheet(
  BuildContext context, {
  required Team team,
  TeamPlayersService? teamPlayersService,
  CardsService? cardsService,
}) {
  Widget buildSheet() {
    return _ManagerTeamCardsSheet(
      team: team,
      teamPlayersService: teamPlayersService,
      cardsService: cardsService,
    );
  }

  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 780),
          child: buildSheet(),
        ),
      ),
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => buildSheet(),
  );
}

class _ManagerTeamCardsSheet extends StatelessWidget {
  const _ManagerTeamCardsSheet({
    required this.team,
    this.teamPlayersService,
    this.cardsService,
  });

  final Team team;
  final TeamPlayersService? teamPlayersService;
  final CardsService? cardsService;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final teamName = managerTeamDisplayName(team, fallback: l10n.entityTeam);
    final media = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: media.size.height * 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.managerCardsTeamTitle(teamName),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.actionClose),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: TeamStatsCardsSection(
                    team: team,
                    isManager: true,
                    teamPlayersService: teamPlayersService,
                    cardsService: cardsService,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
