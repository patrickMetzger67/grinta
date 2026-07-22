import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/create_match_sheet.dart';
import 'package:grinta/widget/create_non_sport_event_sheet.dart';
import 'package:grinta/widget/create_personal_sport_activity_sheet.dart';
import 'package:grinta/widget/create_training_sheet.dart';

enum AgendaAddEventKind {
  match,
  training,
  personalSport,
  nonSport,
}

Future<void> showAgendaAddEventMenu(
  BuildContext context, {
  DateTime? initialDate,
  VoidCallback? onTrainingCreated,
}) async {
  if (kIsWeb) {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _AgendaAddEventDialog(
        hostContext: context,
        overlayContext: dialogContext,
        initialDate: initialDate,
        onTrainingCreated: onTrainingCreated,
      ),
    );
    return;
  }

  final colors = context.appColors;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _AgendaAddEventBody(
            onSelected: (kind) => _handleSelection(
              context,
              sheetContext,
              kind,
              initialDate: initialDate,
              onTrainingCreated: onTrainingCreated,
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _handleSelection(
  BuildContext hostContext,
  BuildContext overlayContext,
  AgendaAddEventKind kind, {
  DateTime? initialDate,
  VoidCallback? onTrainingCreated,
}) async {
  Navigator.of(overlayContext).pop();

  if (kind == AgendaAddEventKind.training) {
    await showCreateTrainingSheet(
      hostContext,
      initialDate: initialDate,
      onSaved: onTrainingCreated,
    );
    return;
  }

  if (kind == AgendaAddEventKind.match) {
    await showCreateMatchSheet(
      hostContext,
      initialDate: initialDate,
      onSaved: onTrainingCreated,
    );
    return;
  }

  if (kind == AgendaAddEventKind.nonSport) {
    await showCreateNonSportEventSheet(
      hostContext,
      initialDate: initialDate,
      onSaved: onTrainingCreated,
    );
    return;
  }

  if (kind == AgendaAddEventKind.personalSport) {
    await showCreatePersonalSportActivitySheet(
      hostContext,
      initialDate: initialDate,
      onSaved: onTrainingCreated,
    );
    return;
  }
}

class _AgendaAddEventDialog extends StatelessWidget {
  const _AgendaAddEventDialog({
    required this.hostContext,
    required this.overlayContext,
    this.initialDate,
    this.onTrainingCreated,
  });

  final BuildContext hostContext;
  final BuildContext overlayContext;
  final DateTime? initialDate;
  final VoidCallback? onTrainingCreated;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: _AgendaAddEventBody(
          onSelected: (kind) => _handleSelection(
            hostContext,
            overlayContext,
            kind,
            initialDate: initialDate,
            onTrainingCreated: onTrainingCreated,
          ),
        ),
      ),
    );
  }
}

class _AgendaAddEventBody extends StatelessWidget {
  const _AgendaAddEventBody({required this.onSelected});

  final ValueChanged<AgendaAddEventKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!kIsWeb) ...[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.agendaAddEventTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _AgendaAddEventOptionTile(
            icon: Icons.sports_soccer_rounded,
            iconColor: colors.danger,
            title: l10n.agendaAddEventMatch,
            onTap: () => onSelected(AgendaAddEventKind.match),
          ),
          const SizedBox(height: 8),
          _AgendaAddEventOptionTile(
            icon: Icons.fitness_center_rounded,
            iconColor: colors.primary,
            title: l10n.agendaAddEventTraining,
            onTap: () => onSelected(AgendaAddEventKind.training),
          ),
          const SizedBox(height: 8),
          _AgendaAddEventOptionTile(
            icon: Icons.directions_run_rounded,
            iconColor: colors.success,
            title: l10n.agendaAddEventPersonalSport,
            subtitle: l10n.agendaAddEventPersonalSportHint,
            onTap: () => onSelected(AgendaAddEventKind.personalSport),
          ),
          const SizedBox(height: 8),
          _AgendaAddEventOptionTile(
            icon: Icons.event_rounded,
            iconColor: colors.warning,
            title: l10n.agendaAddEventNonSport,
            onTap: () => onSelected(AgendaAddEventKind.nonSport),
          ),
        ],
      ),
    );
  }
}

class _AgendaAddEventOptionTile extends StatelessWidget {
  const _AgendaAddEventOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
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
  }
}
