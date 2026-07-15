import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/services/apple_health_platform.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';
import 'package:grinta/services/apple_health_sync_service.dart';
import 'package:grinta/services/fitbit_sync_repository.dart';
import 'package:grinta/services/fitbit_sync_service.dart';
import 'package:grinta/services/google_health_platform.dart';
import 'package:grinta/services/google_health_sync_repository.dart';
import 'package:grinta/services/google_health_sync_service.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:grinta/services/polar_sync_service.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:grinta/services/strava_sync_service.dart';
import 'package:grinta/services/whoop_sync_repository.dart';
import 'package:grinta/services/whoop_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/apple_health_coach_visibility_section.dart';
import 'package:grinta/widget/fitbit_coach_visibility_section.dart';
import 'package:grinta/widget/google_health_coach_visibility_section.dart';
import 'package:grinta/widget/polar_coach_visibility_section.dart';
import 'package:grinta/widget/strava_coach_visibility_section.dart';
import 'package:grinta/widget/wearable_device_type_dropdown.dart';
import 'package:grinta/widget/whoop_coach_visibility_section.dart';

/// Opens the wearable devices management dialog.
Future<void> showWearableDevicesDialog(
  BuildContext context, {
  required String playerId,
  required String initiatedBy,
  String? playerName,
  bool showCoachVisibility = false,
}) {
  final colors = context.appColors;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          dialogContext.l10n.settingsDevicesSection,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: WearableDevicesDialogContent(
            playerId: playerId,
            initiatedBy: initiatedBy,
            playerName: playerName,
            showCoachVisibility: showCoachVisibility,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.settingsDevicesClose),
          ),
        ],
      );
    },
  );
}

class WearableDevicesDialogContent extends StatefulWidget {
  const WearableDevicesDialogContent({
    super.key,
    required this.playerId,
    required this.initiatedBy,
    this.playerName,
    this.showCoachVisibility = false,
  });

  final String playerId;
  final String initiatedBy;
  final String? playerName;
  final bool showCoachVisibility;

  @override
  State<WearableDevicesDialogContent> createState() =>
      _WearableDevicesDialogContentState();
}

class _WearableDevicesDialogContentState
    extends State<WearableDevicesDialogContent> {
  final WhoopSyncRepository _whoopRepository = WhoopSyncRepository();
  final StravaSyncRepository _stravaRepository = StravaSyncRepository();
  final PolarSyncRepository _polarRepository = PolarSyncRepository();
  final FitbitSyncRepository _fitbitRepository = FitbitSyncRepository();
  final AppleHealthSyncRepository _appleHealthRepository =
      AppleHealthSyncRepository();
  final GoogleHealthSyncRepository _googleHealthRepository =
      GoogleHealthSyncRepository();
  WearableDeviceType _selectedType = WearableDeviceType.whoop;
  bool _syncBusy = false;
  String? _disconnectingType;

  Future<void> _syncSelectedType({
    required bool whoopConnected,
    required bool stravaConnected,
    required bool polarConnected,
    required bool fitbitConnected,
    required bool appleHealthConnected,
    required bool googleHealthConnected,
  }) async {
    final selectedConnected = switch (_selectedType) {
      WearableDeviceType.whoop => whoopConnected,
      WearableDeviceType.strava => stravaConnected,
      WearableDeviceType.polar => polarConnected,
      WearableDeviceType.fitbit => fitbitConnected,
      WearableDeviceType.appleHealth => appleHealthConnected,
      WearableDeviceType.googleHealthConnect => googleHealthConnected,
    };
    if (_syncBusy || selectedConnected) return;

    if (_selectedType == WearableDeviceType.appleHealth &&
        !isAppleHealthSupported) {
      _showConnectError(context.l10n.appleHealthIosOnlyMessage);
      return;
    }

    if (_selectedType == WearableDeviceType.googleHealthConnect &&
        !isGoogleHealthConnectSupported) {
      _showConnectError(context.l10n.googleHealthAndroidOnlyMessage);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.playerId.isEmpty) return;

    setState(() => _syncBusy = true);

    try {
      switch (_selectedType) {
        case WearableDeviceType.whoop:
          final result = await WhoopSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != WhoopConnectResult.success) {
            _showConnectError(_whoopConnectMessage(result));
          }
        case WearableDeviceType.strava:
          final result = await StravaSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != StravaConnectResult.success) {
            _showConnectError(_stravaConnectMessage(result));
          }
        case WearableDeviceType.polar:
          final result = await PolarSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != PolarConnectResult.success) {
            _showConnectError(_polarConnectMessage(result));
          }
        case WearableDeviceType.fitbit:
          final result = await FitbitSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != FitbitConnectResult.success) {
            _showConnectError(_fitbitConnectMessage(result));
          }
        case WearableDeviceType.appleHealth:
          final result = await AppleHealthSyncService.instance.connect(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != AppleHealthConnectResult.success) {
            _showConnectError(_appleHealthConnectMessage(result));
          }
        case WearableDeviceType.googleHealthConnect:
          final result = await GoogleHealthSyncService.instance.connect(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result != GoogleHealthConnectResult.success) {
            _showConnectError(_googleHealthConnectMessage(result));
          }
      }
    } catch (_) {
      if (!mounted) return;
      _showConnectError(
        switch (_selectedType) {
          WearableDeviceType.whoop => context.l10n.whoopConnectFailed,
          WearableDeviceType.strava => context.l10n.stravaConnectFailed,
          WearableDeviceType.polar => context.l10n.polarConnectFailed,
          WearableDeviceType.fitbit => context.l10n.fitbitConnectFailed,
          WearableDeviceType.appleHealth => context.l10n.appleHealthConnectFailed,
          WearableDeviceType.googleHealthConnect =>
            context.l10n.googleHealthConnectFailed,
        },
      );
    } finally {
      if (mounted) {
        setState(() => _syncBusy = false);
      }
    }
  }

  void _showConnectError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _whoopConnectMessage(WhoopConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      WhoopConnectResult.launchFailed => l10n.whoopConnectLaunchFailed,
      WhoopConnectResult.unauthenticated => l10n.whoopConnectAuthRequired,
      _ => l10n.whoopConnectFailed,
    };
  }

  String _stravaConnectMessage(StravaConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      StravaConnectResult.launchFailed => l10n.stravaConnectLaunchFailed,
      StravaConnectResult.unauthenticated => l10n.stravaConnectAuthRequired,
      _ => l10n.stravaConnectFailed,
    };
  }

  String _polarConnectMessage(PolarConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      PolarConnectResult.launchFailed => l10n.polarConnectLaunchFailed,
      PolarConnectResult.unauthenticated => l10n.polarConnectAuthRequired,
      _ => l10n.polarConnectFailed,
    };
  }

  String _fitbitConnectMessage(FitbitConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      FitbitConnectResult.launchFailed => l10n.fitbitConnectLaunchFailed,
      FitbitConnectResult.unauthenticated => l10n.fitbitConnectAuthRequired,
      _ => l10n.fitbitConnectFailed,
    };
  }

  String _appleHealthConnectMessage(AppleHealthConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      AppleHealthConnectResult.iosOnly => l10n.appleHealthIosOnlyMessage,
      AppleHealthConnectResult.denied => l10n.appleHealthConnectDenied,
      AppleHealthConnectResult.unauthenticated =>
        l10n.appleHealthConnectAuthRequired,
      _ => l10n.appleHealthConnectFailed,
    };
  }

  String _googleHealthConnectMessage(GoogleHealthConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      GoogleHealthConnectResult.androidOnly => l10n.googleHealthAndroidOnlyMessage,
      GoogleHealthConnectResult.denied => l10n.googleHealthConnectDenied,
      GoogleHealthConnectResult.unauthenticated =>
        l10n.googleHealthConnectAuthRequired,
      _ => l10n.googleHealthConnectFailed,
    };
  }

  Future<void> _disconnectWhoop() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'whoop');

    try {
      final ok = await WhoopSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.whoopDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  Future<void> _disconnectStrava() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'strava');

    try {
      final ok = await StravaSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.stravaDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  Future<void> _disconnectPolar() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'polar');

    try {
      final ok = await PolarSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.polarDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  Future<void> _disconnectFitbit() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'fitbit');

    try {
      final ok = await FitbitSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fitbitDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  Future<void> _disconnectAppleHealth() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'appleHealth');

    try {
      final ok = await AppleHealthSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appleHealthDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  Future<void> _disconnectGoogleHealth() async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = 'googleHealth');

    try {
      final ok = await GoogleHealthSyncService.instance.disconnect(
        playerId: widget.playerId,
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.googleHealthDisconnectFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _disconnectingType = null);
      }
    }
  }

  String _statusSubtitle({
    required WearableDeviceType type,
    required bool connected,
  }) {
    final l10n = context.l10n;
    if (widget.initiatedBy == 'coach' && widget.playerName != null) {
      return switch (type) {
        WearableDeviceType.whoop =>
          connected
              ? l10n.whoopCoachConnectConnectedSubtitle(widget.playerName!)
              : l10n.whoopCoachConnectSubtitle(widget.playerName!),
        WearableDeviceType.strava =>
          connected
              ? l10n.stravaCoachConnectConnectedSubtitle(widget.playerName!)
              : l10n.stravaCoachConnectSubtitle(widget.playerName!),
        WearableDeviceType.polar =>
          connected
              ? l10n.polarCoachConnectConnectedSubtitle(widget.playerName!)
              : l10n.polarCoachConnectSubtitle(widget.playerName!),
        WearableDeviceType.fitbit =>
          connected
              ? l10n.fitbitCoachConnectConnectedSubtitle(widget.playerName!)
              : l10n.fitbitCoachConnectSubtitle(widget.playerName!),
        WearableDeviceType.appleHealth =>
          connected
              ? l10n.appleHealthCoachConnectConnectedSubtitle(
                  widget.playerName!,
                )
              : l10n.appleHealthCoachConnectSubtitle(widget.playerName!),
        WearableDeviceType.googleHealthConnect =>
          connected
              ? l10n.googleHealthCoachConnectConnectedSubtitle(
                  widget.playerName!,
                )
              : l10n.googleHealthCoachConnectSubtitle(widget.playerName!),
      };
    }
    return connected
        ? l10n.settingsDevicesConnectedStatus
        : switch (type) {
            WearableDeviceType.whoop => l10n.whoopConnectToggleSubtitle,
            WearableDeviceType.strava => l10n.stravaConnectToggleSubtitle,
            WearableDeviceType.polar => l10n.polarConnectToggleSubtitle,
            WearableDeviceType.fitbit => l10n.fitbitConnectToggleSubtitle,
            WearableDeviceType.appleHealth =>
              l10n.appleHealthConnectToggleSubtitle,
            WearableDeviceType.googleHealthConnect =>
              l10n.googleHealthConnectToggleSubtitle,
          };
  }

  Stream<_WearableDialogState> _watchDialogState(String syncOwnerUid) {
    final controller = StreamController<_WearableDialogState>();
    WhoopSyncConfig? whoopConfig;
    StravaSyncConfig? stravaConfig;
    PolarSyncConfig? polarConfig;
    FitbitSyncConfig? fitbitConfig;
    AppleHealthSyncConfig? appleHealthConfig;
    GoogleHealthSyncConfig? googleHealthConfig;

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        _WearableDialogState(
          whoopConfig: whoopConfig,
          stravaConfig: stravaConfig,
          polarConfig: polarConfig,
          fitbitConfig: fitbitConfig,
          appleHealthConfig: appleHealthConfig,
          googleHealthConfig: googleHealthConfig,
        ),
      );
    }

    final whoopSub = _whoopRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      whoopConfig = config;
      emit();
    });
    final stravaSub = _stravaRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      stravaConfig = config;
      emit();
    });
    final polarSub = _polarRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      polarConfig = config;
      emit();
    });
    final fitbitSub = _fitbitRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      fitbitConfig = config;
      emit();
    });
    final appleHealthSub = _appleHealthRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      appleHealthConfig = config;
      emit();
    });
    final googleHealthSub = _googleHealthRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      googleHealthConfig = config;
      emit();
    });

    controller.onCancel = () async {
      await whoopSub.cancel();
      await stravaSub.cancel();
      await polarSub.cancel();
      await fitbitSub.cancel();
      await appleHealthSub.cancel();
      await googleHealthSub.cancel();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || widget.playerId.isEmpty) {
      return const SizedBox.shrink();
    }

    final syncOwnerUid = WhoopSyncService.instance.syncOwnerUidForPlayer(
      uid: uid,
      playerId: widget.playerId,
    );

    return StreamBuilder<_WearableDialogState>(
      stream: _watchDialogState(syncOwnerUid),
      builder: (context, snapshot) {
        final state = snapshot.data;
        final whoopConfig = state?.whoopConfig;
        final stravaConfig = state?.stravaConfig;
        final polarConfig = state?.polarConfig;
        final fitbitConfig = state?.fitbitConfig;
        final appleHealthConfig = state?.appleHealthConfig;
        final googleHealthConfig = state?.googleHealthConfig;
        final whoopConnected = whoopConfig?.connected == true;
        final stravaConnected = stravaConfig?.connected == true;
        final polarConnected = polarConfig?.connected == true;
        final fitbitConnected = fitbitConfig?.connected == true;
        final appleHealthConnected = appleHealthConfig?.connected == true;
        final googleHealthConnected = googleHealthConfig?.connected == true;
        final selectedConnected = switch (_selectedType) {
          WearableDeviceType.whoop => whoopConnected,
          WearableDeviceType.strava => stravaConnected,
          WearableDeviceType.polar => polarConnected,
          WearableDeviceType.fitbit => fitbitConnected,
          WearableDeviceType.appleHealth => appleHealthConnected,
          WearableDeviceType.googleHealthConnect => googleHealthConnected,
        };
        final showWhoopCoachVisibility = widget.showCoachVisibility &&
            whoopConnected &&
            (whoopConfig?.initiatedBy == 'player' ||
                whoopConfig?.initiatedBy == null);
        final showStravaCoachVisibility = widget.showCoachVisibility &&
            stravaConnected &&
            (stravaConfig?.initiatedBy == 'player' ||
                stravaConfig?.initiatedBy == null);
        final showPolarCoachVisibility = widget.showCoachVisibility &&
            polarConnected &&
            (polarConfig?.initiatedBy == 'player' ||
                polarConfig?.initiatedBy == null);
        final showFitbitCoachVisibility = widget.showCoachVisibility &&
            fitbitConnected &&
            (fitbitConfig?.initiatedBy == 'player' ||
                fitbitConfig?.initiatedBy == null);
        final showAppleHealthCoachVisibility = widget.showCoachVisibility &&
            appleHealthConnected &&
            (appleHealthConfig?.initiatedBy == 'player' ||
                appleHealthConfig?.initiatedBy == null);
        final showGoogleHealthCoachVisibility = widget.showCoachVisibility &&
            googleHealthConnected &&
            (googleHealthConfig?.initiatedBy == 'player' ||
                googleHealthConfig?.initiatedBy == null);
        final hasConnected = whoopConnected ||
            stravaConnected ||
            polarConnected ||
            fitbitConnected ||
            appleHealthConnected ||
            googleHealthConnected;
        final appleHealthIosOnly = _selectedType == WearableDeviceType.appleHealth &&
            !isAppleHealthSupported;
        final googleHealthAndroidOnly =
            _selectedType == WearableDeviceType.googleHealthConnect &&
                !isGoogleHealthConnectSupported;
        final platformOnlyMessage = appleHealthIosOnly
            ? l10n.appleHealthIosOnlyMessage
            : googleHealthAndroidOnly
                ? l10n.googleHealthAndroidOnlyMessage
                : null;
        final syncDisabled = appleHealthIosOnly || googleHealthAndroidOnly;

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WearableDeviceTypeDropdown(
                value: _selectedType,
                dense: true,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedType = value);
                },
              ),
              if (platformOnlyMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  platformOnlyMessage,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _syncBusy || selectedConnected || syncDisabled
                    ? null
                    : () => _syncSelectedType(
                          whoopConnected: whoopConnected,
                          stravaConnected: stravaConnected,
                          polarConnected: polarConnected,
                          fitbitConnected: fitbitConnected,
                          appleHealthConnected: appleHealthConnected,
                          googleHealthConnected: googleHealthConnected,
                        ),
                icon: _syncBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 20),
                label: Text(l10n.settingsDevicesSync),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.settingsDevicesConnectedTitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              if (whoopConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.whoop.icon,
                  title: WearableDeviceType.whoop.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.whoop,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'whoop',
                  onDisconnect: _disconnectWhoop,
                ),
              if (whoopConnected &&
                  (stravaConnected ||
                      polarConnected ||
                      fitbitConnected ||
                      appleHealthConnected ||
                      googleHealthConnected))
                const SizedBox(height: 8),
              if (stravaConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.strava.icon,
                  title: WearableDeviceType.strava.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.strava,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'strava',
                  onDisconnect: _disconnectStrava,
                ),
              if (stravaConnected &&
                  (polarConnected ||
                      fitbitConnected ||
                      appleHealthConnected ||
                      googleHealthConnected))
                const SizedBox(height: 8),
              if (polarConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.polar.icon,
                  title: WearableDeviceType.polar.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.polar,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'polar',
                  onDisconnect: _disconnectPolar,
                ),
              if (polarConnected &&
                  (fitbitConnected ||
                      appleHealthConnected ||
                      googleHealthConnected))
                const SizedBox(height: 8),
              if (fitbitConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.fitbit.icon,
                  title: WearableDeviceType.fitbit.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.fitbit,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'fitbit',
                  onDisconnect: _disconnectFitbit,
                ),
              if (fitbitConnected &&
                  (appleHealthConnected || googleHealthConnected))
                const SizedBox(height: 8),
              if (appleHealthConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.appleHealth.icon,
                  title: WearableDeviceType.appleHealth.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.appleHealth,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'appleHealth',
                  onDisconnect: _disconnectAppleHealth,
                ),
              if (appleHealthConnected && googleHealthConnected)
                const SizedBox(height: 8),
              if (googleHealthConnected)
                _ConnectedWearableTile(
                  icon: WearableDeviceType.googleHealthConnect.icon,
                  title: WearableDeviceType.googleHealthConnect.label(l10n),
                  subtitle: _statusSubtitle(
                    type: WearableDeviceType.googleHealthConnect,
                    connected: true,
                  ),
                  disconnectLabel: l10n.settingsDevicesDisconnect,
                  disconnectBusy: _disconnectingType == 'googleHealth',
                  onDisconnect: _disconnectGoogleHealth,
                ),
              if (!hasConnected)
                Text(
                  l10n.settingsDevicesNoConnected,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              if (showWhoopCoachVisibility) ...[
                const SizedBox(height: 8),
                WhoopCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility:
                      whoopConfig?.coachVisibility ?? const WhoopCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              if (showStravaCoachVisibility) ...[
                const SizedBox(height: 8),
                StravaCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility: stravaConfig?.coachVisibility ??
                      const StravaCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              if (showPolarCoachVisibility) ...[
                const SizedBox(height: 8),
                PolarCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility: polarConfig?.coachVisibility ??
                      const PolarCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              if (showFitbitCoachVisibility) ...[
                const SizedBox(height: 8),
                FitbitCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility: fitbitConfig?.coachVisibility ??
                      const FitbitCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              if (showAppleHealthCoachVisibility) ...[
                const SizedBox(height: 8),
                AppleHealthCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility: appleHealthConfig?.coachVisibility ??
                      const AppleHealthCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
              if (showGoogleHealthCoachVisibility) ...[
                const SizedBox(height: 8),
                GoogleHealthCoachVisibilitySection(
                  uid: syncOwnerUid,
                  playerId: widget.playerId,
                  visibility: googleHealthConfig?.coachVisibility ??
                      const GoogleHealthCoachVisibility(),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WearableDialogState {
  const _WearableDialogState({
    this.whoopConfig,
    this.stravaConfig,
    this.polarConfig,
    this.fitbitConfig,
    this.appleHealthConfig,
    this.googleHealthConfig,
  });

  final WhoopSyncConfig? whoopConfig;
  final StravaSyncConfig? stravaConfig;
  final PolarSyncConfig? polarConfig;
  final FitbitSyncConfig? fitbitConfig;
  final AppleHealthSyncConfig? appleHealthConfig;
  final GoogleHealthSyncConfig? googleHealthConfig;
}

class _ConnectedWearableTile extends StatelessWidget {
  const _ConnectedWearableTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.disconnectLabel,
    required this.disconnectBusy,
    required this.onDisconnect,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String disconnectLabel;
  final bool disconnectBusy;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (disconnectBusy)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: colors.primary,
              ),
            )
          else
            TextButton(
              onPressed: onDisconnect,
              child: Text(disconnectLabel),
            ),
        ],
      ),
    );
  }
}
