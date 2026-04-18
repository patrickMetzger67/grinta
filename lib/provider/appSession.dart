import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/teamService.dart';

class AppSession extends ChangeNotifier {
  User? user;
  bool isLoading = false;

  /// uid Firebase -> playerId -> Player
  Map<String, Map<String, Player>> players = {};

  /// playerId -> seasonId -> teamId -> Team
  Map<String, Map<String, Map<String, Team>>> teams = {};

  /// playerId -> seasonId -> Season
  Map<String, Map<String, Season>> seasons = {};

  /// playerId -> photo
  Map<String, NetworkImage> playersPhoto = {};

  Season? currentSeason;
  Season? selectedSeason;
  String? selectedPlayerId;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<Player>>? _playersSub;
  StreamSubscription<List<Season>>? _seasonsSub;

  final Map<String, StreamSubscription<List<Team>>> _teamsAsPlayerSubs = {};
  final Map<String, StreamSubscription<List<Team>>> _teamsAsManagerSubs = {};

  /// Données internes séparées pour éviter qu’un flux écrase l’autre
  final Map<String, Map<String, Map<String, Team>>> _teamsAsPlayerData = {};
  final Map<String, Map<String, Map<String, Team>>> _teamsAsManagerData = {};

  Map<String, Season> _allSeasonMap = {};

  bool _isInitializing = false;
  bool _isDisposed = false;
  String? _lastInitializedUid;
  int _listenerGeneration = 0;

  AppSession() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        clear();
      } else {
        unawaited(initFromUser(firebaseUser));
      }
    });
  }

  Map<String, Player> get currentUserPlayers {
    final uid = user?.uid;
    if (uid == null) return {};
    return players[uid] ?? {};
  }

  Player? get selectedPlayer {
    if (selectedPlayerId == null) return null;
    return currentUserPlayers[selectedPlayerId!];
  }

  Map<String, Season> get selectedPlayerSeasons {
    if (selectedPlayerId == null) return {};
    return getSeasonsForPlayer(selectedPlayerId!);
  }

  Map<String, Season> getSeasonsForPlayer(String playerId) {
    final Map<String, Map<String, Team>> seasonTeams =
        teams[playerId] ?? <String, Map<String, Team>>{};

    final Map<String, Season> result = {};

    for (final String seasonId in seasonTeams.keys) {
      final season = _allSeasonMap[seasonId];
      if (season != null) {
        result[seasonId] = season;
      }
    }

    return result;
  }

  Future<void> initFromUser(User firebaseUser) async {
    if (_isInitializing) return;

    final bool alreadyLoadedForSameUser =
        _lastInitializedUid == firebaseUser.uid &&
            user?.uid == firebaseUser.uid &&
            _playersSub != null &&
            _seasonsSub != null;

    if (alreadyLoadedForSameUser) {
      debugPrint(
        'AppSession init ignoré: déjà chargé pour uid=${firebaseUser.uid}',
      );
      return;
    }

    _isInitializing = true;
    final int generation = ++_listenerGeneration;

    try {
      await _cancelDataSubscriptions();

      isLoading = true;
      user = firebaseUser;

      players.clear();
      teams.clear();
      seasons.clear();
      playersPhoto.clear();
      _teamsAsPlayerData.clear();
      _teamsAsManagerData.clear();
      _allSeasonMap.clear();
      currentSeason = null;
      selectedSeason = null;
      selectedPlayerId = null;

      _safeNotify();

      debugPrint('AppSession init user=${firebaseUser.uid}');

      final List<Season> allSeasons = await SeasonService().getAllSeasons();
      if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;
      _updateSeasonCache(allSeasons);

      final List<Player> playersLst = await PlayerService().getPlayersByUserId(
        firebaseUser.uid,
      );
      if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

      final Map<String, Player> playerMap = await _buildPlayerMap(playersLst);
      players[firebaseUser.uid] = playerMap;

      for (final entry in playerMap.entries) {
        final String playerId = entry.key;
        final Player player = entry.value;

        final List<Team> teamsAsPlayer =
        await TeamService().getTeamsByPlayerId(playerId);

        if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

        _replaceTeamsForPlayerSource(
          playerId: playerId,
          teamsList: teamsAsPlayer,
          asPlayer: true,
        );

        if (_isManagerCarrier(player, firebaseUser.uid)) {
          final List<Team> teamsAsManager =
          await TeamService().getTeamsForAManger(firebaseUser.uid);

          if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

          _replaceTeamsForPlayerSource(
            playerId: playerId,
            teamsList: teamsAsManager,
            asPlayer: false,
          );
        } else {
          _teamsAsManagerData[playerId] = <String, Map<String, Team>>{};
        }
      }

      _rebuildMergedTeamsAndSeasons();
      _syncSelectedPlayerAndSeason();

      _startRealtimeSubscriptions(
        firebaseUid: firebaseUser.uid,
        generation: generation,
      );

      _lastInitializedUid = firebaseUser.uid;

      debugPrint('players=$players');
      debugPrint('teams=$teams');
      debugPrint(
        'season keys for selected player = ${selectedPlayerId != null ? getSeasonsForPlayer(selectedPlayerId!).keys.toList() : []}',
      );
    } catch (e, stackTrace) {
      debugPrint('Erreur AppSession.initFromUser: $e');
      debugPrint('$stackTrace');
    } finally {
      isLoading = false;
      _isInitializing = false;
      _safeNotify();
    }
  }

  Future<void> init() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      clear();
      return;
    }
    await initFromUser(current);
  }

  void _startRealtimeSubscriptions({
    required String firebaseUid,
    required int generation,
  }) {
    _seasonsSub = SeasonService().watchAllSeasons().listen(
          (allSeasons) {
        if (!_isCurrentGeneration(generation, firebaseUid)) return;

        _updateSeasonCache(allSeasons);
        _rebuildMergedTeamsAndSeasons();
        _syncSelectedPlayerAndSeason();
        _safeNotify();
      },
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('Erreur watchAllSeasons: $e');
        debugPrint('$stackTrace');
      },
    );

    _playersSub = PlayerService().watchPlayersByUserId(firebaseUid).listen(
          (playersLst) {
        unawaited(
          _onPlayersChanged(
            firebaseUid: firebaseUid,
            generation: generation,
            playersLst: playersLst,
          ),
        );
      },
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('Erreur watchPlayersByUserId: $e');
        debugPrint('$stackTrace');
      },
    );

    final Map<String, Player> currentPlayers = players[firebaseUid] ?? {};
    for (final entry in currentPlayers.entries) {
      _subscribeToPlayerTeamStreams(
        firebaseUid: firebaseUid,
        generation: generation,
        playerId: entry.key,
        player: entry.value,
      );
    }
  }

  Future<void> _onPlayersChanged({
    required String firebaseUid,
    required int generation,
    required List<Player> playersLst,
  }) async {
    if (!_isCurrentGeneration(generation, firebaseUid)) return;

    final Map<String, Player> newPlayerMap = await _buildPlayerMap(playersLst);
    final Map<String, Player> currentPlayerMap = players[firebaseUid] ?? {};

    final Set<String> currentIds = currentPlayerMap.keys.toSet();
    final Set<String> nextIds = newPlayerMap.keys.toSet();

    final Set<String> removedIds = currentIds.difference(nextIds);
    final Set<String> addedIds = nextIds.difference(currentIds);

    for (final String removedId in removedIds) {
      await _removePlayerSubscriptions(removedId);
      _teamsAsPlayerData.remove(removedId);
      _teamsAsManagerData.remove(removedId);
      teams.remove(removedId);
      seasons.remove(removedId);
      playersPhoto.remove(removedId);
    }

    players[firebaseUid] = newPlayerMap;

    for (final String addedId in addedIds) {
      final Player? player = newPlayerMap[addedId];
      if (player == null) continue;

      _subscribeToPlayerTeamStreams(
        firebaseUid: firebaseUid,
        generation: generation,
        playerId: addedId,
        player: player,
      );
    }

    _rebuildMergedTeamsAndSeasons();
    _syncSelectedPlayerAndSeason();
    _safeNotify();
  }

  void _subscribeToPlayerTeamStreams({
    required String firebaseUid,
    required int generation,
    required String playerId,
    required Player player,
  }) {
    _teamsAsPlayerSubs[playerId] ??=
        TeamService().watchTeamsByPlayerId(playerId).listen(
              (teamsList) {
            if (!_isCurrentGeneration(generation, firebaseUid)) return;

            _replaceTeamsForPlayerSource(
              playerId: playerId,
              teamsList: teamsList,
              asPlayer: true,
            );
            _rebuildMergedTeamsAndSeasons();
            _syncSelectedPlayerAndSeason();
            _safeNotify();
          },
          onError: (Object e, StackTrace stackTrace) {
            debugPrint('Erreur watchTeamsByPlayerId($playerId): $e');
            debugPrint('$stackTrace');
          },
        );

    if (_isManagerCarrier(player, firebaseUid)) {
      _teamsAsManagerSubs[playerId] ??=
          TeamService().watchTeamsForAManger(firebaseUid).listen(
                (teamsList) {
              if (!_isCurrentGeneration(generation, firebaseUid)) return;

              _replaceTeamsForPlayerSource(
                playerId: playerId,
                teamsList: teamsList,
                asPlayer: false,
              );
              _rebuildMergedTeamsAndSeasons();
              _syncSelectedPlayerAndSeason();
              _safeNotify();
            },
            onError: (Object e, StackTrace stackTrace) {
              debugPrint('Erreur watchTeamsForAManger($firebaseUid): $e');
              debugPrint('$stackTrace');
            },
          );
    } else {
      unawaited(_teamsAsManagerSubs.remove(playerId)?.cancel());
      _teamsAsManagerData[playerId] = <String, Map<String, Team>>{};
    }
  }

  void _replaceTeamsForPlayerSource({
    required String playerId,
    required List<Team> teamsList,
    required bool asPlayer,
  }) {
    final Map<String, Map<String, Team>> rebuilt = <String, Map<String, Team>>{};

    for (final Team t in teamsList) {
      if (t.keyTeam == null || t.seasonID == null) continue;

      final String seasonId = t.seasonID!;
      final String teamId = t.keyTeam!;

      if (!_allSeasonMap.containsKey(seasonId)) continue;

      rebuilt.putIfAbsent(seasonId, () => <String, Team>{});
      rebuilt[seasonId]![teamId] = t;
    }

    if (asPlayer) {
      _teamsAsPlayerData[playerId] = rebuilt;
    } else {
      _teamsAsManagerData[playerId] = rebuilt;
    }
  }

  void _rebuildMergedTeamsAndSeasons() {
    final Map<String, Map<String, Map<String, Team>>> mergedTeams = {};
    final Map<String, Map<String, Season>> mergedSeasons = {};

    final Set<String> playerIds = {};

    if (user != null && players.containsKey(user!.uid)) {
      playerIds.addAll(players[user!.uid]!.keys);
    }

    playerIds.addAll(_teamsAsPlayerData.keys);
    playerIds.addAll(_teamsAsManagerData.keys);

    for (final String playerId in playerIds) {
      final Map<String, Map<String, Team>> mergedSeasonMap = {};

      final Map<String, Map<String, Team>> sourceAsPlayer =
          _teamsAsPlayerData[playerId] ?? <String, Map<String, Team>>{};
      final Map<String, Map<String, Team>> sourceAsManager =
          _teamsAsManagerData[playerId] ?? <String, Map<String, Team>>{};

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsPlayer,
      );

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsManager,
      );

      mergedTeams[playerId] = mergedSeasonMap;

      final Map<String, Season> playerSeasonMap = {};
      for (final String seasonId in mergedSeasonMap.keys) {
        if (_allSeasonMap.containsKey(seasonId)) {
          playerSeasonMap[seasonId] = _allSeasonMap[seasonId]!;
        }
      }

      mergedSeasons[playerId] = playerSeasonMap;
    }

    teams = mergedTeams;
    seasons = mergedSeasons;
  }

  void _mergeSeasonTeamMap({
    required Map<String, Map<String, Team>> target,
    required Map<String, Map<String, Team>> source,
  }) {
    source.forEach((String seasonId, Map<String, Team> teamMap) {
      target.putIfAbsent(seasonId, () => <String, Team>{});
      target[seasonId]!.addAll(teamMap);
    });
  }

  Future<Map<String, Player>> _buildPlayerMap(List<Player> playersLst) async {
    final Map<String, Player> playerMap = {};

    for (final Player player in playersLst) {
      debugPrint('player=$player');

      if (player.keyMember == null) continue;
      final String playerId = player.keyMember!;
      playerMap[playerId] = player;

      final url = await PlayerService().getUrlPlayer(
        player,
        'portrait_1920x1920.jpg',
      );

      if (url.isNotEmpty) {
        playersPhoto[playerId] = NetworkImage(url);
      } else {
        playersPhoto.remove(playerId);
      }
    }

    return playerMap;
  }

  void _updateSeasonCache(List<Season> allSeasons) {
    final Map<String, Season> nextSeasonMap = {};
    Season? nextCurrentSeason;

    for (final Season s in allSeasons) {
      if (s.ref != null) {
        nextSeasonMap[s.ref!.id] = s;

        if (s.isCurrent == true) {
          nextCurrentSeason = s;
        }
      }
    }

    _allSeasonMap = nextSeasonMap;
    currentSeason = nextCurrentSeason;

    final String? selectedSeasonId = selectedSeason?.ref?.id;
    if (selectedSeasonId != null && _allSeasonMap.containsKey(selectedSeasonId)) {
      selectedSeason = _allSeasonMap[selectedSeasonId];
    } else {
      selectedSeason = nextCurrentSeason;
    }
  }

  void _syncSelectedPlayerAndSeason() {
    final Map<String, Player> playerMap = currentUserPlayers;

    if (playerMap.isEmpty) {
      selectedPlayerId = null;
      selectedSeason = null;
      return;
    }

    if (selectedPlayerId == null || !playerMap.containsKey(selectedPlayerId)) {
      selectedPlayerId = playerMap.keys.first;
    }

    if (selectedPlayerId == null) {
      selectedSeason = null;
      return;
    }

    final Map<String, Season> playerSeasons = getSeasonsForPlayer(
      selectedPlayerId!,
    );

    if (playerSeasons.isEmpty) {
      selectedSeason = null;
      return;
    }

    final String? selectedSeasonId = selectedSeason?.ref?.id;

    if (selectedSeasonId != null && playerSeasons.containsKey(selectedSeasonId)) {
      selectedSeason = playerSeasons[selectedSeasonId];
      return;
    }

    final String? currentSeasonId = currentSeason?.ref?.id;
    if (currentSeasonId != null && playerSeasons.containsKey(currentSeasonId)) {
      selectedSeason = playerSeasons[currentSeasonId];
      return;
    }

    selectedSeason = playerSeasons.values.first;
  }

  bool _isCurrentGeneration(int generation, String firebaseUid) {
    return !_isDisposed &&
        generation == _listenerGeneration &&
        user?.uid == firebaseUid;
  }

  Future<void> _removePlayerSubscriptions(String playerId) async {
    await _teamsAsPlayerSubs.remove(playerId)?.cancel();
    await _teamsAsManagerSubs.remove(playerId)?.cancel();
  }

  Future<void> _cancelDataSubscriptions() async {
    await _playersSub?.cancel();
    _playersSub = null;

    await _seasonsSub?.cancel();
    _seasonsSub = null;

    for (final StreamSubscription<List<Team>> sub in _teamsAsPlayerSubs.values) {
      await sub.cancel();
    }
    _teamsAsPlayerSubs.clear();

    for (final StreamSubscription<List<Team>> sub in _teamsAsManagerSubs.values) {
      await sub.cancel();
    }
    _teamsAsManagerSubs.clear();
  }

  void setSelectedPlayerId(String? playerId) {
    selectedPlayerId = playerId;
    _syncSelectedPlayerAndSeason();
    _safeNotify();
  }

  void setSelectedSeason(Season? season) {
    selectedSeason = season;
    _safeNotify();
  }

  Map<String, Team> get selectedTeamsMap {
    final String? playerId = selectedPlayerId;
    final String? seasonId = selectedSeason?.ref?.id;

    if (playerId == null || seasonId == null) {
      return <String, Team>{};
    }

    return teams[playerId]?[seasonId] ?? <String, Team>{};
  }

  List<Team> get selectedTeams {
    return selectedTeamsMap.values.toList();
  }

  bool _isManagerCarrier(Player player, String firebaseUid) {
    return player.userID == firebaseUid;
  }

  void clear() {
    _listenerGeneration++;
    unawaited(_cancelDataSubscriptions());

    user = null;
    players.clear();
    teams.clear();
    seasons.clear();
    playersPhoto.clear();
    _teamsAsPlayerData.clear();
    _teamsAsManagerData.clear();
    _allSeasonMap.clear();
    currentSeason = null;
    selectedSeason = null;
    selectedPlayerId = null;
    isLoading = false;
    _isInitializing = false;
    _lastInitializedUid = null;

    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _listenerGeneration++;
    unawaited(_cancelDataSubscriptions());
    unawaited(_authSub?.cancel());
    super.dispose();
  }
}