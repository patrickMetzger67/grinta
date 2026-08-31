import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/apple_health_sync_config.dart';
import 'package:grinta/model/fitbit_sync_config.dart';
import 'package:grinta/model/google_health_sync_config.dart';
import 'package:grinta/model/intense_gps_sync_config.dart';
import 'package:grinta/model/polar_sync_config.dart';
import 'package:grinta/model/strava_sync_config.dart';
import 'package:grinta/model/wearable_device_type.dart';
import 'package:grinta/model/whoop_sync_config.dart';
import 'package:grinta/model/oura_sync_config.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/apple_health_platform.dart';
import 'package:grinta/services/apple_health_sync_repository.dart';
import 'package:grinta/services/apple_health_sync_service.dart';
import 'package:grinta/services/fitbit_sync_repository.dart';
import 'package:grinta/services/fitbit_sync_service.dart';
import 'package:grinta/services/google_health_platform.dart';
import 'package:grinta/services/google_health_sync_repository.dart';
import 'package:grinta/services/google_health_sync_service.dart';
import 'package:grinta/services/intense_gps_claim_service.dart';
import 'package:grinta/services/intense_gps_sync_repository.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/polar_sync_repository.dart';
import 'package:grinta/services/polar_sync_service.dart';
import 'package:grinta/services/strava_sync_repository.dart';
import 'package:grinta/services/strava_sync_service.dart';
import 'package:grinta/services/whoop_sync_repository.dart';
import 'package:grinta/services/whoop_sync_service.dart';
import 'package:grinta/services/oura_sync_repository.dart';
import 'package:grinta/services/oura_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/physiological_data_consent.dart';
import 'package:grinta/util/wearable_sync_owner.dart';
import 'package:grinta/widget/apple_health_coach_visibility_section.dart';
import 'package:grinta/widget/fitbit_coach_visibility_section.dart';
import 'package:grinta/widget/google_health_coach_visibility_section.dart';
import 'package:grinta/widget/physiological_data_consent_dialog.dart';
import 'package:grinta/widget/polar_coach_visibility_section.dart';
import 'package:grinta/widget/strava_coach_visibility_section.dart';
import 'package:grinta/widget/wearable_device_type_dropdown.dart';
import 'package:grinta/widget/whoop_coach_visibility_section.dart';
import 'package:grinta/widget/oura_coach_visibility_section.dart';
import 'package:provider/provider.dart';

enum _WearableDialogPage { list, add }

/// Opens the wearable devices management dialog.
///
/// First screen lists existing connections. FAB "+" opens the add flow
/// (device/application type dropdown, then provider connect steps).
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
      return Dialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.border),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: WearableDevicesDialogContent(
              playerId: playerId,
              initiatedBy: initiatedBy,
              playerName: playerName,
              showCoachVisibility: showCoachVisibility,
            ),
          ),
        ),
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
  final OuraSyncRepository _ouraRepository = OuraSyncRepository();
  final StravaSyncRepository _stravaRepository = StravaSyncRepository();
  final PolarSyncRepository _polarRepository = PolarSyncRepository();
  final FitbitSyncRepository _fitbitRepository = FitbitSyncRepository();
  final AppleHealthSyncRepository _appleHealthRepository =
      AppleHealthSyncRepository();
  final GoogleHealthSyncRepository _googleHealthRepository =
      GoogleHealthSyncRepository();
  final IntenseGpsSyncRepository _intenseGpsRepository =
      IntenseGpsSyncRepository();

  _WearableDialogPage _page = _WearableDialogPage.list;
  WearableDeviceType _selectedType = WearableDeviceType.strava;
  /// Connected type whose coach-visibility details are expanded (null = none).
  WearableDeviceType? _detailType;
  bool _syncBusy = false;
  String? _disconnectingType;
  Player? _player;
  bool _playerLoadStarted = false;
  bool _playerLoaded = false;
  bool _whoopRepairStarted = false;
  bool _ouraRepairStarted = false;
  bool _intenseGpsRepairStarted = false;
  final TextEditingController _stravaAccountController =
      TextEditingController();
  final TextEditingController _ouraAccountController =
      TextEditingController();
  final TextEditingController _whoopAccountController =
      TextEditingController();
  final TextEditingController _polarAccountController =
      TextEditingController();
  final TextEditingController _intenseGpsSerialController =
      TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_playerLoadStarted) return;
    _playerLoadStarted = true;

    final fromSession =
        context.read<AppSession>().currentUserPlayers[widget.playerId];
    if (fromSession != null) {
      _player = fromSession;
      _playerLoaded = true;
      _repairSyncIfNeeded();
      return;
    }

    PlayerService().getPlayerById(widget.playerId).then((player) {
      if (!mounted) return;
      setState(() {
        _player = player;
        _playerLoaded = true;
      });
      _repairSyncIfNeeded();
    });
  }

  Future<void> _repairSyncIfNeeded() async {
    var changed = false;
    if (!_whoopRepairStarted && widget.initiatedBy == 'player') {
      _whoopRepairStarted = true;
      changed = await WhoopSyncService.instance
              .repairPlayerSync(playerId: widget.playerId) ||
          changed;
    }
    if (!_ouraRepairStarted && widget.initiatedBy == 'player') {
      _ouraRepairStarted = true;
      changed = await OuraSyncService.instance
              .repairPlayerSync(playerId: widget.playerId) ||
          changed;
    }
    if (!_intenseGpsRepairStarted) {
      _intenseGpsRepairStarted = true;
      changed = await IntenseGpsClaimService.instance.repairPlayerSync(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          ) ||
          changed;
    }
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _stravaAccountController.dispose();
    _whoopAccountController.dispose();
    _ouraAccountController.dispose();
    _polarAccountController.dispose();
    _intenseGpsSerialController.dispose();
    super.dispose();
  }

  List<WearableDeviceType> _availableTypes(_WearableDialogState state) {
    final l10n = context.l10n;
    return [
      for (final type in WearableDeviceType.selectableSorted(l10n))
        if (!_isConnected(type, state)) type,
    ];
  }

  WearableDeviceType _defaultAddType(List<WearableDeviceType> available) {
    if (available.contains(WearableDeviceType.strava)) {
      return WearableDeviceType.strava;
    }
    return available.isNotEmpty ? available.first : WearableDeviceType.strava;
  }

  void _openAddPage(
    _WearableDialogState state, {
    WearableDeviceType? preferredType,
  }) {
    final available = _availableTypes(state);
    if (available.isEmpty) return;
    final preferred =
        preferredType != null && available.contains(preferredType)
            ? preferredType
            : _defaultAddType(available);
    setState(() {
      _page = _WearableDialogPage.add;
      _selectedType = preferred;
    });
  }

  void _backToList() {
    setState(() => _page = _WearableDialogPage.list);
  }

  bool _isConnected(WearableDeviceType type, _WearableDialogState state) {
    return switch (type) {
      WearableDeviceType.whoop => state.whoopConfig?.connected == true,
      WearableDeviceType.oura => state.ouraConfig?.connected == true,
      WearableDeviceType.strava => state.stravaConfig?.connected == true,
      WearableDeviceType.polar => state.polarConfig?.connected == true,
      WearableDeviceType.fitbit => state.fitbitConfig?.connected == true,
      WearableDeviceType.appleHealth =>
        state.appleHealthConfig?.connected == true,
      WearableDeviceType.googleHealthConnect =>
        state.googleHealthConfig?.connected == true,
      WearableDeviceType.gpsInsidersIntense =>
        state.intenseGpsConfig?.connected == true,
    };
  }

  Future<void> _syncSelectedType() async {
    if (_syncBusy) return;

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

    if (_selectedType == WearableDeviceType.strava &&
        _stravaAccountController.text.trim().isEmpty) {
      _showConnectError(context.l10n.stravaAccountHintRequired);
      return;
    }
    if (_selectedType == WearableDeviceType.whoop &&
        _whoopAccountController.text.trim().isEmpty) {
      _showConnectError(context.l10n.whoopAccountHintRequired);
      return;
    }
    if (_selectedType == WearableDeviceType.oura &&
        _ouraAccountController.text.trim().isEmpty) {
      _showConnectError(context.l10n.ouraAccountHintRequired);
      return;
    }
    if (_selectedType == WearableDeviceType.polar &&
        _polarAccountController.text.trim().isEmpty) {
      _showConnectError(context.l10n.polarAccountHintRequired);
      return;
    }
    if (_selectedType == WearableDeviceType.gpsInsidersIntense &&
        _intenseGpsSerialController.text.trim().isEmpty) {
      _showConnectError(context.l10n.intenseGpsSerialRequired);
      return;
    }

    if (wearableRequiresPhysiologicalConsent(_selectedType)) {
      final player =
          await PlayerService().getPlayerById(widget.playerId);
      if (!mounted) return;
      final consentUid = resolveWearableSyncOwnerUid(
        callerUid: uid,
        player: player,
      );
      final gate = await ensurePhysiologicalDataConsent(
        context: context,
        consentUid: consentUid,
        player: player,
      );
      if (!mounted) return;
      if (gate != PhysiologicalConsentGateResult.allowed) {
        if (gate == PhysiologicalConsentGateResult.blocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.physiologicalConsentRefusedHint)),
          );
        }
        return;
      }
    }

    setState(() => _syncBusy = true);

    try {
      switch (_selectedType) {
        case WearableDeviceType.whoop:
          final result = await WhoopSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
            whoopAccountHint: _whoopAccountController.text.trim(),
          );
          if (!mounted) return;
          if (result != WhoopConnectResult.success) {
            _showConnectError(_whoopConnectMessage(result));
          }
        case WearableDeviceType.oura:
          final result = await OuraSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
            ouraAccountHint: _ouraAccountController.text.trim(),
          );
          if (!mounted) return;
          if (result != OuraConnectResult.success) {
            _showConnectError(_ouraConnectMessage(result));
          }
        case WearableDeviceType.strava:
          final result = await StravaSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
            stravaAccountHint: _stravaAccountController.text.trim(),
          );
          if (!mounted) return;
          if (result != StravaConnectResult.success) {
            _showConnectError(_stravaConnectMessage(result));
          }
        case WearableDeviceType.polar:
          final result = await PolarSyncService.instance.startOAuth(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
            polarAccountHint: _polarAccountController.text.trim(),
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
          if (result == AppleHealthConnectResult.success) {
            _backToList();
          } else {
            _showConnectError(_appleHealthConnectMessage(result));
          }
        case WearableDeviceType.googleHealthConnect:
          final result = await GoogleHealthSyncService.instance.connect(
            playerId: widget.playerId,
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result.isAuthorized) {
            _backToList();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result == GoogleHealthConnectResult.successNoRecentWorkouts
                      ? context.l10n.googleHealthConnectNoWorkouts
                      : context.l10n.googleHealthConnectSuccess,
                ),
              ),
            );
          } else {
            _showConnectError(_googleHealthConnectMessage(result));
          }
        case WearableDeviceType.gpsInsidersIntense:
          final result = await IntenseGpsClaimService.instance.claimBySerial(
            playerId: widget.playerId,
            serialNumber: _intenseGpsSerialController.text.trim(),
            initiatedBy: widget.initiatedBy,
          );
          if (!mounted) return;
          if (result == IntenseGpsClaimResult.success) {
            _intenseGpsSerialController.clear();
            _backToList();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.intenseGpsConnectSuccess)),
            );
          } else {
            _showConnectError(_intenseGpsClaimMessage(result));
          }
      }
    } catch (_) {
      if (!mounted) return;
      _showConnectError(
        switch (_selectedType) {
          WearableDeviceType.whoop => context.l10n.whoopConnectFailed,
          WearableDeviceType.oura => context.l10n.ouraConnectFailed,
          WearableDeviceType.strava => context.l10n.stravaConnectFailed,
          WearableDeviceType.polar => context.l10n.polarConnectFailed,
          WearableDeviceType.fitbit => context.l10n.fitbitConnectFailed,
          WearableDeviceType.appleHealth =>
            context.l10n.appleHealthConnectFailed,
          WearableDeviceType.googleHealthConnect =>
            context.l10n.googleHealthConnectFailed,
          WearableDeviceType.gpsInsidersIntense =>
            context.l10n.intenseGpsConnectFailed,
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

  String _ouraConnectMessage(OuraConnectResult result) {
    final l10n = context.l10n;
    return switch (result) {
      OuraConnectResult.launchFailed => l10n.ouraConnectLaunchFailed,
      OuraConnectResult.unauthenticated => l10n.ouraConnectAuthRequired,
      _ => l10n.ouraConnectFailed,
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
      GoogleHealthConnectResult.androidOnly =>
        l10n.googleHealthAndroidOnlyMessage,
      GoogleHealthConnectResult.denied => l10n.googleHealthConnectDenied,
      GoogleHealthConnectResult.unavailable =>
        l10n.googleHealthConnectUnavailable,
      GoogleHealthConnectResult.unauthenticated =>
        l10n.googleHealthConnectAuthRequired,
      GoogleHealthConnectResult.successNoRecentWorkouts =>
        l10n.googleHealthConnectNoWorkouts,
      GoogleHealthConnectResult.success => l10n.googleHealthConnectSuccess,
      _ => l10n.googleHealthConnectFailed,
    };
  }

  String _intenseGpsClaimMessage(IntenseGpsClaimResult result) {
    final l10n = context.l10n;
    return switch (result) {
      IntenseGpsClaimResult.missingSerial => l10n.intenseGpsSerialRequired,
      IntenseGpsClaimResult.notFound => l10n.intenseGpsTrackerNotFound,
      IntenseGpsClaimResult.alreadyAssigned =>
        l10n.intenseGpsTrackerAlreadyAssigned,
      IntenseGpsClaimResult.missingEmail => l10n.intenseGpsMissingEmail,
      IntenseGpsClaimResult.unauthenticated =>
        l10n.appleHealthConnectAuthRequired,
      _ => l10n.intenseGpsConnectFailed,
    };
  }

  Future<void> _disconnect(WearableDeviceType type) async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = type.name);

    try {
      final ok = switch (type) {
        WearableDeviceType.whoop =>
          await WhoopSyncService.instance.disconnect(playerId: widget.playerId),
        WearableDeviceType.oura =>
          await OuraSyncService.instance.disconnect(playerId: widget.playerId),
        WearableDeviceType.strava => await StravaSyncService.instance
            .disconnect(playerId: widget.playerId),
        WearableDeviceType.polar =>
          await PolarSyncService.instance.disconnect(playerId: widget.playerId),
        WearableDeviceType.fitbit => await FitbitSyncService.instance
            .disconnect(playerId: widget.playerId),
        WearableDeviceType.appleHealth => await AppleHealthSyncService.instance
            .disconnect(playerId: widget.playerId),
        WearableDeviceType.googleHealthConnect =>
          await GoogleHealthSyncService.instance
              .disconnect(playerId: widget.playerId),
        WearableDeviceType.gpsInsidersIntense =>
          await IntenseGpsClaimService.instance
              .disconnect(playerId: widget.playerId),
      };
      if (!mounted) return;
      if (!ok) {
        final message = switch (type) {
          WearableDeviceType.whoop => context.l10n.whoopDisconnectFailed,
          WearableDeviceType.oura => context.l10n.ouraDisconnectFailed,
          WearableDeviceType.strava => context.l10n.stravaDisconnectFailed,
          WearableDeviceType.polar => context.l10n.polarDisconnectFailed,
          WearableDeviceType.fitbit => context.l10n.fitbitDisconnectFailed,
          WearableDeviceType.appleHealth =>
            context.l10n.appleHealthDisconnectFailed,
          WearableDeviceType.googleHealthConnect =>
            context.l10n.googleHealthDisconnectFailed,
          WearableDeviceType.gpsInsidersIntense =>
            context.l10n.intenseGpsDisconnectFailed,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _disconnectingType = null;
          if (_detailType == type) {
            _detailType = null;
          }
        });
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
        WearableDeviceType.oura =>
          connected
              ? l10n.ouraCoachConnectConnectedSubtitle(widget.playerName!)
              : l10n.ouraCoachConnectSubtitle(widget.playerName!),
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
        WearableDeviceType.gpsInsidersIntense =>
          connected
              ? l10n.intenseGpsConnectToggleConnectedSubtitle
              : l10n.intenseGpsSerialGuidance,
      };
    }
    return connected
        ? switch (type) {
            WearableDeviceType.gpsInsidersIntense =>
              l10n.intenseGpsConnectToggleConnectedSubtitle,
            _ => l10n.settingsDevicesConnectedStatus,
          }
        : switch (type) {
            WearableDeviceType.whoop => l10n.whoopConnectToggleSubtitle,
            WearableDeviceType.oura => l10n.ouraConnectToggleSubtitle,
            WearableDeviceType.strava => l10n.stravaConnectToggleSubtitle,
            WearableDeviceType.polar => l10n.polarConnectToggleSubtitle,
            WearableDeviceType.fitbit => l10n.fitbitConnectToggleSubtitle,
            WearableDeviceType.appleHealth =>
              l10n.appleHealthConnectToggleSubtitle,
            WearableDeviceType.googleHealthConnect =>
              l10n.googleHealthConnectToggleSubtitle,
            WearableDeviceType.gpsInsidersIntense =>
              l10n.intenseGpsSerialGuidance,
          };
  }

  String _connectSubtitle(WearableDeviceType type) {
    final l10n = context.l10n;
    if (widget.initiatedBy == 'coach' && widget.playerName != null) {
      return _statusSubtitle(type: type, connected: false);
    }
    return switch (type) {
      WearableDeviceType.whoop => l10n.whoopConnectToggleSubtitle,
      WearableDeviceType.oura => l10n.ouraConnectToggleSubtitle,
      WearableDeviceType.strava => l10n.stravaConnectToggleSubtitle,
      WearableDeviceType.polar => l10n.polarConnectToggleSubtitle,
      WearableDeviceType.fitbit => l10n.fitbitConnectToggleSubtitle,
      WearableDeviceType.appleHealth => l10n.appleHealthConnectToggleSubtitle,
      WearableDeviceType.googleHealthConnect =>
        l10n.googleHealthConnectToggleSubtitle,
      WearableDeviceType.gpsInsidersIntense => l10n.intenseGpsSerialGuidance,
    };
  }

  String _connectedTileSubtitle({
    required WearableDeviceType type,
    required _WearableDialogState state,
  }) {
    if (type == WearableDeviceType.googleHealthConnect &&
        (state.googleHealthConfig?.recentWorkoutCount ?? 0) <= 0) {
      return context.l10n.googleHealthConnectNoWorkoutsShort;
    }
    final base = _statusSubtitle(type: type, connected: true);
    final hint = switch (type) {
      WearableDeviceType.strava =>
        state.stravaConfig?.stravaAccountHint?.trim(),
      WearableDeviceType.whoop => state.whoopConfig?.whoopAccountHint?.trim(),
      WearableDeviceType.oura => state.ouraConfig?.ouraAccountHint?.trim(),
      WearableDeviceType.polar => state.polarConfig?.polarAccountHint?.trim(),
      WearableDeviceType.gpsInsidersIntense =>
        state.intenseGpsConfig?.serialNumber?.trim(),
      _ => null,
    };
    if (hint == null || hint.isEmpty) return base;
    return '$base · $hint';
  }

  Widget _buildAccountHintField({
    required AppColors colors,
    required AppLocalizations l10n,
    required TextEditingController controller,
    required String guidance,
    required String label,
    required String placeholder,
    required bool syncDisabled,
    TextInputType keyboardType = TextInputType.emailAddress,
  }) {
    final trimmedGuidance = guidance.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trimmedGuidance.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            trimmedGuidance,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: label,
            hintText: placeholder,
            labelStyle: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            hintStyle: TextStyle(
              color: colors.textSecondary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          onSubmitted: (_) {
            if (!_syncBusy && !syncDisabled) {
              _syncSelectedType();
            }
          },
        ),
      ],
    );
  }

  Stream<_WearableDialogState> _watchDialogState(String syncOwnerUid) {
    final controller = StreamController<_WearableDialogState>();
    WhoopSyncConfig? whoopConfig;
    OuraSyncConfig? ouraConfig;
    StravaSyncConfig? stravaConfig;
    PolarSyncConfig? polarConfig;
    FitbitSyncConfig? fitbitConfig;
    AppleHealthSyncConfig? appleHealthConfig;
    GoogleHealthSyncConfig? googleHealthConfig;
    IntenseGpsSyncConfig? intenseGpsConfig;

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        _WearableDialogState(
          whoopConfig: whoopConfig,
          ouraConfig: ouraConfig,
          stravaConfig: stravaConfig,
          polarConfig: polarConfig,
          fitbitConfig: fitbitConfig,
          appleHealthConfig: appleHealthConfig,
          googleHealthConfig: googleHealthConfig,
          intenseGpsConfig: intenseGpsConfig,
        ),
      );
    }

    final whoopSub = _whoopRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      whoopConfig = config;
      emit();
    });
    final ouraSub = _ouraRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      ouraConfig = config;
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
    final intenseGpsSub = _intenseGpsRepository
        .watchConfig(syncOwnerUid, widget.playerId)
        .listen((config) {
      intenseGpsConfig = config;
      emit();
    });

    controller.onCancel = () async {
      await whoopSub.cancel();
      await ouraSub.cancel();
      await stravaSub.cancel();
      await polarSub.cancel();
      await fitbitSub.cancel();
      await appleHealthSub.cancel();
      await googleHealthSub.cancel();
      await intenseGpsSub.cancel();
    };

    return controller.stream;
  }

  Widget? _coachVisibilityFor(
    WearableDeviceType type,
    _WearableDialogState state,
    String syncOwnerUid,
  ) {
    if (!widget.showCoachVisibility) return null;

    switch (type) {
      case WearableDeviceType.whoop:
        final config = state.whoopConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return WhoopCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility: config?.coachVisibility ?? const WhoopCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.oura:
        final config = state.ouraConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return OuraCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility: config?.coachVisibility ?? const OuraCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.strava:
        final config = state.stravaConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return StravaCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility: config?.coachVisibility ?? const StravaCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.polar:
        final config = state.polarConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return PolarCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility: config?.coachVisibility ?? const PolarCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.fitbit:
        final config = state.fitbitConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return FitbitCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility: config?.coachVisibility ?? const FitbitCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.appleHealth:
        final config = state.appleHealthConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return AppleHealthCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility:
              config?.coachVisibility ?? const AppleHealthCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.googleHealthConnect:
        final config = state.googleHealthConfig;
        if (config?.connected != true) return null;
        if (config?.initiatedBy != 'player' && config?.initiatedBy != null) {
          return null;
        }
        return GoogleHealthCoachVisibilitySection(
          uid: syncOwnerUid,
          playerId: widget.playerId,
          visibility:
              config?.coachVisibility ?? const GoogleHealthCoachVisibility(),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      case WearableDeviceType.gpsInsidersIntense:
        return null;
    }
  }

  List<WearableDeviceType> _connectedTypes(_WearableDialogState state) {
    final l10n = context.l10n;
    return [
      for (final type in WearableDeviceType.selectableSorted(l10n))
        if (_isConnected(type, state)) type,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || widget.playerId.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!_playerLoaded) {
      return ColoredBox(
        color: colors.card,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Player flow: sync docs live under the signed-in uid.
    // Coach flow: sync docs live under the member owner uid.
    final syncOwnerUid = widget.initiatedBy == 'coach'
        ? resolveWearableSyncOwnerUid(callerUid: uid, player: _player)
        : uid;

    return StreamBuilder<_WearableDialogState>(
      stream: _watchDialogState(syncOwnerUid),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const _WearableDialogState();
        final connectedTypes = _connectedTypes(state);
        final availableTypes = _availableTypes(state);

        final title = _page == _WearableDialogPage.add
            ? l10n.settingsDevicesAddTitle
            : l10n.settingsDevicesSection;

        return Scaffold(
          backgroundColor: colors.card,
          appBar: AppBar(
            backgroundColor: colors.card,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: _page == _WearableDialogPage.add
                ? IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: _backToList,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.textPrimary,
                    ),
                  )
                : null,
            title: Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.settingsDevicesClose),
              ),
            ],
          ),
          floatingActionButton: _page == _WearableDialogPage.list &&
                  availableTypes.isNotEmpty
              ? FloatingActionButton(
                  tooltip: l10n.settingsDevicesAddFabTooltip,
                  onPressed: () => _openAddPage(state),
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          body: _page == _WearableDialogPage.add
              ? _buildAddPage(
                  colors: colors,
                  l10n: l10n,
                  state: state,
                  connectedTypes: connectedTypes,
                )
              : _buildListPage(
                  colors: colors,
                  l10n: l10n,
                  state: state,
                  syncOwnerUid: syncOwnerUid,
                  connectedTypes: connectedTypes,
                  availableTypes: availableTypes,
                ),
        );
      },
    );
  }

  Widget _buildListPage({
    required AppColors colors,
    required AppLocalizations l10n,
    required _WearableDialogState state,
    required String syncOwnerUid,
    required List<WearableDeviceType> connectedTypes,
    required List<WearableDeviceType> availableTypes,
  }) {
    if (connectedTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settingsDevicesConnectedTitle,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Text(
                  l10n.settingsDevicesNoConnected,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
      children: [
        Text(
          l10n.settingsDevicesConnectedTitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < connectedTypes.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final type = connectedTypes[i];
              final coachVisibility = _coachVisibilityFor(
                type,
                state,
                syncOwnerUid,
              );
              final detailsExpanded = _detailType == type;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ConnectedWearableTile(
                    icon: type.icon,
                    title: type.label(l10n),
                    subtitle: _connectedTileSubtitle(
                      type: type,
                      state: state,
                    ),
                    disconnectLabel: l10n.settingsDevicesDisconnect,
                    disconnectBusy: _disconnectingType == type.name,
                    onDisconnect: () => _disconnect(type),
                    showDetailsButton: coachVisibility != null,
                    detailsExpanded: detailsExpanded,
                    onToggleDetails: coachVisibility == null
                        ? null
                        : () {
                            setState(() {
                              _detailType = detailsExpanded ? null : type;
                            });
                          },
                  ),
                  if (detailsExpanded && coachVisibility != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: coachVisibility,
                    ),
                ],
              );
            },
          ),
        ],
        if (availableTypes.isEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.settingsDevicesAllConnected,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddPage({
    required AppColors colors,
    required AppLocalizations l10n,
    required _WearableDialogState state,
    required List<WearableDeviceType> connectedTypes,
  }) {
    final allTypes = WearableDeviceType.selectableSorted(l10n);
    if (allTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedType = allTypes.contains(_selectedType)
        ? _selectedType
        : _defaultAddType(allTypes);
    if (selectedType != _selectedType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedType != selectedType) {
          setState(() => _selectedType = selectedType);
        }
      });
    }

    final selectedConnected = _isConnected(selectedType, state);
    final appleHealthIosOnly = selectedType == WearableDeviceType.appleHealth &&
        !isAppleHealthSupported;
    final googleHealthAndroidOnly =
        selectedType == WearableDeviceType.googleHealthConnect &&
            !isGoogleHealthConnectSupported;
    final platformOnlyMessage = appleHealthIosOnly
        ? l10n.appleHealthIosOnlyMessage
        : googleHealthAndroidOnly
            ? l10n.googleHealthAndroidOnlyMessage
            : null;
    // Joueur GPS is required to *sync* personal GPS later, not to claim the
    // serial in Réglages — so connect stays available without entitlement.
    final syncDisabled = appleHealthIosOnly || googleHealthAndroidOnly;
    final disconnectBusy = _disconnectingType == selectedType.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WearableDeviceTypeDropdown(
            value: selectedType,
            types: allTypes,
            connectedTypes: connectedTypes.toSet(),
            dense: true,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 12),
          Text(
            selectedConnected
                ? _statusSubtitle(type: selectedType, connected: true)
                : _connectSubtitle(selectedType),
            style: TextStyle(
              color: selectedConnected ? colors.success : colors.textSecondary,
              fontSize: 13,
              fontWeight: selectedConnected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (!selectedConnected && selectedType == WearableDeviceType.strava)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _stravaAccountController,
              guidance: l10n.stravaAccountHintGuidance,
              label: l10n.stravaAccountHintLabel,
              placeholder: l10n.stravaAccountHintPlaceholder,
              syncDisabled: syncDisabled,
            ),
          if (!selectedConnected && selectedType == WearableDeviceType.whoop)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _whoopAccountController,
              guidance: l10n.whoopAccountHintGuidance,
              label: l10n.whoopAccountHintLabel,
              placeholder: l10n.whoopAccountHintPlaceholder,
              syncDisabled: syncDisabled,
            ),
          if (!selectedConnected && selectedType == WearableDeviceType.oura)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _ouraAccountController,
              guidance: l10n.ouraAccountHintGuidance,
              label: l10n.ouraAccountHintLabel,
              placeholder: l10n.ouraAccountHintPlaceholder,
              syncDisabled: syncDisabled,
            ),
          if (!selectedConnected && selectedType == WearableDeviceType.polar)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _polarAccountController,
              guidance: l10n.polarAccountHintGuidance,
              label: l10n.polarAccountHintLabel,
              placeholder: l10n.polarAccountHintPlaceholder,
              syncDisabled: syncDisabled,
            ),
          // Guidance is already in [_connectSubtitle] — avoid duplicating it.
          if (!selectedConnected &&
              selectedType == WearableDeviceType.gpsInsidersIntense)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _intenseGpsSerialController,
              guidance: '',
              label: l10n.intenseGpsSerialLabel,
              placeholder: l10n.intenseGpsSerialPlaceholder,
              syncDisabled: syncDisabled,
              keyboardType: TextInputType.text,
            ),
          if (!selectedConnected && platformOnlyMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              platformOnlyMessage,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (selectedConnected)
            OutlinedButton.icon(
              onPressed: disconnectBusy
                  ? null
                  : () => _disconnect(selectedType),
              icon: disconnectBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                  : Icon(Icons.link_off_rounded, size: 20, color: colors.primary),
              label: Text(l10n.settingsDevicesDisconnect),
            )
          else
            ElevatedButton.icon(
              onPressed: _syncBusy || syncDisabled ? null : _syncSelectedType,
              icon: _syncBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link_rounded, size: 20),
              label: Text(
                switch (selectedType) {
                  WearableDeviceType.strava => l10n.stravaConnectContinue,
                  WearableDeviceType.whoop => l10n.whoopConnectContinue,
                  WearableDeviceType.oura => l10n.ouraConnectContinue,
                  WearableDeviceType.polar => l10n.polarConnectContinue,
                  _ => l10n.settingsDevicesSync,
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WearableDialogState {
  const _WearableDialogState({
    this.whoopConfig,
    this.ouraConfig,
    this.stravaConfig,
    this.polarConfig,
    this.fitbitConfig,
    this.appleHealthConfig,
    this.googleHealthConfig,
    this.intenseGpsConfig,
  });

  final WhoopSyncConfig? whoopConfig;
  final OuraSyncConfig? ouraConfig;
  final StravaSyncConfig? stravaConfig;
  final PolarSyncConfig? polarConfig;
  final FitbitSyncConfig? fitbitConfig;
  final AppleHealthSyncConfig? appleHealthConfig;
  final GoogleHealthSyncConfig? googleHealthConfig;
  final IntenseGpsSyncConfig? intenseGpsConfig;
}

class _ConnectedWearableTile extends StatelessWidget {
  const _ConnectedWearableTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.disconnectLabel,
    required this.disconnectBusy,
    required this.onDisconnect,
    this.showDetailsButton = false,
    this.detailsExpanded = false,
    this.onToggleDetails,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String disconnectLabel;
  final bool disconnectBusy;
  final VoidCallback onDisconnect;
  final bool showDetailsButton;
  final bool detailsExpanded;
  final VoidCallback? onToggleDetails;

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
          if (showDetailsButton && onToggleDetails != null)
            IconButton(
              tooltip: detailsExpanded
                  ? MaterialLocalizations.of(context).closeButtonTooltip
                  : MaterialLocalizations.of(context).moreButtonTooltip,
              onPressed: onToggleDetails,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                detailsExpanded
                    ? Icons.expand_less_rounded
                    : Icons.tune_rounded,
                color: colors.primary,
                size: 22,
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
