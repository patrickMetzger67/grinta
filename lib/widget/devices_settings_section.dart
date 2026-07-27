import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/user_trial_service.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/services/whoop_sync_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/wearable_devices_access.dart';
import 'package:grinta/widget/account_create_profile_entry.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:provider/provider.dart';

/// Settings row that opens the wearable devices dialog (premium-gated).
class DevicesSettingsSection extends StatefulWidget {
  const DevicesSettingsSection({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  State<DevicesSettingsSection> createState() => _DevicesSettingsSectionState();
}

class _DevicesSettingsSectionState extends State<DevicesSettingsSection> {
  final WearableDevicesRepository _repository = WearableDevicesRepository();
  String? _repairedPlayerId;

  Future<void> _repairIfNeeded(String playerId) async {
    if (_repairedPlayerId == playerId) return;
    _repairedPlayerId = playerId;
    // Legacy Whoop docs may live under member.userID; move onto auth uid.
    await WhoopSyncService.instance.repairPlayerSync(playerId: playerId);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final player = context.select<AppSession, Player?>(
      (session) => session.selectedPlayer,
    );
    final playerId = (player != null ? effectiveMemberId(player) : null) ??
        context.select<AppSession, String?>(
          (session) => session.selectedPlayerId,
        );

    if (uid == null || playerId == null || playerId.isEmpty) {
      return const SizedBox.shrink();
    }

    // Player settings always watch the signed-in account (OAuth stores here).
    if (_repairedPlayerId != playerId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _repairIfNeeded(playerId);
      });
    }

    void openDialog() {
      openWearableDevicesFromTap(
        context,
        playerId: playerId,
        initiatedBy: 'player',
        showCoachVisibility: true,
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

        return StreamBuilder<int>(
          stream: _repository.watchConnectedCount(uid, playerId),
          builder: (context, snapshot) {
            final connectedCount = snapshot.data ?? 0;
            final badgeLabel = l10n.settingsDevicesBadgeLabel(connectedCount);
            final leading = SubscriptionPremiumBadge.withIconOverlay(
              context: context,
              colors: colors,
              showPremium: showPremiumBadge,
              icon: NavIconCountBadge(
                icon: Icons.watch_outlined,
                count: connectedCount,
                iconColor: colors.primary,
                iconSize: widget.webCardStyle ? kWebMenuIconSize : 24,
              ),
            );

            if (widget.webCardStyle) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Semantics(
                  button: true,
                  label: badgeLabel,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: openDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            leading,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.settingsDevicesSection,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: settingsMenuTitleStyle(context),
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
                              size: kWebMenuIconSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Semantics(
              button: true,
              label: badgeLabel,
              child: ListTile(
                contentPadding: widget.contentPadding,
                leading: leading,
                title: Text(
                  l10n.settingsDevicesSection,
                  style: settingsMenuTitleStyle(context),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                onTap: openDialog,
              ),
            );
          },
        );
      },
    );
  }
}
