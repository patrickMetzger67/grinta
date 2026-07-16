import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/training.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/services/deviceOwnerService.dart' as device_owner_svc;
import 'package:grinta/services/ownerService.dart';
import 'package:grinta/services/trainingService.dart';
import 'package:grinta/navigation/app_navigator.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/training_creation_helper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Common training durations (minutes).
const List<int> kTrainingDurationOptions = <int>[45, 60, 75, 90, 105, 120, 150];

/// Shows the training creation form (bottom sheet on mobile, dialog on web).
Future<bool?> showCreateTrainingSheet(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialTime,
  Training? trainingToEdit,
  VoidCallback? onSaved,
}) {
  if (kIsWeb) {
    return showDialog<bool>(
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: CreateTrainingSheet(
            initialDate: initialDate,
            initialTime: initialTime,
            trainingToEdit: trainingToEdit,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useRootNavigator: true,
    backgroundColor: context.appColors.card,
    builder: (_) => CreateTrainingSheet(
      initialDate: initialDate,
      initialTime: initialTime,
      trainingToEdit: trainingToEdit,
      onSaved: onSaved,
    ),
  );
}

class CreateTrainingSheet extends StatefulWidget {
  const CreateTrainingSheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.trainingToEdit,
    this.onSaved,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final Training? trainingToEdit;
  final VoidCallback? onSaved;

  bool get isEditMode => trainingToEdit != null;

  @override
  State<CreateTrainingSheet> createState() => _CreateTrainingSheetState();
}

class _CreateTrainingSheetState extends State<CreateTrainingSheet> {
  final TrainingService _trainingService = TrainingService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Team> _teams = const <Team>[];
  String? _selectedTeamId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _durationMinutes = 90;
  bool _isRecurrent = false;
  late Set<int> _selectedWeekdays;
  late DateTime _recurrentFromDate;
  late DateTime _recurrentToDate;
  bool _withTracker = false;
  String? _selectedOwnerId;
  List<TeamOwnerRef> _ownerOptions = const <TeamOwnerRef>[];
  bool _ownersLoading = false;
  bool _isSubmitting = false;
  bool _isPrefilling = false;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    if (_isEditMode) {
      _initFromExistingTraining(widget.trainingToEdit!);
    } else {
      _selectedDate = DateUtils.dateOnly(widget.initialDate ?? now);
      _selectedTime =
          widget.initialTime ?? TimeOfDay(hour: now.hour, minute: 0);
      _selectedWeekdays = <int>{_selectedDate.weekday};
      _resetRecurrentRange();
      _initTeams();
    }
  }

  Future<void> _initFromExistingTraining(Training training) async {
    _isPrefilling = true;

    final DateTime now = DateTime.now();
    final DateTime? parsedDate = training.dateTime?.toDate() ??
        parseTrainingDateTg(training.dateTg);
    final TimeOfDay? parsedTime =
        parseTrainingTime(training.startTime) ??
            (training.dateTime != null
                ? TimeOfDay.fromDateTime(training.dateTime!.toDate())
                : null);

    _selectedDate = DateUtils.dateOnly(parsedDate ?? now);
    _selectedTime = parsedTime ?? TimeOfDay(hour: now.hour, minute: 0);
    _durationMinutes = training.duration ?? 90;
    _withTracker = training.withTracker;
    _selectedOwnerId =
        training.ownerId?.trim().isNotEmpty == true ? training.ownerId : null;

    _isRecurrent = isTrainingRecurrent(training) || training.isReccurent == true;
    final Set<int> existingWeekdays = recurrentWeekdaysFromTraining(training);
    _selectedWeekdays = existingWeekdays.isNotEmpty
        ? existingWeekdays
        : <int>{_selectedDate.weekday};
    _recurrentFromDate = training.reccurentStart != null
        ? DateUtils.dateOnly(training.reccurentStart!.toDate())
        : _selectedDate;
    _recurrentToDate = training.reccurentEnd != null
        ? DateUtils.dateOnly(training.reccurentEnd!.toDate())
        : _addOneMonth(_selectedDate);
    if (_recurrentToDate.isBefore(_recurrentFromDate)) {
      _recurrentToDate = _addOneMonth(_recurrentFromDate);
    }

    _initTeams();
    _selectedTeamId = managedTrainingTeamId(training) ?? _selectedTeamId;
    await _refreshOwnerOptions();

    if (!mounted) return;
    setState(() => _isPrefilling = false);
  }

  static DateTime _addOneMonth(DateTime date) {
    final int month = date.month + 1;
    if (month > 12) {
      return DateTime(date.year + 1, month - 12, date.day);
    }
    return DateTime(date.year, month, date.day);
  }

  void _resetRecurrentRange() {
    _recurrentFromDate = _selectedDate;
    _recurrentToDate = _addOneMonth(_selectedDate);
  }

  bool get _recurrentRangeValid =>
      !_isRecurrent || !_recurrentToDate.isBefore(_recurrentFromDate);

  void _initTeams() {
    final AppSession session = context.read<AppSession>();
    final List<Team> teams = List<Team>.from(session.managerTeamsForSelectedSeason)
      ..sort(
        (Team a, Team b) =>
            (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()),
      );

    _teams = teams;
    if (teams.length == 1) {
      _selectedTeamId = teams.first.keyTeam;
    } else if (_selectedTeamId != null &&
        !teams.any((Team t) => t.keyTeam == _selectedTeamId)) {
      _selectedTeamId = null;
    }
  }

  Team? get _selectedTeam {
    if (_selectedTeamId == null) return null;
    for (final Team team in _teams) {
      if (team.keyTeam == _selectedTeamId) return team;
    }
    return null;
  }

  Future<void> _refreshOwnerOptions() async {
    if (!_withTracker) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = const <TeamOwnerRef>[];
        _ownersLoading = false;
      });
      return;
    }

    final Team? team = _selectedTeam;
    final List<TeamOwnerRef> rawRefs = team?.ownerRefs ?? const <TeamOwnerRef>[];
    if (team == null || rawRefs.isEmpty) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = const <TeamOwnerRef>[];
        _ownersLoading = false;
        _selectedOwnerId = null;
      });
      return;
    }

    setState(() => _ownersLoading = true);

    try {
      final List<TeamOwnerRef> refs =
          await OwnerService().enrichTeamOwnerRefs(rawRefs);
      if (!mounted) return;
      setState(() {
        _ownerOptions = refs;
        _ownersLoading = false;
        if (refs.length == 1) {
          _selectedOwnerId = refs.first.id;
        } else if (_selectedOwnerId != null &&
            !refs.any((TeamOwnerRef ref) => ref.id == _selectedOwnerId)) {
          _selectedOwnerId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ownerOptions = rawRefs;
        _ownersLoading = false;
      });
    }
  }

  String _weekdayLabel(BuildContext context, int weekday) {
    final DateTime monday = DateTime(2024, 1, 1);
    final DateTime date = monday.add(Duration(days: weekday - 1));
    return DateFormat.E(Localizations.localeOf(context).toString()).format(date);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.createTrainingDate,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateUtils.dateOnly(picked);
      // Keep the single selected weekday in sync with the session date so opening
      // the sheet on Wednesday then picking Thursday does not leave Wednesday
      // selected when recurrence is enabled later.
      if (!_isRecurrent || _selectedWeekdays.length <= 1) {
        _selectedWeekdays = <int>{_selectedDate.weekday};
      }
    });
  }

  Future<void> _pickRecurrentFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurrentFromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: context.l10n.createTrainingRecurrentFrom,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _recurrentFromDate = DateUtils.dateOnly(picked);
      if (_recurrentToDate.isBefore(_recurrentFromDate)) {
        _recurrentToDate = _addOneMonth(_recurrentFromDate);
      }
    });
  }

  Future<void> _pickRecurrentToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurrentToDate.isBefore(_recurrentFromDate)
          ? _recurrentFromDate
          : _recurrentToDate,
      firstDate: _recurrentFromDate,
      lastDate: DateTime(2100),
      helpText: context.l10n.createTrainingRecurrentTo,
    );
    if (picked == null || !mounted) return;
    setState(() => _recurrentToDate = DateUtils.dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: context.l10n.createTrainingTime,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  void _onTeamChanged(String? teamId) {
    setState(() {
      _selectedTeamId = teamId;
      _selectedOwnerId = null;
    });
    _refreshOwnerOptions();
  }

  void _toggleWeekday(int weekday, bool selected) {
    setState(() {
      if (selected) {
        _selectedWeekdays.add(weekday);
      } else {
        _selectedWeekdays.remove(weekday);
      }
    });
  }

  Future<bool?> _confirmRecurrentCreation() {
    final l10n = context.l10n;
    final colors = context.appColors;

    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          l10n.createTrainingRecurrentConfirmTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          l10n.createTrainingRecurrentConfirmMessage,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionNo),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionYes),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_teams.isEmpty) {
      AppSnackbar.show(context, context.l10n.createTrainingNoManagedTeams);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_isRecurrent && _selectedWeekdays.isEmpty) {
      AppSnackbar.show(context, context.l10n.createTrainingRecurrentDaysRequired);
      return;
    }

    if (_isRecurrent && !_recurrentRangeValid) {
      AppSnackbar.show(context, context.l10n.createTrainingRecurrentInvalidRange);
      return;
    }

    if (_withTracker && (_selectedOwnerId == null || _selectedOwnerId!.isEmpty)) {
      AppSnackbar.show(context, context.l10n.createTrainingOwnerRequired);
      return;
    }

    if (_isRecurrent && !_isEditMode) {
      final bool? confirmed = await _confirmRecurrentCreation();
      if (!mounted || confirmed != true) return;
    }

    final AppSession session = context.read<AppSession>();
    final Season? season = session.selectedSeason;
    final Team? team = _selectedTeam;

    if (season == null || team == null || team.keyTeam == null) {
      AppSnackbar.show(context, context.l10n.createTrainingError);
      return;
    }

    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
    final VoidCallback? onSaved = widget.onSaved;
    final Training? existingTraining = widget.trainingToEdit;
    final String successMessage = _isEditMode
        ? context.l10n.editTrainingSaved
        : context.l10n.createTrainingSaved(1);
    final String errorMessage =
        _isEditMode ? context.l10n.editTrainingError : context.l10n.createTrainingError;

    setState(() => _isSubmitting = true);

    var didPop = false;
    try {
      if (_isEditMode && existingTraining != null) {
        await saveTrainingEdit(
          service: _trainingService,
          existing: existingTraining,
          date: _selectedDate,
          time: _selectedTime,
          durationMinutes: _durationMinutes,
          team: team,
          season: season,
          withTracker: _withTracker,
          ownerId: _selectedOwnerId,
          isRecurrent: _isRecurrent,
          recurrentWeekdays: _selectedWeekdays,
          recurrentFrom: _isRecurrent ? _recurrentFromDate : null,
          recurrentTo: _isRecurrent ? _recurrentToDate : null,
        );
      } else {
        Map<String, DeviceOwner>? ownerDevicesByDocId;
        if (_withTracker) {
          final String ownerId = _selectedOwnerId!.trim();
          final devices =
              await device_owner_svc.DeviceOwnerService().listByOwnerId(ownerId);
          ownerDevicesByDocId = {
            for (final DeviceOwner device in devices) device.id: device,
          };
        }

        final playerTraining = playerTrainingFromGrintaPlayers(
          team.grintaPlayers ?? const [],
          managerIds: managerIdsFromTeam(team),
          withTracker: _withTracker,
          ownerDevicesByDocId: ownerDevicesByDocId,
        );

        final trainings = buildTrainingsForCreation(
          startDate: _selectedDate,
          time: _selectedTime,
          durationMinutes: _durationMinutes,
          team: team,
          season: season,
          playerTraining: playerTraining,
          isRecurrent: _isRecurrent,
          recurrentWeekdays: _selectedWeekdays,
          withTracker: _withTracker,
          ownerId: _selectedOwnerId,
          recurrentFrom: _isRecurrent ? _recurrentFromDate : null,
          recurrentTo: _isRecurrent ? _recurrentToDate : null,
        );

        if (trainings.isEmpty) {
          if (mounted) {
            AppSnackbar.show(context, context.l10n.createTrainingRecurrentDaysRequired);
          }
          return;
        }

        await _trainingService.createTrainings(trainings);
      }

      if (!mounted) return;

      navigator.pop(true);
      didPop = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        onSaved?.call();
        final BuildContext? rootContext = appNavigatorKey.currentContext;
        if (rootContext != null && rootContext.mounted) {
          AppSnackbar.show(rootContext, successMessage, isError: false);
        }
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(context, errorMessage);
      }
    } finally {
      if (mounted && !didPop) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _closeWithoutSaving() {
    Navigator.of(context, rootNavigator: true).pop(false);
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
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateLabel = DateFormat.yMMMd(locale).format(_selectedDate);
    final timeLabel = _selectedTime.format(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isEditMode ? l10n.editTrainingTitle : l10n.createTrainingTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isPrefilling)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                if (_teams.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.createTrainingNoManagedTeams,
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
                    decoration: _fieldDecoration(context, l10n.createTrainingTeam),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.createTrainingTeamRequired;
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createTrainingDate,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    dateLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today_rounded, color: colors.primary),
                  onTap: _pickDate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createTrainingTime,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  subtitle: Text(
                    timeLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(Icons.schedule_rounded, color: colors.primary),
                  onTap: _pickTime,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: colors.border),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _durationMinutes,
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  decoration: _fieldDecoration(context, l10n.createTrainingDuration),
                  items: kTrainingDurationOptions
                      .map(
                        (int minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text(l10n.createTrainingDurationMinutes(minutes)),
                        ),
                      )
                      .toList(),
                  onChanged: (int? value) {
                    if (value == null) return;
                    setState(() => _durationMinutes = value);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createTrainingRecurrent,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _isRecurrent,
                  activeThumbColor: colors.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _isRecurrent = value;
                      if (value) {
                        if (_isEditMode) {
                          if (_recurrentToDate.isBefore(_recurrentFromDate)) {
                            _resetRecurrentRange();
                          }
                        } else {
                          _resetRecurrentRange();
                          // Create mode: default weekdays to the session date's
                          // weekday (replace stale init-from-today selection).
                          _selectedWeekdays = <int>{_selectedDate.weekday};
                        }
                        if (_selectedWeekdays.isEmpty) {
                          _selectedWeekdays = <int>{_selectedDate.weekday};
                        }
                      }
                    });
                  },
                ),
                if (_isRecurrent) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.createTrainingRecurrentFrom,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd(locale).format(_recurrentFromDate),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.calendar_today_rounded,
                            color: colors.primary,
                          ),
                          onTap: _pickRecurrentFromDate,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n.createTrainingRecurrentTo,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd(locale).format(_recurrentToDate),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.calendar_today_rounded,
                            color: colors.primary,
                          ),
                          onTap: _pickRecurrentToDate,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: colors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_recurrentRangeValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.createTrainingRecurrentInvalidRange,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.danger,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createTrainingRecurrentDays,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(7, (int index) {
                      final int weekday = index + 1;
                      final bool selected = _selectedWeekdays.contains(weekday);
                      return FilterChip(
                        label: Text(_weekdayLabel(context, weekday)),
                        selected: selected,
                        onSelected: (bool value) => _toggleWeekday(weekday, value),
                        selectedColor: colors.primary.withValues(alpha: 0.18),
                        checkmarkColor: colors.primary,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.createTrainingWithTracker,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  value: _withTracker,
                  activeThumbColor: colors.primary,
                  onChanged: (bool value) {
                    setState(() {
                      _withTracker = value;
                      if (!value) {
                        _selectedOwnerId = null;
                      }
                    });
                    _refreshOwnerOptions();
                  },
                ),
                if (_withTracker) ...[
                  const SizedBox(height: 4),
                  if (_ownersLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_ownerOptions.isEmpty)
                    Text(
                      l10n.createTrainingNoOwners,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.warning,
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _ownerOptions.any((ref) => ref.id == _selectedOwnerId)
                          ? _selectedOwnerId
                          : null,
                      isExpanded: true,
                      dropdownColor: colors.surface,
                      decoration:
                          _fieldDecoration(context, l10n.createTrainingSelectOwner),
                      items: _ownerOptions
                          .map(
                            (TeamOwnerRef owner) => DropdownMenuItem<String>(
                              value: owner.id,
                              child: Text(owner.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        setState(() => _selectedOwnerId = value);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _closeWithoutSaving,
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSubmitting ||
                                _teams.isEmpty ||
                                !_recurrentRangeValid
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? l10n.editTrainingSubmit
                                    : l10n.createTrainingSubmit,
                              ),
                      ),
                    ),
                  ],
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
