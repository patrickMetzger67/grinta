import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/season.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/seasonService.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/user_avatar_service.dart';
import 'package:grinta/util/coach_filter_period.dart';
import 'package:grinta/util/player_photo_resolver.dart';
import 'package:grinta/util/team_deletion_access.dart';
import 'package:grinta/util/team_list_visibility.dart';

class AppSession extends ChangeNotifier {
  User? user;
  bool isLoading = false;

  /// uid Firebase -> playerId -> Player
  Map<String, Map<String, Player>> players = {};

  /// playerId -> seasonId -> teamId -> Team
  Map<String, Map<String, Map<String, Team>>> teams = {};

  /// playerId -> seasonId -> Season
  Map<String, Map<String, Season>> seasons = {};

  /// playerId -> URLs photo (joueur → utilisateur → défaut)
  Map<String, List<String>> playersPhotoUrls = {};

  Season? currentSeason;
  Season? selectedSeason;
  String? selectedPlayerId;

  /// Last managed team chosen on Dashboard / Analyse charge (season-scoped UX).
  String? selectedManagedTeamId;

  /// Last Semaine / Mois / Personnalisé chosen on Dashboard / Analyse charge.
  CoachFilterPeriod selectedCoachFilterPeriod = CoachFilterPeriod.month;

  /// Inclusive custom range when [selectedCoachFilterPeriod] is custom.
  DateTimeRange? selectedCoachFilterCustomRange;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _userProfileSub;
  StreamSubscription<User?>? _idTokenSub;
  StreamSubscription<List<Player>>? _playersSub;
  StreamSubscription<List<Season>>? _seasonsSub;

  final Map<String, StreamSubscription<List<Team>>> _teamsAsPlayerSubs = {};
  final Map<String, StreamSubscription<List<Team>>> _teamsAsManagerSubs = {};
  final Map<String, StreamSubscription<List<Team>>> _teamsAsGrintaPlayerSubs =
      {};
  StreamSubscription<List<Team>>? _teamsAsOwnerSub;

  /// Données internes séparées pour éviter qu’un flux écrase l’autre
  final Map<String, Map<String, Map<String, Team>>> _teamsAsPlayerData = {};
  final Map<String, Map<String, Map<String, Team>>> _teamsAsManagerData = {};
  final Map<String, Map<String, Map<String, Team>>> _teamsAsGrintaPlayerData =
      {};
  final Map<String, Map<String, Map<String, Team>>> _teamsAsOwnerData = {};


  Map<String, Season> _allSeasonMap = {};

  bool _isDisposed = false;

  String? _lastInitializedUid;
  int _listenerGeneration = 0;
  Future<void>? _initInFlight;
  String? _initInFlightUid;
  String? _lastRefreshedAuthPhotoUrl;
  String? _lastHandledAuthProfilePhotoUrl;
  String? _oauthPhotoUrl;
  Future<void>? _avatarRefreshInFlight;
  DateTime? _lastAvatarRefreshRequestAt;
  Timer? _webAvatarPollTimer;
  int _webAvatarPollAttempts = 0;
  bool _webAvatarPollExhausted = false;

  /// On web, OAuth photoURL can arrive before [User.photoURL] is populated.
  void cacheOAuthPhotoUrl(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    _oauthPhotoUrl = normalizeAuthPhotoDisplayUrl(trimmed);
  }

  /// chain (see [resolvePlayerAvatarUrls]).
  ///
  /// On web, [authStateChanges] often fires before OAuth providers populate
  /// [User.photoURL]. [userChanges] and [idTokenChanges] plus a capped timed
  /// poll cover late photoURL arrival; [User.reload] is attempted with a
  /// short timeout when resolving avatars.
  static const Duration _kWebAvatarPollInterval = Duration(milliseconds: 750);
  static const int _kWebAvatarPollMaxAttempts = 8;
  static const Duration _kAuthReloadTimeout = Duration(seconds: 5);
  static const Duration _kAvatarRefreshDebounce = Duration(milliseconds: 750);

  AppSession() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser == null) {
        if (FirebaseAuth.instance.currentUser != null) {
          return;
        }
        clear();
      } else {
        unawaited(initFromUser(firebaseUser));
      }
    });

    _userProfileSub = FirebaseAuth.instance.userChanges().listen((authUser) {
      unawaited(_onAuthProfileMaybeUpdated(authUser));
    });

    _idTokenSub = FirebaseAuth.instance.idTokenChanges().listen((authUser) {
      unawaited(_onAuthProfileMaybeUpdated(authUser));
    });
  }


  bool get hasManagedTeamsInSelectedSeason {
    return managerTeamsForSelectedSeason.isNotEmpty;
  }

  List<String> get managedTeamsIdsForSelectedSeason {
    final String? seasonId = selectedSeason?.ref?.id;
    if (seasonId == null) return const <String>[];

    final Set<String> ids = <String>{};

    final Map<String, Map<String, Team>>? teamsAsManager =
        _teamsAsManagerData[selectedPlayerId];
    final Map<String, Team>? managerTeamsForSeason =
        teamsAsManager?[seasonId];
    if (managerTeamsForSeason != null) {
      ids.addAll(managerTeamsForSeason.keys);
    }

    final Map<String, Map<String, Team>>? teamsAsOwner =
        _teamsAsOwnerData[selectedPlayerId];
    final Map<String, Team>? ownedTeamsForSeason = teamsAsOwner?[seasonId];
    if (ownedTeamsForSeason != null) {
      ids.addAll(ownedTeamsForSeason.keys);
    }

    return ids.toList();
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

  /// Seasons available in the player/season selector.
  ///
  /// Lists every configured season document, not only seasons where the player
  /// already has teams (teams still filter by [selectedSeason] elsewhere).
  Map<String, Season> getSeasonsForPlayer(String playerId) {
    if (_allSeasonMap.isNotEmpty) {
      return Map<String, Season>.from(_allSeasonMap);
    }

    return _currentSeasonsFromCache();
  }

  Map<String, Season> _currentSeasonsFromCache() {
    final Map<String, Season> result = {};

    for (final MapEntry<String, Season> entry in _allSeasonMap.entries) {
      if (entry.value.isCurrent == true) {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  Future<void> initFromUser(User firebaseUser) async {
    final String uid = firebaseUser.uid;

    final bool alreadyLoadedForSameUser =
        _lastInitializedUid == uid &&
            user?.uid == uid &&
            _playersSub != null &&
            _seasonsSub != null;

    if (alreadyLoadedForSameUser) {
      debugPrint('AppSession init ignoré: déjà chargé pour uid=$uid');
      _webAvatarPollExhausted = false;
      final User? current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == uid) {
        user = current;
        _safeNotify();
      }
      unawaited(_refreshAvatarsIfLinkedAuthPhotoMissing());
      return;
    }

    if (_initInFlight != null && _initInFlightUid == uid) {
      return _initInFlight!;
    }

    _initInFlightUid = uid;
    _initInFlight = _initFromUserBody(firebaseUser);
    try {
      await _initInFlight!;
    } finally {
      if (_initInFlightUid == uid) {
        _initInFlight = null;
        _initInFlightUid = null;
      }
    }
  }

  Future<void> _initFromUserBody(User firebaseUser) async {
    final int generation = ++_listenerGeneration;

    try {
      await _cancelDataSubscriptions();

      isLoading = true;
      final User? liveUser = FirebaseAuth.instance.currentUser;
      user = liveUser != null && liveUser.uid == firebaseUser.uid
          ? liveUser
          : firebaseUser;
      cacheOAuthPhotoUrl(readAuthUserPhotoUrl(user));

      players.clear();
      teams.clear();
      seasons.clear();
      playersPhotoUrls.clear();
      PlayerService.clearPlayerPhotoUrlCache();
      _teamsAsPlayerData.clear();
      _teamsAsManagerData.clear();
      _teamsAsGrintaPlayerData.clear();
      _teamsAsOwnerData.clear();
      _allSeasonMap.clear();
      currentSeason = null;
      selectedSeason = null;
      selectedPlayerId = null;
      selectedManagedTeamId = null;
      selectedCoachFilterPeriod = CoachFilterPeriod.month;
      selectedCoachFilterCustomRange = null;

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

        final List<Team> teamsAsGrintaPlayer =
            await TeamService().getTeamsForPlayerGrintaMembership(player);

        if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

        _replaceGrintaMemberTeams(
          playerId: playerId,
          teamsList: teamsAsGrintaPlayer,
        );

        final List<Team> teamsAsManager =
            await TeamService().getTeamsForAManger(firebaseUser.uid);

        if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

        _replaceTeamsForPlayerSource(
          playerId: playerId,
          teamsList: teamsAsManager,
          asPlayer: false,
        );
      }

      final List<Team> teamsAsOwner =
          await TeamService().getTeamsByOwnerUid(firebaseUser.uid);

      if (!_isCurrentGeneration(generation, firebaseUser.uid)) return;

      _replaceOwnerTeamsForAllPlayers(teamsAsOwner);

      _rebuildMergedTeamsAndSeasons();
      _syncSelectedPlayerAndSeason();

      _startRealtimeSubscriptions(
        firebaseUid: firebaseUser.uid,
        generation: generation,
      );

      _lastInitializedUid = firebaseUser.uid;
      _webAvatarPollExhausted = false;
      _lastHandledAuthProfilePhotoUrl = null;
      _lastAvatarRefreshRequestAt = null;

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
      _safeNotify();
    }
  }

  Future<void> init() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      // Ne pas clear ici : la déconnexion est gérée par authStateChanges.
      return;
    }
    await initFromUser(current);
  }

  /// Unblocks the UI when [init] was abandoned after an external timeout.
  ///
  /// Invalidates in-flight listener work and clears [isLoading] without wiping
  /// a user that already matches [expectedUid].
  void releaseStuckInit({String? expectedUid}) {
    if (expectedUid != null &&
        user != null &&
        user!.uid != expectedUid) {
      return;
    }

    _listenerGeneration++;
    _initInFlight = null;
    _initInFlightUid = null;
    isLoading = false;

    final User? current = FirebaseAuth.instance.currentUser;
    if (user == null && current != null) {
      user = current;
    } else if (expectedUid != null &&
        current != null &&
        current.uid == expectedUid) {
      user = current;
    }

    _safeNotify();
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

    _teamsAsOwnerSub ??=
        TeamService().watchTeamsByOwnerUid(firebaseUid).listen(
              (teamsList) {
            if (!_isCurrentGeneration(generation, firebaseUid)) return;

            _replaceOwnerTeamsForAllPlayers(teamsList);
            _rebuildMergedTeamsAndSeasons();
            _syncSelectedPlayerAndSeason();
            _safeNotify();
          },
          onError: (Object e, StackTrace stackTrace) {
            debugPrint('Erreur watchTeamsByOwnerUid($firebaseUid): $e');
            debugPrint('$stackTrace');
          },
        );
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
      _teamsAsGrintaPlayerData.remove(removedId);
      _teamsAsOwnerData.remove(removedId);
      teams.remove(removedId);
      seasons.remove(removedId);
      playersPhotoUrls.remove(removedId);
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

    if (addedIds.isNotEmpty) {
      final Map<String, Team> ownerTeamsById = {};
      for (final Map<String, Map<String, Team>> seasonMap
          in _teamsAsOwnerData.values) {
        for (final Map<String, Team> teamMap in seasonMap.values) {
          for (final MapEntry<String, Team> entry in teamMap.entries) {
            ownerTeamsById.putIfAbsent(entry.key, () => entry.value);
          }
        }
      }
      if (ownerTeamsById.isNotEmpty) {
        _replaceOwnerTeamsForAllPlayers(ownerTeamsById.values.toList());
      }
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

    _teamsAsGrintaPlayerSubs[playerId] ??=
        TeamService().watchTeamsForPlayerGrintaMembership(player).listen(
              (teamsList) {
            if (!_isCurrentGeneration(generation, firebaseUid)) return;

            _replaceGrintaMemberTeams(
              playerId: playerId,
              teamsList: teamsList,
            );
            _rebuildMergedTeamsAndSeasons();
            _syncSelectedPlayerAndSeason();
            _safeNotify();
          },
          onError: (Object e, StackTrace stackTrace) {
            debugPrint(
              'Erreur watchTeamsForPlayerGrintaMembership($playerId): $e',
            );
            debugPrint('$stackTrace');
          },
        );

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

  void _replaceGrintaMemberTeams({
    required String playerId,
    required List<Team> teamsList,
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

    _teamsAsGrintaPlayerData[playerId] = rebuilt;
  }

  /// Picks up grinta roster membership from teams already loaded via legacy
  /// players, manager, or owner paths (covers stale index / id-alias gaps).
  void _supplementGrintaTeamsForAllPlayers() {
    final String? uid = user?.uid;
    if (uid == null) return;

    final Map<String, Player> playerMap = players[uid] ?? {};
    for (final MapEntry<String, Player> entry in playerMap.entries) {
      final String playerId = entry.key;
      final Player player = entry.value;
      final Map<String, Map<String, Team>> rebuilt =
          Map<String, Map<String, Team>>.from(
            _teamsAsGrintaPlayerData[playerId] ?? const <String, Map<String, Team>>{},
          );

      void absorb(Map<String, Map<String, Team>>? source) {
        if (source == null) return;
        for (final MapEntry<String, Map<String, Team>> seasonEntry
            in source.entries) {
          final String seasonId = seasonEntry.key;
          if (!_allSeasonMap.containsKey(seasonId)) continue;
          for (final MapEntry<String, Team> teamEntry
              in seasonEntry.value.entries) {
            if (!teamContainsGrintaMemberForPlayer(teamEntry.value, player)) {
              continue;
            }
            rebuilt.putIfAbsent(seasonId, () => <String, Team>{});
            rebuilt[seasonId]![teamEntry.key] = teamEntry.value;
          }
        }
      }

      absorb(_teamsAsPlayerData[playerId]);
      absorb(_teamsAsManagerData[playerId]);
      absorb(_teamsAsOwnerData[playerId]);

      _teamsAsGrintaPlayerData[playerId] = rebuilt;
    }
  }

  void _replaceOwnerTeamsForAllPlayers(List<Team> teamsList) {
    final Map<String, Map<String, Team>> rebuilt =
        <String, Map<String, Team>>{};

    for (final Team t in teamsList) {
      if (t.keyTeam == null || t.seasonID == null) continue;

      final String seasonId = t.seasonID!;
      final String teamId = t.keyTeam!;

      if (!_allSeasonMap.containsKey(seasonId)) continue;

      rebuilt.putIfAbsent(seasonId, () => <String, Team>{});
      rebuilt[seasonId]![teamId] = t;
    }

    final Map<String, Player> playerMap = currentUserPlayers;
    if (playerMap.isEmpty) {
      _teamsAsOwnerData.clear();
      return;
    }

    for (final String playerId in playerMap.keys) {
      _teamsAsOwnerData[playerId] = rebuilt;
    }

    final Set<String> staleOwnerKeys =
        _teamsAsOwnerData.keys.toSet().difference(playerMap.keys.toSet());
    for (final String staleKey in staleOwnerKeys) {
      _teamsAsOwnerData.remove(staleKey);
    }
  }

  void _rebuildMergedTeamsAndSeasons() {
    _supplementGrintaTeamsForAllPlayers();

    final Map<String, Map<String, Map<String, Team>>> mergedTeams = {};
    final Map<String, Map<String, Season>> mergedSeasons = {};

    final Set<String> playerIds = {};

    if (user != null && players.containsKey(user!.uid)) {
      playerIds.addAll(players[user!.uid]!.keys);
    }

    playerIds.addAll(_teamsAsPlayerData.keys);
    playerIds.addAll(_teamsAsManagerData.keys);
    playerIds.addAll(_teamsAsGrintaPlayerData.keys);
    playerIds.addAll(_teamsAsOwnerData.keys);

    final Map<String, Player> playerMap =
        user != null ? (players[user!.uid] ?? const <String, Player>{}) : const <String, Player>{};

    for (final String playerId in playerIds) {
      final Map<String, Map<String, Team>> mergedSeasonMap = {};

      final Map<String, Map<String, Team>> sourceAsPlayer =
          _teamsAsPlayerData[playerId] ?? <String, Map<String, Team>>{};
      final Map<String, Map<String, Team>> sourceAsManager =
          _teamsAsManagerData[playerId] ?? <String, Map<String, Team>>{};
      final Map<String, Map<String, Team>> sourceAsGrintaPlayer =
          _teamsAsGrintaPlayerData[playerId] ?? <String, Map<String, Team>>{};
      final Map<String, Map<String, Team>> sourceAsOwner =
          _teamsAsOwnerData[playerId] ?? <String, Map<String, Team>>{};

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsPlayer,
      );

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsManager,
      );

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsGrintaPlayer,
      );

      _mergeSeasonTeamMap(
        target: mergedSeasonMap,
        source: sourceAsOwner,
      );

      final Player? memberProfile = playerMap[playerId];
      if (memberProfile != null &&
          !memberProfileShowsNonRosterOwnedTeams(memberProfile)) {
        for (final MapEntry<String, Map<String, Team>> seasonEntry
            in mergedSeasonMap.entries.toList()) {
          final Map<String, Team> teamMap = seasonEntry.value;
          teamMap.removeWhere(
            (String teamId, Team team) =>
                !shouldIncludeTeamInMemberProfileList(team, memberProfile),
          );
          if (teamMap.isEmpty) {
            mergedSeasonMap.remove(seasonEntry.key);
          }
        }
      }

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

    if (kDebugMode) {
      for (final MapEntry<String, Map<String, Map<String, Team>>> playerEntry
          in mergedTeams.entries) {
        final String playerId = playerEntry.key;
        final Map<String, Map<String, Team>> asPlayer =
            _teamsAsPlayerData[playerId] ?? const {};
        final Map<String, Map<String, Team>> asGrinta =
            _teamsAsGrintaPlayerData[playerId] ?? const {};
        final Map<String, Map<String, Team>> asManager =
            _teamsAsManagerData[playerId] ?? const {};
        final Map<String, Map<String, Team>> asOwner =
            _teamsAsOwnerData[playerId] ?? const {};

        String summarizeSource(Map<String, Map<String, Team>> source, String label) {
          if (source.isEmpty) return '$label=[]';
          final List<String> parts = <String>[];
          source.forEach((String seasonId, Map<String, Team> teamMap) {
            for (final Team team in teamMap.values) {
              parts.add(
                '$label:${team.keyTeam}(season=$seasonId,'
                'isGrinta=${team.isGrinta},'
                'players=${team.players?.length ?? 0},'
                'grintaPlayers=${team.grintaPlayers?.length ?? 0})',
              );
            }
          });
          return parts.join('; ');
        }

        debugPrint(
          'AppSession mergedTeams playerId=$playerId '
          '${summarizeSource(asPlayer, 'legacyPlayers')} | '
          '${summarizeSource(asGrinta, 'grintaRoster')} | '
          '${summarizeSource(asManager, 'manager')} | '
          '${summarizeSource(asOwner, 'owner')} | '
          'mergedCount=${playerEntry.value.values.fold<int>(0, (int n, Map<String, Team> m) => n + m.length)}',
        );
      }
    }
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
    final User? authUser = await _authUserReadyForAvatarResolution();

    playersPhotoUrls.remove('');

    for (final Player player in playersLst) {
      debugPrint('player=$player');

      normalizePlayerMemberId(player);
      final String? playerId = effectiveMemberId(player);
      if (playerId == null) continue;

      playerMap[playerId] = player;

      final urls = await PlayerService().getCachedPlayerAvatarUrls(
        player,
        authUser: authUser,
      );

      if (urls.isNotEmpty) {
        playersPhotoUrls[playerId] = urls;
      } else {
        playersPhotoUrls.remove(playerId);
      }
    }

    unawaited(_refreshAvatarsIfLinkedAuthPhotoMissing());
    _safeNotify();
    return playerMap;
  }

  /// Auth prêt avant résolution avatar. [User.reload] is mobile-only; on web
  /// it can hang indefinitely so [currentUser.photoURL] is used as-is.
  Future<User?> _authUserReadyForAvatarResolution() async {
    final User? initialUser = user ?? FirebaseAuth.instance.currentUser;
    if (initialUser == null) return null;

    User authUser = initialUser;

    if (kIsWeb) {
      final User? current = FirebaseAuth.instance.currentUser;
      if (current != null && current.uid == authUser.uid) {
        authUser = current;
        if (user?.uid == current.uid) {
          user = current;
        }
      }
      try {
        await authUser.reload().timeout(
          _kAuthReloadTimeout,
          onTimeout: () {
            debugPrint(
              'User.reload timed out during avatar resolution on web; '
              'using cached user',
            );
          },
        );
        final User? reloaded = FirebaseAuth.instance.currentUser;
        if (reloaded != null) {
          authUser = reloaded;
          if (user?.uid == reloaded.uid) {
            user = reloaded;
          }
        }
      } catch (_) {}
    } else {
      try {
        await authUser.reload().timeout(
          _kAuthReloadTimeout,
          onTimeout: () {
            debugPrint(
              'User.reload timed out during avatar resolution; using cached user',
            );
          },
        );
        final User? reloaded = FirebaseAuth.instance.currentUser;
        if (reloaded != null) {
          authUser = reloaded;
          if (user?.uid == reloaded.uid) {
            user = reloaded;
          }
        }
      } catch (_) {}
    }

    final User readyUser = authUser;
    if (readyUser.photoURL?.trim().isNotEmpty ?? false) {
      unawaited(UserAvatarService.instance.ensureCachedAuthPhoto(readyUser));
    }
    return readyUser;
  }

  /// Recharge les URLs avatar après onboarding ou changement Auth (évite cache stale).
  Future<void> refreshPlayerAvatarUrls({bool allowWebRetry = true}) async {
    final String? uid = user?.uid;
    if (uid == null) return;

    if (_avatarRefreshInFlight != null) {
      await _avatarRefreshInFlight;
      return;
    }

    if (_shouldDebounceAvatarRefresh()) {
      final User? liveAuthUser = FirebaseAuth.instance.currentUser ?? user;
      if (!_linkedPlayersMissingAuthPhoto(uid, liveAuthUser)) {
        return;
      }
    }

    _lastAvatarRefreshRequestAt = DateTime.now();
    _avatarRefreshInFlight = _refreshPlayerAvatarUrlsBody(
      uid: uid,
      allowWebRetry: allowWebRetry,
    );
    try {
      await _avatarRefreshInFlight;
    } finally {
      _avatarRefreshInFlight = null;
    }
  }

  bool _shouldDebounceAvatarRefresh() {
    final DateTime? lastRequest = _lastAvatarRefreshRequestAt;
    if (lastRequest == null) return false;
    return DateTime.now().difference(lastRequest) < _kAvatarRefreshDebounce;
  }

  Future<void> _refreshPlayerAvatarUrlsBody({
    required String uid,
    required bool allowWebRetry,
  }) async {
    var playersLst = players[uid]?.values.toList() ?? const [];
    if (playersLst.isEmpty) {
      playersLst = await PlayerService().getPlayersByUserId(uid);
    }
    if (playersLst.isEmpty) {
      if (allowWebRetry && kIsWeb && user?.uid == uid) {
        _scheduleWebAvatarPoll(uid: uid);
      }
      return;
    }

    PlayerService.clearPlayerPhotoUrlCache();
    playersPhotoUrls.remove('');
    final User? authUser = await _authUserReadyForAvatarResolution();

    for (final Player player in playersLst) {
      normalizePlayerMemberId(player);
      final String? playerId = effectiveMemberId(player);
      if (playerId == null) continue;

      final urls = await PlayerService().getCachedPlayerAvatarUrls(
        player,
        authUser: authUser,
      );

      if (urls.isNotEmpty) {
        playersPhotoUrls[playerId] = urls;
      } else {
        playersPhotoUrls.remove(playerId);
      }
    }

    _syncLastRefreshedAuthPhotoUrl(authUser);

    if (kDebugMode) {
      debugPrint(
        'refreshPlayerAvatarUrls uid=$uid '
        'authPhoto=${authUser?.photoURL ?? 'null'} '
        'playersPhotoUrls=$playersPhotoUrls',
      );
    }

    _safeNotify();

    if (!allowWebRetry || !kIsWeb || user?.uid != uid) {
      return;
    }

    if (!_linkedPlayersMissingAuthPhoto(uid, authUser)) {
      _stopWebAvatarPoll();
      return;
    }

    _scheduleWebAvatarPoll(uid: uid);
  }

  Future<void> _onAuthProfileMaybeUpdated(User? authUser) async {
    if (authUser == null) return;

    final String authUid = authUser.uid.trim();
    if (authUid.isEmpty) return;

    final String? sessionUid = user?.uid.trim();
    if (sessionUid != null && sessionUid != authUid) return;

    final String? previousPhoto = _liveAuthUserPhotoUrl();

    final User? liveUser = FirebaseAuth.instance.currentUser;
    if (liveUser != null && liveUser.uid.trim() == authUid) {
      user = liveUser;
    } else {
      user = authUser;
    }

    final String uid = authUid;
    final String? authPhoto = _liveAuthUserPhotoUrl(authUser: authUser);
    if (authPhoto != null &&
        authPhoto.isNotEmpty &&
        authPhoto != previousPhoto) {
      _resetWebAvatarPollBudget();
      _safeNotify();
    }
    if (authPhoto != null &&
        authPhoto.isNotEmpty &&
        authPhoto == _lastHandledAuthProfilePhotoUrl &&
        authPhoto == _lastRefreshedAuthPhotoUrl &&
        !_linkedPlayersMissingAuthPhoto(uid, authUser)) {
      return;
    }

    if (_avatarRefreshInFlight != null ||
        (_shouldDebounceAvatarRefresh() &&
            !_linkedPlayersMissingAuthPhoto(
              uid,
              FirebaseAuth.instance.currentUser ?? authUser,
            ))) {
      return;
    }

    if (authPhoto != null && authPhoto.isNotEmpty) {
      _lastHandledAuthProfilePhotoUrl = authPhoto;
    }

    if (_isDisposed || user?.uid != uid) return;

    await _refreshAvatarsIfLinkedAuthPhotoMissing(authUser: authUser);
  }

  /// True when a linked player has no own photo and session URLs lack Auth photo.
  bool _linkedPlayersMissingAuthPhoto(String uid, User? authUser) {
    final String? authPhoto = _liveAuthUserPhotoUrl(authUser: authUser);
    if (authPhoto == null || authPhoto.isEmpty) return true;

    final Map<String, Player> playerMap = players[uid] ?? {};
    if (playerMap.isEmpty) return true;

    for (final Player player in playerMap.values) {
      if (_linkedPlayerAvatarMissingAuthPhoto(
        player,
        uid,
        playersPhotoUrls[effectiveMemberId(player)],
        authPhoto,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _linkedPlayerAvatarMissingAuthPhoto(
    Player player,
    String uid,
    List<String>? urls,
    String authPhotoUrl,
  ) {
    if (!isPlayerLinkedToAuthUser(player, uid)) return false;
    if (hasPlayerPhoto(player)) return false;
    if (urls == null || urls.isEmpty) return true;
    return !_avatarUrlsContainAuthPhoto(urls, authPhotoUrl);
  }

  bool _avatarUrlsContainAuthPhoto(List<String> urls, String authPhotoUrl) {
    final normalizedAuth = _normalizePhotoUrl(authPhotoUrl);
    if (normalizedAuth.isEmpty) return false;

    for (final url in urls) {
      final normalized = _normalizePhotoUrl(url);
      if (normalized == normalizedAuth) return true;
      if (normalized.contains(normalizedAuth) ||
          normalizedAuth.contains(normalized)) {
        return true;
      }
    }
    return false;
  }

  String _normalizePhotoUrl(String url) {
    return url.trim().split('?').first;
  }

  /// Called by avatar widgets when session URLs look stale (default only).
  void requestAvatarRefreshIfStale() {
    if (_avatarRefreshInFlight != null) {
      return;
    }
    final String? uid = user?.uid;
    if (uid != null &&
        _shouldDebounceAvatarRefresh() &&
        !_linkedPlayersMissingAuthPhoto(
          uid,
          FirebaseAuth.instance.currentUser ?? user,
        )) {
      return;
    }
    unawaited(_refreshAvatarsIfLinkedAuthPhotoMissing());
  }

  /// True when [urls] for a linked player likely need an Auth photo refresh.
  bool sessionAvatarUrlsLookStale(Player player, List<String>? urls) {
    final String? uid = user?.uid;
    if (uid == null) return false;
    if (!isPlayerLinkedToAuthUser(player, uid)) return false;
    if (hasPlayerPhoto(player)) return false;
    if (urls == null || urls.isEmpty) return true;

    final String? authPhoto = _liveAuthUserPhotoUrl();
    if (authPhoto == null || authPhoto.isEmpty) return true;
    return !_avatarUrlsContainAuthPhoto(urls, authPhoto);
  }

  String? _liveAuthUserPhotoUrl({User? authUser}) {
    final User? liveUser = FirebaseAuth.instance.currentUser;
    final String? livePhoto = readAuthUserPhotoUrl(liveUser);
    if (livePhoto != null && livePhoto.isNotEmpty) {
      return livePhoto;
    }

    final String? eventPhoto = readAuthUserPhotoUrl(authUser);
    if (eventPhoto != null && eventPhoto.isNotEmpty) {
      return eventPhoto;
    }

    final String? sessionPhoto = readAuthUserPhotoUrl(user);
    if (sessionPhoto != null && sessionPhoto.isNotEmpty) {
      return sessionPhoto;
    }

    final String? cached = _oauthPhotoUrl?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    return null;
  }

  void _syncLastRefreshedAuthPhotoUrl(User? authUser) {
    final String? uid = user?.uid;
    final String? authPhoto = _liveAuthUserPhotoUrl(authUser: authUser);
    if (uid == null || authPhoto == null || authPhoto.isEmpty) return;

    if (_linkedPlayersMissingAuthPhoto(uid, authUser)) return;
    _lastRefreshedAuthPhotoUrl = authPhoto;
  }

  Future<void> _refreshAvatarsIfLinkedAuthPhotoMissing({User? authUser}) async {
    final String? uid = user?.uid;
    if (uid == null) return;

    if (_avatarRefreshInFlight != null) {
      return;
    }

    final User? resolvedAuthUser =
        authUser ?? await _authUserReadyForAvatarResolution();
    if (_isDisposed || user?.uid != uid) return;

    final String? authPhoto = _liveAuthUserPhotoUrl(authUser: resolvedAuthUser);
    if (authPhoto == null || authPhoto.isEmpty) {
      if (kIsWeb && !_webAvatarPollExhausted) {
        _scheduleWebAvatarPoll(uid: uid);
      }
      return;
    }

    if (!_linkedPlayersMissingAuthPhoto(uid, resolvedAuthUser)) {
      _lastRefreshedAuthPhotoUrl = authPhoto;
      _lastHandledAuthProfilePhotoUrl = authPhoto;
      _stopWebAvatarPoll();
      return;
    }

    await refreshPlayerAvatarUrls(allowWebRetry: kIsWeb);
  }

  void _scheduleWebAvatarPoll({required String uid}) {
    if (!kIsWeb || _isDisposed || _webAvatarPollExhausted) return;
    if (_webAvatarPollTimer != null) return;

    _webAvatarPollTimer = Timer.periodic(_kWebAvatarPollInterval, (timer) {
      unawaited(_runWebAvatarPollTick(uid: uid, timer: timer));
    });
  }

  Future<void> _runWebAvatarPollTick({
    required String uid,
    required Timer timer,
  }) async {
    if (_isDisposed || user?.uid != uid) {
      _stopWebAvatarPoll();
      return;
    }

    if (_webAvatarPollAttempts >= _kWebAvatarPollMaxAttempts) {
      _stopWebAvatarPoll(exhausted: true);
      return;
    }

    _webAvatarPollAttempts++;

    final User? authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || authUser.uid != uid) {
      _stopWebAvatarPoll();
      return;
    }

    await _refreshAvatarsIfLinkedAuthPhotoMissing(authUser: authUser);

    if (_isDisposed || user?.uid != uid) {
      _stopWebAvatarPoll();
      return;
    }

    if (!_linkedPlayersMissingAuthPhoto(uid, authUser)) {
      _stopWebAvatarPoll();
      return;
    }

    if (_webAvatarPollAttempts >= _kWebAvatarPollMaxAttempts) {
      _stopWebAvatarPoll(exhausted: true);
    }
  }

  void _stopWebAvatarPoll({bool exhausted = false}) {
    _webAvatarPollTimer?.cancel();
    _webAvatarPollTimer = null;
    if (exhausted) {
      _webAvatarPollExhausted = true;
    }
    _webAvatarPollAttempts = 0;
  }

  void _resetWebAvatarPollBudget() {
    _webAvatarPollExhausted = false;
    _webAvatarPollAttempts = 0;
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
    if (selectedSeasonId != null &&
        _allSeasonMap.containsKey(selectedSeasonId)) {
      selectedSeason = _allSeasonMap[selectedSeasonId];
      return;
    }

    selectedSeason = _defaultSeasonFrom(_allSeasonMap);
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
      selectedSeason = currentSeason;
      return;
    }

    final String? selectedSeasonId = selectedSeason?.ref?.id;

    if (selectedSeasonId != null && playerSeasons.containsKey(selectedSeasonId)) {
      selectedSeason = playerSeasons[selectedSeasonId];
      return;
    }

    selectedSeason = _defaultSeasonFrom(playerSeasons);
  }

  Season? _defaultSeasonFrom(Map<String, Season> availableSeasons) {
    final String? currentSeasonId = currentSeason?.ref?.id;
    if (currentSeasonId != null &&
        availableSeasons.containsKey(currentSeasonId)) {
      return availableSeasons[currentSeasonId];
    }

    if (availableSeasons.isEmpty) {
      return currentSeason;
    }

    final List<Season> sorted = availableSeasons.values.toList()
      ..sort((Season a, Season b) {
        final DateTime? aStart = a.startDate?.toDate();
        final DateTime? bStart = b.startDate?.toDate();
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return bStart.compareTo(aStart);
      });

    return sorted.first;
  }

  bool _isCurrentGeneration(int generation, String firebaseUid) {
    return !_isDisposed &&
        generation == _listenerGeneration &&
        user?.uid == firebaseUid;
  }

  Future<void> _removePlayerSubscriptions(String playerId) async {
    await _teamsAsPlayerSubs.remove(playerId)?.cancel();
    await _teamsAsManagerSubs.remove(playerId)?.cancel();
    await _teamsAsGrintaPlayerSubs.remove(playerId)?.cancel();
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

    for (final StreamSubscription<List<Team>> sub
        in _teamsAsGrintaPlayerSubs.values) {
      await sub.cancel();
    }
    _teamsAsGrintaPlayerSubs.clear();

    await _teamsAsOwnerSub?.cancel();
    _teamsAsOwnerSub = null;
  }

  /// Removes [teamId] from all in-memory team caches after a successful delete.
  void removeTeamFromSession(String teamId) {
    final String trimmedTeamId = teamId.trim();
    if (trimmedTeamId.isEmpty) {
      return;
    }

    var removed = false;

    void removeFromSource(Map<String, Map<String, Map<String, Team>>> source) {
      for (final MapEntry<String, Map<String, Map<String, Team>>> playerEntry
          in source.entries.toList()) {
        final Map<String, Map<String, Team>> seasonMaps = playerEntry.value;
        for (final MapEntry<String, Map<String, Team>> seasonEntry
            in seasonMaps.entries.toList()) {
          if (seasonEntry.value.remove(trimmedTeamId) != null) {
            removed = true;
          }
          if (seasonEntry.value.isEmpty) {
            seasonMaps.remove(seasonEntry.key);
          }
        }
        if (seasonMaps.isEmpty) {
          source.remove(playerEntry.key);
        }
      }
    }

    removeFromSource(_teamsAsPlayerData);
    removeFromSource(_teamsAsManagerData);
    removeFromSource(_teamsAsGrintaPlayerData);
    removeFromSource(_teamsAsOwnerData);

    if (!removed) {
      return;
    }

    _rebuildMergedTeamsAndSeasons();
    _syncSelectedPlayerAndSeason();
    _safeNotify();
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

  /// Persists the managed-team selection shared by Dashboard and Analyse charge.
  void setSelectedManagedTeamId(String? teamId) {
    final trimmed = teamId?.trim();
    final next = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    if (selectedManagedTeamId == next) return;
    selectedManagedTeamId = next;
    _safeNotify();
  }

  /// Persists Semaine / Mois / Personnalisé shared by Dashboard and Analyse charge.
  void setSelectedCoachFilterPeriod(
    CoachFilterPeriod period, {
    DateTimeRange? customRange,
  }) {
    final DateTimeRange? nextCustom = period == CoachFilterPeriod.custom
        ? (customRange == null
            ? selectedCoachFilterCustomRange
            : DateTimeRange(
                start: DateTime(
                  customRange.start.year,
                  customRange.start.month,
                  customRange.start.day,
                ),
                end: DateTime(
                  customRange.end.year,
                  customRange.end.month,
                  customRange.end.day,
                ),
              ))
        : null;
    if (selectedCoachFilterPeriod == period &&
        selectedCoachFilterCustomRange == nextCustom) {
      return;
    }
    selectedCoachFilterPeriod = period;
    selectedCoachFilterCustomRange = nextCustom;
    _safeNotify();
  }

  /// Resolves a managed team id still valid for the selected season.
  String? resolveSelectedManagedTeamId({List<String>? preferredOrder}) {
    final managedIds = managedTeamsIdsForSelectedSeason
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (managedIds.isEmpty) return null;

    final current = selectedManagedTeamId?.trim() ?? '';
    if (current.isNotEmpty && managedIds.contains(current)) {
      return current;
    }

    for (final id in preferredOrder ?? const <String>[]) {
      final trimmed = id.trim();
      if (trimmed.isNotEmpty && managedIds.contains(trimmed)) {
        return trimmed;
      }
    }

    return managedIds.first;
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

  /// Identifiants d'équipes du profil sélectionné pour la saison courante.
  List<String> get teamIdsForSelectedSeason {
    return teamsForAgendaSelectedSeason
        .map((Team team) => team.keyTeam)
        .whereType<String>()
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toList();
  }

  /// Teams the selected player manages for the selected season.
  ///
  /// Includes manager/owner session caches and any merged team where the
  /// signed-in user is [Team.uid] or listed in [Team.managers] (same rules as
  /// [canManageTeam] on team detail).
  List<Team> get managerTeamsForSelectedSeason {
    final String? playerId = selectedPlayerId;
    final String? seasonId = selectedSeason?.ref?.id;
    if (playerId == null || seasonId == null) {
      return const <Team>[];
    }

    final Map<String, Team>? seasonTeams = teams[playerId]?[seasonId];
    if (seasonTeams == null || seasonTeams.isEmpty) {
      return const <Team>[];
    }

    final String? currentUserUid = user?.uid;
    final Set<String> sessionManagedIds =
        managedTeamsIdsForSelectedSeason.toSet();

    return seasonTeams.values
        .where((Team team) {
          final String teamId = team.keyTeam?.trim() ?? '';
          return canManageTeam(
            team,
            currentUserUid,
            isManager:
                teamId.isNotEmpty && sessionManagedIds.contains(teamId),
          );
        })
        .toList();
  }

  /// Teams where the selected player is on the roster or a Grinta member,
  /// for the selected season (excludes manager/owner-only access).
  List<Team> get memberTeamsForSelectedSeason {
    final String? playerId = selectedPlayerId;
    final String? seasonId = selectedSeason?.ref?.id;
    if (playerId == null || seasonId == null) {
      return const <Team>[];
    }

    final Map<String, Team> merged = <String, Team>{};

    void absorb(Map<String, Map<String, Map<String, Team>>> source) {
      final Map<String, Team>? seasonTeams = source[playerId]?[seasonId];
      if (seasonTeams != null) {
        merged.addAll(seasonTeams);
      }
    }

    absorb(_teamsAsPlayerData);
    absorb(_teamsAsGrintaPlayerData);

    return merged.values.toList();
  }

  /// Teams whose matches/trainings should appear on the agenda for the
  /// selected season (roster, Grinta member, manager, or owner).
  List<Team> get teamsForAgendaSelectedSeason {
    final String? playerId = selectedPlayerId;
    final String? seasonId = selectedSeason?.ref?.id;
    if (playerId == null || seasonId == null) {
      return const <Team>[];
    }

    final Map<String, Team> merged = <String, Team>{};

    void absorb(Map<String, Map<String, Map<String, Team>>> source) {
      final Map<String, Team>? seasonTeams = source[playerId]?[seasonId];
      if (seasonTeams != null) {
        merged.addAll(seasonTeams);
      }
    }

    absorb(_teamsAsPlayerData);
    absorb(_teamsAsGrintaPlayerData);
    absorb(_teamsAsManagerData);
    absorb(_teamsAsOwnerData);

    return merged.values.toList();
  }

  /// Stable key fragment for agenda reload when team membership changes.
  String get agendaTeamsKey {
    final List<String> teamIds = teamsForAgendaSelectedSeason
        .map((Team team) => team.keyTeam)
        .whereType<String>()
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toList()
      ..sort();
    return teamIds.join(',');
  }

  void clear() {
    _listenerGeneration++;
    _initInFlight = null;
    _initInFlightUid = null;
    unawaited(_cancelDataSubscriptions());

    user = null;
    players.clear();
    teams.clear();
    seasons.clear();
    playersPhotoUrls.clear();
    PlayerService.clearPlayerPhotoUrlCache();
    _teamsAsPlayerData.clear();
    _teamsAsManagerData.clear();
    _teamsAsGrintaPlayerData.clear();
    _teamsAsOwnerData.clear();
    _allSeasonMap.clear();
    currentSeason = null;
    selectedSeason = null;
    selectedPlayerId = null;
    isLoading = false;
    _lastInitializedUid = null;
    _lastRefreshedAuthPhotoUrl = null;
    _lastHandledAuthProfilePhotoUrl = null;
    _oauthPhotoUrl = null;
    _lastAvatarRefreshRequestAt = null;
    _webAvatarPollExhausted = false;
    _stopWebAvatarPoll();

    _safeNotify();
  }

  void _safeNotify() {
    if (_isDisposed) return;

    final SchedulerBinding scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.idle) {
      notifyListeners();
      return;
    }

    scheduler.addPostFrameCallback((_) {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _listenerGeneration++;
    unawaited(_cancelDataSubscriptions());
    unawaited(_authSub?.cancel());
    unawaited(_userProfileSub?.cancel());
    unawaited(_idTokenSub?.cancel());
    _stopWebAvatarPoll();
    super.dispose();
  }
}