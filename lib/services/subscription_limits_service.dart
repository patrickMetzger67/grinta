import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/subscription_state.dart';
import 'package:grinta/model/subscription_tier_limits.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/util/player_positions.dart';
import 'package:grinta/services/effectivesService.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/subscription_service.dart';
import 'package:grinta/services/teamService.dart';
import 'package:grinta/services/user_trial_service.dart';

/// Loads tier caps from Firestore and resolves the active profile for the user.
///
/// ## Firestore schema
/// Document: `config/subscription_limits`
/// ```json
/// {
///   "coach_basic": { "maxTeams": 1, "maxPlayersPerTeam": 20 },
///   "coach_elite": { "maxTeams": 3, "maxPlayersPerTeam": 22 },
///   "coach_pro": { "maxTeams": 5, "maxPlayersPerTeam": 25 },
///   "player": {
///     "maxTeams": 3,
///     "maxPlayersPerTeam": 1,
///     "maxProfiles": 3,
///     "allowOnlySelfAsPlayer": true
///   },
///   "maxProfilesFreePlayer": 1,
///   "maxTeamsFreePlayer": 1,
///   "trial": { "maxTeams": 1, "maxPlayersPerTeam": 20, "maxProfiles": 1 }
/// }
/// ```
///
/// Edit this document in the Firebase console to change limits without redeploying.
class SubscriptionLimitsService {
  SubscriptionLimitsService._();

  static final SubscriptionLimitsService instance = SubscriptionLimitsService._();

  static const String collectionName = 'config';
  static const String documentId = 'subscription_limits';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<SubscriptionLimitsTier, SubscriptionTierLimits> _limits =
      SubscriptionTierLimitsDefaults.all();
  int _maxProfilesFreePlayer =
      SubscriptionTierLimitsDefaults.maxProfilesFreePlayer;
  int _maxTeamsFreePlayer =
      SubscriptionTierLimitsDefaults.maxTeamsFreePlayer;
  bool _initialized = false;
  Future<void>? _initFuture;

  Map<SubscriptionLimitsTier, SubscriptionTierLimits> get limits =>
      Map<SubscriptionLimitsTier, SubscriptionTierLimits>.unmodifiable(_limits);

  int get maxProfilesFreePlayer => _maxProfilesFreePlayer;

  int get maxTeamsFreePlayer => _maxTeamsFreePlayer;

  bool get isInitialized => _initialized;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initFuture ??= _load();
    await _initFuture;
  }

  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await ensureInitialized();
  }

  Future<void> _load() async {
    var resolved = (
      SubscriptionTierLimitsDefaults.all(),
      SubscriptionTierLimitsDefaults.maxProfilesFreePlayer,
      SubscriptionTierLimitsDefaults.maxTeamsFreePlayer,
    );

    try {
      final doc = await _firestore.collection(collectionName).doc(documentId).get();
      if (doc.exists) {
        resolved = _parseDocument(doc.data());
      } else if (kDebugMode) {
        debugPrint(
          'SubscriptionLimitsService: $collectionName/$documentId missing — '
          'using built-in defaults',
        );
      }
    } catch (e, st) {
      debugPrint('SubscriptionLimitsService load failed: $e\n$st');
    }

    _limits = resolved.$1;
    _maxProfilesFreePlayer = resolved.$2;
    _maxTeamsFreePlayer = resolved.$3;
    _initialized = true;
    _logLoadedLimits();
  }

  (Map<SubscriptionLimitsTier, SubscriptionTierLimits>, int, int) _parseDocument(
    Map<String, dynamic>? data,
  ) {
    if (data == null || data.isEmpty) {
      return (
        SubscriptionTierLimitsDefaults.all(),
        SubscriptionTierLimitsDefaults.maxProfilesFreePlayer,
        SubscriptionTierLimitsDefaults.maxTeamsFreePlayer,
      );
    }

    final defaults = SubscriptionTierLimitsDefaults.all();
    final parsed = Map<SubscriptionLimitsTier, SubscriptionTierLimits>.from(defaults);
    var maxProfilesFreePlayer =
        SubscriptionTierLimitsDefaults.maxProfilesFreePlayer;
    var maxTeamsFreePlayer =
        SubscriptionTierLimitsDefaults.maxTeamsFreePlayer;
    final rawFreeMax = data['maxProfilesFreePlayer'];
    if (rawFreeMax is int) {
      maxProfilesFreePlayer = rawFreeMax;
    } else if (rawFreeMax is num) {
      maxProfilesFreePlayer = rawFreeMax.toInt();
    }
    final rawFreeTeamMax = data['maxTeamsFreePlayer'];
    if (rawFreeTeamMax is int) {
      maxTeamsFreePlayer = rawFreeTeamMax;
    } else if (rawFreeTeamMax is num) {
      maxTeamsFreePlayer = rawFreeTeamMax.toInt();
    }

    for (final entry in data.entries) {
      final tier = SubscriptionTierLimitsDefaults.tierFromFirestoreKey(entry.key);
      if (tier == null) continue;

      final raw = entry.value;
      if (raw is! Map) continue;

      final map = Map<String, dynamic>.from(raw);
      try {
        parsed[tier] = SubscriptionTierLimits.fromMap(map);
      } catch (_) {
        if (kDebugMode) {
          debugPrint(
            'SubscriptionLimitsService: invalid limits for ${entry.key}, '
            'keeping default',
          );
        }
      }
    }

    return (parsed, maxProfilesFreePlayer, maxTeamsFreePlayer);
  }

  void _logLoadedLimits() {
    if (!kDebugMode) return;
    final buffer = StringBuffer('SubscriptionLimitsService: active limits\n');
    for (final tier in SubscriptionLimitsTier.values) {
      final limits = _limits[tier] ?? SubscriptionTierLimitsDefaults.all()[tier]!;
      buffer.writeln(
        '  ${SubscriptionTierLimitsDefaults.firestoreKeyFor(tier)}: '
        'maxTeams=${limits.maxTeams}, '
        'maxPlayersPerTeam=${limits.maxPlayersPerTeam}, '
        'maxProfiles=${limits.maxProfiles}'
        '${limits.allowOnlySelfAsPlayer ? ', allowOnlySelfAsPlayer=true' : ''}',
      );
    }
    buffer.writeln('  maxProfilesFreePlayer=$_maxProfilesFreePlayer');
    buffer.writeln('  maxTeamsFreePlayer=$_maxTeamsFreePlayer');
    debugPrint(buffer.toString());
  }

  SubscriptionTierLimits limitsForTier(SubscriptionLimitsTier tier) {
    return _limits[tier] ?? SubscriptionTierLimitsDefaults.all()[tier]!;
  }

  /// Highest-priority active profile: coach entitlement > player > trial > basic.
  SubscriptionLimitsTier resolveEffectiveTier({
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) {
    final sub = subscription ?? SubscriptionService.instance;
    final trialService = trial ?? UserTrialService.instance;

    final coachTier = sub.coachTier;
    if (coachTier != null) {
      return SubscriptionTierLimitsDefaults.fromCoachTier(coachTier);
    }

    if (sub.hasPlayerSubscription) {
      return SubscriptionLimitsTier.player;
    }

    if (trialService.shouldShowTrial) {
      return SubscriptionLimitsTier.trial;
    }

    return SubscriptionLimitsTier.coachBasic;
  }

  SubscriptionTierLimits effectiveLimits({
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) {
    return limitsForTier(
      resolveEffectiveTier(subscription: subscription, trial: trial),
    );
  }

  Future<int> maxProfilesForUser({
    SubscriptionService? subscription,
  }) async {
    await ensureInitialized();
    final sub = subscription ?? SubscriptionService.instance;

    final coachTier = sub.coachTier;
    if (coachTier != null) {
      return limitsForTier(
        SubscriptionTierLimitsDefaults.fromCoachTier(coachTier),
      ).maxProfiles;
    }

    if (sub.hasPlayerSubscription) {
      return limitsForTier(SubscriptionLimitsTier.player).maxProfiles;
    }

    return _maxProfilesFreePlayer;
  }

  Future<int> maxTeamsForUser({
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) async {
    await ensureInitialized();
    await (subscription ?? SubscriptionService.instance).refreshForActiveSession();
    await (trial ?? UserTrialService.instance).ensureInitialized();
    return _maxTeamsForUserSync(
      subscription ?? SubscriptionService.instance,
      trial: trial,
    );
  }

  TeamCreationGate resolveTeamCreationGate(
    int currentTeamCount, {
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) {
    final sub = subscription ?? SubscriptionService.instance;
    final maxTeams = _maxTeamsForUserSync(sub, trial: trial);

    if (currentTeamCount < maxTeams) {
      return TeamCreationGate.allowed;
    }

    if (!sub.hasActivePaidSubscription) {
      return TeamCreationGate.needsUpgrade;
    }

    if (sub.coachTier == CoachTier.basic) {
      return TeamCreationGate.needsUpgrade;
    }

    return TeamCreationGate.atMaxLimit;
  }

  Future<int> countTeamsForUser({
    required String userId,
    required String seasonId,
    String? playerId,
    Player? player,
    SubscriptionService? subscription,
  }) async {
    final sub = subscription ?? SubscriptionService.instance;
    if (sub.coachTier != null) {
      final teams = await TeamService().getTeamsBySeasonIdAndManager(
        seasonId: seasonId,
        userId: userId,
      );
      return teams.length;
    }

    return _countPlayerProfileTeamsInSeason(
      userId: userId,
      seasonId: seasonId,
      playerId: playerId,
      player: player,
    );
  }

  /// Teams linked to a player profile in [seasonId] (owner, roster, or manager).
  Future<int> _countPlayerProfileTeamsInSeason({
    required String userId,
    required String seasonId,
    String? playerId,
    Player? player,
  }) async {
    final normalizedSeasonId = seasonId.trim();
    if (normalizedSeasonId.isEmpty) {
      return 0;
    }

    final teamService = TeamService();
    final Map<String, Team> merged = <String, Team>{};

    void absorb(Iterable<Team> teams) {
      for (final Team team in teams) {
        if ((team.seasonID?.trim() ?? '') != normalizedSeasonId) {
          continue;
        }
        final String? key = team.keyTeam?.trim();
        if (key == null || key.isEmpty) {
          continue;
        }
        merged[key] = team;
      }
    }

    final String trimmedPlayerId = playerId?.trim() ?? '';
    if (trimmedPlayerId.isNotEmpty) {
      absorb(await teamService.getTeamsByPlayerId(trimmedPlayerId));
    }

    if (player != null) {
      absorb(await teamService.getTeamsForPlayerGrintaMembership(player));
      if (player.userID?.trim() == userId.trim()) {
        absorb(await teamService.getTeamsForAManger(userId));
      }
    } else if (trimmedPlayerId.isNotEmpty) {
      absorb(await teamService.getTeamsByGrintaPlayerMemberId(trimmedPlayerId));
    }

    absorb(await teamService.getTeamsByOwnerUid(userId));

    return merged.length;
  }

  ProfileCreationGate resolveProfileCreationGate(
    int currentProfileCount, {
    SubscriptionService? subscription,
  }) {
    final sub = subscription ?? SubscriptionService.instance;
    final maxProfiles = _maxProfilesForUserSync(sub);

    if (currentProfileCount < maxProfiles) {
      return ProfileCreationGate.allowed;
    }

    if (!sub.hasActivePaidSubscription) {
      return ProfileCreationGate.needsUpgrade;
    }

    if (sub.coachTier == CoachTier.basic) {
      return ProfileCreationGate.needsUpgrade;
    }

    return ProfileCreationGate.atMaxLimit;
  }

  Future<bool> canCreateProfile({
    required int currentProfileCount,
    SubscriptionService? subscription,
  }) async {
    await ensureInitialized();
    await (subscription ?? SubscriptionService.instance).refreshForActiveSession();
    return resolveProfileCreationGate(
          currentProfileCount,
          subscription: subscription,
        ) ==
        ProfileCreationGate.allowed;
  }

  Future<void> assertCanCreateProfile({
    required int currentProfileCount,
    SubscriptionService? subscription,
  }) async {
    await ensureInitialized();
    await (subscription ?? SubscriptionService.instance).refreshForActiveSession();

    final sub = subscription ?? SubscriptionService.instance;
    final gate = resolveProfileCreationGate(
      currentProfileCount,
      subscription: sub,
    );

    switch (gate) {
      case ProfileCreationGate.allowed:
        return;
      case ProfileCreationGate.needsUpgrade:
        throw SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxProfiles,
          tier: _profileLimitTier(sub),
          limit: await maxProfilesForUser(subscription: sub),
          requiresUpgrade: true,
        );
      case ProfileCreationGate.atMaxLimit:
        throw SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxProfiles,
          tier: _profileLimitTier(sub),
          limit: await maxProfilesForUser(subscription: sub),
        );
    }
  }

  int _maxProfilesForUserSync(SubscriptionService sub) {
    final coachTier = sub.coachTier;
    if (coachTier != null) {
      return limitsForTier(
        SubscriptionTierLimitsDefaults.fromCoachTier(coachTier),
      ).maxProfiles;
    }

    if (sub.hasPlayerSubscription) {
      return limitsForTier(SubscriptionLimitsTier.player).maxProfiles;
    }

    return _maxProfilesFreePlayer;
  }

  SubscriptionLimitsTier _profileLimitTier(SubscriptionService sub) {
    final coachTier = sub.coachTier;
    if (coachTier != null) {
      return SubscriptionTierLimitsDefaults.fromCoachTier(coachTier);
    }
    if (sub.hasPlayerSubscription) {
      return SubscriptionLimitsTier.player;
    }
    return SubscriptionLimitsTier.coachBasic;
  }

  int _maxTeamsForUserSync(
    SubscriptionService sub, {
    UserTrialService? trial,
  }) {
    final coachTier = sub.coachTier;
    if (coachTier != null) {
      return limitsForTier(
        SubscriptionTierLimitsDefaults.fromCoachTier(coachTier),
      ).maxTeams;
    }

    if (sub.hasPlayerSubscription) {
      return limitsForTier(SubscriptionLimitsTier.player).maxTeams;
    }

    final trialService = trial ?? UserTrialService.instance;
    if (trialService.shouldShowTrial) {
      return limitsForTier(SubscriptionLimitsTier.trial).maxTeams;
    }

    return _maxTeamsFreePlayer;
  }

  SubscriptionLimitsTier _teamLimitTier(SubscriptionService sub) {
    return _profileLimitTier(sub);
  }

  Future<void> assertCanCreateTeam({
    required String userId,
    required String seasonId,
    String? playerId,
    Player? player,
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) async {
    await ensureInitialized();
    await (subscription ?? SubscriptionService.instance).refreshForActiveSession();
    await (trial ?? UserTrialService.instance).ensureInitialized();

    final sub = subscription ?? SubscriptionService.instance;
    final teamCount = await countTeamsForUser(
      userId: userId,
      seasonId: seasonId,
      playerId: playerId,
      player: player,
      subscription: sub,
    );
    final gate = resolveTeamCreationGate(
      teamCount,
      subscription: sub,
      trial: trial,
    );

    switch (gate) {
      case TeamCreationGate.allowed:
        return;
      case TeamCreationGate.needsUpgrade:
        throw SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxTeams,
          tier: _teamLimitTier(sub),
          limit: await maxTeamsForUser(subscription: sub, trial: trial),
          requiresUpgrade: true,
        );
      case TeamCreationGate.atMaxLimit:
        throw SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.maxTeams,
          tier: _teamLimitTier(sub),
          limit: await maxTeamsForUser(subscription: sub, trial: trial),
        );
    }
  }

  Future<void> assertCanAddPlayer({
    required String teamId,
    required String memberId,
    String? firebaseUserId,
    SubscriptionService? subscription,
    UserTrialService? trial,
  }) async {
    await ensureInitialized();
    await (subscription ?? SubscriptionService.instance).refreshForActiveSession();
    await (trial ?? UserTrialService.instance).ensureInitialized();

    final tier = resolveEffectiveTier(subscription: subscription, trial: trial);
    final caps = limitsForTier(tier);
    final uid = firebaseUserId ?? FirebaseAuth.instance.currentUser?.uid;

    if (caps.allowOnlySelfAsPlayer) {
      final allowed = await _memberBelongsToFirebaseUser(
        memberId: memberId,
        firebaseUserId: uid,
      );
      if (!allowed) {
        throw SubscriptionLimitExceeded(
          violation: SubscriptionLimitViolation.playerTierOnlySelf,
          tier: tier,
        );
      }
    }

    final rosterCount = await _countRosterPlayers(teamId);
    if (rosterCount >= caps.maxPlayersPerTeam) {
      throw SubscriptionLimitExceeded(
        violation: SubscriptionLimitViolation.maxPlayersPerTeam,
        tier: tier,
        limit: caps.maxPlayersPerTeam,
      );
    }
  }

  Future<bool> _memberBelongsToFirebaseUser({
    required String memberId,
    required String? firebaseUserId,
  }) async {
    if (firebaseUserId == null || firebaseUserId.isEmpty) return false;

    final trimmedMemberId = memberId.trim();
    if (trimmedMemberId.isEmpty) return false;

    final playerService = PlayerService();
    final playersForUser =
        await playerService.getPlayersByUserId(firebaseUserId);
    for (final player in playersForUser) {
      final key = player.keyMember?.trim() ?? '';
      if (key.isNotEmpty && key == trimmedMemberId) return true;
    }

    Player? player = await playerService.getPlayerById(trimmedMemberId);
    player ??= await playerService.getPlayerByUserId(trimmedMemberId);
    if (player == null) return false;

    if (player.userID?.trim() == firebaseUserId) return true;

    for (final dynamic raw in player.users ?? const <dynamic>[]) {
      if (raw?.toString().trim() == firebaseUserId) return true;
    }

    return false;
  }

  Future<int> _countRosterPlayers(String teamId) async {
    final team = await TeamService().getTeamById(teamId);
    if (team != null && team.isGrinta == true) {
      return _countGrintaRosterPlayers(team);
    }

    final effectives = await EffectivesService().getEffectivesByTeamId(teamId);
    return effectives.where((Effectives e) => e.type == 0).length;
  }

  int _countGrintaRosterPlayers(Team team) {
    final Set<String> managerIds = _managerIdsFromTeam(team);
    var count = 0;
    for (final GrintaPlayer grintaPlayer
        in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      if (grintaPlayer.playerId.trim().isEmpty) {
        continue;
      }
      if (isGrintaRosterStaff(
        positions: grintaPlayer.positions,
        listedInManagers:
            managerIds.contains(grintaPlayer.playerId.trim()),
      )) {
        continue;
      }
      count++;
    }
    return count;
  }

  static Set<String> _managerIdsFromTeam(Team team) {
    final Set<String> ids = <String>{};
    for (final dynamic raw in team.managers ?? const <dynamic>[]) {
      if (raw is! String) {
        continue;
      }
      final String id = raw.trim();
      if (id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids;
  }
}
