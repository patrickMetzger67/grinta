import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/util/app_theme.dart';

/// Team-kit / wearable icons for admin player rows (non-blocking decoration).
class AdminPlayerSensorIcons extends StatelessWidget {
  const AdminPlayerSensorIcons({
    super.key,
    required this.flags,
  });

  final AdminPlayerSensorFlags flags;

  @override
  Widget build(BuildContext context) {
    if (!flags.hasAny) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flags.hasTeamKitSensor)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: l10n.adminPlayerTeamKitSensorTooltip,
              child: Icon(
                Icons.sensors_rounded,
                color: colors.primary,
                size: 22,
              ),
            ),
          ),
        if (flags.hasConnectedDevices)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tooltip(
              message: l10n.adminPlayerConnectedDevicesTooltip,
              child: Icon(
                Icons.watch_outlined,
                color: colors.primary,
                size: 22,
              ),
            ),
          ),
      ],
    );
  }
}
