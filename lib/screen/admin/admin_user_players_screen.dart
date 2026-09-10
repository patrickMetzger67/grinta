import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_player_hub_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/admin_player_sensor_icons.dart';
import 'package:grinta/widget/admin_user_avatar.dart';
import 'package:grinta/widget/member_search_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';

class AdminUserPlayersScreen extends StatefulWidget {
  const AdminUserPlayersScreen({
    super.key,
    required this.user,
    this.initialPlayers,
    this.playersStream,
    this.sensorService,
    this.playerPhotoBuilder,
  });

  final UserProfile user;

  /// Association list already known from the Utilisateurs row (no spinner).
  final List<Player>? initialPlayers;

  /// Overrides [PlayerService.streamPlayersByUserId] (widget tests).
  final Stream<List<Player>>? playersStream;

  final AdminPlayerSensorService? sensorService;

  @visibleForTesting
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  @override
  State<AdminUserPlayersScreen> createState() => _AdminUserPlayersScreenState();
}

class _AdminUserPlayersScreenState extends State<AdminUserPlayersScreen> {
  PlayerService? _playerService;
  AdminPlayerSensorService? _sensorService;
  bool _associating = false;

  Stream<List<Player>> get _playersStream =>
      widget.playersStream ??
      (_playerService ??= PlayerService())
          .streamPlayersByUserId(widget.user.uid);

  AdminPlayerSensorService get _effectiveSensorService =>
      widget.sensorService ??
      (_sensorService ??= AdminPlayerSensorService());

  Future<void> _associatePlayer(List<Player> linkedPlayers) async {
    if (_associating) return;

    final excludeIds = <String>{
      for (final player in linkedPlayers)
        if ((effectiveMemberId(player) ?? '').isNotEmpty)
          effectiveMemberId(player)!,
    };

    final selected = await showMemberSearchSheet(
      context,
      title: context.l10n.adminUsersAssociatePlayerTitle,
      excludeMemberIds: excludeIds,
      showCreateButton: false,
    );
    if (selected == null || !mounted) return;

    final memberId = effectiveMemberId(selected)?.trim() ?? '';
    if (memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminUsersAssociateFailed)),
      );
      return;
    }

    setState(() => _associating = true);
    try {
      await (_playerService ??= PlayerService()).adminAssociateUserToMember(
        memberId: memberId,
        uid: widget.user.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminUsersAssociateSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminUsersAssociateFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _associating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final user = widget.user;

    return StreamBuilder<List<Player>>(
      stream: _playersStream,
      initialData: widget.initialPlayers,
      builder: (context, snapshot) {
        final players = snapshot.data ?? const <Player>[];

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              l10n.adminUsersPlayersTitle(
                user.adminListLabel(noEmailLabel: l10n.adminNoEmail),
              ),
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _associating ? null : () => _associatePlayer(players),
            icon: _associating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.adminUsersAssociatePlayerFab),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Material(
                  color: colors.primary.withValues(alpha: 0.16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        AdminUserAvatar(user: user, radius: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.adminUsersEntityLabel,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.adminListLabel(
                                  noEmailLabel: l10n.adminNoEmail,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (user.adminEmailSubtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.adminEmailSubtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.adminUsersPlayersLoadError,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (players.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.adminUsersPlayersEmpty,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }

                    final sorted = [...players]..sort(
                        (a, b) => playerDisplayName(a)
                            .toLowerCase()
                            .compareTo(playerDisplayName(b).toLowerCase()),
                      );

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final player = sorted[index];
                        return _AdminLinkedPlayerCard(
                          player: player,
                          sensorService: _effectiveSensorService,
                          photo: widget.playerPhotoBuilder?.call(player, 24) ??
                              PlayerPhoto(player: player, radius: 24),
                          onOpenHub: () => AdminPlayerHubScreen.open(
                            context,
                            player: player,
                            sensorService: _effectiveSensorService,
                            playerPhotoBuilder: widget.playerPhotoBuilder,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminLinkedPlayerCard extends StatefulWidget {
  const _AdminLinkedPlayerCard({
    required this.player,
    required this.sensorService,
    required this.photo,
    required this.onOpenHub,
  });

  final Player player;
  final AdminPlayerSensorService sensorService;
  final Widget photo;
  final VoidCallback onOpenHub;

  @override
  State<_AdminLinkedPlayerCard> createState() => _AdminLinkedPlayerCardState();
}

class _AdminLinkedPlayerCardState extends State<_AdminLinkedPlayerCard> {
  AdminPlayerSensorFlags _flags = AdminPlayerSensorFlags.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadFlags());
    });
  }

  Future<void> _loadFlags() async {
    try {
      final flags = await widget.sensorService.loadFlags(widget.player);
      if (!mounted) return;
      setState(() => _flags = flags);
    } catch (_) {
      // Player row stays tappable even if indicators fail.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final firstName = (widget.player.firstName ?? '').trim();
    final lastName = (widget.player.lastName ?? '').trim();
    final name = [
      if (firstName.isNotEmpty) firstName,
      if (lastName.isNotEmpty) lastName,
    ].join(' ');
    final key = effectiveMemberId(widget.player)?.trim() ?? '';

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        key: ValueKey<String>('admin-linked-player-${key.isEmpty ? name : key}'),
        onTap: widget.onOpenHub,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              widget.photo,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name.isEmpty
                      ? playerDisplayName(widget.player, unknownLabel: '—')
                      : name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AdminPlayerSensorIcons(flags: _flags),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
