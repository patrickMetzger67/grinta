import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player_feeling.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/activity_types_service.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/services/strava_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/player_feeling_faces.dart';
import 'package:grinta/widget/sport_metric_pickers.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<PersonalSportActivity?> showCreatePersonalSportActivitySheet(
  BuildContext context, {
  DateTime? initialDate,
  TimeOfDay? initialTime,
  PersonalSportActivity? activityToEdit,
  bool readOnly = false,
  VoidCallback? onSaved,
}) async {
  final bool isEdit = activityToEdit != null;
  final PersonalSportActivity? saved;
  if (kIsWeb) {
    saved = await showDialog<PersonalSportActivity>(
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
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: CreatePersonalSportActivitySheet(
            initialDate: initialDate,
            initialTime: initialTime,
            activityToEdit: activityToEdit,
            readOnly: readOnly,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  } else {
    saved = await showModalBottomSheet<PersonalSportActivity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.card,
      builder: (_) => CreatePersonalSportActivitySheet(
        initialDate: initialDate,
        initialTime: initialTime,
        activityToEdit: activityToEdit,
        readOnly: readOnly,
        onSaved: onSaved,
      ),
    );
  }

  if (saved != null && context.mounted && !readOnly) {
    AppSnackbar.show(
      context,
      isEdit
          ? context.l10n.editPersonalSportSaved
          : context.l10n.createPersonalSportSaved,
      isError: false,
    );
  }
  return saved;
}

class CreatePersonalSportActivitySheet extends StatefulWidget {
  const CreatePersonalSportActivitySheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.activityToEdit,
    this.readOnly = false,
    this.onSaved,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final PersonalSportActivity? activityToEdit;
  final bool readOnly;
  final VoidCallback? onSaved;

  bool get isEditMode => activityToEdit != null;

  @override
  State<CreatePersonalSportActivitySheet> createState() =>
      _CreatePersonalSportActivitySheetState();
}

class _CreatePersonalSportActivitySheetState
    extends State<CreatePersonalSportActivitySheet> {
  final _service = PersonalSportActivityService();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  late TimeOfDay _time;
  bool _manualEntry = true;
  bool _submitting = false;
  bool _loadingTypes = true;
  bool _loadingStrava = false;
  bool _loadingConnectedApps = false;

  List<ActivityTypeDefinition> _types = const [];
  String? _typeId;
  PlayerFeeling? _feeling;
  PersonalSportVisibility _visibility = PersonalSportVisibility.private;

  Duration _duration = Duration.zero;
  SportDistanceValue? _distance;
  SportPaceValue? _pace;

  final List<WearableDeviceType> _connectedSources = [];
  WearableDeviceType? _importSource;
  List<StravaImportableActivity> _stravaActivities = const [];
  StravaImportableActivity? _selectedStrava;

  bool get _readOnly => widget.readOnly;
  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    final existing = widget.activityToEdit;
    if (existing != null) {
      _date = DateUtils.dateOnly(existing.startAt);
      _time = TimeOfDay(
        hour: existing.startAt.hour,
        minute: existing.startAt.minute,
      );
      _manualEntry = existing.entryMode == PersonalSportEntryMode.manual;
      _typeId = existing.typeId;
      _feeling = PlayerFeeling.fromValue(existing.feeling);
      _visibility = existing.visibility;
      _notesController.text = existing.notes ?? '';
      if (existing.durationSeconds != null && existing.durationSeconds! > 0) {
        _duration = Duration(seconds: existing.durationSeconds!);
      }
      if (existing.distanceMeters != null && existing.distanceMeters! > 0) {
        _distance = SportDistanceValue(
          kilometers: existing.distanceMeters! / 1000,
          unit: existing.distanceUnit,
        );
      }
      if (existing.paceSecondsPerKm != null &&
          existing.paceSecondsPerKm! > 0) {
        _pace = SportPaceValue(
          secondsPerKm: existing.paceSecondsPerKm!,
          unit: existing.paceUnit,
        );
      }
    } else {
      final now = DateTime.now();
      _date = DateUtils.dateOnly(widget.initialDate ?? now);
      _time = widget.initialTime ?? TimeOfDay(hour: now.hour, minute: 0);
    }
    _loadTypes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    await ActivityTypesService.instance.ensureInitialized();
    if (!mounted) return;
    final types = ActivityTypesService.instance.types;
    setState(() {
      _types = types;
      if (_typeId == null || _typeId!.isEmpty) {
        _typeId = types.isNotEmpty ? types.first.id : null;
      }
      _loadingTypes = false;
    });
  }

  Future<void> _pickDate() async {
    if (_readOnly) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _date = DateUtils.dateOnly(picked));
    }
  }

  Future<void> _pickTime() async {
    if (_readOnly) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  Future<void> _loadConnectedAppsAndActivities() async {
    final session = context.read<AppSession>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (uid == null || playerId.isEmpty) {
      setState(() {
        _connectedSources.clear();
        _importSource = null;
        _stravaActivities = const [];
        _selectedStrava = null;
      });
      return;
    }

    setState(() {
      _loadingConnectedApps = true;
      _loadingStrava = true;
      _stravaActivities = const [];
      _selectedStrava = null;
    });

    final stravaConfig =
        await StravaSyncService.instance.repository.getConfig(uid, playerId);
    if (!mounted) return;

    final connected = <WearableDeviceType>[];
    if (stravaConfig?.connected == true) {
      connected.add(WearableDeviceType.strava);
    }

    setState(() {
      _connectedSources
        ..clear()
        ..addAll(connected);
      _importSource = connected.isEmpty ? null : connected.first;
      _loadingConnectedApps = false;
    });

    if (_importSource == WearableDeviceType.strava) {
      await _loadStravaActivities();
    } else if (mounted) {
      setState(() => _loadingStrava = false);
    }
  }

  Future<void> _loadStravaActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingStrava = false);
      return;
    }

    setState(() {
      _loadingStrava = true;
      _stravaActivities = const [];
      _selectedStrava = null;
    });

    final list = await StravaSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _stravaActivities = list;
      _loadingStrava = false;
      if (list.isNotEmpty) {
        _selectedStrava = list.first;
        _typeId = list.first.typeId;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || _readOnly) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final session = context.read<AppSession>();
    final player = session.selectedPlayer;
    final playerId = (player == null ? null : effectiveMemberId(player)) ??
        session.selectedPlayerId?.trim() ??
        '';
    if (uid == null || playerId.isEmpty) {
      AppSnackbar.show(context, context.l10n.createPersonalSportAuthRequired);
      return;
    }

    setState(() => _submitting = true);
    try {
      final existing = widget.activityToEdit;
      if (!_isEditMode && !_manualEntry) {
        if (_importSource != WearableDeviceType.strava ||
            _selectedStrava == null) {
          AppSnackbar.show(
            context,
            context.l10n.createPersonalSportImportRequired,
          );
          return;
        }
        final imported = await StravaSyncService.instance.importActivity(
          playerId: playerId,
          externalId: _selectedStrava!.externalId,
          visibility: _visibility.firestoreValue,
          feeling: _feeling?.value,
          notes: _notesController.text.trim(),
          typeId: _typeId,
        );
        if (!mounted) return;
        if (imported == null) {
          AppSnackbar.show(context, context.l10n.createPersonalSportError);
          return;
        }
        widget.onSaved?.call();
        Navigator.of(context).pop(imported);
        return;
      }

      if (_typeId == null || _typeId!.isEmpty) {
        AppSnackbar.show(context, context.l10n.createPersonalSportTypeRequired);
        return;
      }

      final startAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );
      final durationSeconds = _duration.inSeconds;
      final endAt = startAt.add(
        Duration(seconds: durationSeconds > 0 ? durationSeconds : 0),
      );
      final typeLabel = ActivityTypesService.instance
              .byId(_typeId!)
              ?.labelForLocale(Localizations.localeOf(context)) ??
          _typeId!;

      final activity = PersonalSportActivity(
        id: existing?.id,
        memberId: existing?.memberId ?? playerId,
        createdByUserId: existing?.createdByUserId ?? uid,
        startAt: startAt,
        endAt: endAt,
        typeId: _typeId!,
        title: existing?.title?.trim().isNotEmpty == true &&
                existing!.entryMode == PersonalSportEntryMode.import
            ? existing.title
            : typeLabel,
        visibility: _visibility,
        entryMode: existing?.entryMode ?? PersonalSportEntryMode.manual,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        feeling: _feeling?.value,
        durationSeconds: durationSeconds > 0 ? durationSeconds : null,
        distanceMeters: _distance == null
            ? null
            : _distance!.kilometers * 1000,
        paceSecondsPerKm: _pace?.secondsPerKm,
        distanceUnit: _distance?.unit ?? existing?.distanceUnit ?? 'km',
        paceUnit: _pace?.unit ?? existing?.paceUnit ?? '/km',
        externalSource: existing?.externalSource,
        externalId: existing?.externalId,
        seasonId: existing?.seasonId ?? session.selectedSeason?.ref?.id,
        teamIds: existing?.teamIds ?? const <String>[],
        accessMemberIds: existing?.accessMemberIds.isNotEmpty == true
            ? existing!.accessMemberIds
            : [playerId],
      );

      final saved = _isEditMode
          ? await _service.update(activity)
          : await _service.create(activity);
      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop(saved);
    } catch (e, st) {
      debugPrint('save personal sport failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(
        context,
        _isEditMode
            ? context.l10n.editPersonalSportError
            : context.l10n.createPersonalSportError,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final dateLabel = DateFormat.yMMMEd(locale.toString()).format(_date);
    final timeLabel = _time.format(context);

    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: media.viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _readOnly
                    ? l10n.viewPersonalSportTitle
                    : _isEditMode
                        ? l10n.editPersonalSportTitle
                        : l10n.createPersonalSportTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.createPersonalSportDate),
                subtitle: Text(dateLabel),
                trailing: _readOnly
                    ? null
                    : const Icon(Icons.calendar_today_rounded),
                onTap: _readOnly ? null : _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.createPersonalSportTime),
                subtitle: Text(timeLabel),
                trailing:
                    _readOnly ? null : const Icon(Icons.schedule_rounded),
                onTap: _readOnly ? null : _pickTime,
              ),
              if (!_isEditMode)
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.createPersonalSportManualEntry),
                  subtitle: Text(
                    _manualEntry
                        ? l10n.createPersonalSportManualEntryHint
                        : l10n.createPersonalSportImportHint,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  value: _manualEntry,
                  activeColor: colors.primary,
                  onChanged: (value) {
                    setState(() => _manualEntry = value);
                    if (!value) {
                      _loadConnectedAppsAndActivities();
                    }
                  },
                ),
              const SizedBox(height: 8),
              if (_manualEntry || _isEditMode) ...[
                _MetricTile(
                  label: l10n.createPersonalSportDuration,
                  value: _duration.inSeconds > 0
                      ? formatSportDuration(_duration)
                      : l10n.createPersonalSportTapToSet,
                  onTap: _readOnly
                      ? null
                      : () async {
                          final picked = await showSportDurationPicker(
                            context,
                            initial: _duration,
                          );
                          if (picked != null && mounted) {
                            setState(() => _duration = picked);
                          }
                        },
                ),
                _MetricTile(
                  label: l10n.createPersonalSportDistance,
                  value: _distance == null
                      ? l10n.createPersonalSportTapToSet
                      : formatSportDistanceKm(
                          _distance!.kilometers,
                          _distance!.unit,
                        ),
                  onTap: _readOnly
                      ? null
                      : () async {
                          final picked = await showSportDistancePicker(
                            context,
                            initial: _distance,
                          );
                          if (picked != null && mounted) {
                            setState(() => _distance = picked);
                          }
                        },
                ),
                _MetricTile(
                  label: l10n.createPersonalSportPace,
                  value: _pace == null
                      ? l10n.createPersonalSportTapToSet
                      : formatSportPace(_pace!.secondsPerKm, _pace!.unit),
                  onTap: _readOnly
                      ? null
                      : () async {
                          final picked = await showSportPacePicker(
                            context,
                            initial: _pace,
                          );
                          if (picked != null && mounted) {
                            setState(() => _pace = picked);
                          }
                        },
                ),
                const SizedBox(height: 8),
                if (_loadingTypes)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    value: _typeId,
                    decoration: InputDecoration(
                      labelText: l10n.createPersonalSportType,
                    ),
                    items: [
                      for (final type in _types)
                        DropdownMenuItem(
                          value: type.id,
                          child: Text(type.labelForLocale(locale)),
                        ),
                    ],
                    onChanged: _readOnly
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _typeId = value);
                            }
                          },
                  ),
              ] else ...[
                if (_loadingConnectedApps)
                  const Center(child: CircularProgressIndicator())
                else if (_connectedSources.isEmpty)
                  Text(
                    l10n.createPersonalSportNoConnectedApps,
                    style: TextStyle(color: colors.textSecondary),
                  )
                else ...[
                  DropdownButtonFormField<WearableDeviceType>(
                    value: _importSource,
                    decoration: InputDecoration(
                      labelText: l10n.createPersonalSportImportSource,
                    ),
                    items: [
                      for (final source in _connectedSources)
                        DropdownMenuItem(
                          value: source,
                          child: Text(
                            source == WearableDeviceType.strava
                                ? l10n.wearableDeviceStrava
                                : source.name,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _importSource = value);
                      if (value == WearableDeviceType.strava) {
                        _loadStravaActivities();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_loadingStrava)
                    const Center(child: CircularProgressIndicator())
                  else if (_importSource == WearableDeviceType.strava &&
                      _stravaActivities.isEmpty)
                    Text(
                      l10n.createPersonalSportNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource == WearableDeviceType.strava)
                    DropdownButtonFormField<String>(
                      value: _selectedStrava?.externalId,
                      decoration: InputDecoration(
                        labelText: l10n.createPersonalSportStravaActivity,
                      ),
                      items: [
                        for (final activity in _stravaActivities)
                          DropdownMenuItem(
                            value: activity.externalId,
                            child: Text(
                              activity.displayLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        StravaImportableActivity? match;
                        for (final activity in _stravaActivities) {
                          if (activity.externalId == id) {
                            match = activity;
                            break;
                          }
                        }
                        setState(() {
                          _selectedStrava = match;
                          if (match != null) _typeId = match.typeId;
                        });
                      },
                    ),
                ],
              ],
              const SizedBox(height: 16),
              Text(
                l10n.playerFeelingPrompt,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              PlayerFeelingFacesRow(
                selected: _feeling,
                enabled: !_readOnly,
                onChanged: (feeling) => setState(() => _feeling = feeling),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                readOnly: _readOnly,
                decoration: InputDecoration(
                  labelText: l10n.createPersonalSportNotes,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PersonalSportVisibility>(
                value: _visibility,
                decoration: InputDecoration(
                  labelText: l10n.createPersonalSportVisibility,
                ),
                items: [
                  DropdownMenuItem(
                    value: PersonalSportVisibility.private,
                    child: Text(l10n.createPersonalSportVisibilityPrivate),
                  ),
                  DropdownMenuItem(
                    value: PersonalSportVisibility.coach,
                    child: Text(l10n.createPersonalSportVisibilityCoach),
                  ),
                  DropdownMenuItem(
                    value: PersonalSportVisibility.team,
                    child: Text(l10n.createPersonalSportVisibilityTeam),
                  ),
                ],
                onChanged: _readOnly
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _visibility = value);
                        }
                      },
              ),
              if (!_readOnly) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode
                              ? l10n.editPersonalSportSubmit
                              : l10n.createPersonalSportSubmit,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
