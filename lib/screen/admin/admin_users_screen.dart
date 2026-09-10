import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_user_players_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/services/password_reset_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/userService.dart';
import 'package:grinta/util/admin_player_association.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/widget/admin_user_avatar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
    this.usersStream,
    this.membersStream,
    this.sensorService,
    this.playerPhotoBuilder,
  });

  /// Overrides [UserService.streamUsers] (widget tests).
  final Stream<List<UserProfile>>? usersStream;

  /// Overrides [PlayerService.streamAllMembers] for list counts (widget tests).
  ///
  /// Counts come from this single snapshot — never per-row player queries.
  final Stream<List<Player>>? membersStream;

  final AdminPlayerSensorService? sensorService;
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  static const searchFieldKey = ValueKey<String>('admin-users-search');
  static const googleSignInKey = ValueKey<String>('admin-user-signin-google');
  static const appleSignInKey = ValueKey<String>('admin-user-signin-apple');
  static const passwordSignInKey =
      ValueKey<String>('admin-user-signin-password');

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  UserService? _userService;
  PlayerService? _playerService;
  PasswordResetService? _passwordResetService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  final ValueNotifier<String> _query = ValueNotifier<String>('');
  String? _resettingUid;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _query.value = _searchController.text;
    });
  }

  Stream<List<UserProfile>> get _usersStream =>
      widget.usersStream ?? (_userService ??= UserService()).streamUsers();

  Stream<List<Player>> get _membersStream =>
      widget.membersStream ??
      (_playerService ??= PlayerService()).streamAllMembers();

  Future<void> _openUserPlayers(
    UserProfile user, {
    List<Player>? initialPlayers,
  }) {
    return Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.adminUserPlayers,
        builder: (_) => AdminUserPlayersScreen(
          user: user,
          initialPlayers: initialPlayers,
          sensorService: widget.sensorService,
          playerPhotoBuilder: widget.playerPhotoBuilder,
        ),
      ),
    );
  }

  Future<void> _renewPassword(UserProfile user) async {
    final email = user.email.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.adminUsersPasswordResetNoEmail)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.adminUsersPasswordResetConfirmTitle),
          content: Text(l10n.adminUsersPasswordResetConfirmMessage(email)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.adminUsersPasswordResetConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resettingUid = user.uid);
    try {
      final locale = Localizations.localeOf(context).languageCode;
      final result = await (_passwordResetService ??= PasswordResetService())
          .sendResetEmail(
        email: email,
        locale: locale,
      );
      if (!mounted) return;

      final message = switch (result) {
        PasswordResetResult.sent => context.l10n.adminUsersPasswordResetSent,
        PasswordResetResult.invalidEmail =>
          context.l10n.adminUsersPasswordResetInvalidEmail,
        PasswordResetResult.userNotFound =>
          context.l10n.adminUsersPasswordResetUserNotFound,
        PasswordResetResult.failed =>
          context.l10n.adminUsersPasswordResetFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _resettingUid = null);
      }
    }
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
            child: _AdminUsersSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: l10n.adminUsersSearchHint,
              labelText: l10n.adminUsersSearchHint,
              onClear: () {
                _searchController.clear();
                _query.value = '';
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _usersStream,
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

                return StreamBuilder<List<Player>>(
                  stream: _membersStream,
                  builder: (context, membersSnapshot) {
                    final members = membersSnapshot.data ?? const <Player>[];
                    final counts = adminPlayerCountsByUserId(members);

                    return ValueListenableBuilder<String>(
                      valueListenable: _query,
                      builder: (context, query, _) {
                        final users =
                            (usersSnapshot.data ?? const <UserProfile>[])
                                .where((user) => user.isListedInAdminUsers)
                                .where((user) => user.matchesSearch(query))
                                .toList(growable: false);

                        if (users.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                query.trim().isEmpty
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

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _AdminUserCard(
                              user: user,
                              playerCount: counts[user.uid] ?? 0,
                              isResetting: _resettingUid == user.uid,
                              onTap: () => _openUserPlayers(
                                user,
                                initialPlayers: adminPlayersLinkedToUser(
                                  members,
                                  user.uid,
                                ),
                              ),
                              onRenewPassword: () => _renewPassword(user),
                            );
                          },
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

/// Owns its own [setState] for the clear suffix so list rebuilds cannot
/// recreate the search [TextField] or steal focus while typing.
class _AdminUsersSearchField extends StatefulWidget {
  const _AdminUsersSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.labelText,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final String labelText;
  final VoidCallback onClear;

  @override
  State<_AdminUsersSearchField> createState() => _AdminUsersSearchFieldState();
}

class _AdminUsersSearchFieldState extends State<_AdminUsersSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasQuery = widget.controller.text.trim().isNotEmpty;
    return TextField(
      key: AdminUsersScreen.searchFieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: true,
      readOnly: false,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasQuery
            ? IconButton(
                onPressed: widget.onClear,
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.playerCount,
    required this.isResetting,
    required this.onTap,
    required this.onRenewPassword,
  });

  final UserProfile user;
  final int playerCount;
  final bool isResetting;
  final VoidCallback onTap;
  final VoidCallback onRenewPassword;

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
                      user.adminListLabel(noNameLabel: l10n.adminNoName),
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
                    if (user.signedInWithGoogle ||
                        user.signedInWithApple ||
                        user.signedInWithPassword) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (user.signedInWithGoogle)
                            _SignInProviderBadge(
                              badgeKey: AdminUsersScreen.googleSignInKey,
                              label: l10n.adminUsersSignInGoogle,
                              assetPath: 'assets/images/google_logo.svg',
                              tintAsset: false,
                            ),
                          if (user.signedInWithApple)
                            _SignInProviderBadge(
                              badgeKey: AdminUsersScreen.appleSignInKey,
                              label: l10n.adminUsersSignInApple,
                              assetPath: 'assets/images/apple_logo.svg',
                              tintAsset: true,
                            ),
                          if (user.signedInWithPassword &&
                              !user.signedInWithGoogle &&
                              !user.signedInWithApple)
                            _SignInProviderBadge(
                              badgeKey: AdminUsersScreen.passwordSignInKey,
                              label: l10n.adminUsersSignInPassword,
                              icon: Icons.mail_outline_rounded,
                            ),
                        ],
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
              IconButton(
                tooltip: l10n.adminUsersPasswordResetTooltip,
                onPressed: isResetting ? null : onRenewPassword,
                icon: isResetting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    : Icon(
                        Icons.lock_reset_outlined,
                        color: colors.primary,
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

class _SignInProviderBadge extends StatelessWidget {
  const _SignInProviderBadge({
    required this.badgeKey,
    required this.label,
    this.assetPath,
    this.tintAsset = false,
    this.icon,
  });

  final Key badgeKey;
  final String label;
  final String? assetPath;
  final bool tintAsset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final iconColor = colors.textPrimary;

    Widget leading;
    if (assetPath != null) {
      leading = SvgPicture.asset(
        assetPath!,
        width: 14,
        height: 14,
        colorFilter:
            tintAsset ? ColorFilter.mode(iconColor, BlendMode.srcIn) : null,
      );
    } else {
      leading = Icon(icon, size: 14, color: iconColor);
    }

    return Container(
      key: badgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
