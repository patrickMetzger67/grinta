import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/model/admin_player_sensor_flags.dart';
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

  /// Overrides the default sensor-flag loader (widget tests).
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
  String _query = '';

  Stream<List<Player>> get _membersStream =>
      widget.membersStream ??
      (_playerService ??= PlayerService()).streamAllMembers();

  AdminPlayerSensorService get _effectiveSensorService =>
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
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = _searchController.text);
    });
  }

  List<String> _queryTokens(String query) => playerSearchQueryTokens(query);

  bool _matchesPlayer(Player player, List<String> tokens) {
    if (tokens.isEmpty) return true;
    return tokens.every((token) => playerMatchesNameQuery(player, token));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final tokens = _queryTokens(_query);

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
            child: TextField(
              key: AdminPlayersScreen.searchFieldKey,
              controller: _searchController,
              focusNode: _searchFocusNode,
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
                hintText: l10n.adminPlayersSearchHint,
                prefixIcon: Icon(
                  Icons.search,
                  color: colors.textSecondary,
                ),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
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

                return _AdminPlayersResults(
                  players: players,
                  sensorService: _effectiveSensorService,
                  playerPhotoBuilder: widget.playerPhotoBuilder,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns sensor-flag loading so flag `setState` cannot rebuild the search field.
class _AdminPlayersResults extends StatefulWidget {
  const _AdminPlayersResults({
    required this.players,
    required this.sensorService,
    this.playerPhotoBuilder,
  });

  final List<Player> players;
  final AdminPlayerSensorService sensorService;
  final Widget Function(Player player, double radius)? playerPhotoBuilder;

  @override
  State<_AdminPlayersResults> createState() => _AdminPlayersResultsState();
}

class _AdminPlayersResultsState extends State<_AdminPlayersResults> {
  final Map<String, AdminPlayerSensorFlags> _flagsByPlayerId = {};
  final Set<String> _flagsLoading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetchFlags(widget.players);
    });
  }

  @override
  void didUpdateWidget(covariant _AdminPlayersResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.players, widget.players)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefetchFlags(widget.players);
      });
    }
  }

  String? _playerCacheKey(Player player) => effectiveMemberId(player)?.trim();

  void _prefetchFlags(List<Player> players) {
    for (final player in players) {
      _loadFlagsIfNeeded(player);
    }
  }

  void _loadFlagsIfNeeded(Player player) {
    final key = _playerCacheKey(player);
    if (key == null || key.isEmpty) return;
    if (_flagsByPlayerId.containsKey(key) || _flagsLoading.contains(key)) {
      return;
    }
    _flagsLoading.add(key);
    unawaited(() async {
      try {
        final flags = await widget.sensorService.loadFlags(player);
        if (!mounted) return;
        setState(() {
          _flagsByPlayerId[key] = flags;
          _flagsLoading.remove(key);
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _flagsByPlayerId[key] = AdminPlayerSensorFlags.none;
          _flagsLoading.remove(key);
        });
      }
    }());
  }

  /// Opens the hub immediately. Sensor flags decorate the card / hub and
  /// must never gate navigation — `loadFlags` can hang on Firestore.
  void _openPlayer(Player player) {
    final key = _playerCacheKey(player);
    final flags = key == null
        ? AdminPlayerSensorFlags.none
        : (_flagsByPlayerId[key] ?? AdminPlayerSensorFlags.none);
    Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.adminPlayerHub,
        builder: (_) => AdminPlayerHubScreen(
          player: player,
          flags: flags,
          sensorService: widget.sensorService,
          playerPhotoBuilder: widget.playerPhotoBuilder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: widget.players.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final player = widget.players[index];
        final userCount = collectMemberLinkedUserIds(player).length;
        final key = _playerCacheKey(player);
        final flags = key == null
            ? AdminPlayerSensorFlags.none
            : (_flagsByPlayerId[key] ?? AdminPlayerSensorFlags.none);
        return _AdminPlayerCard(
          key: ValueKey<String>('admin-player-card-${key ?? index}'),
          player: player,
          userCount: userCount,
          flags: flags,
          photo: widget.playerPhotoBuilder?.call(player, 24) ??
              PlayerPhoto(player: player, radius: 24),
          onTap: () => _openPlayer(player),
        );
      },
    );
  }
}

class _AdminPlayerCard extends StatelessWidget {
  const _AdminPlayerCard({
    super.key,
    required this.player,
    required this.userCount,
    required this.flags,
    required this.photo,
    required this.onTap,
  });

  final Player player;
  final int userCount;
  final AdminPlayerSensorFlags flags;
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
              if (flags.hasTeamKitSensor)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: l10n.adminPlayerTeamKitSensorTooltip,
                    child: Icon(
                      Icons.sensors_rounded,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                ),
              if (flags.hasConnectedDevices)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: l10n.adminPlayerConnectedDevicesTooltip,
                    child: Icon(
                      Icons.watch_outlined,
                      color: colors.primary,
                      size: 22,
                    ),
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
