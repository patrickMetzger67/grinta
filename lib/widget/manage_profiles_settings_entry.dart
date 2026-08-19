import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/manage_profiles_screen.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/member_unsubscribe.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:provider/provider.dart';

/// Settings-menu entry to manage / leave linked profiles.
///
/// Hidden when the account is linked to fewer than two profiles.
class ManageProfilesListTile extends StatelessWidget {
  const ManageProfilesListTile({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        if (!canManageLinkedProfiles(appSession.currentUserPlayers.length)) {
          return const SizedBox.shrink();
        }

        return ListTile(
          leading: Icon(
            Icons.manage_accounts_outlined,
            color: colors.primary,
          ),
          title: Text(
            l10n.settingsManageProfiles,
            style: settingsMenuTitleStyle(context),
          ),
          onTap: onTap,
        );
      },
    );
  }
}

/// Sidebar button variant for web navigation.
class ManageProfilesSidebarButton extends StatelessWidget {
  const ManageProfilesSidebarButton({
    super.key,
    required this.onTap,
    required this.collapsed,
  });

  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return Consumer<AppSession>(
      builder: (context, appSession, _) {
        if (!canManageLinkedProfiles(appSession.currentUserPlayers.length)) {
          return const SizedBox.shrink();
        }

        if (collapsed) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Tooltip(
              message: l10n.settingsManageProfiles,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.manage_accounts_outlined,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.manage_accounts_outlined,
                    color: colors.primary,
                    size: kWebMenuIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.settingsManageProfiles,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: settingsMenuTitleStyle(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Opens the manage-profiles screen when the account has multiple profiles.
Future<void> openManageProfilesSettings(BuildContext context) {
  return openManageProfilesScreen(context);
}
