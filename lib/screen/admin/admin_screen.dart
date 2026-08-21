import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/screen/admin/admin_players_screen.dart';
import 'package:grinta/screen/admin/admin_promo_codes_screen.dart';
import 'package:grinta/screen/admin/admin_seasons_screen.dart';
import 'package:grinta/screen/admin/admin_stream_groups_screen.dart';
import 'package:grinta/screen/admin/admin_tracker_devices_screen.dart';
import 'package:grinta/screen/admin/admin_tracker_fields_screen.dart';
import 'package:grinta/screen/admin/admin_tracker_owners_screen.dart';
import 'package:grinta/screen/admin/admin_users_screen.dart';
import 'package:grinta/screen/admin/admin_youtube_screen.dart';
import 'package:grinta/util/app_theme.dart';

Future<void> openAdminScreen(BuildContext context) async {
  await Navigator.of(context, rootNavigator: true).push(
    analyticsMaterialRoute<void>(
      screenName: AnalyticsScreenNames.admin,
      builder: (_) => const AdminScreen(),
    ),
  );
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.adminSubtitle,
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          _AdminSectionCard(
            icon: Icons.people_outline,
            title: l10n.adminUsersSection,
            subtitle: l10n.adminUsersSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminUsers,
                  builder: (_) => const AdminUsersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.sports_soccer_outlined,
            title: l10n.adminPlayersSection,
            subtitle: l10n.adminPlayersSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminPlayers,
                  builder: (_) => const AdminPlayersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.local_offer_outlined,
            title: l10n.adminPromoCodesSection,
            subtitle: l10n.adminPromoCodesSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminPromoCodes,
                  builder: (_) => const AdminPromoCodesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.gps_fixed,
            title: l10n.adminTrackerOwnersSection,
            subtitle: l10n.adminTrackerOwnersSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminTrackerOwners,
                  builder: (_) => const AdminTrackerOwnersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.devices_outlined,
            title: l10n.adminTrackerDevicesSection,
            subtitle: l10n.adminTrackerDevicesSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminTrackerDevices,
                  builder: (_) => const AdminTrackerDevicesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.map_outlined,
            title: l10n.adminTrackerFieldsSection,
            subtitle: l10n.adminTrackerFieldsSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminTrackerFields,
                  builder: (_) => const AdminTrackerFieldsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.calendar_month_outlined,
            title: l10n.adminSeasonsSection,
            subtitle: l10n.adminSeasonsSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminSeasons,
                  builder: (_) => const AdminSeasonsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.forum_outlined,
            title: l10n.adminStreamGroupsSection,
            subtitle: l10n.adminStreamGroupsSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminStreamGroups,
                  builder: (_) => const AdminStreamGroupsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _AdminSectionCard(
            icon: Icons.ondemand_video_outlined,
            title: l10n.adminYoutubeSection,
            subtitle: l10n.adminYoutubeSectionDesc,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminYoutube,
                  builder: (_) => const AdminYoutubeScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
