import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/player_task_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_task_access.dart';
import 'package:grinta/widget/confirm_delete_dialog.dart';
import 'package:grinta/widget/create_player_task_sheet.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> showPlayerTaskDetailSheet(
  BuildContext context, {
  required PlayerTask task,
  VoidCallback? onChanged,
}) {
  if (kIsWeb) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.appColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.appColors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: _PlayerTaskDetailBody(
            task: task,
            onChanged: onChanged,
          ),
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
    builder: (_) => _PlayerTaskDetailBody(
      task: task,
      onChanged: onChanged,
    ),
  );
}

class _PlayerTaskDetailBody extends StatelessWidget {
  const _PlayerTaskDetailBody({
    required this.task,
    this.onChanged,
  });

  final PlayerTask task;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final session = context.watch<AppSession>();
    final bool canManage = canManagePlayerTask(task, session);
    final String period = task.startDay == task.endDay
        ? DateFormat.yMMMEd(locale).format(task.startDay)
        : '${DateFormat.yMMMd(locale).format(task.startDay)} → ${DateFormat.yMMMd(locale).format(task.endDay)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: task.colorValue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.barLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.playerTaskPeriod,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              period,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.playerTaskAssignees,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              task.assigneeNames.isEmpty
                  ? l10n.createPlayerTaskNoPlayers
                  : task.assigneeNames.join(', '),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
            if (canManage) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final PlayerTask? updated =
                            await showCreatePlayerTaskSheet(
                          context,
                          initialDate: task.startAt,
                          taskToEdit: task,
                          onSaved: onChanged,
                        );
                        if (updated != null && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.playerTaskEdit),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final bool? deleted = await showConfirmDeleteDialog(
                          context: context,
                          title: l10n.deletePlayerTaskConfirmTitle,
                          message: l10n.deletePlayerTaskConfirmMessage(
                            task.barLabel,
                          ),
                          onConfirm: () =>
                              PlayerTaskService().deleteTask(task),
                        );
                        if (deleted == true && context.mounted) {
                          onChanged?.call();
                          Navigator.of(context).pop();
                        }
                      },
                      icon: Icon(Icons.delete_outline, color: colors.danger),
                      label: Text(
                        l10n.actionDelete,
                        style: TextStyle(color: colors.danger),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
