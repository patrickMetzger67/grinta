import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_player_sessions_screen.dart';
import 'package:grinta/screen/admin/admin_player_users_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/widget/playerPhoto.dart';

/// Admin hub for one player: linked users + optional session history.
class AdminPlayerHubScreen extends StatefulWidget {
  const AdminPlayerHubScreen({
    super.key,
    required this.player,
    this.flags = AdminPlayerSensorFlags.none,
    this.sensorService,
    this.playerPhotoBuilder,
  });

  final Player player;
  final AdminPlayerSensorFlags flags;
  final AdminPlayerSensorService? sensorService;
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  static const usersTileKey = ValueKey<String>('admin-player-hub-users');
  static const sessionsTileKey = ValueKey<String>('admin-player-hub-sessions');

  @override
  State<AdminPlayerHubScreen> createState() => _AdminPlayerHubScreenState();
}

class _AdminPlayerHubScreenState extends State<AdminPlayerHubScreen> {
  late AdminPlayerSensorFlags _flags;

  @override
  void initState() {
    super.initState();
    _flags = widget.flags;
    if (!_flags.hasAny && widget.sensorService != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_refreshFlags());
      });
    }
  }

  Future<void> _refreshFlags() async {
    final service = widget.sensorService;
    if (service == null) return;
    try {
      final flags = await service.loadFlags(widget.player);
      if (!mounted) return;
      setState(() => _flags = flags);
    } catch (_) {
      // Keep the hub usable even if indicators fail to load.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final player = widget.player;
    final name = playerDisplayName(player, unknownLabel: '—');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          name,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            children: [
              widget.playerPhotoBuilder?.call(player, 28) ??
                  PlayerPhoto(player: player, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_flags.hasAny) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_flags.hasTeamKitSensor)
                            _FlagChip(
                              icon: Icons.sensors_rounded,
                              label: l10n.adminPlayerTeamKitSensorLabel,
                            ),
                          if (_flags.hasConnectedDevices)
                            _FlagChip(
                              icon: Icons.watch_outlined,
                              label: l10n.adminPlayerConnectedDevicesLabel,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HubTile(
            key: AdminPlayerHubScreen.usersTileKey,
            icon: Icons.group_outlined,
            title: l10n.adminPlayerHubUsersTitle,
            subtitle: l10n.adminPlayerHubUsersSubtitle,
            onTap: () {
              Navigator.of(context).push(
                analyticsMaterialRoute<void>(
                  screenName: AnalyticsScreenNames.adminPlayerUsers,
                  builder: (_) => AdminPlayerUsersScreen(player: player),
                ),
              );
            },
          ),
          if (_flags.hasAny) ...[
            const SizedBox(height: 10),
            _HubTile(
              key: AdminPlayerHubScreen.sessionsTileKey,
              icon: Icons.timeline_outlined,
              title: l10n.adminPlayerHubSessionsTitle,
              subtitle: l10n.adminPlayerHubSessionsSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  analyticsMaterialRoute<void>(
                    screenName: AnalyticsScreenNames.adminPlayerSessions,
                    builder: (_) => AdminPlayerSessionsScreen(
                      player: player,
                      flags: _flags,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    super.key,
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
              Icon(icon, color: colors.primary),
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
