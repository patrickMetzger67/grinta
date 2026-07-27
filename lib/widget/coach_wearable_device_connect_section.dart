import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/wearable_devices_access.dart';
import 'package:grinta/util/wearable_sync_owner.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';

/// Coach trackers sheet row that opens the wearable devices dialog.
class CoachWearableDeviceConnectSection extends StatefulWidget {
  const CoachWearableDeviceConnectSection({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  final String playerId;
  final String playerName;

  @override
  State<CoachWearableDeviceConnectSection> createState() =>
      _CoachWearableDeviceConnectSectionState();
}

class _CoachWearableDeviceConnectSectionState
    extends State<CoachWearableDeviceConnectSection> {
  late final Future<Player?> _playerFuture;
  final WearableDevicesRepository _repository = WearableDevicesRepository();

  @override
  void initState() {
    super.initState();
    _playerFuture = PlayerService().getPlayerById(widget.playerId.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final trimmedPlayerId = widget.playerId.trim();

    if (uid == null || trimmedPlayerId.isEmpty) {
      return const SizedBox.shrink();
    }

    void openDialog() {
      openWearableDevicesFromTap(
        context,
        playerId: trimmedPlayerId,
        initiatedBy: 'coach',
        playerName: widget.playerName,
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        SubscriptionService.instance,
        UserTrialService.instance,
      ]),
      builder: (context, _) {
        final showPremiumBadge =
            !UserTrialService.instance.hasPremiumAccess;

        return FutureBuilder<Player?>(
          future: _playerFuture,
          builder: (context, playerSnapshot) {
            final syncOwnerUid = resolveWearableSyncOwnerUid(
              callerUid: uid,
              player: playerSnapshot.data,
            );

            return StreamBuilder<int>(
              stream:
                  _repository.watchConnectedCount(syncOwnerUid, trimmedPlayerId),
              builder: (context, snapshot) {
                final connectedCount = snapshot.data ?? 0;
                final badgeLabel =
                    l10n.settingsDevicesBadgeLabel(connectedCount);

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            SubscriptionPremiumBadge.withIconOverlay(
                              context: context,
                              colors: colors,
                              showPremium: showPremiumBadge,
                              icon: NavIconCountBadge(
                                icon: Icons.watch_outlined,
                                count: connectedCount,
                                iconColor: colors.primary,
                                iconSize: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.settingsDevicesSection,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (showPremiumBadge) ...[
                              SubscriptionPremiumBadge(
                                colors: colors,
                                compact: true,
                              ),
                              const SizedBox(width: 8),
                            ],
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
          },
        );
      },
    );
  }
}
