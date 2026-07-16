import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';

/// Opens a dialog to edit [team]'s name and saves via [TeamService].
///
/// Returns `true` when the name was updated successfully.
/// Callers must gate access (e.g. managers/owners only).
Future<bool> editTeamName(
  BuildContext context, {
  required Team team,
}) async {
  final String? newName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => _EditTeamNameDialog(
      initialName: team.name ?? '',
    ),
  );
  if (newName == null || !context.mounted) {
    return false;
  }

  final String teamId = team.keyTeam?.trim() ?? '';
  if (teamId.isEmpty) {
    AppSnackbar.show(
      context,
      context.l10n.errorGeneric('keyTeam null ou vide'),
      isError: true,
    );
    return false;
  }

  try {
    await TeamService().updateTeamName(teamId: teamId, name: newName);
    team.name = newName;

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

class _EditTeamNameDialog extends StatefulWidget {
  const _EditTeamNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditTeamNameDialog> createState() => _EditTeamNameDialogState();
}

class _EditTeamNameDialogState extends State<_EditTeamNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.teamEditNameTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.entityTeam,
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return l10n.hintRequiredField;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
