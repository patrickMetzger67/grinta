import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';

import '../../model/effectives.dart';
import '../../model/tracker/deviceOwner.dart';
import '../../model/training.dart';
import '../../services/deviceOwnerService.dart' as device_owner_svc;
import '../../util/app_theme.dart';

class TrainingTrackerContext {
  TrainingTrackerContext({
    required this.devicesByOwnerId,
    required this.ownerDeviceByDocId,
  });

  final Map<String, List<DeviceOwner>> devicesByOwnerId;
  final Map<String, DeviceOwner> ownerDeviceByDocId;

  static Future<TrainingTrackerContext?> loadForTraining(Training training) async {
    final ownerId = training.ownerId?.trim();
    if (training.withTracker != true || ownerId == null || ownerId.isEmpty) {
      return null;
    }

    final devices = await device_owner_svc.DeviceOwnerService().listByOwnerId(ownerId);
    devices.sort(compareDeviceOwnersByCustomName);
    final ownerDeviceByDocId = <String, DeviceOwner>{};
    for (final device in devices) {
      ownerDeviceByDocId[device.id] = device;
    }

    return TrainingTrackerContext(
      devicesByOwnerId: {ownerId: devices},
      ownerDeviceByDocId: ownerDeviceByDocId,
    );
  }

  void applyDefaultFromEffectives({
    required PlayerTraining playerTraining,
    Effectives? effectives,
    required String ownerId,
    required Set<String> devicesAffected,
  }) {
    if (playerTraining.deviceId != null && playerTraining.deviceId!.isNotEmpty) {
      devicesAffected.add(playerTraining.deviceId!);
      return;
    }

    final trackers = effectives?.trackers;
    if (trackers == null || trackers.isEmpty) return;

    for (final trackerDocId in trackers) {
      final device = ownerDeviceByDocId[trackerDocId];
      if (device == null) continue;
      if (devicesAffected.contains(device.id)) continue;

      playerTraining.deviceId = device.id;
      final name = device.customName?.trim();
      playerTraining.customName =
          (name != null && name.isNotEmpty) ? name : device.deviceId;
      devicesAffected.add(device.id);
      break;
    }
  }

  Set<String> collectAffectedDeviceIds(Iterable<PlayerTraining> players) {
    final affected = <String>{};
    for (final pt in players) {
      final id = pt.deviceId?.trim();
      if (id != null && id.isNotEmpty) {
        affected.add(id);
      }
    }
    return affected;
  }

  String displayLabel(PlayerTraining playerTraining) {
    final custom = playerTraining.customName?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final device = ownerDeviceByDocId[playerTraining.deviceId ?? ''];
    if (device != null) {
      final name = device.customName?.trim();
      if (name != null && name.isNotEmpty) return name;
      return device.deviceId;
    }
    return playerTraining.deviceId ?? '';
  }

  List<DeviceOwner> availableDevices(String ownerId, Set<String> devicesAffected) {
    final all = devicesByOwnerId[ownerId] ?? <DeviceOwner>[];
    final available = all
        .where((d) => !devicesAffected.contains(d.id))
        .toList();
    available.sort(compareDeviceOwnersByCustomName);
    return available;
  }
}

int compareDeviceOwnersByCustomName(DeviceOwner a, DeviceOwner b) {
  final aLabel = _deviceSortLabel(a);
  final bLabel = _deviceSortLabel(b);
  return aLabel.compareTo(bLabel);
}

String _deviceSortLabel(DeviceOwner device) {
  final custom = device.customName?.trim();
  if (custom != null && custom.isNotEmpty) {
    return custom.toLowerCase();
  }
  return device.deviceId.toLowerCase();
}

Future<DeviceOwner?> showAssignTrackerDialog({
  required BuildContext context,
  required List<DeviceOwner> availableDevices,
}) {
  final colors = context.appColors;
  final l10n = context.l10n;

  return showDialog<DeviceOwner>(
    context: context,
    builder: (ctx) {
      DeviceOwner? selected;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              l10n.trainingPlayersAssignTracker,
              style: TextStyle(color: colors.textPrimary),
            ),
            content: availableDevices.isEmpty
                ? Text(
                    l10n.trainingPlayersNoTrackerAvailable,
                    style: TextStyle(color: colors.textSecondary),
                  )
                : DropdownButtonFormField<DeviceOwner>(
                    value: selected,
                    isExpanded: true,
                    dropdownColor: colors.surface,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      labelText: l10n.trainingPlayersSelectTracker,
                      labelStyle: TextStyle(color: colors.textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.primary, width: 2),
                      ),
                    ),
                    items: availableDevices.map((d) {
                      final label = (d.customName != null &&
                              d.customName!.trim().isNotEmpty)
                          ? '${d.customName} (${d.deviceId})'
                          : d.deviceId;
                      return DropdownMenuItem(
                        value: d,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.textPrimary),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selected = val),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10n.actionCancel,
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: availableDevices.isEmpty || selected == null
                    ? null
                    : () => Navigator.of(ctx).pop(selected),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.actionValidate),
              ),
            ],
          );
        },
      );
    },
  );
}
