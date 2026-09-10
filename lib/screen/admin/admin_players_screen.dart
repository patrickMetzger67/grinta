import 'dart:async';

import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/screen/admin/admin_player_hub_screen.dart';
import 'package:grinta/services/admin_player_sensor_service.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/util/app_theme.dart';
import 'package:grinta/util/playerDisplayName.dart';
import 'package:grinta/util/player_photo_resolver.dart';

class AdminPlayersScreen extends StatefulWidget {
  const AdminPlayersScreen({
    super.key,
    this.membersStream,
    this.sensorService,
    this.playerPhotoBuilder,
  });

  /// Overrides [PlayerService.streamAllMembers] (widget tests).
  final Stream<List<Player>>? membersStream;

  /// Passed to the hub after tap. Never queried from the list/search path.
  final AdminPlayerSensorService? sensorService;

  /// Replaces the list avatar so widget tests can avoid Firebase.
  @visibleForTesting
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  static const searchFieldKey = ValueKey<String>('admin-players-search');
  static const searchDebounce = Duration(milliseconds: 180);

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _IndexedAdminPlayer {
  const _IndexedAdminPlayer({
    required this.player,
    required this.userCount,
  });

  final Player player;
  final int userCount;
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  PlayerService? _playerService;
  AdminPlayerSensorService? _sensorService;
  Timer? _debounce;
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  StreamSubscription<List<Player>>? _membersSub;
  bool _membersReady = false;
  Object? _membersError;
  List<_IndexedAdminPlayer> _indexedPlayers = const <_IndexedAdminPlayer>[];

  Stream<List<Player>> get _membersStream =>
      widget.membersStream ??
      (_playerService ??= PlayerService()).streamAllMembers();

  AdminPlayerSensorService _sensorForHub() =>
      widget.sensorService ?? (_sensorService ??= AdminPlayerSensorService());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _membersSub = _membersStream.listen(
      _onMembers,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _membersError = error;
          _membersReady = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _membersSub?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _query.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(AdminPlayersScreen.searchDebounce, () {
      if (!mounted) return;
      _query.value = _searchController.text;
    });
  }

  void _onMembers(List<Player> members) {
    if (!mounted) return;
    final indexed = members
        .map(
          (player) => _IndexedAdminPlayer(
            player: player,
            userCount: collectMemberLinkedUserIds(player).length,
          ),
        )
        .toList(growable: true)
      ..sort(
        (a, b) => playerDisplayName(a.player).toLowerCase().compareTo(
              playerDisplayName(b.player).toLowerCase(),
            ),
      );
    setState(() {
      _indexedPlayers = List<_IndexedAdminPlayer>.unmodifiable(indexed);
      _membersError = null;
      _membersReady = true;
    });
  }

  List<String> _queryTokens(String query) => playerSearchQueryTokens(query);

  bool _matchesPlayer(Player player, List<String> tokens) {
    if (tokens.isEmpty) return true;
    return tokens.every((token) => playerMatchesNameQuery(player, token));
  }

  /// Opens the hub immediately. Sensor flags / sessions stay off the list path.
  void _openPlayer(Player player) {
    unawaited(
      AdminPlayerHubScreen.open(
        context,
        player: player,
        sensorService: _sensorForHub(),
        playerPhotoBuilder: widget.playerPhotoBuilder,
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
          l10n.adminPlayersTitle,
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
            child: _AdminPlayersSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hintText: l10n.adminPlayersSearchHint,
              onClear: () {
                _searchController.clear();
                _query.value = '';
              },
            ),
          ),
          Expanded(
            child: _membersError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.adminPlayersLoadError,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : !_membersReady
                    ? const Center(child: CircularProgressIndicator())
                    : ValueListenableBuilder<String>(
                        valueListenable: _query,
                        builder: (context, query, _) {
                          final tokens = _queryTokens(query);
                          final players = _indexedPlayers
                              .where(
                                (row) => _matchesPlayer(row.player, tokens),
                              )
                              .toList(growable: false);

                          if (players.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  tokens.isEmpty
                                      ? l10n.adminPlayersEmpty
                                      : l10n.adminPlayersSearchEmpty,
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
                            itemCount: players.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final row = players[index];
                              final key = effectiveMemberId(row.player)?.trim();
                              return _AdminPlayerCard(
                                key: ValueKey<String>(
                                  'admin-player-card-${key ?? index}',
                                ),
                                player: row.player,
                                userCount: row.userCount,
                                photo: widget.playerPhotoBuilder
                                        ?.call(row.player, 24) ??
                                    _AdminPlayerListPhoto(
                                      player: row.player,
                                      radius: 24,
                                    ),
                                onTap: () => _openPlayer(row.player),
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
class _AdminPlayersSearchField extends StatefulWidget {
  const _AdminPlayersSearchField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final VoidCallback onClear;

  @override
  State<_AdminPlayersSearchField> createState() =>
      _AdminPlayersSearchFieldState();
}

class _AdminPlayersSearchFieldState extends State<_AdminPlayersSearchField> {
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
    final textTheme = Theme.of(context).textTheme;
    final hasQuery = widget.controller.text.trim().isNotEmpty;
    return TextField(
      key: AdminPlayersScreen.searchFieldKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: true,
      readOnly: false,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: textTheme.bodyLarge?.copyWith(
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: Icon(
          Icons.search,
          color: colors.textSecondary,
        ),
        suffixIcon: hasQuery
            ? IconButton(
                onPressed: widget.onClear,
                icon: const Icon(Icons.clear),
              )
            : null,
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Initials / already-http photo only. No Storage, Auth, or session work.
class _AdminPlayerListPhoto extends StatelessWidget {
  const _AdminPlayerListPhoto({
    required this.player,
    required this.radius,
  });

  final Player player;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photo = (player.photo ?? '').trim();
    final isNetwork =
        photo.startsWith('http://') || photo.startsWith('https://');
    final size = radius * 2;

    if (isNetwork) {
      return ClipOval(
        child: Image.network(
          photo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(colors),
        ),
      );
    }

    return _initials(colors);
  }

  Widget _initials(AppColors colors) {
    final first = (player.firstName ?? '').trim();
    final last = (player.lastName ?? '').trim();
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final initials = '$f$l'.isNotEmpty ? '$f$l' : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      child: Text(
        initials,
        style: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

class _AdminPlayerCard extends StatelessWidget {
  const _AdminPlayerCard({
    super.key,
    required this.player,
    required this.userCount,
    required this.photo,
    required this.onTap,
  });

  final Player player;
  final int userCount;
  final Widget photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final title = adminPlayerListLabel(
      player,
      noEmailLabel: l10n.adminNoEmail,
    );
    final email = (player.email ?? '').trim();
    final showEmail =
        email.isNotEmpty && email.toLowerCase() != title.toLowerCase();

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
              photo,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showEmail) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      l10n.adminPlayersUserCount(userCount),
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
