import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/agendaItem.dart';
import 'package:grinta/model/apple_health_importable_activity.dart';
import 'package:grinta/model/google_health_importable_activity.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/apple_health_sync_service.dart';
import 'package:grinta/services/google_health_sync_service.dart';
import 'package:grinta/services/personal_gps_sync_service.dart';
import 'package:grinta/services/polar_sync_service.dart';
import 'package:grinta/services/session_personal_data_service.dart';
import 'package:grinta/services/strava_sync_service.dart';
import 'package:grinta/services/whoop_sync_service.dart';
import 'package:grinta/util/app_snackbar.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/field_gps_localization_helper.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:provider/provider.dart';

/// Opens the dialog to attach personal GPS / connected-app data to a
/// training or match that has no team tracker kit.
Future<bool?> showSessionPersonalDataDialog(
  BuildContext context, {
  required AgendaItem item,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => SessionPersonalDataDialog(item: item),
  );
}

/// Agenda control next to session time. Visible only when:
/// - the event has no usable team kit, and
/// - the profile email matches an active [Owner.isIndividual] owner.
class SessionPersonalDataAgendaButton extends StatefulWidget {
  const SessionPersonalDataAgendaButton({
    super.key,
    required this.item,
    required this.playerId,
    this.onPersonalDataSaved,
  });

  final AgendaItem item;
  final String playerId;

  /// Called with the agenda event id after a successful GPS / apps attach.
  final ValueChanged<String>? onPersonalDataSaved;

  @override
  State<SessionPersonalDataAgendaButton> createState() =>
      _SessionPersonalDataAgendaButtonState();
}

class _SessionPersonalDataAgendaButtonState
    extends State<SessionPersonalDataAgendaButton> {
  final _gpsSyncService = PersonalGpsSyncService();
  bool _visible = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveVisibility());
  }

  @override
  void didUpdateWidget(covariant SessionPersonalDataAgendaButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.playerId != widget.playerId) {
      _resolveVisibility();
    }
  }

  Future<void> _resolveVisibility() async {
    if (!SessionPersonalDataService.isEligibleAgendaItem(widget.item)) {
      if (mounted) {
        setState(() {
          _visible = false;
          _loading = false;
        });
      }
      return;
    }

    final session = context.read<AppSession>();
    final playerEmail = session.selectedPlayer?.email?.trim() ?? '';
    final authEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final emails = <String>[
      if (playerEmail.isNotEmpty) playerEmail,
      if (authEmail.isNotEmpty &&
          authEmail.toLowerCase() != playerEmail.toLowerCase())
        authEmail,
    ];

    final hasIndividual =
        await _gpsSyncService.hasIndividualOwnerForEmails(emails);
    if (!mounted) return;
    setState(() {
      _visible = hasIndividual;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_visible) return const SizedBox.shrink();

    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // High-contrast control from app theme: near-black fill, near-white icon.
    final Color backgroundColor =
        isDark ? colors.background : colors.textPrimary;
    final Color iconColor = isDark ? colors.textPrimary : colors.surface;

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: context.l10n.sessionPersonalDataTitle,
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              final saved = await showSessionPersonalDataDialog(
                context,
                item: widget.item,
              );
              if (!context.mounted || saved != true) return;
              final eventId = widget.item.id.trim();
              if (eventId.isEmpty) return;
              widget.onPersonalDataSaved?.call(eventId);
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.sensors_rounded,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SessionPersonalDataDialog extends StatefulWidget {
  const SessionPersonalDataDialog({super.key, required this.item});

  final AgendaItem item;

  @override
  State<SessionPersonalDataDialog> createState() =>
      _SessionPersonalDataDialogState();
}

class _SessionPersonalDataDialogState extends State<SessionPersonalDataDialog> {
  final _gpsSyncService = PersonalGpsSyncService();
  final _sessionDataService = SessionPersonalDataService();

  bool _loading = true;
  bool _submitting = false;

  PersonalGpsOwnerAvailability? _gpsAvailability;
  PersonalGpsDeviceOption? _selectedGpsDevice;

  final List<WearableDeviceType> _connectedSources = [];
  WearableDeviceType? _importSource;
  bool _loadingImportActivities = false;

  List<StravaImportableActivity> _stravaActivities = const [];
  StravaImportableActivity? _selectedStrava;
  List<PolarImportableActivity> _polarActivities = const [];
  PolarImportableActivity? _selectedPolar;
  List<WhoopImportableActivity> _whoopActivities = const [];
  WhoopImportableActivity? _selectedWhoop;
  List<AppleHealthImportableActivity> _appleActivities = const [];
  AppleHealthImportableActivity? _selectedApple;
  List<GoogleHealthImportableActivity> _googleActivities = const [];
  GoogleHealthImportableActivity? _selectedGoogle;

  String? _playerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final session = context.read<AppSession>();
    final player = session.selectedPlayer;
    _playerId = (player == null ? null : effectiveMemberId(player)) ??
        session.selectedPlayerId?.trim();

    final playerEmail = player?.email?.trim() ?? '';
    final authEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final emails = <String>[
      if (playerEmail.isNotEmpty) playerEmail,
      if (authEmail.isNotEmpty &&
          authEmail.toLowerCase() != playerEmail.toLowerCase())
        authEmail,
    ];

    PersonalGpsOwnerAvailability? gps;
    for (final email in emails) {
      gps = await _gpsSyncService.resolveForEmail(email);
      if (gps != null) break;
    }

    if (!mounted) return;
    // Feature requires an individual owner matching the profile email.
    // Without it, close the dialog (agenda button should already hide).
    var hasIndividual = false;
    for (final email in emails) {
      final individuals =
          await _gpsSyncService.resolveIndividualOwnersForEmail(email);
      if (individuals.isNotEmpty) {
        hasIndividual = true;
        break;
      }
    }
    if (!mounted) return;
    if (!hasIndividual) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _gpsAvailability = gps;
      _selectedGpsDevice =
          gps?.devices.isNotEmpty == true ? gps!.devices.first : null;
      // GPS appears in the App / device import list when available.
      _loading = false;
    });

    await _loadConnectedAppsAndActivities();
  }

  bool get _canUseMyGps =>
      _gpsAvailability != null && _gpsAvailability!.devices.isNotEmpty;

  Future<void> _loadConnectedAppsAndActivities() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = _playerId?.trim() ?? '';
    if (uid == null || playerId.isEmpty) {
      setState(() {
        _connectedSources.clear();
        _importSource = null;
      });
      return;
    }

    setState(() => _loadingImportActivities = true);

    final stravaConfig =
        await StravaSyncService.instance.repository.getConfig(uid, playerId);
    final polarConfig =
        await PolarSyncService.instance.repository.getConfig(uid, playerId);
    final whoopConfig =
        await WhoopSyncService.instance.repository.getConfig(uid, playerId);
    final appleConfig =
        await AppleHealthSyncService.instance.repository.getConfig(uid, playerId);
    final googleConfig = await GoogleHealthSyncService.instance.repository
        .getConfig(uid, playerId);
    if (!mounted) return;

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
    });

    if (_importSource != null) {
      await _loadImportActivitiesForSource(_importSource!);
    } else if (mounted) {
      setState(() => _loadingImportActivities = false);
    }
  }

  Future<void> _loadImportActivitiesForSource(WearableDeviceType source) async {
    final playerId = _playerId?.trim() ?? '';
    if (playerId.isEmpty) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }

    setState(() => _loadingImportActivities = true);

    if (source == WearableDeviceType.strava) {
      final list = await StravaSyncService.instance
          .listImportableActivities(playerId: playerId);
      if (!mounted) return;
      setState(() {
        _stravaActivities = list;
        _selectedStrava = list.isNotEmpty ? list.first : null;
        _loadingImportActivities = false;
      });
      return;
    }
    if (source == WearableDeviceType.polar) {
      final result = await PolarSyncService.instance
          .listImportableActivities(playerId: playerId);
      if (!mounted) return;
      setState(() {
        _polarActivities = result.activities;
        _selectedPolar =
            result.activities.isNotEmpty ? result.activities.first : null;
        _loadingImportActivities = false;
      });
      return;
    }
    if (source == WearableDeviceType.whoop) {
      final result = await WhoopSyncService.instance
          .listImportableActivities(playerId: playerId);
      if (!mounted) return;
      setState(() {
        _whoopActivities = result.activities;
        _selectedWhoop =
            result.activities.isNotEmpty ? result.activities.first : null;
        _loadingImportActivities = false;
      });
      return;
    }
    if (source == WearableDeviceType.appleHealth) {
      final result = await AppleHealthSyncService.instance
          .listImportableActivities(playerId: playerId);
      if (!mounted) return;
      setState(() {
        _appleActivities = result.activities;
        _selectedApple =
            result.activities.isNotEmpty ? result.activities.first : null;
        _loadingImportActivities = false;
      });
      return;
    }
    if (source == WearableDeviceType.googleHealthConnect) {
      final result = await GoogleHealthSyncService.instance
          .listImportableActivities(playerId: playerId);
      if (!mounted) return;
      setState(() {
        _googleActivities = result.activities;
        _selectedGoogle =
            result.activities.isNotEmpty ? result.activities.first : null;
        _loadingImportActivities = false;
      });
      return;
    }
    if (source == WearableDeviceType.gpsInsidersIntense) {
      if (mounted) setState(() => _loadingImportActivities = false);
      return;
    }
    if (mounted) setState(() => _loadingImportActivities = false);
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
    if (_submitting) return;
    final playerId = _playerId?.trim() ?? '';
    if (playerId.isEmpty) {
      AppSnackbar.show(context, context.l10n.sessionPersonalDataAuthRequired);
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_importSource == WearableDeviceType.gpsInsidersIntense) {
        await _submitGps(playerId);
      } else {
        await _submitApp(playerId);
      }
    } catch (e, st) {
      debugPrint('session personal data attach failed: $e\n$st');
      if (!mounted) return;
      AppSnackbar.show(context, context.l10n.sessionPersonalDataError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitGps(String playerId) async {
    final device = _selectedGpsDevice;
    if (device == null) {
      AppSnackbar.show(context, context.l10n.createPersonalSportGpsDeviceRequired);
      return;
    }

    // Match + Intense GPS: ensure pitch corners so heatmap can be generated.
    final match = widget.item.match;
    if (match != null) {
      await FieldGpsLocalizationHelper.ensureMatchFieldGpsCorners(
        context,
        match: match,
      );
      if (!mounted) return;
    }

    final result = await _sessionDataService.attachGps(
      item: widget.item,
      playerId: playerId,
      device: device,
    );
    if (!mounted) return;
    if (result == null) {
      final useManual = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.createPersonalSportUseMyGps),
            content: Text(
              '${l10n.createPersonalSportGpsNoData}\n\n'
              '${l10n.sessionPersonalDataSwitchToAppsQuestion}',
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
      if (!mounted) return;
      if (useManual == true) {
        setState(() {
          _importSource = _connectedSources.isEmpty
              ? null
              : _connectedSources.firstWhere(
                  (s) => s != WearableDeviceType.gpsInsidersIntense,
                  orElse: () => _connectedSources.first,
                );
        });
        await _loadConnectedAppsAndActivities();
      }
      return;
    }

    AppSnackbar.show(
      context,
      context.l10n.sessionPersonalDataSaved,
      isError: false,
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _submitApp(String playerId) async {
    final source = _importSource;
    if (source == null) {
      AppSnackbar.show(context, context.l10n.createPersonalSportImportRequired);
      return;
    }

    int? durationSeconds;
    double? distanceMeters;
    String sourceId = source.name;

    if (source == WearableDeviceType.strava) {
      final selected = _selectedStrava;
      if (selected == null) {
        AppSnackbar.show(
          context,
          context.l10n.createPersonalSportImportRequired,
        );
        return;
      }
      durationSeconds = selected.durationSeconds;
      distanceMeters = selected.distanceMeters;
      sourceId = 'strava';
    } else if (source == WearableDeviceType.polar) {
      final selected = _selectedPolar;
      if (selected == null) {
        AppSnackbar.show(
          context,
          context.l10n.createPersonalSportImportRequired,
        );
        return;
      }
      durationSeconds = selected.durationSeconds;
      distanceMeters = selected.distanceMeters;
      sourceId = 'polar';
    } else if (source == WearableDeviceType.whoop) {
      final selected = _selectedWhoop;
      if (selected == null) {
        AppSnackbar.show(
          context,
          context.l10n.createPersonalSportImportRequired,
        );
        return;
      }
      durationSeconds = selected.durationSeconds;
      distanceMeters = selected.distanceMeters;
      sourceId = 'whoop';
    } else if (source == WearableDeviceType.appleHealth) {
      final selected = _selectedApple;
      if (selected == null) {
        AppSnackbar.show(
          context,
          context.l10n.createPersonalSportImportRequired,
        );
        return;
      }
      durationSeconds = selected.durationSeconds;
      distanceMeters = selected.distanceMeters;
      sourceId = 'appleHealth';
    } else if (source == WearableDeviceType.googleHealthConnect) {
      final selected = _selectedGoogle;
      if (selected == null) {
        AppSnackbar.show(
          context,
          context.l10n.createPersonalSportImportRequired,
        );
        return;
      }
      durationSeconds = selected.durationSeconds;
      distanceMeters = selected.distanceMeters;
      sourceId = 'googleHealth';
    } else {
      AppSnackbar.show(
        context,
        context.l10n.createPersonalSportImportRequired,
      );
      return;
    }

    await _sessionDataService.attachAppMetrics(
      item: widget.item,
      playerId: playerId,
      sourceId: sourceId,
      durationSeconds: durationSeconds,
      distanceMeters: distanceMeters,
    );
    if (!mounted) return;
    AppSnackbar.show(
      context,
      context.l10n.sessionPersonalDataSaved,
      isError: false,
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: colors.card,
      title: Text(l10n.sessionPersonalDataTitle),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.sessionPersonalDataSubtitle,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_connectedSources.isEmpty)
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
                        onChanged: _submitting
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _importSource = value);
                                _loadImportActivitiesForSource(value);
                              },
                      ),
                      const SizedBox(height: 12),
                      if (_importSource ==
                          WearableDeviceType.gpsInsidersIntense) ...[
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
                            onChanged: _submitting
                                ? null
                                : (id) {
                                    if (id == null) return;
                                    PersonalGpsDeviceOption? match;
                                    for (final device
                                        in _gpsAvailability!.devices) {
                                      if (device.deviceOwner.id == id) {
                                        match = device;
                                        break;
                                      }
                                    }
                                    setState(
                                      () => _selectedGpsDevice = match,
                                    );
                                  },
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          l10n.sessionPersonalDataGpsHint,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ] else if (_loadingImportActivities)
                        const Center(child: CircularProgressIndicator())
                      else
                        _buildActivityPicker(),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submitting || _loading ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _importSource == WearableDeviceType.gpsInsidersIntense
                      ? l10n.sessionPersonalDataGpsSubmit
                      : l10n.sessionPersonalDataAppSubmit,
                ),
        ),
      ],
    );
  }

  Widget _buildActivityPicker() {
    final l10n = context.l10n;
    final colors = context.appColors;
    final source = _importSource;

    if (source == WearableDeviceType.strava) {
      if (_stravaActivities.isEmpty) {
        return Text(
          l10n.createPersonalSportNoImportable,
          style: TextStyle(color: colors.textSecondary),
        );
      }
      return DropdownButtonFormField<String>(
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
          setState(() => _selectedStrava = match);
        },
      );
    }

    if (source == WearableDeviceType.polar) {
      if (_polarActivities.isEmpty) {
        return Text(
          l10n.createPersonalSportPolarNoImportable,
          style: TextStyle(color: colors.textSecondary),
        );
      }
      return DropdownButtonFormField<String>(
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
          setState(() => _selectedPolar = match);
        },
      );
    }

    if (source == WearableDeviceType.whoop) {
      if (_whoopActivities.isEmpty) {
        return Text(
          l10n.createPersonalSportWhoopNoImportable,
          style: TextStyle(color: colors.textSecondary),
        );
      }
      return DropdownButtonFormField<String>(
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
          setState(() => _selectedWhoop = match);
        },
      );
    }

    if (source == WearableDeviceType.appleHealth) {
      if (_appleActivities.isEmpty) {
        return Text(
          l10n.createPersonalSportAppleNoImportable,
          style: TextStyle(color: colors.textSecondary),
        );
      }
      return DropdownButtonFormField<String>(
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
          setState(() => _selectedApple = match);
        },
      );
    }

    if (source == WearableDeviceType.googleHealthConnect) {
      if (_googleActivities.isEmpty) {
        return Text(
          l10n.createPersonalSportGoogleNoImportable,
          style: TextStyle(color: colors.textSecondary),
        );
      }
      return DropdownButtonFormField<String>(
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
          setState(() => _selectedGoogle = match);
        },
      );
    }

    return const SizedBox.shrink();
  }
}
