import 'dart:async';

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
  const AdminPlayersScreen({super.key});

  @override
  State<AdminPlayersScreen> createState() => _AdminPlayersScreenState();
}

class _AdminPlayersScreenState extends State<AdminPlayersScreen> {
  final PlayerService _playerService = PlayerService();
  final AdminPlayerSensorService _sensorService = AdminPlayerSensorService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, AdminPlayerSensorFlags> _flagsByPlayerId = {};
  final Set<String> _flagsLoading = {};
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

  List<String> _queryTokens(String query) => playerSearchQueryTokens(query);

  bool _matchesPlayer(Player player, List<String> tokens) {
    if (tokens.isEmpty) return true;
    return tokens.every((token) => playerMatchesNameQuery(player, token));
  }

  String? _playerCacheKey(Player player) => effectiveMemberId(player)?.trim();

  void _ensureFlags(Player player) {
    final key = _playerCacheKey(player);
    if (key == null || key.isEmpty) return;
    if (_flagsByPlayerId.containsKey(key) || _flagsLoading.contains(key)) {
      return;
    }
    _flagsLoading.add(key);
    unawaited(() async {
      final flags = await _sensorService.loadFlags(player);
      if (!mounted) return;
      setState(() {
        _flagsByPlayerId[key] = flags;
        _flagsLoading.remove(key);
      });
    }());
  }

  Future<void> _openPlayer(Player player) async {
    final key = _playerCacheKey(player);
    var flags = key == null ? AdminPlayerSensorFlags.none : _flagsByPlayerId[key];
    if (flags == null) {
      flags = await _sensorService.loadFlags(player);
      if (!mounted) return;
      if (key != null && key.isNotEmpty) {
        setState(() => _flagsByPlayerId[key] = flags!);
      }
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      analyticsMaterialRoute<void>(
        screenName: AnalyticsScreenNames.adminPlayerHub,
        builder: (_) => AdminPlayerHubScreen(
          player: player,
          flags: flags ?? AdminPlayerSensorFlags.none,
        ),
      ),
    );
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
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: l10n.adminPlayersSearchHint,
                hintText: l10n.adminPlayersSearchHint,
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
            child: StreamBuilder<List<Player>>(
              stream: _playerService.streamAllMembers(),
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

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final userCount =
                        collectMemberLinkedUserIds(player).length;
                    final key = _playerCacheKey(player);
                    _ensureFlags(player);
                    final flags = key == null
                        ? AdminPlayerSensorFlags.none
                        : (_flagsByPlayerId[key] ??
                            AdminPlayerSensorFlags.none);
                    return _AdminPlayerCard(
                      player: player,
                      userCount: userCount,
                      flags: flags,
                      onTap: () => _openPlayer(player),
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

class _AdminPlayerCard extends StatelessWidget {
  const _AdminPlayerCard({
    required this.player,
    required this.userCount,
    required this.flags,
    required this.onTap,
  });

  final Player player;
  final int userCount;
  final AdminPlayerSensorFlags flags;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final firstName = (player.firstName ?? '').trim();
    final lastName = (player.lastName ?? '').trim();
    final name = [
      if (firstName.isNotEmpty) firstName,
      if (lastName.isNotEmpty) lastName,
    ].join(' ');
    final email = (player.email ?? '').trim();

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
              PlayerPhoto(player: player, radius: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty
                          ? playerDisplayName(player, unknownLabel: '—')
                          : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
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
