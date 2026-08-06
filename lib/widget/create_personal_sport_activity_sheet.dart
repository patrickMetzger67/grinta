import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/personal_sport_activity.dart';
import 'package:grinta/model/player_feeling.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/activity_types_service.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
import 'package:grinta/services/personal_sport_activity_service.dart';
import 'package:grinta/model/apple_health_importable_activity.dart';
import 'package:grinta/model/google_health_importable_activity.dart';
import 'package:grinta/services/apple_health_sync_service.dart';
import 'package:grinta/services/google_health_sync_service.dart';
import 'package:grinta/services/polar_sync_service.dart';
import 'package:grinta/services/strava_sync_service.dart';
import 'package:grinta/services/whoop_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/player_feeling_faces.dart';
import 'package:grinta/widget/polar_analysis/polar_hr_zones_chart.dart';
import 'package:grinta/widget/sport_metric_pickers.dart';
import 'package:grinta/widget/whoop_analysis/whoop_hr_zones_card.dart';
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
  final _gpsSyncService = PersonalGpsSyncService();
  final _notesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late DateTime _date;
  TimeOfDay? _time;
  bool _manualEntry = true;
  bool _submitting = false;
  bool _loadingTypes = true;
  bool _loadingImportActivities = false;
  bool _loadingConnectedApps = false;
  bool _loadingGpsOwner = false;

  PersonalGpsOwnerAvailability? _gpsAvailability;
  PersonalGpsDeviceOption? _selectedGpsDevice;

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
  List<PolarImportableActivity> _polarActivities = const [];
  PolarImportableActivity? _selectedPolar;
  String? _polarListError;
  String? _polarEmptyReason;
  List<WhoopImportableActivity> _whoopActivities = const [];
  WhoopImportableActivity? _selectedWhoop;
  String? _whoopListError;
  List<AppleHealthImportableActivity> _appleActivities = const [];
  AppleHealthImportableActivity? _selectedApple;
  String? _appleListError;
  List<GoogleHealthImportableActivity> _googleActivities = const [];
  GoogleHealthImportableActivity? _selectedGoogle;
  String? _googleListError;

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
      // No default time: user must pick a start time explicitly.
      _date = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
      _time = widget.initialTime;
    }
    _loadTypes();
    if (!_isEditMode && !_readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadGpsOwnerAvailability();
      });
    }
  }

  Future<void> _loadGpsOwnerAvailability() async {
    final session = context.read<AppSession>();
    final playerEmail = session.selectedPlayer?.email?.trim() ?? '';
    final authEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final emails = <String>[
      if (playerEmail.isNotEmpty) playerEmail,
      if (authEmail.isNotEmpty &&
          authEmail.toLowerCase() != playerEmail.toLowerCase())
        authEmail,
    ];
    if (emails.isEmpty) return;

    setState(() => _loadingGpsOwner = true);
    try {
      PersonalGpsOwnerAvailability? availability;
      for (final email in emails) {
        availability = await _gpsSyncService.resolveForEmail(email);
        if (availability != null) break;
      }
      if (!mounted) return;
      setState(() {
        _gpsAvailability = availability;
        _selectedGpsDevice = availability?.devices.isNotEmpty == true
            ? availability!.devices.first
            : null;
        _loadingGpsOwner = false;
      });
    } catch (e, st) {
      debugPrint('load personal GPS owner failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _gpsAvailability = null;
        _selectedGpsDevice = null;
        _loadingGpsOwner = false;
      });
    }
  }

  bool get _canUseMyGps =>
      !_isEditMode &&
      !_readOnly &&
      _gpsAvailability != null &&
      _gpsAvailability!.devices.isNotEmpty;

  bool get _importingFromGps =>
      !_manualEntry &&
      _importSource == WearableDeviceType.gpsInsidersIntense;

  void _closeWithoutSaving() {
    if (_submitting) return;
    Navigator.of(context).pop();
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
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() => _time = picked);
    }
  }

  bool _ensureStartTimeSelected() {
    if (_time != null) return true;
    AppSnackbar.show(context, context.l10n.createPersonalSportTimeRequired);
    return false;
  }

  void _clearImportSelections() {
    _stravaActivities = const [];
    _selectedStrava = null;
    _polarActivities = const [];
    _selectedPolar = null;
    _polarListError = null;
    _polarEmptyReason = null;
    _whoopActivities = const [];
    _selectedWhoop = null;
    _whoopListError = null;
    _appleActivities = const [];
    _selectedApple = null;
    _appleListError = null;
    _googleActivities = const [];
    _selectedGoogle = null;
    _googleListError = null;
  }

  Future<void> _loadConnectedAppsAndActivities() async {
    final session = context.read<AppSession>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (uid == null || playerId.isEmpty) {
      setState(() {
        _connectedSources.clear();
        _importSource = null;
        _clearImportSelections();
      });
      return;
    }

    setState(() {
      _loadingConnectedApps = true;
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final stravaFuture =
        StravaSyncService.instance.repository.getConfig(uid, playerId);
    final polarFuture =
        PolarSyncService.instance.repository.getConfig(uid, playerId);
    final whoopFuture =
        WhoopSyncService.instance.repository.getConfig(uid, playerId);
    final appleFuture =
        AppleHealthSyncService.instance.repository.getConfig(uid, playerId);
    final googleFuture =
        GoogleHealthSyncService.instance.repository.getConfig(uid, playerId);
    final stravaConfig = await stravaFuture;
    final polarConfig = await polarFuture;
    final whoopConfig = await whoopFuture;
    final appleConfig = await appleFuture;
    final googleConfig = await googleFuture;
    if (!mounted) return;

    // Ensure personal Intense GPS is resolved before building the source list.
    if (_gpsAvailability == null) {
      await _loadGpsOwnerAvailability();
      if (!mounted) return;
    }

    final connected = <WearableDeviceType>[];
    if (stravaConfig?.connected == true) {
      connected.add(WearableDeviceType.strava);
    }
    if (polarConfig?.connected == true) {
      connected.add(WearableDeviceType.polar);
    }
    if (whoopConfig?.connected == true) {
      connected.add(WearableDeviceType.whoop);
    }
    if (appleConfig?.connected == true) {
      connected.add(WearableDeviceType.appleHealth);
    }
    if (googleConfig?.connected == true) {
      connected.add(WearableDeviceType.googleHealthConnect);
    }
    if (_canUseMyGps) {
      connected.add(WearableDeviceType.gpsInsidersIntense);
    }

    setState(() {
      _connectedSources
        ..clear()
        ..addAll(connected);
      _importSource = connected.isEmpty ? null : connected.first;
      _loadingConnectedApps = false;
    });

    if (_importSource != null) {
      await _loadImportActivitiesForSource(_importSource!);
    } else if (mounted) {
      setState(() => _loadingImportActivities = false);
    }
  }

  Future<void> _loadImportActivitiesForSource(WearableDeviceType source) async {
    if (source == WearableDeviceType.strava) {
      await _loadStravaActivities();
      return;
    }
    if (source == WearableDeviceType.polar) {
      await _loadPolarActivities();
      return;
    }
    if (source == WearableDeviceType.whoop) {
      await _loadWhoopActivities();
      return;
    }
    if (source == WearableDeviceType.appleHealth) {
      await _loadAppleHealthActivities();
      return;
    }
    if (source == WearableDeviceType.googleHealthConnect) {
      await _loadGoogleHealthActivities();
      return;
    }
    if (source == WearableDeviceType.gpsInsidersIntense) {
      // Window-based sync (start → now), no discrete activity list.
      if (mounted) {
        setState(() => _loadingImportActivities = false);
      }
      return;
    }
    if (mounted) {
      setState(() => _loadingImportActivities = false);
    }
  }

  Future<void> _loadStravaActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() {
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final list = await StravaSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _stravaActivities = list;
      _loadingImportActivities = false;
      if (list.isNotEmpty) {
        _selectedStrava = list.first;
        _typeId = list.first.typeId;
      }
    });
  }

  Future<void> _loadPolarActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() {
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final result = await PolarSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _polarActivities = result.activities;
      _polarEmptyReason = result.emptyReason;
      _loadingImportActivities = false;
      if (result.hasError) {
        _polarListError = result.errorCode == 'not-found' ||
                result.errorCode == 'unimplemented'
            ? context.l10n.createPersonalSportPolarDeployRequired
            : (result.errorMessage?.trim().isNotEmpty == true
                ? result.errorMessage
                : context.l10n.createPersonalSportPolarLoadError);
      } else if (result.activities.isNotEmpty) {
        _selectedPolar = result.activities.first;
        _typeId = result.activities.first.typeId;
      }
    });
    if (result.hasError && mounted) {
      AppSnackbar.show(
        context,
        _polarListError ?? context.l10n.createPersonalSportPolarLoadError,
      );
    }
  }

  Future<void> _loadWhoopActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() {
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final result = await WhoopSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _whoopActivities = result.activities;
      _loadingImportActivities = false;
      if (result.hasError) {
        _whoopListError = result.errorCode == 'not-found' ||
                result.errorCode == 'unimplemented'
            ? context.l10n.createPersonalSportWhoopDeployRequired
            : (result.errorMessage?.trim().isNotEmpty == true
                ? result.errorMessage
                : context.l10n.createPersonalSportWhoopLoadError);
      } else if (result.activities.isNotEmpty) {
        _selectedWhoop = result.activities.first;
        _typeId = result.activities.first.typeId;
      }
    });
    if (result.hasError && mounted) {
      AppSnackbar.show(
        context,
        _whoopListError ?? context.l10n.createPersonalSportWhoopLoadError,
      );
    }
  }

  Future<void> _loadAppleHealthActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() {
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final result =
        await AppleHealthSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _appleActivities = result.activities;
      _loadingImportActivities = false;
      if (result.hasError) {
        _appleListError = result.errorCode == 'ios-only'
            ? context.l10n.createPersonalSportAppleIosOnly
            : (result.errorMessage?.trim().isNotEmpty == true
                ? result.errorMessage
                : context.l10n.createPersonalSportAppleLoadError);
      } else if (result.activities.isNotEmpty) {
        _selectedApple = result.activities.first;
        _typeId = result.activities.first.typeId;
      }
    });
    if (result.hasError && mounted) {
      AppSnackbar.show(
        context,
        _appleListError ?? context.l10n.createPersonalSportAppleLoadError,
      );
    }
  }

  Future<void> _loadGoogleHealthActivities() async {
    final session = context.read<AppSession>();
    final playerId = session.selectedPlayerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() {
      _loadingImportActivities = true;
      _clearImportSelections();
    });

    final result =
        await GoogleHealthSyncService.instance.listImportableActivities(
      playerId: playerId,
    );
    if (!mounted) return;
    setState(() {
      _googleActivities = result.activities;
      _loadingImportActivities = false;
      if (result.hasError) {
        _googleListError = result.errorCode == 'android-only'
            ? context.l10n.createPersonalSportGoogleAndroidOnly
            : (result.errorMessage?.trim().isNotEmpty == true
                ? result.errorMessage
                : context.l10n.createPersonalSportGoogleLoadError);
      } else if (result.activities.isNotEmpty) {
        _selectedGoogle = result.activities.first;
        _typeId = result.activities.first.typeId;
      }
    });
    if (result.hasError && mounted) {
      AppSnackbar.show(
        context,
        _googleListError ?? context.l10n.createPersonalSportGoogleLoadError,
      );
    }
  }

  String _labelForImportSource(WearableDeviceType source) {
    final l10n = context.l10n;
    switch (source) {
      case WearableDeviceType.strava:
        return l10n.wearableDeviceStrava;
      case WearableDeviceType.polar:
        return l10n.wearableDevicePolar;
      case WearableDeviceType.whoop:
        return l10n.wearableDeviceWhoop;
      case WearableDeviceType.appleHealth:
        return l10n.wearableDeviceAppleHealth;
      case WearableDeviceType.googleHealthConnect:
        return l10n.wearableDeviceGoogleHealthConnect;
      case WearableDeviceType.gpsInsidersIntense:
        return l10n.wearableDeviceGpsInsidersIntense;
      case WearableDeviceType.fitbit:
        return source.label(l10n);
    }
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

    final needsStartTime = _manualEntry ||
        _isEditMode ||
        _importSource == WearableDeviceType.gpsInsidersIntense;
    if (needsStartTime && !_ensureStartTimeSelected()) return;

    setState(() => _submitting = true);
    try {
      final existing = widget.activityToEdit;
      if (!_isEditMode && !_manualEntry) {
        if (_importSource == WearableDeviceType.gpsInsidersIntense) {
          await _submitFromGps(
            uid: uid,
            playerId: playerId,
            session: session,
          );
          return;
        }
        PersonalSportActivity? imported;
        if (_importSource == WearableDeviceType.strava &&
            _selectedStrava != null) {
          imported = await StravaSyncService.instance.importActivity(
            playerId: playerId,
            externalId: _selectedStrava!.externalId,
            visibility: _visibility.firestoreValue,
            feeling: _feeling?.value,
            notes: _notesController.text.trim(),
            typeId: _typeId,
          );
        } else if (_importSource == WearableDeviceType.polar &&
            _selectedPolar != null) {
          imported = await PolarSyncService.instance.importActivity(
            playerId: playerId,
            externalId: _selectedPolar!.externalId,
            visibility: _visibility.firestoreValue,
            feeling: _feeling?.value,
            notes: _notesController.text.trim(),
            typeId: _typeId,
          );
        } else if (_importSource == WearableDeviceType.whoop &&
            _selectedWhoop != null) {
          imported = await WhoopSyncService.instance.importActivity(
            playerId: playerId,
            externalId: _selectedWhoop!.externalId,
            visibility: _visibility.firestoreValue,
            feeling: _feeling?.value,
            notes: _notesController.text.trim(),
            typeId: _typeId,
          );
        } else if (_importSource == WearableDeviceType.appleHealth &&
            _selectedApple != null) {
          imported = await AppleHealthSyncService.instance.importActivity(
            playerId: playerId,
            workout: _selectedApple!,
            visibility: _visibility.firestoreValue,
            feeling: _feeling?.value,
            notes: _notesController.text.trim(),
            typeId: _typeId,
          );
        } else if (_importSource == WearableDeviceType.googleHealthConnect &&
            _selectedGoogle != null) {
          imported = await GoogleHealthSyncService.instance.importActivity(
            playerId: playerId,
            workout: _selectedGoogle!,
            visibility: _visibility.firestoreValue,
            feeling: _feeling?.value,
            notes: _notesController.text.trim(),
            typeId: _typeId,
          );
        } else {
          AppSnackbar.show(
            context,
            context.l10n.createPersonalSportImportRequired,
          );
          return;
        }
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

      final time = _time;
      if (time == null) {
        AppSnackbar.show(context, context.l10n.createPersonalSportTimeRequired);
        return;
      }

      final startAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        time.hour,
        time.minute,
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
        caloriesKcal: existing?.caloriesKcal,
        averageHeartRateBpm: existing?.averageHeartRateBpm,
        maxHeartRateBpm: existing?.maxHeartRateBpm,
        minHeartRateBpm: existing?.minHeartRateBpm,
        hrSamplesCount: existing?.hrSamplesCount ?? 0,
        strain: existing?.strain,
        altitudeGainMeters: existing?.altitudeGainMeters,
        hrZoneSeconds: existing?.hrZoneSeconds ?? const <String, int>{},
        hrMaxUsedBpm: existing?.hrMaxUsedBpm,
        hrTimeline: existing?.hrTimeline ?? const [],
        hrTimelineBucketMinutes: existing?.hrTimelineBucketMinutes ?? 5,
        distanceUnit: _distance?.unit ?? existing?.distanceUnit ?? 'km',
        paceUnit: _pace?.unit ?? existing?.paceUnit ?? '/km',
        externalSource: existing?.externalSource,
        externalId: existing?.externalId,
        externalDevice: existing?.externalDevice,
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

  Future<void> _submitFromGps({
    required String uid,
    required String playerId,
    required AppSession session,
  }) async {
    final device = _selectedGpsDevice;
    if (device == null) {
      AppSnackbar.show(context, context.l10n.createPersonalSportGpsDeviceRequired);
      return;
    }
    if (_typeId == null || _typeId!.isEmpty) {
      AppSnackbar.show(context, context.l10n.createPersonalSportTypeRequired);
      return;
    }

    final time = _time;
    if (time == null) {
      AppSnackbar.show(context, context.l10n.createPersonalSportTimeRequired);
      return;
    }

    final startAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      time.hour,
      time.minute,
    );
    final stopAt = DateTime.now();
    if (!stopAt.isAfter(startAt)) {
      AppSnackbar.show(context, context.l10n.createPersonalSportGpsStartInFuture);
      return;
    }

    try {
      final analysis = await _gpsSyncService.syncWindow(
        device: device,
        playerId: playerId,
        startAt: startAt,
        stopAt: stopAt,
      );
      if (!mounted) return;
      if (analysis == null) {
        await _promptGpsNoDataManualEntry();
        return;
      }

      final metrics = PersonalGpsSyncService.metricsFromAnalysis(analysis);
      if (metrics.durationSeconds <= 0 && metrics.distanceMeters <= 0) {
        await _promptGpsNoDataManualEntry();
        return;
      }

      final endAt = startAt.add(Duration(seconds: metrics.durationSeconds));
      final typeLabel = ActivityTypesService.instance
              .byId(_typeId!)
              ?.labelForLocale(Localizations.localeOf(context)) ??
          _typeId!;

      final activity = PersonalSportActivity(
        memberId: playerId,
        createdByUserId: uid,
        startAt: startAt,
        endAt: endAt,
        typeId: _typeId!,
        title: typeLabel,
        visibility: _visibility,
        entryMode: PersonalSportEntryMode.import,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        feeling: _feeling?.value,
        durationSeconds:
            metrics.durationSeconds > 0 ? metrics.durationSeconds : null,
        distanceMeters:
            metrics.distanceMeters > 0 ? metrics.distanceMeters : null,
        paceSecondsPerKm: metrics.paceSecondsPerKm,
        distanceUnit: 'km',
        paceUnit: '/km',
        externalSource: PersonalGpsSyncService.externalSource,
        externalId: device.insidersDeviceId,
        seasonId: session.selectedSeason?.ref?.id,
        teamIds: const <String>[],
        accessMemberIds: [playerId],
      );

      final saved = await _service.create(activity);
      if (!mounted) return;
      widget.onSaved?.call();
      Navigator.of(context).pop(saved);
    } catch (e, st) {
      if (!mounted) return;
      if (_isGpsNoDataError(e)) {
        debugPrint('[PersonalGps] no data to sync for selected window');
        await _promptGpsNoDataManualEntry();
        return;
      }
      debugPrint('personal GPS sync failed: $e\n$st');
      AppSnackbar.show(context, context.l10n.createPersonalSportGpsSyncError);
    }
  }

  bool _isGpsNoDataError(Object error) {
    final raw = error is StateError
        ? error.message
        : error.toString();
    final lower = raw.toLowerCase();
    return lower.contains('aucune donnée gnss') ||
        lower.contains('no gnss data') ||
        lower.contains('no sensor samples') ||
        lower.contains('count=0');
  }

  Future<void> _promptGpsNoDataManualEntry() async {
    final l10n = context.l10n;
    final useManual = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.wearableDeviceGpsInsidersIntense),
          content: Text(
            '${l10n.createPersonalSportGpsNoData}\n\n'
            '${l10n.createPersonalSportGpsManualEntryQuestion}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.actionNo),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.actionYes),
            ),
          ],
        );
      },
    );
    if (!mounted || useManual != true) return;
    setState(() {
      _manualEntry = true;
      _importSource = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final dateLabel = DateFormat.yMMMEd(locale.toString()).format(_date);
    final timeLabel = _time?.format(context) ?? l10n.createPersonalSportTapToSet;

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
                subtitle: Text(
                  timeLabel,
                  style: _time == null
                      ? TextStyle(
                          color: colors.textSecondary,
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
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
                          child: Text(_labelForImportSource(source)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _importSource = value);
                      _loadImportActivitiesForSource(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_importingFromGps) ...[
                    if (_gpsAvailability != null &&
                        _gpsAvailability!.devices.length > 1) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedGpsDevice?.deviceOwner.id,
                        decoration: InputDecoration(
                          labelText: l10n.createPersonalSportGpsDevice,
                        ),
                        items: [
                          for (final device in _gpsAvailability!.devices)
                            DropdownMenuItem(
                              value: device.deviceOwner.id,
                              child: Text(device.label),
                            ),
                        ],
                        onChanged: (id) {
                          if (id == null) return;
                          PersonalGpsDeviceOption? match;
                          for (final device in _gpsAvailability!.devices) {
                            if (device.deviceOwner.id == id) {
                              match = device;
                              break;
                            }
                          }
                          setState(() => _selectedGpsDevice = match);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      l10n.createPersonalSportGpsMetricsHint,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                  ] else if (_loadingImportActivities)
                    const Center(child: CircularProgressIndicator())
                  else if (_importSource == WearableDeviceType.strava &&
                      _stravaActivities.isEmpty)
                    Text(
                      l10n.createPersonalSportNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource == WearableDeviceType.polar &&
                      _polarActivities.isEmpty)
                    Text(
                      _polarListError ??
                          l10n.createPersonalSportPolarNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource == WearableDeviceType.whoop &&
                      _whoopActivities.isEmpty)
                    Text(
                      _whoopListError ??
                          l10n.createPersonalSportWhoopNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource == WearableDeviceType.appleHealth &&
                      _appleActivities.isEmpty)
                    Text(
                      _appleListError ??
                          l10n.createPersonalSportAppleNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource ==
                          WearableDeviceType.googleHealthConnect &&
                      _googleActivities.isEmpty)
                    Text(
                      _googleListError ??
                          l10n.createPersonalSportGoogleNoImportable,
                      style: TextStyle(color: colors.textSecondary),
                    )
                  else if (_importSource == WearableDeviceType.strava)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
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
                    )
                  else if (_importSource == WearableDeviceType.polar)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedPolar?.externalId,
                      decoration: InputDecoration(
                        labelText: l10n.createPersonalSportPolarActivity,
                      ),
                      items: [
                        for (final activity in _polarActivities)
                          DropdownMenuItem(
                            value: activity.externalId,
                            child: Text(
                              activity.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        PolarImportableActivity? match;
                        for (final activity in _polarActivities) {
                          if (activity.externalId == id) {
                            match = activity;
                            break;
                          }
                        }
                        setState(() {
                          _selectedPolar = match;
                          if (match != null) _typeId = match.typeId;
                        });
                      },
                    )
                  else if (_importSource == WearableDeviceType.whoop)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedWhoop?.externalId,
                      decoration: InputDecoration(
                        labelText: l10n.createPersonalSportWhoopActivity,
                      ),
                      items: [
                        for (final activity in _whoopActivities)
                          DropdownMenuItem(
                            value: activity.externalId,
                            child: Text(
                              activity.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        WhoopImportableActivity? match;
                        for (final activity in _whoopActivities) {
                          if (activity.externalId == id) {
                            match = activity;
                            break;
                          }
                        }
                        setState(() {
                          _selectedWhoop = match;
                          if (match != null) _typeId = match.typeId;
                        });
                      },
                    )
                  else if (_importSource == WearableDeviceType.appleHealth)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedApple?.externalId,
                      decoration: InputDecoration(
                        labelText: l10n.createPersonalSportAppleActivity,
                      ),
                      items: [
                        for (final activity in _appleActivities)
                          DropdownMenuItem(
                            value: activity.externalId,
                            child: Text(
                              activity.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        AppleHealthImportableActivity? match;
                        for (final activity in _appleActivities) {
                          if (activity.externalId == id) {
                            match = activity;
                            break;
                          }
                        }
                        setState(() {
                          _selectedApple = match;
                          if (match != null) _typeId = match.typeId;
                        });
                      },
                    )
                  else if (_importSource ==
                      WearableDeviceType.googleHealthConnect)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGoogle?.externalId,
                      decoration: InputDecoration(
                        labelText: l10n.createPersonalSportGoogleActivity,
                      ),
                      items: [
                        for (final activity in _googleActivities)
                          DropdownMenuItem(
                            value: activity.externalId,
                            child: Text(
                              activity.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                      ],
                      onChanged: (id) {
                        GoogleHealthImportableActivity? match;
                        for (final activity in _googleActivities) {
                          if (activity.externalId == id) {
                            match = activity;
                            break;
                          }
                        }
                        setState(() {
                          _selectedGoogle = match;
                          if (match != null) _typeId = match.typeId;
                        });
                      },
                    ),
                ],
              ],
              if ((_isEditMode || _readOnly) &&
                  widget.activityToEdit != null &&
                  widget.activityToEdit!.isWhoopImport) ...[
                const SizedBox(height: 12),
                WhoopHrZonesCard(activity: widget.activityToEdit!),
              ] else if (_isEditMode || _readOnly) ...[
                if (widget.activityToEdit?.averageHeartRateBpm != null) ...[
                  const SizedBox(height: 8),
                  _MetricTile(
                    label: l10n.personalSportMetricAvgHeartRate,
                    value:
                        '${widget.activityToEdit!.averageHeartRateBpm} ${l10n.personalSportUnitBpm}',
                  ),
                ],
                if (widget.activityToEdit?.hasHrTimeline == true) ...[
                  const SizedBox(height: 12),
                  PolarHrZonesChart(
                    timeline: widget.activityToEdit!.hrTimeline,
                    bucketMinutes:
                        widget.activityToEdit!.hrTimelineBucketMinutes,
                    height: 260,
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _closeWithoutSaving,
                        child: Text(l10n.actionCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
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
                                _importingFromGps
                                    ? l10n.createPersonalSportGpsSubmit
                                    : _isEditMode
                                        ? l10n.editPersonalSportSubmit
                                        : l10n.createPersonalSportSubmit,
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
