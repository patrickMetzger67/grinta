import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
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
  final StravaSyncRepository _stravaRepository = StravaSyncRepository();
  final PolarSyncRepository _polarRepository = PolarSyncRepository();
  final FitbitSyncRepository _fitbitRepository = FitbitSyncRepository();
  final AppleHealthSyncRepository _appleHealthRepository =
      AppleHealthSyncRepository();
  final GoogleHealthSyncRepository _googleHealthRepository =
      GoogleHealthSyncRepository();

  _WearableDialogPage _page = _WearableDialogPage.list;
  WearableDeviceType _selectedType = WearableDeviceType.strava;
  bool _syncBusy = false;
  String? _disconnectingType;
  final TextEditingController _stravaAccountController =
      TextEditingController();
  final TextEditingController _whoopAccountController =
      TextEditingController();

  @override
  void dispose() {
    _stravaAccountController.dispose();
    _whoopAccountController.dispose();
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

  void _openAddPage(_WearableDialogState state) {
    final available = _availableTypes(state);
    if (available.isEmpty) return;
    setState(() {
      _page = _WearableDialogPage.add;
      _selectedType = _defaultAddType(available);
    });
  }

  void _backToList() {
    setState(() => _page = _WearableDialogPage.list);
  }

  bool _isConnected(WearableDeviceType type, _WearableDialogState state) {
    return switch (type) {
      WearableDeviceType.whoop => state.whoopConfig?.connected == true,
      WearableDeviceType.strava => state.stravaConfig?.connected == true,
      WearableDeviceType.polar => state.polarConfig?.connected == true,
      WearableDeviceType.fitbit => state.fitbitConfig?.connected == true,
      WearableDeviceType.appleHealth =>
        state.appleHealthConfig?.connected == true,
      WearableDeviceType.googleHealthConnect =>
        state.googleHealthConfig?.connected == true,
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
          if (result == GoogleHealthConnectResult.success) {
            _backToList();
          } else {
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
          WearableDeviceType.appleHealth =>
            context.l10n.appleHealthConnectFailed,
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
      GoogleHealthConnectResult.androidOnly =>
        l10n.googleHealthAndroidOnlyMessage,
      GoogleHealthConnectResult.denied => l10n.googleHealthConnectDenied,
      GoogleHealthConnectResult.unauthenticated =>
        l10n.googleHealthConnectAuthRequired,
      _ => l10n.googleHealthConnectFailed,
    };
  }

  Future<void> _disconnect(WearableDeviceType type) async {
    if (_disconnectingType != null) return;

    setState(() => _disconnectingType = type.name);

    try {
      final ok = switch (type) {
        WearableDeviceType.whoop =>
          await WhoopSyncService.instance.disconnect(playerId: widget.playerId),
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
      };
      if (!mounted) return;
      if (!ok) {
        final message = switch (type) {
          WearableDeviceType.whoop => context.l10n.whoopDisconnectFailed,
          WearableDeviceType.strava => context.l10n.stravaDisconnectFailed,
          WearableDeviceType.polar => context.l10n.polarDisconnectFailed,
          WearableDeviceType.fitbit => context.l10n.fitbitDisconnectFailed,
          WearableDeviceType.appleHealth =>
            context.l10n.appleHealthDisconnectFailed,
          WearableDeviceType.googleHealthConnect =>
            context.l10n.googleHealthDisconnectFailed,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
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

  String _connectSubtitle(WearableDeviceType type) {
    final l10n = context.l10n;
    if (widget.initiatedBy == 'coach' && widget.playerName != null) {
      return _statusSubtitle(type: type, connected: false);
    }
    return switch (type) {
      WearableDeviceType.whoop => l10n.whoopConnectToggleSubtitle,
      WearableDeviceType.strava => l10n.stravaConnectToggleSubtitle,
      WearableDeviceType.polar => l10n.polarConnectToggleSubtitle,
      WearableDeviceType.fitbit => l10n.fitbitConnectToggleSubtitle,
      WearableDeviceType.appleHealth => l10n.appleHealthConnectToggleSubtitle,
      WearableDeviceType.googleHealthConnect =>
        l10n.googleHealthConnectToggleSubtitle,
    };
  }

  String _connectedTileSubtitle({
    required WearableDeviceType type,
    required _WearableDialogState state,
  }) {
    final base = _statusSubtitle(type: type, connected: true);
    final hint = switch (type) {
      WearableDeviceType.strava =>
        state.stravaConfig?.stravaAccountHint?.trim(),
      WearableDeviceType.whoop => state.whoopConfig?.whoopAccountHint?.trim(),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text(
          guidance,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
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

    final syncOwnerUid = WhoopSyncService.instance.syncOwnerUidForPlayer(
      uid: uid,
      playerId: widget.playerId,
    );

    return StreamBuilder<_WearableDialogState>(
      stream: _watchDialogState(syncOwnerUid),
      builder: (context, snapshot) {
        final state = snapshot.data ?? const _WearableDialogState();
        final connectedTypes = _connectedTypes(state);
        final availableTypes = _availableTypes(state);

        // After OAuth completes in the browser, return to the list.
        if (_page == _WearableDialogPage.add &&
            _isConnected(_selectedType, state)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _page == _WearableDialogPage.add) {
              _backToList();
            }
          });
        }

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
                  availableTypes: availableTypes,
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
          _ConnectedWearableTile(
            icon: connectedTypes[i].icon,
            title: connectedTypes[i].label(l10n),
            subtitle: _connectedTileSubtitle(
              type: connectedTypes[i],
              state: state,
            ),
            disconnectLabel: l10n.settingsDevicesDisconnect,
            disconnectBusy: _disconnectingType == connectedTypes[i].name,
            onDisconnect: () => _disconnect(connectedTypes[i]),
          ),
          Builder(
            builder: (context) {
              final coachVisibility = _coachVisibilityFor(
                connectedTypes[i],
                state,
                syncOwnerUid,
              );
              if (coachVisibility == null) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: coachVisibility,
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
    required List<WearableDeviceType> availableTypes,
  }) {
    if (availableTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          l10n.settingsDevicesAllConnected,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    final selectedType = availableTypes.contains(_selectedType)
        ? _selectedType
        : _defaultAddType(availableTypes);
    if (selectedType != _selectedType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedType != selectedType) {
          setState(() => _selectedType = selectedType);
        }
      });
    }

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
    final syncDisabled = appleHealthIosOnly || googleHealthAndroidOnly;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WearableDeviceTypeDropdown(
            value: selectedType,
            types: availableTypes,
            dense: true,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedType = value);
            },
          ),
          const SizedBox(height: 12),
          Text(
            _connectSubtitle(selectedType),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (selectedType == WearableDeviceType.strava)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _stravaAccountController,
              guidance: l10n.stravaAccountHintGuidance,
              label: l10n.stravaAccountHintLabel,
              placeholder: l10n.stravaAccountHintPlaceholder,
              syncDisabled: syncDisabled,
            ),
          if (selectedType == WearableDeviceType.whoop)
            _buildAccountHintField(
              colors: colors,
              l10n: l10n,
              controller: _whoopAccountController,
              guidance: l10n.whoopAccountHintGuidance,
              label: l10n.whoopAccountHintLabel,
              placeholder: l10n.whoopAccountHintPlaceholder,
              syncDisabled: syncDisabled,
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
          const SizedBox(height: 16),
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
