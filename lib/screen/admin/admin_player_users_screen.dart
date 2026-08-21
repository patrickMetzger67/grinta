import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/admin_user_avatar.dart';
import 'package:grinta/widget/admin_user_search_sheet.dart';
import 'package:grinta/widget/playerPhoto.dart';

class AdminPlayerUsersScreen extends StatefulWidget {
  const AdminPlayerUsersScreen({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  State<AdminPlayerUsersScreen> createState() => _AdminPlayerUsersScreenState();
}

class _AdminPlayerUsersScreenState extends State<AdminPlayerUsersScreen> {
  final PlayerService _playerService = PlayerService();
  final UserService _userService = UserService();
  bool _associating = false;

  String? get _memberId => effectiveMemberId(widget.player);

  Future<void> _addUser(Set<String> linkedUserIds) async {
    if (_associating) return;

    final memberId = _memberId?.trim() ?? '';
    if (memberId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminPlayersAssociateFailed)),
      );
      return;
    }

    final selected = await showAdminUserSearchSheet(
      context,
      title: context.l10n.adminPlayersAddUserTitle,
      excludeUserIds: linkedUserIds,
    );
    if (selected == null || !mounted) return;

    setState(() => _associating = true);
    try {
      await _playerService.adminAssociateUserToMember(
        memberId: memberId,
        uid: selected.uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminPlayersAssociateSuccess)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminPlayersAssociateFailed)),
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
    final player = widget.player;
    final memberId = _memberId?.trim() ?? '';

    final liveStream = memberId.isEmpty
        ? Stream<Player?>.value(player)
        : _playerService.streamPlayerById(memberId);

    return StreamBuilder<Player?>(
      stream: liveStream,
      initialData: player,
      builder: (context, playerSnapshot) {
        final current = playerSnapshot.data ?? player;
        final linkedIds = collectMemberLinkedUserIds(current);

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              l10n.adminPlayersUsersTitle,
              style: textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _associating ? null : () => _addUser(linkedIds),
            icon: _associating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_outlined),
            label: Text(l10n.adminPlayersAddUserFab),
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
                        PlayerPhoto(player: current, radius: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerDisplayName(
                                  current,
                                  unknownLabel: '—',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((current.email ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  current.email!.trim(),
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
                child: linkedIds.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l10n.adminPlayersUsersEmpty,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : StreamBuilder<List<UserProfile>>(
                        stream: _userService.streamUsers(),
                        builder: (context, usersSnapshot) {
                          if (usersSnapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  l10n.adminPlayersUsersLoadError,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          if (usersSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !usersSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final byId = <String, UserProfile>{
                            for (final user
                                in usersSnapshot.data ?? const <UserProfile>[])
                              user.uid: user,
                          };

                          final linkedUsers = linkedIds
                              .map(
                                (uid) =>
                                    byId[uid] ??
                                    UserProfile(
                                      uid: uid,
                                      firstName: '',
                                      lastName: '',
                                      email: uid,
                                    ),
                              )
                              .toList(growable: false)
                            ..sort(
                              (a, b) => a.displayName.toLowerCase().compareTo(
                                    b.displayName.toLowerCase(),
                                  ),
                            );

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                            itemCount: linkedUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final user = linkedUsers[index];
                              return _AdminLinkedUserCard(user: user);
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

class _AdminLinkedUserCard extends StatelessWidget {
  const _AdminLinkedUserCard({required this.user});

  final UserProfile user;

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AdminUserAvatar(user: user, radius: 24),
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
                      fontWeight: FontWeight.w600,
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
    );
  }
}
