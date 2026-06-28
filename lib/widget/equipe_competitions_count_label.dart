import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';

/// Competition count subtitle used in équipe picker and teams list.
class EquipeCompetitionsCountLabel extends StatelessWidget {
  const EquipeCompetitionsCountLabel({
    super.key,
    required this.count,
    this.maxLines = 2,
  });

  final int count;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final colors = context.appColors;
    return Text(
      context.l10n.teamCreationClubTeamCompetitionsCount(count),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
    );
  }
}
