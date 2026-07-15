import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:grinta/widget/wearable_devices_dialog.dart';

/// Coach trackers sheet row that opens the wearable devices dialog.
class CoachWearableDeviceConnectSection extends StatelessWidget {
  const CoachWearableDeviceConnectSection({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  final String playerId;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final trimmedPlayerId = playerId.trim();

    if (uid == null || trimmedPlayerId.isEmpty) {
      return const SizedBox.shrink();
    }

    final repository = WearableDevicesRepository();

    void openDialog() {
      showWearableDevicesDialog(
        context,
        playerId: trimmedPlayerId,
        initiatedBy: 'coach',
        playerName: playerName,
      );
    }

    return StreamBuilder<int>(
      stream: repository.watchConnectedCount(uid, trimmedPlayerId),
      builder: (context, snapshot) {
        final connectedCount = snapshot.data ?? 0;
        final badgeLabel = l10n.settingsDevicesBadgeLabel(connectedCount);

        return Semantics(
          button: true,
          label: badgeLabel,
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: openDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    NavIconCountBadge(
                      icon: Icons.watch_outlined,
                      count: connectedCount,
                      iconColor: colors.primary,
                      iconSize: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.settingsDevicesSection,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    CountBadgeLabel(count: connectedCount),
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
      },
    );
  }
}
