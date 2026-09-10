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
import 'package:grinta/widget/playerPhoto.dart';

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

  /// Replaces [PlayerPhoto] so widget tests can avoid Firebase.
  @visibleForTesting
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  static const searchFieldKey = ValueKey<String>('admin-players-search');

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  PlayerService? _playerService;
  AdminPlayerSensorService? _sensorService;
  Timer? _debounce;
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  Stream<List<Player>> get _membersStream =>
      widget.membersStream ??
      (_playerService ??= PlayerService()).streamAllMembers();

  AdminPlayerSensorService _sensorForHub() =>
      widget.sensorService ??
      (_sensorService ??= AdminPlayerSensorService());

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
            child: StreamBuilder<List<Player>>(
              stream: _membersStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
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
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ValueListenableBuilder<String>(
                  valueListenable: _query,
                  builder: (context, query, _) {
                    final tokens = _queryTokens(query);
                    final players = (snapshot.data ?? const <Player>[])
                        .where((player) => _matchesPlayer(player, tokens))
                        .toList(growable: false)
                      ..sort(
                        (a, b) => playerDisplayName(a).toLowerCase().compareTo(
                              playerDisplayName(b).toLowerCase(),
                            ),
                      );

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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final userCount =
                            collectMemberLinkedUserIds(player).length;
                        final key = effectiveMemberId(player)?.trim();
                        return _AdminPlayerCard(
                          key: ValueKey<String>(
                            'admin-player-card-${key ?? index}',
                          ),
                          player: player,
                          userCount: userCount,
                          photo: widget.playerPhotoBuilder?.call(player, 24) ??
                              PlayerPhoto(player: player, radius: 24),
                          onTap: () => _openPlayer(player),
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
