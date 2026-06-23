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
import 'package:grinta/util/player_photo_resolver.dart';

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

  StreamSubscription<User?>? _authSub;
  StreamSubscription<User?>? _userProfileSub;
  StreamSubscription<User?>? _idTokenSub;
  StreamSubscription<List<Player>>? _playersSub;
  StreamSubscription<List<Season>>? _seasonsSub;

  final Map<String, StreamSubscription<List<Team>>> _teamsAsPlayerSubs = {};
  final Map<String, StreamSubscription<List<Team>>> _teamsAsManagerSubs = {};

  /// Données internes séparées pour éviter qu’un flux écrase l’autre
  final Map<String, Map<String, Map<String, Team>>> _teamsAsPlayerData = {};
  final Map<String, Map<String, Map<String, Team>>> _teamsAsManagerData = {};


  Map<String, Season> _allSeasonMap = {};

  bool _isDisposed = false;

  String? _lastInitializedUid;
  int _listenerGeneration = 0;
  Future<void>? _initInFlight;
  String? _initInFlightUid;
  String? _lastRefreshedAuthPhotoUrl;
  String? _lastHandledAuthProfilePhotoUrl;
  Future<void>? _avatarRefreshInFlight;
  DateTime? _lastAvatarRefreshRequestAt;
  Timer? _webAvatarPollTimer;
  int _webAvatarPollAttempts = 0;
  bool _webAvatarPollExhausted = false;

  /// WEB AVATAR RACE — do not re-add Firestore Storage URLs to the display
  /// chain (see [resolvePlayerAvatarUrls]).
  ///
  /// On web, [authStateChanges] often fires before OAuth providers populate
  /// [User.photoURL]. [User.reload] hangs on web and must not be called there;
  /// use [FirebaseAuth.currentUser.photoURL] directly. [userChanges] and
  /// [idTokenChanges] plus a capped timed poll cover late photoURL arrival.
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
    final String? seasonId = selectedSeason?.ref?.id;
    if (seasonId == null) return false;

    Map<String, Map<String, Team>>? teamsAsManager = _teamsAsManagerData[selectedPlayerId];
    if(teamsAsManager == null || teamsAsManager.isEmpty) return false;
    Map<String, Team>? teamsForSeasonId = teamsAsManager[seasonId];
    if(teamsForSeasonId == null || teamsForSeasonId.isEmpty) return false;

    return true;
  }

  List<String> get managedTeamsIdsForSelectedSeason {
    List<String> ids = [];

    final String? seasonId = selectedSeason?.ref?.id;
    if (seasonId == null) return ids;

    Map<String, Map<String, Team>>? teamsAsManager = _teamsAsManagerData[selectedPlayerId];
    if(teamsAsManager == null || teamsAsManager.isEmpty) return ids;
    Map<String, Team>? teamsForSeasonId = teamsAsManager[seasonId];
    if(teamsForSeasonId == null || teamsForSeasonId.isEmpty) return ids;


    for (final entry in teamsForSeasonId.entries) {
        final String teamId = entry.key;
        ids.add(teamId);
    }
    return ids;
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

    if (result.isEmpty) {
      return _currentSeasonsFromCache();
    }

    return result;
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
      user = firebaseUser;

      players.clear();
      teams.clear();
      seasons.clear();
      playersPhotoUrls.clear();
      PlayerService.clearPlayerPhotoUrlCache();
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
    final User? authUser = await _authUserReadyForAvatarResolution();

    for (final Player player in playersLst) {
      debugPrint('player=$player');

      if (player.keyMember == null) continue;
      final String playerId = player.keyMember!;
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
    final User? authUser = await _authUserReadyForAvatarResolution();

    for (final Player player in playersLst) {
      final String? playerId = player.keyMember;
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

    final String? uid = user?.uid;
    if (uid == null || uid != authUser.uid) return;

    if (user?.uid == authUser.uid) {
      user = authUser;
    }

    final String? authPhoto = _liveAuthUserPhotoUrl(authUser: authUser);
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
        playersPhotoUrls[player.keyMember],
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
    if (authPhoto == null || authPhoto.isEmpty) return kIsWeb;
    return !_avatarUrlsContainAuthPhoto(urls, authPhoto);
  }

  String? _liveAuthUserPhotoUrl({User? authUser}) {
    final User? liveUser = FirebaseAuth.instance.currentUser;
    final String? livePhoto = liveUser?.photoURL?.trim();
    if (livePhoto != null && livePhoto.isNotEmpty) {
      return livePhoto;
    }

    final String? eventPhoto = authUser?.photoURL?.trim();
    if (eventPhoto != null && eventPhoto.isNotEmpty) {
      return eventPhoto;
    }

    return user?.photoURL?.trim();
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
      selectedSeason = currentSeason;
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
    _allSeasonMap.clear();
    currentSeason = null;
    selectedSeason = null;
    selectedPlayerId = null;
    isLoading = false;
    _lastInitializedUid = null;
    _lastRefreshedAuthPhotoUrl = null;
    _lastHandledAuthProfilePhotoUrl = null;
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