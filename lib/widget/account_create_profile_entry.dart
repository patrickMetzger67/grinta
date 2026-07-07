import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/services/subscription_limits_service.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/subscription_limits_access.dart';
import 'package:grinta/widget/settings_menu_style.dart';
import 'package:provider/provider.dart';

/// Account-menu entry to create an additional member profile.
class AccountCreateProfileListTile extends StatelessWidget {
  const AccountCreateProfileListTile({
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
        return ListenableBuilder(
          listenable: SubscriptionService.instance,
          builder: (context, _) {
            final profileCount = appSession.currentUserPlayers.length;
            final gate =
                SubscriptionLimitsService.instance.resolveProfileCreationGate(
              profileCount,
            );
            final showPremiumBadge = gate == ProfileCreationGate.needsUpgrade;

            return ListTile(
              leading: Icon(
                Icons.person_add_outlined,
                color: colors.primary,
              ),
              title: Text(
                l10n.actionCreateNewProfile,
                style: settingsMenuTitleStyle(context),
              ),
              trailing: showPremiumBadge
                  ? SubscriptionPremiumBadge(colors: colors)
                  : null,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}

/// Sidebar button variant for web navigation.
class AccountCreateProfileSidebarButton extends StatelessWidget {
  const AccountCreateProfileSidebarButton({
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
        return ListenableBuilder(
          listenable: SubscriptionService.instance,
          builder: (context, _) {
            final profileCount = appSession.currentUserPlayers.length;
            final gate =
                SubscriptionLimitsService.instance.resolveProfileCreationGate(
              profileCount,
            );
            final showPremiumBadge = gate == ProfileCreationGate.needsUpgrade;

            if (collapsed) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Tooltip(
                  message: l10n.actionCreateNewProfile,
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            color: colors.primary,
                            size: kWebMenuIconSize,
                          ),
                          if (showPremiumBadge)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: colors.warning,
                              ),
                            ),
                        ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        color: colors.primary,
                        size: kWebMenuIconSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.actionCreateNewProfile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: settingsMenuTitleStyle(context),
                        ),
                      ),
                      if (showPremiumBadge) ...[
                        const SizedBox(width: 8),
                        SubscriptionPremiumBadge(colors: colors, compact: true),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SubscriptionPremiumBadge extends StatelessWidget {
  const SubscriptionPremiumBadge({
    super.key,
    required this.colors,
    this.compact = false,
  });

  final AppColors colors;
  final bool compact;

  /// Small top-right marker for icon buttons (same placement as [NavIconCountBadge]).
  static Widget withIconOverlay({
    required BuildContext context,
    required AppColors colors,
    required Widget icon,
    required bool showPremium,
  }) {
    if (!showPremium) return icon;

    final l10n = context.l10n;
    return Tooltip(
      message: l10n.subscriptionLimitProfilePremiumBadge,
      child: Badge(
        label: Icon(
          Icons.workspace_premium_outlined,
          size: 9,
          color: colors.warning,
        ),
        backgroundColor: colors.warning.withValues(alpha: 0.22),
        padding: const EdgeInsets.all(2),
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconSize = compact ? 14.0 : 16.0;

    return Tooltip(
      message: l10n.subscriptionLimitProfilePremiumBadge,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: iconSize,
              color: colors.warning,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                l10n.subscriptionLimitProfilePremiumBadge,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.warning,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens the gated create-profile flow (limits + paywall + sheet).
Future<void> openAccountCreateProfileFlow(BuildContext context) {
  return SubscriptionLimitsAccess.openCreateProfileFlow(context);
}
