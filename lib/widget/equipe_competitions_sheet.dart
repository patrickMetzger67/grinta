import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/teams_per_club.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/fff_competition_url.dart';

/// Shows a bottom sheet listing parsed FFF competitions for an [equipe].
Future<void> showEquipeCompetitionsSheet(
  BuildContext context, {
  required Equipe equipe,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => EquipeCompetitionsSheet(equipe: equipe),
  );
}

class EquipeCompetitionsSheet extends StatelessWidget {
  const EquipeCompetitionsSheet({
    super.key,
    required this.equipe,
  });

  final Equipe equipe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final teamName = equipe.name?.trim() ?? '';
    final entries = equipe.competitions
        .map(
          (url) => (
            url: url,
            info: parseFffCompetitionUrl(url),
          ),
        )
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.equipeCompetitionsSheetTitle(teamName),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final info = entry.info;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      info?.name ?? entry.url,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: info == null
                        ? null
                        : Text(
                            '${l10n.fffCompetitionPhaseLabel(info.phase)} · '
                            '${l10n.fffCompetitionGroupeLabel(info.groupe)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.textSecondary,
                                    ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
