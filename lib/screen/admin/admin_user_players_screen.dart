import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/admin_user_avatar.dart';
import 'package:grinta/widget/member_search_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';

class AdminUserPlayersScreen extends StatefulWidget {
  const AdminUserPlayersScreen({
    super.key,
    required this.user,
  });

  final UserProfile user;

  @override
  State<AdminUserPlayersScreen> createState() => _AdminUserPlayersScreenState();
}

class _AdminUserPlayersScreenState extends State<AdminUserPlayersScreen> {
  final PlayerService _playerService = PlayerService();
  bool _associating = false;

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
      await _playerService.adminAssociateUserToMember(
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
      stream: _playerService.streamPlayersByUserId(user.uid),
      builder: (context, snapshot) {
        final players = snapshot.data ?? const <Player>[];

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              l10n.adminUsersPlayersTitle(user.displayName),
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
                  color: colors.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.border),
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
                                user.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (user.email.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user.email.trim(),
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
                        return _AdminLinkedPlayerCard(player: player);
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

class _AdminLinkedPlayerCard extends StatelessWidget {
  const _AdminLinkedPlayerCard({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final firstName = (player.firstName ?? '').trim();
    final lastName = (player.lastName ?? '').trim();
    final name = [
      if (firstName.isNotEmpty) firstName,
      if (lastName.isNotEmpty) lastName,
    ].join(' ');

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            PlayerPhoto(player: player, radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name.isEmpty
                    ? playerDisplayName(player, unknownLabel: '—')
                    : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
