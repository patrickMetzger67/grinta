import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/team_fine_scale.dart';
import 'package:grinta/model/team_fine_type.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/team_fine_scale_service.dart';
import 'package:grinta/services/team_fine_type_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/team_fine_amount.dart';
import 'package:provider/provider.dart';

Future<TeamFineScale?> showCreateTeamFineScaleSheet(
  BuildContext context, {
  required List<Team> teams,
  String? lockedTeamId,
}) async {
  if (teams.isEmpty) {
    return null;
  }

  final TeamFineScale? saved;
  if (kIsWeb) {
    saved = await showDialog<TeamFineScale>(
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
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
          child: CreateTeamFineScaleSheet(
            teams: teams,
            lockedTeamId: lockedTeamId,
          ),
        ),
      ),
    );
  } else {
    saved = await showModalBottomSheet<TeamFineScale>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.card,
      builder: (_) => CreateTeamFineScaleSheet(
        teams: teams,
        lockedTeamId: lockedTeamId,
      ),
    );
  }

  if (saved != null && context.mounted) {
    AppSnackbar.show(
      context,
      context.l10n.createTeamFineScaleSaved,
      isError: false,
    );
  }
  return saved;
}

class CreateTeamFineScaleSheet extends StatefulWidget {
  const CreateTeamFineScaleSheet({
    super.key,
    required this.teams,
    this.lockedTeamId,
  });

  final List<Team> teams;
  final String? lockedTeamId;

  @override
  State<CreateTeamFineScaleSheet> createState() =>
      _CreateTeamFineScaleSheetState();
}

class _CreateTeamFineScaleSheetState extends State<CreateTeamFineScaleSheet> {
  final TeamFineTypeService _typeService = TeamFineTypeService();
  final TeamFineScaleService _scaleService = TeamFineScaleService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  late List<Team> _teams;
  String? _selectedTeamId;
  List<TeamFineType> _types = const <TeamFineType>[];
  String? _selectedTypeId;

  bool get _showTeamDropdown => _teams.length > 1;

  @override
  void initState() {
    super.initState();
    _teams = List<Team>.from(widget.teams)
      ..sort(
        (Team a, Team b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );
    final String? locked = widget.lockedTeamId?.trim();
    if (locked != null &&
        locked.isNotEmpty &&
        _teams.any((Team team) => team.keyTeam == locked)) {
      _selectedTeamId = locked;
    } else if (_teams.length == 1) {
      _selectedTeamId = _teams.first.keyTeam;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_selectedTeamId == null && _teams.isNotEmpty) {
      _selectedTeamId = _teams.first.keyTeam;
    }
    if (mounted) {
      setState(() {});
    }
    if (_selectedTeamId != null) {
      await _loadTypes(_selectedTeamId!);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTypes(String teamId) async {
    try {
      final List<TeamFineType> types = await _typeService.ensureDefaultTypes(
        teamId: teamId,
        l10n: context.l10n,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _types = types;
        if (_selectedTypeId == null ||
            !_types.any((TeamFineType type) => type.id == _selectedTypeId)) {
          _selectedTypeId = _types.isEmpty ? null : _types.first.id;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('CreateTeamFineScaleSheet types failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _types = const <TeamFineType>[]);
      }
    }
  }

  Future<void> _onTeamChanged(String? teamId) async {
    setState(() {
      _selectedTeamId = teamId;
      _selectedTypeId = null;
      _types = const <TeamFineType>[];
    });
    if (teamId != null && teamId.isNotEmpty) {
      await _loadTypes(teamId);
    }
  }

  TeamFineType? get _selectedType {
    for (final TeamFineType type in _types) {
      if (type.id == _selectedTypeId) {
        return type;
      }
    }
    return null;
  }

  String _teamName(Team team) {
    final String name = team.name?.trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return context.l10n.entityTeam;
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final colors = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: colors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
    );
  }

  Future<TeamFineType?> _promptNewType() {
    final String? teamId = _selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      return Future<TeamFineType?>.value(null);
    }
    return showDialog<TeamFineType>(
      context: context,
      builder: (dialogContext) => _CreateTeamFineTypeDialog(
        onCreate: (String name) {
          return _typeService.createType(teamId: teamId, name: name);
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final User? user = FirebaseAuth.instance.currentUser;
    final TeamFineType? type = _selectedType;
    if (user == null || type == null || _selectedTeamId == null) {
      AppSnackbar.show(
        context,
        context.l10n.createTeamFineScaleError,
        isError: true,
      );
      return;
    }
    final double? amount = parseFineAmount(_amountController.text);
    if (amount == null) {
      AppSnackbar.show(
        context,
        context.l10n.createTeamFineScaleAmountRequired,
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final AppSession session = context.read<AppSession>();
    try {
      final TeamFineScale saved = await _scaleService.createScale(
        teamId: _selectedTeamId!,
        type: type,
        amount: amount,
        createdByUserId: user.uid,
        createdByMemberId: session.selectedPlayerId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(saved);
    } catch (error, stackTrace) {
      debugPrint('CreateTeamFineScaleSheet submit failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      AppSnackbar.show(
        context,
        context.l10n.createTeamFineScaleError,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.createTeamFineScaleTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.actionClose,
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_teams.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.teamFinesNoTeams,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                )
              else if (_showTeamDropdown)
                DropdownButtonFormField<String>(
                  value: _selectedTeamId,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  decoration: _fieldDecoration(
                    context,
                    l10n.createTeamFineScaleTeam,
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return l10n.createTeamFineScaleTeamRequired;
                    }
                    return null;
                  },
                  items: _teams
                      .map(
                        (Team team) => DropdownMenuItem<String>(
                          value: team.keyTeam,
                          child: Text(
                            _teamName(team),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isSubmitting ? null : _onTeamChanged,
                )
              else
                InputDecorator(
                  decoration: _fieldDecoration(
                    context,
                    l10n.createTeamFineScaleTeam,
                  ),
                  child: Text(
                    _teamName(_teams.first),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _types.any(
                        (TeamFineType type) => type.id == _selectedTypeId,
                      )
                          ? _selectedTypeId
                          : null,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      decoration: _fieldDecoration(
                        context,
                        l10n.createTeamFineScaleType,
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return l10n.createTeamFineScaleTypeRequired;
                        }
                        return null;
                      },
                      items: _types
                          .map(
                            (TeamFineType type) => DropdownMenuItem<String>(
                              value: type.id,
                              child: Text(
                                type.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (String? value) {
                              setState(() => _selectedTypeId = value);
                            },
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.createTeamFineScaleNewType,
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final TeamFineType? created =
                                await _promptNewType();
                            if (!mounted || created == null) {
                              return;
                            }
                            setState(() {
                              _types = <TeamFineType>[..._types, created]
                                ..sort(
                                  (TeamFineType a, TeamFineType b) =>
                                      a.name.toLowerCase().compareTo(
                                            b.name.toLowerCase(),
                                          ),
                                );
                              _selectedTypeId = created.id;
                            });
                          },
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _fieldDecoration(
                  context,
                  l10n.createTeamFineScaleAmount,
                ).copyWith(suffixText: '€'),
                validator: (String? value) {
                  final double? amount = parseFineAmount(value);
                  if (amount == null) {
                    return l10n.createTeamFineScaleAmountRequired;
                  }
                  if (amount < 0) {
                    return l10n.createTeamFineScaleAmountRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting || _teams.isEmpty ? null : _submit,
                child: Text(
                  _isSubmitting ? l10n.actionSaving : l10n.actionSave,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateTeamFineTypeDialog extends StatefulWidget {
  const _CreateTeamFineTypeDialog({required this.onCreate});

  final Future<TeamFineType> Function(String name) onCreate;

  @override
  State<_CreateTeamFineTypeDialog> createState() =>
      _CreateTeamFineTypeDialogState();
}

class _CreateTeamFineTypeDialogState extends State<_CreateTeamFineTypeDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      final TeamFineType created = await widget.onCreate(name);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(created);
    } catch (error, stackTrace) {
      debugPrint('CreateTeamFineTypeDialog failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      AppSnackbar.show(
        context,
        context.l10n.createTeamFineScaleError,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      title: Text(l10n.createTeamFineScaleNewTypeTitle),
      content: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.createTeamFineScaleTypeName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
