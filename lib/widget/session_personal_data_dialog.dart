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
  bool _useMyGps = false;

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
    setState(() {
      _gpsAvailability = gps;
      _selectedGpsDevice =
          gps?.devices.isNotEmpty == true ? gps!.devices.first : null;
      _useMyGps = gps != null;
      _loading = false;
    });

    if (!_useMyGps) {
      await _loadConnectedAppsAndActivities();
    }
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
      default:
        return source.name;
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
      if (_useMyGps) {
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
        setState(() => _useMyGps = false);
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
                    if (_canUseMyGps) ...[
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.createPersonalSportUseMyGps),
                        subtitle: Text(
                          l10n.sessionPersonalDataGpsHint,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        value: _useMyGps,
                        activeColor: colors.primary,
                        onChanged: _submitting
                            ? null
                            : (value) async {
                                setState(() => _useMyGps = value);
                                if (!value) {
                                  await _loadConnectedAppsAndActivities();
                                }
                              },
                      ),
                      if (_useMyGps &&
                          _gpsAvailability!.devices.length > 1) ...[
                        const SizedBox(height: 8),
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
                                  setState(() => _selectedGpsDevice = match);
                                },
                        ),
                      ],
                    ],
                    if (!_useMyGps) ...[
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
                        if (_loadingImportActivities)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildActivityPicker(),
                      ],
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
                  _useMyGps
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
                overflow: TextOverflow.ellipsis,
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
                overflow: TextOverflow.ellipsis,
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
                overflow: TextOverflow.ellipsis,
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
                overflow: TextOverflow.ellipsis,
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
