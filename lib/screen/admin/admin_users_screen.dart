import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_user_players_screen.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/widget/admin_user_avatar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService _userService = UserService();
  final PlayerService _playerService = PlayerService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text);
    });
  }

  Map<String, int> _playerCountsByUserId(List<Player> members) {
    final counts = <String, int>{};
    for (final player in members) {
      for (final uid in collectMemberLinkedUserIds(player)) {
        counts[uid] = (counts[uid] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> _openUserPlayers(UserProfile user) {
    return Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.adminUserPlayers,
        builder: (_) => AdminUserPlayersScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          l10n.adminUsersTitle,
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.adminUsersSearchHint,
                hintText: l10n.adminUsersSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _userService.streamUsers(),
              builder: (context, usersSnapshot) {
                if (usersSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.adminUsersLoadError,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                if (usersSnapshot.connectionState == ConnectionState.waiting &&
                    !usersSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = (usersSnapshot.data ?? const <UserProfile>[])
                    .where((user) => user.matchesSearch(_query))
                    .toList(growable: false);

                if (users.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.trim().isEmpty
                            ? l10n.adminUsersEmpty
                            : l10n.adminUsersSearchEmpty,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return StreamBuilder<List<Player>>(
                  stream: _playerService.streamAllMembers(),
                  builder: (context, membersSnapshot) {
                    final counts = _playerCountsByUserId(
                      membersSnapshot.data ?? const <Player>[],
                    );

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _AdminUserCard(
                          user: user,
                          playerCount: counts[user.uid] ?? 0,
                          onTap: () => _openUserPlayers(user),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.playerCount,
    required this.onTap,
  });

  final UserProfile user;
  final int playerCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              AdminUserAvatar(user: user, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayFirstName,
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
                    const SizedBox(height: 6),
                    Text(
                      l10n.adminUsersPlayerCount(playerCount),
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
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
