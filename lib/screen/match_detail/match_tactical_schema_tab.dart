import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:provider/provider.dart';

import '../../model/compoType.dart';
import '../../model/grinta_player.dart';
import '../../model/grinta_player_hw.dart';
import '../../model/match.dart' as models;
import '../../model/matchCompo.dart';
import '../../model/player.dart';
import '../../model/team.dart';
import '../../model/tracker/deviceOwner.dart';
import '../../provider/appSession.dart';
import '../../screen/player_season_summary/player_season_summary_screen.dart';
import '../../services/compoTypeService.dart';
import '../../services/deviceOwnerService.dart' as device_owner_svc;
import '../../services/effectivesService.dart';
import '../../services/matchCompoService.dart';
import '../../services/playerService.dart';
import '../../services/teamService.dart';
import '../../services/team_players_service.dart';
import '../../screen/team_players/training_team_players_tracker.dart';
import '../../screen/team_players/training_team_players_presence.dart';
import '../../util/app_theme.dart';
import '../../util/match_compo_pitch_mapper.dart';
import '../../util/match_convocation_helper.dart';
import '../../util/playerDisplayName.dart';
import '../../util/player_photo_resolver.dart';
import '../../widget/half_pitch_compo_widget.dart';
import '../../widget/player_info_bubble.dart';
import '../../widget/playerPhoto.dart';

const Object _clearSlotToken = Object();

/// Onglet schéma tactique pour un match.
class MatchTacticalSchemaTab extends StatefulWidget {
  const MatchTacticalSchemaTab({
    super.key,
    required this.match,
    required this.isManager,
  });

  final models.Match match;
  final bool isManager;

  @override
  State<MatchTacticalSchemaTab> createState() => _MatchTacticalSchemaTabState();
}

class _MatchTacticalSchemaTabState extends State<MatchTacticalSchemaTab>
    with AutomaticKeepAliveClientMixin {
  final _matchCompoService = MatchCompoService();
  MatchCompo? _cachedMatchCompo;
  Stream<MatchCompo?>? _matchCompoStream;
  String? _streamMatchId;
  List<String> _streamProfileTeamIds = const <String>[];
  String? _streamPreferredTeamId;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final matchId = widget.match.id?.trim() ?? '';
    final appSession = context.read<AppSession>();
    final profileTeamIds = profileTeamIdsForMatch(
      profileTeamIds: appSession.teamIdsForSelectedSeason,
      match: widget.match,
    );
    final preferredTeamId = resolveTeamIdForMatch(
      widget.match,
      managedTeamIds: appSession.managedTeamsIdsForSelectedSeason,
    );

    final bool streamInputsChanged = _streamMatchId != matchId ||
        !_setEquals(_streamProfileTeamIds, profileTeamIds) ||
        _streamPreferredTeamId != preferredTeamId;

    if (streamInputsChanged) {
      _streamMatchId = matchId;
      _streamProfileTeamIds = List<String>.from(profileTeamIds);
      _streamPreferredTeamId = preferredTeamId;
      _matchCompoStream = matchId.isEmpty
          ? Stream<MatchCompo?>.value(null)
          : _matchCompoService.streamMatchCompoForMatchAndTeamIds(
              matchId,
              profileTeamIds: profileTeamIds,
              preferredTeamId: preferredTeamId,
            );
    }
  }

  bool _setEquals(List<String> a, List<String> b) {
    return Set<String>.from(a).containsAll(b) &&
        Set<String>.from(b).containsAll(a);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final matchId = widget.match.id?.trim() ?? '';
    if (matchId.isEmpty) {
      return _TacticalEmptyState(
        icon: Icons.sports_soccer_outlined,
        message: context.l10n.matchTacticalSchemaUnavailable,
      );
    }

    return StreamBuilder<MatchCompo?>(
      stream: _matchCompoStream ?? Stream<MatchCompo?>.value(null),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedMatchCompo = snapshot.data;
        }

        final matchCompo = snapshot.hasData ? snapshot.data : _cachedMatchCompo;

        final waitingForFirstCompo = matchCompo == null &&
            !snapshot.hasError &&
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        if (waitingForFirstCompo) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: context.appColors.primary),
                const SizedBox(height: 16),
                Text(
                  context.l10n.trainingPlayersLoading,
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _TacticalEmptyState(
            icon: Icons.error_outline_rounded,
            message: '${snapshot.error}',
          );
        }

        if (matchCompo == null && !widget.isManager) {
          return _TacticalEmptyState(
            icon: Icons.grid_view_rounded,
            message: context.l10n.matchTacticalSchemaEmpty,
          );
        }

        return _MatchTacticalSchemaBody(
          key: ValueKey('tactical-schema-${widget.match.id}'),
          match: widget.match,
          isManager: widget.isManager,
          initialMatchCompo: matchCompo,
        );
      },
    );
  }
}

class _MatchTacticalSchemaBody extends StatefulWidget {
  const _MatchTacticalSchemaBody({
    super.key,
    required this.match,
    required this.isManager,
    this.initialMatchCompo,
  });

  final models.Match match;
  final bool isManager;
  final MatchCompo? initialMatchCompo;

  @override
  State<_MatchTacticalSchemaBody> createState() =>
      _MatchTacticalSchemaBodyState();
}

class _MatchTacticalSchemaBodyState extends State<_MatchTacticalSchemaBody>
    with AutomaticKeepAliveClientMixin {
  final _teamPlayersService = TeamPlayersService();
  final _teamService = TeamService();
  final _playerService = PlayerService();
  final _compoTypeService = CompoTypeService();
  final _matchCompoService = MatchCompoService();

  @override
  bool get wantKeepAlive => true;

  bool _loadingPlayers = true;
  bool _playersLoaded = false;
  String? _resolvedTeamId;
  Team? _team;
  int? _teamSoccerType;
  List<Player> _teamPlayers = [];
  final Map<String, Player> _playersById = {};

  /// Roster sensor assignments: playerId → TRACKER_DeviceOwner doc ids.
  Map<String, List<String>> _rosterTrackerIdsByPlayerId = {};

  MatchCompo? _draftCompo;
  Set<String> _convokedIds = {};
  Map<String, PlayerCompo> _startersBySlot = {};
  List<PlayerCompo> _substitutes = [];

  CompoType? _selectedCompoType;
  String? _selectedCompoTypeKey;
  bool _saving = false;

  Map<String, PlayerCompo> _baselineStartersBySlot = {};
  List<PlayerCompo> _baselineSubstitutes = [];
  String? _baselineCompoTypeKey;

  bool get _canEdit =>
      widget.isManager && widget.match.isMatchPlayed != true;

  bool get _hasUnsavedChanges {
    if (_selectedCompoTypeKey != _baselineCompoTypeKey) return true;
    if (!_startersMapsEqual(_startersBySlot, _baselineStartersBySlot)) {
      return true;
    }
    if (!_substitutesListsEqual(_substitutes, _baselineSubstitutes)) {
      return true;
    }
    return false;
  }

  bool get _readOnly => !_canEdit;

  @override
  void initState() {
    super.initState();
    _loadTeamPlayers();
  }

  @override
  void didUpdateWidget(covariant _MatchTacticalSchemaBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = convokedPlayerIds(
      oldWidget.initialMatchCompo ?? MatchCompo(),
    );
    final newIds = convokedPlayerIds(
      widget.initialMatchCompo ?? MatchCompo(),
    );
    final bool refChanged = oldWidget.initialMatchCompo?.ref?.path !=
        widget.initialMatchCompo?.ref?.path;
    final bool lineupChanged = !_lineupEquals(
      oldWidget.initialMatchCompo,
      widget.initialMatchCompo,
    );
    if (refChanged || oldIds != newIds) {
      _hydrateFromMatchCompo(widget.initialMatchCompo);
      return;
    }
    // Apply remote lineup updates only when the editor has nothing pending.
    if (lineupChanged && !_hasUnsavedChanges) {
      _hydrateFromMatchCompo(widget.initialMatchCompo);
    }
  }

  bool _lineupEquals(MatchCompo? a, MatchCompo? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if ((a.compoTypeID ?? '') != (b.compoTypeID ?? '')) return false;
    return _startersMapsEqual(
          startersFromMatchCompo(a),
          startersFromMatchCompo(b),
        ) &&
        _substitutesListsEqual(
          substitutesFromMatchCompo(a),
          substitutesFromMatchCompo(b),
        );
  }

  Future<void> _loadTeamPlayers() async {
    final managedTeamIds = context.read<AppSession>().managedTeamsIdsForSelectedSeason;
    final teamId = resolveTeamIdForMatch(
      widget.match,
      matchCompo: widget.initialMatchCompo,
      managedTeamIds: managedTeamIds,
    );

    if (_playersLoaded &&
        teamId != null &&
        teamId.isNotEmpty &&
        teamId == _resolvedTeamId &&
        _teamPlayers.isNotEmpty) {
      return;
    }

    if (teamId == null || teamId.isEmpty) {
      if (mounted) {
        setState(() {
          _resolvedTeamId = null;
          _team = null;
          _teamPlayers = [];
          _rosterTrackerIdsByPlayerId = {};
          _loadingPlayers = false;
        });
      }
      return;
    }

    try {
      final team = await _teamService.getTeamById(teamId);
      final players = await _teamPlayersService.loadPlayers(teamId: teamId);
      final rosterTrackers = await _loadRosterTrackerIdsByPlayer(
        teamId: teamId,
        team: team,
      );

      _playersById
        ..clear()
        ..addEntries(
          players.map((p) => MapEntry(p.ref?.id ?? '', p)).where(
            (e) => e.key.isNotEmpty,
          ),
        );

      if (mounted) {
        setState(() {
          _resolvedTeamId = teamId;
          _team = team;
          _teamSoccerType = team?.soccerType;
          _teamPlayers = players;
          _rosterTrackerIdsByPlayerId = rosterTrackers;
          _loadingPlayers = false;
          _playersLoaded = true;
        });
        _hydrateFromMatchCompo(widget.initialMatchCompo);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedTeamId = teamId;
          _loadingPlayers = false;
        });
      }
    }
  }

  /// Loads kit sensor doc ids assigned on the team roster (effectif).
  ///
  /// Prefers [Team.grintaPlayers]; falls back to legacy `effectives.trackers`.
  Future<Map<String, List<String>>> _loadRosterTrackerIdsByPlayer({
    required String teamId,
    required Team? team,
  }) async {
    final map = <String, List<String>>{};
    final List<GrintaPlayer> grintaPlayers =
        team?.grintaPlayers ?? const <GrintaPlayer>[];
    if (grintaPlayers.isNotEmpty) {
      for (final GrintaPlayer entry in grintaPlayers) {
        final String playerId = entry.playerId.trim();
        if (playerId.isEmpty) continue;
        final List<String> trackers = entry.trackers
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty)
            .toList(growable: false);
        if (trackers.isNotEmpty) {
          map[playerId] = trackers;
        }
      }
      return map;
    }

    final String seasonId = widget.match.seasonID?.trim() ?? '';
    try {
      final effectives =
          await EffectivesService().getEffectivesByTeamId(teamId);
      for (final effective in effectives) {
        final String memberId = effective.memberID?.trim() ?? '';
        if (memberId.isEmpty) continue;
        if (seasonId.isNotEmpty) {
          final String effectiveSeason = effective.seasonID?.trim() ?? '';
          if (effectiveSeason.isNotEmpty && effectiveSeason != seasonId) {
            continue;
          }
        }
        final List<String> trackers = (effective.trackers ?? const <String>[])
            .map((String id) => id.trim())
            .where((String id) => id.isNotEmpty)
            .toList(growable: false);
        if (trackers.isNotEmpty) {
          map[memberId] = trackers;
        }
      }
    } catch (_) {
      // Roster defaults are best-effort; assignment sheet still works without them.
    }
    return map;
  }

  Future<void> _hydrateFromMatchCompo(MatchCompo? compo) async {
    if (compo == null) {
      setState(() {
        _draftCompo = null;
        _convokedIds = {};
        _startersBySlot = {};
        _substitutes = [];
        _selectedCompoType = null;
        _selectedCompoTypeKey = null;
      });
      return;
    }

    _draftCompo = compo;
    _convokedIds = convokedPlayerIds(compo);
    _startersBySlot = startersFromMatchCompo(compo);
    _substitutes = substitutesFromMatchCompo(compo);

    final compoTypeId = resolveCompoTypeDocumentId(compo.compoTypeID);
    if (compoTypeId != null) {
      final type = await _compoTypeService.getCompoTypeById(compoTypeId);
      if (mounted && type != null) {
        setState(() {
          _selectedCompoType = type;
          _selectedCompoTypeKey = compoTypeKey(type);
        });
      }
    }
    if (mounted) {
      setState(() {});
      _resetSavedBaseline();
      await _ensureConvokedPlayersLoaded();
    }
  }

  void _resetSavedBaseline() {
    _baselineStartersBySlot = {
      for (final entry in _startersBySlot.entries)
        entry.key: _copyPlayerCompo(entry.value),
    };
    _baselineSubstitutes =
        _substitutes.map(_copyPlayerCompo).toList(growable: false);
    _baselineCompoTypeKey = _selectedCompoTypeKey;
  }

  PlayerCompo _copyPlayerCompo(PlayerCompo source) {
    return PlayerCompo.fromMap(source.toMap());
  }

  bool _playerCompoEquals(PlayerCompo a, PlayerCompo b) {
    return (a.playerID?.trim() ?? '') == (b.playerID?.trim() ?? '') &&
        a.number == b.number &&
        (a.deviceOwnerId?.trim() ?? '') == (b.deviceOwnerId?.trim() ?? '') &&
        (a.customName?.trim() ?? '') == (b.customName?.trim() ?? '');
  }

  bool _startersMapsEqual(
    Map<String, PlayerCompo> a,
    Map<String, PlayerCompo> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || !_playerCompoEquals(entry.value, other)) {
        return false;
      }
    }
    return true;
  }

  bool _substitutesListsEqual(List<PlayerCompo> a, List<PlayerCompo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_playerCompoEquals(a[i], b[i])) return false;
    }
    return true;
  }

  Future<void> _ensureConvokedPlayersLoaded() async {
    if (_convokedIds.isEmpty) {
      return;
    }

    final rosterLookupIds = <String>{
      for (final player in _teamPlayers) ...playerMemberLookupIds(player),
    };

    final missingIds = _convokedIds
        .where((id) => id.isNotEmpty && !rosterLookupIds.contains(id))
        .toList();

    if (missingIds.isEmpty) {
      return;
    }

    final extraPlayers = <Player>[];
    for (final id in missingIds) {
      final player = await _playerService.getPlayerById(id);
      if (player != null) {
        extraPlayers.add(player);
      }
    }

    if (extraPlayers.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _teamPlayers = TeamPlayersService.dedupePlayersByMemberId(
        <Player>[..._teamPlayers, ...extraPlayers],
      )..sort(TeamPlayersService.comparePlayersByName);
      for (final player in extraPlayers) {
        final id = effectiveMemberId(player);
        if (id != null && id.isNotEmpty) {
          _playersById[id] = player;
        }
        final docId = player.ref?.id ?? '';
        if (docId.isNotEmpty) {
          _playersById[docId] = player;
        }
      }
    });
  }

  List<Player> get _playerPool {
    final seasonId = widget.match.seasonID?.trim();
    final eventDate = matchEventDateTime(widget.match);
    return _teamPlayers.where((p) {
      final lookupIds = playerMemberLookupIds(p);
      if (!lookupIds.any(_convokedIds.contains)) return false;
      if (isPlayerUnavailableOnDate(
        p,
        seasonId,
        eventDate,
        managerView: widget.isManager,
      )) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _assignedPlayerIds {
    final ids = <String>{};
    for (final p in _startersBySlot.values) {
      final id = p.playerID?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    for (final p in _substitutes) {
      final id = p.playerID?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    return ids;
  }

  /// Joueurs du pool convoqué non encore placés sur la compo.
  /// Si [excludeSlotId] est fourni, le joueur déjà sur ce poste reste listé.
  List<Player> _availablePlayersForPicker({String? excludeSlotId}) {
    final assigned = _assignedPlayerIds;
    if (excludeSlotId != null) {
      final current = _startersBySlot[excludeSlotId]?.playerID?.trim();
      if (current != null && current.isNotEmpty) assigned.remove(current);
    }

    return _playerPool.where((p) {
      final id = p.ref?.id.trim();
      if (id == null || id.isEmpty) return false;
      return !assigned.contains(id);
    }).toList();
  }

  Map<String, CompoFieldPlayer> get _displayFieldPlayers {
    final map = <String, CompoFieldPlayer>{};
    for (final entry in _startersBySlot.entries) {
      final playerId = entry.value.playerID?.trim();
      if (playerId == null || playerId.isEmpty) continue;
      final player = _playersById[playerId];
      map[entry.key] = CompoFieldPlayer(
        id: playerId,
        name: _displayName(entry.value, player),
        shirtNumber: entry.value.number?.toString(),
      );
    }
    return map;
  }

  String _displayName(PlayerCompo compo, Player? player) {
    final custom = compo.playerNameDisplayed?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    if (player != null) {
      return playerDisplayName(player, unknownLabel: playerIdLabel(context));
    }
    return compo.playerID ?? '';
  }

  String playerIdLabel(BuildContext context) => context.l10n.entityPlayer;

  PlayerCompo? _playerCompoForId(String playerId) {
    final id = playerId.trim();
    if (id.isEmpty) return null;
    for (final PlayerCompo compo in _startersBySlot.values) {
      if (compo.playerID?.trim() == id) return compo;
    }
    for (final PlayerCompo compo in _substitutes) {
      if (compo.playerID?.trim() == id) return compo;
    }
    return null;
  }

  /// Sensor display name when match uses trackers and one is assigned.
  String? _sensorLabelForPlayer(String playerId) {
    if (!_trackerRequiredForMatch) return null;
    final String? label = _playerCompoForId(playerId)?.customName?.trim();
    if (label == null || label.isEmpty) return null;
    return label;
  }

  GrintaPlayer? _grintaPlayerFor(Player player) {
    final Set<String> lookupIds = playerMemberLookupIds(player);
    for (final GrintaPlayer entry
        in _team?.grintaPlayers ?? const <GrintaPlayer>[]) {
      final String id = entry.playerId.trim();
      if (id.isNotEmpty && lookupIds.contains(id)) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _openPlayerStatistics(Player player) async {
    final Team? team = _team;
    final String seasonId = widget.match.seasonID?.trim() ?? '';
    if (team == null || seasonId.isEmpty || !mounted) return;

    final GrintaPlayer? grintaPlayer = _grintaPlayerFor(player);
    final GrintaPlayerHW? latestHw = grintaPlayer?.latestHw;

    await openPlayerSeasonSummaryScreen(
      context,
      team: team,
      initialSeasonId: seasonId,
      isManager: widget.isManager,
      identity: PlayerSeasonSummaryIdentity(
        player: player,
        positionCodes: grintaPlayer == null
            ? const <int>[]
            : List<int>.from(grintaPlayer.positions),
        birthday: grintaPlayer?.birthday ?? Player.parseBirthDay(player.birthDay),
        heightCm: latestHw != null && latestHw.height > 0
            ? latestHw.height
            : null,
        weightKg: latestHw != null && latestHw.weight > 0
            ? latestHw.weight
            : null,
        hwMeasuredAt: latestHw?.dateTime,
        preferredFoot: grintaPlayer?.preferredFoot,
        isGrintaRoster: grintaPlayer != null,
      ),
    );
  }

  void _showPlayerInfo(String playerId) {
    final player = _playersById[playerId];
    if (player == null) return;
    showPlayerInfoBubble(
      context,
      player,
      sensorLabel: _sensorLabelForPlayer(playerId),
      onStatistics: _team != null &&
              (widget.match.seasonID?.trim().isNotEmpty ?? false)
          ? () => _openPlayerStatistics(player)
          : null,
    );
  }

  Future<void> _onPlayerAvatarLongPress(String playerId) async {
    if (_readOnly) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.matchTacticalSchemaRemoveFromCompo),
        content: Text(l10n.matchTacticalSchemaRemoveFromCompoMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.matchTacticalSchemaRemoveFromCompoConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _startersBySlot.removeWhere((_, p) => p.playerID?.trim() == playerId);
      _substitutes.removeWhere((p) => p.playerID?.trim() == playerId);
    });
  }

  Widget _playerAvatar(String playerId, double size) {
    final player = _playersById[playerId];
    if (player == null) {
      return CircleAvatar(
        radius: size / 2,
        child: Icon(Icons.person, size: size * 0.45),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: PlayerPhoto(player: player, radius: size / 2),
    );
  }

  bool get _trackerRequiredForMatch {
    final ownerId = widget.match.ownerId?.trim() ?? '';
    return widget.match.withTracker == true && ownerId.isNotEmpty;
  }

  Future<List<DeviceOwner>> _loadAvailableTrackers({
    String? excludeSlotId,
    PlayerCompo? retainAssignment,
  }) async {
    final ownerId = widget.match.ownerId?.trim() ?? '';
    if (!_trackerRequiredForMatch) return [];

    final all =
        await device_owner_svc.DeviceOwnerService().listByOwnerId(ownerId);
    final usedIds = <String>{};
    final usedNames = <String>{};
    collectUsedTrackerAssignments(
      startersBySlotId: _startersBySlot,
      substitutes: _substitutes,
      excludeSlotId: excludeSlotId,
      outDeviceOwnerIds: usedIds,
      outCustomNames: usedNames,
    );

    if (retainAssignment != null) {
      final retainId = retainAssignment.deviceOwnerId?.trim();
      if (retainId != null && retainId.isNotEmpty) usedIds.remove(retainId);
      final retainName = retainAssignment.customName?.trim();
      if (retainName != null && retainName.isNotEmpty) {
        usedNames.remove(retainName);
      }
    }

    final available = all.where((device) {
      if (usedIds.contains(device.id)) return false;
      final name = device.customName?.trim();
      if (name != null && name.isNotEmpty && usedNames.contains(name)) {
        return false;
      }
      return true;
    }).toList();
    available.sort(compareDeviceOwnersByCustomName);
    return available;
  }

  int? _defaultJerseyNumber(Player player, PlayerCompo? existing) {
    if (existing?.number != null) return existing!.number;
    return int.tryParse(player.personNumber?.trim() ?? '');
  }

  Future<Player?> _showPlayerPickerSheet({
    required String title,
    required List<Player> players,
    VoidCallback? onClear,
    String? clearLabel,
    String? emptyMessage,
  }) {
    return showModalBottomSheet<Player>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlayerPickerSheet(
        title: title,
        players: players,
        onClear: onClear,
        clearLabel: clearLabel,
        emptyMessage: emptyMessage,
      ),
    );
  }

  Future<PlayerCompo?> _showPlayerAssignmentSheet({
    required Player player,
    PlayerCompo? existing,
    String? excludeSlotId,
  }) async {
    final availableTrackers = await _loadAvailableTrackers(
      excludeSlotId: excludeSlotId,
      retainAssignment: existing,
    );
    if (!mounted) return null;

    final jerseyNumbers = availableJerseyNumbers(
      startersBySlotId: _startersBySlot,
      substitutes: _substitutes,
      excludeSlotId: excludeSlotId,
      retainAssignment: existing,
    );

    return showModalBottomSheet<PlayerCompo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlayerCompoDetailsSheet(
        player: player,
        requireTracker: _trackerRequiredForMatch,
        availableTrackers: availableTrackers,
        availableJerseyNumbers: jerseyNumbers,
        initialNumber: _defaultJerseyNumber(player, existing),
        initialTracker: _defaultTrackerForPlayer(
          player: player,
          existing: existing,
          availableTrackers: availableTrackers,
        ),
      ),
    );
  }

  DeviceOwner? _deviceOwnerForCompo(
    PlayerCompo? compo,
    List<DeviceOwner> availableTrackers,
  ) {
    final docId = compo?.deviceOwnerId?.trim();
    if (docId == null || docId.isEmpty) return null;
    for (final device in availableTrackers) {
      if (device.id == docId) return device;
    }
    return null;
  }

  /// Prefer an existing match assignment; otherwise the player's roster sensor
  /// if still free for this composition.
  DeviceOwner? _defaultTrackerForPlayer({
    required Player player,
    PlayerCompo? existing,
    required List<DeviceOwner> availableTrackers,
  }) {
    final DeviceOwner? fromCompo =
        _deviceOwnerForCompo(existing, availableTrackers);
    if (fromCompo != null) return fromCompo;

    if (!_trackerRequiredForMatch || availableTrackers.isEmpty) {
      return null;
    }

    final String playerId =
        (effectiveMemberId(player) ?? player.ref?.id ?? '').trim();
    if (playerId.isEmpty) return null;

    final List<String> rosterIds =
        _rosterTrackerIdsByPlayerId[playerId] ?? const <String>[];
    if (rosterIds.isEmpty) return null;

    final Map<String, DeviceOwner> availableById = <String, DeviceOwner>{
      for (final DeviceOwner device in availableTrackers) device.id: device,
    };

    for (final String trackerDocId in rosterIds) {
      final DeviceOwner? device = availableById[trackerDocId];
      if (device != null) return device;
    }
    return null;
  }

  Future<void> _pickPlayer({
    required String title,
    String? excludeSlotId,
    bool forSubstitute = false,
  }) async {
    if (!mounted) return;

    final picked = await _showPlayerPickerSheet(
      title: title,
      players: _availablePlayersForPicker(excludeSlotId: excludeSlotId),
      emptyMessage: context.l10n.matchTacticalSchemaNoPlayerAvailable,
    );

    if (picked == null || !forSubstitute) return;

    final compo = await _showPlayerAssignmentSheet(
      player: picked,
      excludeSlotId: excludeSlotId,
    );
    if (!mounted || compo == null) return;

    setState(() {
      _substitutes = [..._substitutes, compo];
    });
  }

  Future<void> _onSlotTap(CompoSlot slot) async {
    if (_readOnly) return;

    final existing = _startersBySlot[slot.id];
    final currentId = existing?.playerID?.trim();

    final picked = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlayerPickerSheet(
        title: context.l10n.matchTacticalSchemaPickPlayer,
        players: _availablePlayersForPicker(excludeSlotId: slot.id),
        emptyMessage: context.l10n.matchTacticalSchemaNoPlayerAvailable,
        onClear: currentId != null
            ? () => Navigator.of(ctx).pop(_clearSlotToken)
            : null,
        clearLabel: context.l10n.matchTacticalSchemaClearSlot,
      ),
    );

    if (!mounted) return;

    if (identical(picked, _clearSlotToken)) {
      setState(() => _startersBySlot.remove(slot.id));
      return;
    }
    if (picked is! Player) return;

    final retainExisting =
        currentId != null && currentId == picked.ref?.id.trim()
            ? existing
            : null;

    final compo = await _showPlayerAssignmentSheet(
      player: picked,
      existing: retainExisting,
      excludeSlotId: slot.id,
    );
    if (!mounted || compo == null) return;

    setState(() => _startersBySlot[slot.id] = compo);
  }

  void _onCompoTypeChanged(CompoType type) {
    final validSlotIds =
        buildCompoSlots(type).map((s) => s.id).toSet();

    setState(() {
      _selectedCompoType = type;
      _selectedCompoTypeKey = compoTypeKey(type);
      _startersBySlot.removeWhere((key, _) => !validSlotIds.contains(key));
    });
  }

  Future<void> _save() async {
    if (_readOnly || _selectedCompoType == null || _saving) return;

    final matchId = widget.match.id?.trim();
    final teamId = _resolvedTeamId ??
        resolveTeamIdForMatch(
          widget.match,
          matchCompo: _draftCompo,
          managedTeamIds:
              context.read<AppSession>().managedTeamsIdsForSelectedSeason,
        );
    if (matchId == null || matchId.isEmpty) return;
    if (teamId == null || teamId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final compo = _draftCompo ??
          MatchCompo(
            matchID: matchId,
            teamID: teamId,
            seasonID: widget.match.seasonID,
            compoTypeID: _selectedCompoType!.ref?.id,
          );

      compo.matchID = matchId;
      compo.teamID = teamId;
      compo.seasonID = widget.match.seasonID;
      compo.compoTypeID = _selectedCompoType!.ref?.id;

      applyAssignmentsToMatchCompo(
        compo: compo,
        startersBySlotId: _startersBySlot,
        substitutes: _substitutes,
      );

      await _matchCompoService.saveMatchCompo(compo);
      _draftCompo = compo;
      _resetSavedBaseline();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.matchTacticalSchemaSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final colors = context.appColors;
    final l10n = context.l10n;

    if (_loadingPlayers && !_playersLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.trainingPlayersLoading,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_resolvedTeamId == null) {
      return _TacticalEmptyState(
        icon: Icons.groups_outlined,
        message: l10n.matchTacticalSchemaNoTeam,
      );
    }

    if (_teamPlayers.isEmpty) {
      return _TacticalEmptyState(
        icon: Icons.groups_outlined,
        message: l10n.emptyNoPlayerForTeam,
      );
    }

    final preferredSoccerType = widget.match.soccerType ?? _teamSoccerType;

    return StreamBuilder<List<CompoType>>(
      stream: _compoTypeService.streamCompoTypesResolved(
        preferredSoccerType: preferredSoccerType,
      ),
      builder: (context, compoSnapshot) {
        if (compoSnapshot.connectionState == ConnectionState.waiting &&
            !compoSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final compoTypes = compoSnapshot.data ?? <CompoType>[];
        if (compoTypes.isEmpty) {
          return _TacticalEmptyState(
            icon: Icons.tune_rounded,
            message: l10n.emptyNoCompoType,
          );
        }

        final selectedType = _resolveCompoType(compoTypes);
        if (_selectedCompoType == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _selectedCompoType != null) return;
            _onCompoTypeChanged(selectedType);
            _resetSavedBaseline();
          });
        }

        final hasSchema = _startersBySlot.isNotEmpty || _substitutes.isNotEmpty;
        final showEditor = _canEdit;

        return LayoutBuilder(
          builder: (context, constraints) {
            final Size screenSize = MediaQuery.sizeOf(context);
            final bool isPhone = screenSize.shortestSide < 600;
            // Prefer the tab content box so Flutter web (Chrome on tablet)
            // matches the native landscape-tablet side-by-side layout.
            // Slightly looser than a pure landscape check so short web
            // viewports (header + tabs) still get a readable pitch.
            final bool useSideBySideLayout = !isPhone &&
                constraints.maxWidth >= 640 &&
                constraints.maxWidth > constraints.maxHeight * 0.75;
            final bool tightHeight = constraints.maxHeight < 520;
            final double sectionGap = isPhone ? 6 : (tightHeight ? 4 : 8);

            final Widget compoSelector = showEditor
                ? _CompoTypeSelector(
                    compoTypes: compoTypes,
                    selectedKey:
                        _selectedCompoTypeKey ?? compoTypeKey(selectedType),
                    compact: tightHeight,
                    onChanged: (key) {
                      final type = compoTypes.firstWhere(
                        (t) => compoTypeKey(t) == key,
                        orElse: () => selectedType,
                      );
                      _onCompoTypeChanged(type);
                    },
                  )
                : (selectedType.name != null
                    ? _ReadOnlyCompoTypeLabel(name: selectedType.name!)
                    : const SizedBox.shrink());

            final Widget pitch = hasSchema || showEditor
                ? LayoutBuilder(
                    builder: (context, pitchConstraints) {
                      return HalfPitchCompoWidget(
                        height: pitchConstraints.maxHeight,
                        compoType: selectedType,
                        selectedPlayers: _displayFieldPlayers,
                        onSlotTap: showEditor ? _onSlotTap : null,
                        playerAvatarBuilder: _playerAvatar,
                        onPlayerAvatarTap: _showPlayerInfo,
                        onPlayerAvatarLongPress: showEditor
                            ? _onPlayerAvatarLongPress
                            : null,
                      );
                    },
                  )
                : _TacticalEmptyState(
                    icon: Icons.grid_view_rounded,
                    message: l10n.matchTacticalSchemaEmpty,
                  );

            final Widget substitutes = _SubstitutesSection(
              substitutes: _substitutes,
              playersById: _playersById,
              readOnly: _readOnly,
              showSensor: _trackerRequiredForMatch,
              onPlayerStatistics: _team != null &&
                      (widget.match.seasonID?.trim().isNotEmpty ?? false)
                  ? _openPlayerStatistics
                  : null,
              onRemove: (index) {
                setState(() => _substitutes.removeAt(index));
              },
              onAdd: showEditor
                  ? () => _pickPlayer(
                        title: l10n.matchTacticalSchemaAddSubstitute,
                        forSubstitute: true,
                      )
                  : null,
            );

            final Widget? saveButton = showEditor && _hasUnsavedChanges
                ? FilledButton.icon(
                    onPressed:
                        _saving || _selectedCompoType == null ? null : _save,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.surface,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.actionSave),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : null;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                isPhone ? 8 : 12,
                tightHeight ? 2 : 4,
                isPhone ? 8 : 12,
                isPhone ? 8 : (tightHeight ? 6 : 12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  compoSelector,
                  SizedBox(height: sectionGap),
                  if (useSideBySideLayout)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: tightHeight ? 4 : 3,
                            child: pitch,
                          ),
                          SizedBox(width: sectionGap + 4),
                          SizedBox(
                            width: () {
                              final double proposed = constraints.maxWidth *
                                  (tightHeight ? 0.24 : 0.30);
                              final double minW = tightHeight ? 200.0 : 240.0;
                              final double maxW = tightHeight ? 280.0 : 340.0;
                              if (proposed < minW) return minW;
                              if (proposed > maxW) return maxW;
                              return proposed;
                            }(),
                            child: SingleChildScrollView(
                              child: substitutes,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Expanded(child: pitch),
                    SizedBox(height: sectionGap),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: isPhone
                            ? 108
                            : (tightHeight ? 120 : 140),
                      ),
                      child: SingleChildScrollView(child: substitutes),
                    ),
                  ],
                  if (saveButton != null) ...[
                    SizedBox(height: sectionGap),
                    saveButton,
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  CompoType _resolveCompoType(List<CompoType> types) {
    if (_selectedCompoType != null) {
      for (final t in types) {
        if (compoTypeKey(t) == _selectedCompoTypeKey) return t;
      }
      return _selectedCompoType!;
    }
    return types.first;
  }
}

class _CompoTypeSelector extends StatelessWidget {
  const _CompoTypeSelector({
    required this.compoTypes,
    required this.selectedKey,
    required this.onChanged,
    this.compact = false,
  });

  final List<CompoType> compoTypes;
  final String selectedKey;
  final ValueChanged<String?> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final bool isPhone = MediaQuery.sizeOf(context).width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 10 : 12,
        vertical: compact ? 0 : (isPhone ? 2 : 4),
      ),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(isPhone ? 16 : 22),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedKey,
        isExpanded: true,
        isDense: compact,
        decoration: InputDecoration(
          labelText: context.l10n.hintCompoType,
          border: InputBorder.none,
          isDense: compact,
          contentPadding: compact
              ? const EdgeInsets.symmetric(vertical: 4)
              : null,
        ),
        items: compoTypes.map((type) {
          final key = compoTypeKey(type);
          return DropdownMenuItem(
            value: key,
            child: Text(
              type.name ?? key,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ReadOnlyCompoTypeLabel extends StatelessWidget {
  const _ReadOnlyCompoTypeLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SubstitutesSection extends StatelessWidget {
  const _SubstitutesSection({
    required this.substitutes,
    required this.playersById,
    required this.readOnly,
    required this.onRemove,
    this.showSensor = false,
    this.onPlayerStatistics,
    this.onAdd,
  });

  final List<PlayerCompo> substitutes;
  final Map<String, Player> playersById;
  final bool readOnly;
  final bool showSensor;
  final Future<void> Function(Player player)? onPlayerStatistics;
  final void Function(int index) onRemove;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.matchTacticalSchemaSubstitutes,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: Text(l10n.matchTacticalSchemaAddSubstitute),
              ),
          ],
        ),
        if (substitutes.isEmpty)
          Text(
            l10n.matchTacticalSchemaNoSubstitutes,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < substitutes.length; i++)
                _SubstituteChip(
                  compo: substitutes[i],
                  player: playersById[substitutes[i].playerID ?? ''],
                  readOnly: readOnly,
                  showSensor: showSensor,
                  onStatistics: onPlayerStatistics,
                  onRemove: () => onRemove(i),
                ),
            ],
          ),
      ],
    );
  }
}

class _SubstituteChip extends StatelessWidget {
  const _SubstituteChip({
    required this.compo,
    required this.player,
    required this.readOnly,
    required this.onRemove,
    this.showSensor = false,
    this.onStatistics,
  });

  final PlayerCompo compo;
  final Player? player;
  final bool readOnly;
  final bool showSensor;
  final Future<void> Function(Player player)? onStatistics;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final name = compo.playerNameDisplayed?.trim().isNotEmpty == true
        ? compo.playerNameDisplayed!
        : playerDisplayName(
            player ?? Player(),
            unknownLabel: l10n.entityPlayer,
          );
    final String? sensorLabel = showSensor
        ? (compo.customName?.trim().isNotEmpty == true
            ? compo.customName!.trim()
            : null)
        : null;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player != null)
          PlayerPhoto(player: player!, radius: 16)
        else
          CircleAvatar(
            radius: 16,
            child: Icon(Icons.person, size: 16, color: colors.textSecondary),
          ),
        const SizedBox(width: 8),
        Text(
          name,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (!readOnly) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 18, color: colors.textSecondary),
          ),
        ],
      ],
    );

    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: player != null
            ? () => showPlayerInfoBubble(
                  context,
                  player!,
                  sensorLabel: sensorLabel,
                  onStatistics: onStatistics == null
                      ? null
                      : () => onStatistics!(player!),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: content,
        ),
      ),
    );
  }
}

class _PlayerCompoDetailsSheet extends StatefulWidget {
  const _PlayerCompoDetailsSheet({
    required this.player,
    required this.requireTracker,
    required this.availableTrackers,
    required this.availableJerseyNumbers,
    this.initialNumber,
    this.initialTracker,
  });

  final Player player;
  final bool requireTracker;
  final List<DeviceOwner> availableTrackers;
  final List<int> availableJerseyNumbers;
  final int? initialNumber;
  final DeviceOwner? initialTracker;

  @override
  State<_PlayerCompoDetailsSheet> createState() =>
      _PlayerCompoDetailsSheetState();
}

class _PlayerCompoDetailsSheetState extends State<_PlayerCompoDetailsSheet> {
  int? _jerseyNumber;
  DeviceOwner? _selectedTracker;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialNumber;
    if (initial != null &&
        initial >= 1 &&
        initial <= 99 &&
        widget.availableJerseyNumbers.contains(initial)) {
      _jerseyNumber = initial;
    }
    _selectedTracker = widget.initialTracker;
    if (_selectedTracker == null &&
        widget.requireTracker &&
        widget.availableTrackers.length == 1) {
      _selectedTracker = widget.availableTrackers.first;
    }
  }

  void _confirm() {
    final l10n = context.l10n;
    if (widget.availableJerseyNumbers.isEmpty) {
      setState(
        () => _errorText = l10n.matchTacticalSchemaNoJerseyNumberAvailable,
      );
      return;
    }

    final number = _jerseyNumber;
    if (number == null || number < 1 || number > 99) {
      setState(() => _errorText = l10n.matchTacticalSchemaJerseyNumberRequired);
      return;
    }

    if (widget.requireTracker &&
        widget.availableTrackers.isNotEmpty &&
        _selectedTracker == null) {
      setState(() => _errorText = l10n.matchTacticalSchemaSensorRequired);
      return;
    }

    final tracker = _selectedTracker;
    final customName = tracker == null
        ? null
        : (tracker.customName?.trim().isNotEmpty == true
            ? tracker.customName!.trim()
            : tracker.deviceId);

    Navigator.of(context).pop(
      playerCompoFromPlayer(
        widget.player,
        number: number,
        deviceOwnerId: tracker?.id,
        customName: customName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final name = playerDisplayName(
      widget.player,
      unknownLabel: l10n.entityPlayer,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.matchTacticalSchemaPlayerAssignment,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (widget.availableJerseyNumbers.isEmpty)
            Text(
              l10n.matchTacticalSchemaNoJerseyNumberAvailable,
              style: TextStyle(color: colors.textSecondary),
            )
          else
            DropdownButtonFormField<int>(
              value: widget.availableJerseyNumbers.contains(_jerseyNumber)
                  ? _jerseyNumber
                  : null,
              isExpanded: true,
              dropdownColor: colors.surface,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.matchTacticalSchemaJerseyNumber,
                labelStyle: TextStyle(color: colors.textSecondary),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.primary, width: 2),
                ),
              ),
              items: widget.availableJerseyNumbers
                  .map(
                    (number) => DropdownMenuItem(
                      value: number,
                      child: Text('$number'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _jerseyNumber = value;
                _errorText = null;
              }),
            ),
          if (widget.requireTracker) ...[
            const SizedBox(height: 16),
            if (widget.availableTrackers.isEmpty)
              Text(
                l10n.trainingPlayersNoTrackerAvailable,
                style: TextStyle(color: colors.textSecondary),
              )
            else
              DropdownButtonFormField<DeviceOwner>(
                value: _selectedTracker,
                isExpanded: true,
                dropdownColor: colors.surface,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.trainingPlayersSelectTracker,
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                items: widget.availableTrackers.map((device) {
                  final custom = device.customName?.trim();
                  final label = (custom != null && custom.isNotEmpty)
                      ? '$custom (${device.deviceId})'
                      : device.deviceId;
                  return DropdownMenuItem(
                    value: device,
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() {
                  _selectedTracker = value;
                  _errorText = null;
                }),
              ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(color: colors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _confirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.actionValidate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerPickerSheet extends StatelessWidget {
  const _PlayerPickerSheet({
    required this.title,
    required this.players,
    this.onClear,
    this.clearLabel,
    this.emptyMessage,
  });

  final String title;
  final List<Player> players;
  final VoidCallback? onClear;
  final String? clearLabel;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (ctx, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
              ),
            ),
            if (onClear != null && clearLabel != null)
              ListTile(
                leading: Icon(Icons.clear, color: colors.danger),
                title: Text(clearLabel!, style: TextStyle(color: colors.danger)),
                onTap: onClear,
              ),
            Expanded(
              child: players.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          emptyMessage ?? l10n.emptyNoPlayerSelected,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: players.length,
                      itemBuilder: (ctx, index) {
                        final p = players[index];
                        return ListTile(
                          leading: PlayerPhoto(player: p, radius: 20),
                          title: Text(
                            playerDisplayName(
                              p,
                              unknownLabel: l10n.entityPlayer,
                            ),
                          ),
                          onTap: () => Navigator.of(ctx).pop(p),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TacticalEmptyState extends StatelessWidget {
  const _TacticalEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: colors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
