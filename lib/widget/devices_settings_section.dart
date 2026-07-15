import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/wearable_devices_repository.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/nav_icon_count_badge.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:grinta/widget/wearable_devices_dialog.dart';
import 'package:provider/provider.dart';

/// Settings row that opens the wearable devices dialog.
class DevicesSettingsSection extends StatelessWidget {
  const DevicesSettingsSection({
    super.key,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.webCardStyle = false,
  });

  final EdgeInsetsGeometry contentPadding;
  final bool webCardStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final playerId = context.select<AppSession, String?>(
      (session) => session.selectedPlayerId,
    );

    if (uid == null || playerId == null) {
      return const SizedBox.shrink();
    }

    final repository = WearableDevicesRepository();

    void openDialog() {
      showWearableDevicesDialog(
        context,
        playerId: playerId,
        initiatedBy: 'player',
        showCoachVisibility: true,
      );
    }

    return StreamBuilder<int>(
      stream: repository.watchConnectedCount(uid, playerId),
      builder: (context, snapshot) {
        final connectedCount = snapshot.data ?? 0;
        final badgeLabel = l10n.settingsDevicesBadgeLabel(connectedCount);

        if (webCardStyle) {
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
                        NavIconCountBadge(
                          icon: Icons.watch_outlined,
                          count: connectedCount,
                          iconColor: colors.primary,
                          iconSize: kWebMenuIconSize,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.settingsDevicesSection,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: settingsMenuTitleStyle(context),
                          ),
                        ),
                        CountBadgeLabel(count: connectedCount),
                        const SizedBox(width: 8),
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
            contentPadding: contentPadding,
            leading: NavIconCountBadge(
              icon: Icons.watch_outlined,
              count: connectedCount,
              iconColor: colors.primary,
            ),
            title: Text(
              l10n.settingsDevicesSection,
              style: settingsMenuTitleStyle(context),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountBadgeLabel(count: connectedCount),
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
  }
}
