import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/player_task.dart';
import 'package:grinta/model/player_task_type.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/internal_reminder_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/player_task_service.dart';
import 'package:grinta/services/player_task_type_service.dart';
import 'package:grinta/services/team_players_service.dart';
import 'package:grinta/util/agenda_calendar_date.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<PlayerTask?> showCreatePlayerTaskSheet(
  BuildContext context, {
  DateTime? initialDate,
  PlayerTask? taskToEdit,
  VoidCallback? onSaved,
}) async {
  final PlayerTask? saved;
  if (kIsWeb) {
    saved = await showDialog<PlayerTask>(
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
          child: CreatePlayerTaskSheet(
            initialDate: initialDate,
            taskToEdit: taskToEdit,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  } else {
    saved = await showModalBottomSheet<PlayerTask>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.card,
      builder: (_) => CreatePlayerTaskSheet(
        initialDate: initialDate,
        taskToEdit: taskToEdit,
        onSaved: onSaved,
      ),
    );
  }

  if (saved != null && context.mounted) {
    AppSnackbar.show(
      context,
      taskToEdit == null
          ? context.l10n.createPlayerTaskSaved
          : context.l10n.editPlayerTaskSaved,
      isError: false,
    );
  }
  return saved;
}

class CreatePlayerTaskSheet extends StatefulWidget {
  const CreatePlayerTaskSheet({
    super.key,
    this.initialDate,
    this.taskToEdit,
    this.onSaved,
  });

  final DateTime? initialDate;
  final PlayerTask? taskToEdit;
  final VoidCallback? onSaved;

  @override
  State<CreatePlayerTaskSheet> createState() => _CreatePlayerTaskSheetState();
}

class _CreatePlayerTaskSheetState extends State<CreatePlayerTaskSheet> {
  final PlayerTaskService _taskService = PlayerTaskService();
  final PlayerTaskTypeService _typeService = PlayerTaskTypeService();
  final TeamPlayersService _playersService = TeamPlayersService();
  final PlayerService _playerService = PlayerService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();

  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSubmitting = false;
  bool _isLoading = true;

  List<Team> _teams = const <Team>[];
  String? _selectedTeamId;
  List<PlayerTaskType> _types = const <PlayerTaskType>[];
  String? _selectedTypeId;
  List<Player> _roster = const <Player>[];
  final Map<String, Player> _assigneesById = <String, Player>{};
  bool _loadingRoster = false;

  bool get _isEditMode => widget.taskToEdit != null;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final PlayerTask? existing = widget.taskToEdit;
    if (existing != null) {
      _noteController.text = existing.title;
      _startDate = DateUtils.dateOnly(existing.startAt);
      _endDate = DateUtils.dateOnly(existing.endAt);
      _selectedTeamId = existing.teamId;
      _selectedTypeId = existing.typeId;
    } else {
      final DateTime initial = DateUtils.dateOnly(widget.initialDate ?? now);
      _startDate = initial;
      _endDate = initial;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final AppSession session = context.read<AppSession>();
    final List<Team> teams =
        List<Team>.from(session.managerTeamsForSelectedSeason)
          ..sort(
            (Team a, Team b) =>
                (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
          );
    _teams = teams;
    if (_selectedTeamId == null && teams.isNotEmpty) {
      _selectedTeamId = session.resolveSelectedManagedTeamId(
            preferredOrder: teams
                .map((Team t) => t.keyTeam ?? '')
                .where((String id) => id.isNotEmpty)
                .toList(),
          ) ??
          teams.first.keyTeam;
    } else if (_selectedTeamId != null &&
        !teams.any((Team t) => t.keyTeam == _selectedTeamId)) {
      _selectedTeamId = teams.isEmpty ? null : teams.first.keyTeam;
    }

    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      _types = await _typeService.ensureDefaultTypes(
        ownerUserId: uid,
        l10n: context.l10n,
      );
      if (_selectedTypeId == null && _types.isNotEmpty) {
        _selectedTypeId = _types.first.id;
      }
    } catch (error, stackTrace) {
      debugPrint('CreatePlayerTaskSheet types failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (widget.taskToEdit != null) {
      await _prefillAssignees(widget.taskToEdit!);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
    if (_selectedTeamId != null) {
      unawaited(_loadRoster(_selectedTeamId!));
    }
  }

  Future<void> _prefillAssignees(PlayerTask existing) async {
    for (final String memberId in existing.assigneeMemberIds) {
      final Player? player = await _playerService.getPlayerById(memberId);
      if (player != null) {
        _assigneesById[memberId] = player;
      }
    }
  }

  Future<void> _loadRoster(String teamId) async {
    setState(() => _loadingRoster = true);
    try {
      final List<Player> players =
          await _playersService.loadPlayers(teamId: teamId);
      if (!mounted) return;
      setState(() {
        _roster = players;
        _loadingRoster = false;
      });
    } catch (error, stackTrace) {
      debugPrint('CreatePlayerTaskSheet roster failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _loadingRoster = false);
    }
  }

  Future<void> _onTeamChanged(String? teamId) async {
    if (teamId == null || teamId == _selectedTeamId) {
      return;
    }
    setState(() {
      _selectedTeamId = teamId;
      _assigneesById.clear();
    });
    await _loadRoster(teamId);
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.createPlayerTaskStartDate,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _startDate = DateUtils.dateOnly(picked);
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      helpText: context.l10n.createPlayerTaskEndDate,
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = DateUtils.dateOnly(picked));
  }

  void _applyThisWeek() {
    final DateTime focus = DateUtils.dateOnly(widget.initialDate ?? _startDate);
    setState(() {
      _startDate = agendaWeekStart(focus);
      _endDate = agendaWeekEnd(focus);
    });
  }

  void _applyToday() {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _startDate = today;
      _endDate = today;
    });
  }

  Future<void> _selectPlayers() async {
    if (_roster.isEmpty) {
      AppSnackbar.show(
        context,
        context.l10n.createPlayerTaskNoPlayers,
        isError: true,
      );
      return;
    }

    final Set<String>? picked = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        final Set<String> draft = _assigneesById.keys.toSet();
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final colors = context.appColors;
            return AlertDialog(
              backgroundColor: colors.card,
              surfaceTintColor: Colors.transparent,
              title: Text(context.l10n.createPlayerTaskSelectPlayers),
              content: SizedBox(
                width: 420,
                height: 420,
                child: ListView.builder(
                  itemCount: _roster.length,
                  itemBuilder: (context, index) {
                    final Player player = _roster[index];
                    final String? memberId = effectiveMemberId(player);
                    if (memberId == null) {
                      return const SizedBox.shrink();
                    }
                    return CheckboxListTile(
                      value: draft.contains(memberId),
                      onChanged: (bool? value) {
                        setLocalState(() {
                          if (value == true) {
                            draft.add(memberId);
                          } else {
                            draft.remove(memberId);
                          }
                        });
                      },
                      title: Text(playerDisplayName(player)),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(context.l10n.actionCancel),
                ),
                TextButton(
                  onPressed: () {
                    setLocalState(() {
                      draft
                        ..clear()
                        ..addAll(
                          _roster
                              .map(effectiveMemberId)
                              .whereType<String>(),
                        );
                    });
                  },
                  child: Text(context.l10n.createPlayerTaskSelectAll),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(draft),
                  child: Text(context.l10n.actionValidate),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _assigneesById
        ..clear()
        ..addEntries(
          _roster
              .where((Player p) {
                final String? id = effectiveMemberId(p);
                return id != null && picked.contains(id);
              })
              .map(
                (Player p) => MapEntry<String, Player>(
                  effectiveMemberId(p)!,
                  p,
                ),
              ),
        );
    });
  }

  Future<PlayerTaskType?> _promptNewType() {
    return showDialog<PlayerTaskType>(
      context: context,
      builder: (dialogContext) => _CreatePlayerTaskTypeDialog(
        onCreate: (String name, int color) async {
          final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          return _typeService.createType(
            ownerUserId: uid,
            name: name,
            color: color,
          );
        },
      ),
    );
  }

  PlayerTaskType? get _selectedType {
    for (final PlayerTaskType type in _types) {
      if (type.id == _selectedTypeId) {
        return type;
      }
    }
    return null;
  }

  Team? get _selectedTeam {
    for (final Team team in _teams) {
      if (team.keyTeam == _selectedTeamId) {
        return team;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_assigneesById.isEmpty) {
      AppSnackbar.show(
        context,
        context.l10n.createPlayerTaskPlayersRequired,
        isError: true,
      );
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      AppSnackbar.show(
        context,
        context.l10n.createPlayerTaskInvalidRange,
        isError: true,
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    final PlayerTaskType? type = _selectedType;
    if (user == null || type == null || _selectedTeamId == null) {
      AppSnackbar.show(
        context,
        context.l10n.createPlayerTaskError,
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final AppSession session = context.read<AppSession>();
    try {
      final PlayerTask saved;
      if (_isEditMode) {
        saved = await _taskService.updateTask(
          l10n: context.l10n,
          existing: widget.taskToEdit!,
          title: _noteController.text,
          type: type,
          startAt: _startDate,
          endAt: _endDate,
          teamId: _selectedTeamId!,
          assignees: _assigneesById.values.toList(),
        );
      } else {
        saved = await _taskService.createTask(
          l10n: context.l10n,
          title: _noteController.text,
          type: type,
          startAt: _startDate,
          endAt: _endDate,
          teamId: _selectedTeamId!,
          assignees: _assigneesById.values.toList(),
          createdByUserId: user.uid,
          createdByMemberId: session.selectedPlayerId,
          seasonId: session.selectedSeason?.ref?.id,
          clubId: _selectedTeam?.clubId,
        );
      }
      if (!mounted) return;
      InternalReminderService.instance.onAgendaChanged();
      widget.onSaved?.call();
      Navigator.of(context).pop(saved);
    } catch (error, stackTrace) {
      debugPrint('CreatePlayerTaskSheet._submit failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      AppSnackbar.show(
        context,
        _isEditMode
            ? context.l10n.editPlayerTaskError
            : context.l10n.createPlayerTaskError,
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final media = MediaQuery.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: kIsWeb ? 16 : 0,
          bottom: media.viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditMode
                            ? l10n.editPlayerTaskTitle
                            : l10n.createPlayerTaskTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
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
                        l10n.createPlayerTaskNoManagedTeams,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      decoration: _fieldDecoration(
                        context,
                        l10n.createPlayerTaskTeam,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.createPlayerTaskTeamRequired;
                        }
                        return null;
                      },
                      items: _teams
                          .map(
                            (Team team) => DropdownMenuItem<String>(
                              value: team.keyTeam,
                              child: Text(
                                team.name ?? '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isEditMode ? null : _onTeamChanged,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _types.any((t) => t.id == _selectedTypeId)
                              ? _selectedTypeId
                              : null,
                          isExpanded: true,
                          dropdownColor: colors.surface,
                          decoration: _fieldDecoration(
                            context,
                            l10n.createPlayerTaskType,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.createPlayerTaskTypeRequired;
                            }
                            return null;
                          },
                          items: _types
                              .map(
                                (PlayerTaskType type) =>
                                    DropdownMenuItem<String>(
                                  value: type.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: type.colorValue,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          type.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (String? value) {
                            setState(() => _selectedTypeId = value);
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.createPlayerTaskNewType,
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                final PlayerTaskType? created =
                                    await _promptNewType();
                                if (!mounted || created == null) {
                                  return;
                                }
                                setState(() {
                                  _types = <PlayerTaskType>[..._types, created]
                                    ..sort(
                                      (PlayerTaskType a, PlayerTaskType b) =>
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: Text(l10n.createPlayerTaskToday),
                        onPressed: _applyToday,
                      ),
                      ActionChip(
                        label: Text(l10n.createPlayerTaskThisWeek),
                        onPressed: _applyThisWeek,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickStartDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            DateFormat.yMMMd(locale).format(_startDate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickEndDate,
                          icon: const Icon(Icons.event_outlined),
                          label: Text(
                            DateFormat.yMMMd(locale).format(_endDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.createPlayerTaskPlayers,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      _assigneesById.isEmpty
                          ? l10n.createPlayerTaskPlayersHint
                          : _assigneesById.values
                              .map(playerDisplayName)
                              .join(', '),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: _loadingRoster
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.group_add_rounded,
                            color: colors.primary,
                          ),
                    onTap: _loadingRoster ? null : _selectPlayers,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colors.border),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _fieldDecoration(
                      context,
                      l10n.createPlayerTaskNote,
                    ).copyWith(
                      hintText: l10n.createPlayerTaskNoteHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSubmitting || _teams.isEmpty ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditMode
                                ? l10n.actionSave
                                : l10n.actionValidate,
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreatePlayerTaskTypeDialog extends StatefulWidget {
  const _CreatePlayerTaskTypeDialog({required this.onCreate});

  final Future<PlayerTaskType> Function(String name, int color) onCreate;

  @override
  State<_CreatePlayerTaskTypeDialog> createState() =>
      _CreatePlayerTaskTypeDialogState();
}

class _CreatePlayerTaskTypeDialogState
    extends State<_CreatePlayerTaskTypeDialog> {
  final TextEditingController _nameController = TextEditingController();
  int _color = kPlayerTaskTypePalette.first;
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
      final PlayerTaskType created = await widget.onCreate(name, _color);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error, stackTrace) {
      debugPrint('CreatePlayerTaskTypeDialog failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.show(
        context,
        context.l10n.createPlayerTaskError,
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
      title: Text(l10n.createPlayerTaskNewTypeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.createPlayerTaskTypeName,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.createPlayerTaskTypeColor,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final int value in kPlayerTaskTypePalette)
                GestureDetector(
                  onTap: () => setState(() => _color = value),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == value
                            ? colors.textPrimary
                            : colors.border,
                        width: _color == value ? 2.5 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
