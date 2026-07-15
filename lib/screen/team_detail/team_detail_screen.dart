import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grinta/core/extensions/app_localizations_effectives_extension.dart';
import 'package:grinta/analytics/analytics_features.dart';
import 'package:grinta/analytics/analytics_interactions.dart';
import 'package:grinta/analytics/analytics_routes.dart';
import 'package:grinta/analytics/analytics_screen_names.dart';
import 'package:grinta/core/extensions/l10n_extension.dart';
import 'package:grinta/l10n/app_localizations.dart';
import 'package:grinta/model/grinta_player.dart';
import 'package:grinta/model/grinta_player_hw.dart';
import 'package:grinta/model/effectives.dart';
import 'package:grinta/model/invitation.dart';
import 'package:grinta/model/player.dart';
import 'package:grinta/model/team.dart';
import 'package:grinta/model/tracker/deviceOwner.dart';
import 'package:grinta/provider/appSession.dart';
import 'package:grinta/screen/team_param_screen.dart';
import 'package:provider/provider.dart';
import 'package:grinta/services/playerService.dart';
import 'package:grinta/services/teamService.dart';
import '../../util/app_snackbar.dart';
import '../../util/app_theme.dart';
import '../../util/player_positions.dart';
import '../../util/playerDisplayName.dart';
import '../../util/subscription_limits_access.dart';
import '../../util/team_deletion_access.dart';
import '../../util/team_tracker_access.dart';
import '../../util/player_photo_resolver.dart';
import '../../util/player_profile_validator.dart';

import '../../model/tracker/owner.dart';
import '../../services/effectivesService.dart';
import '../../services/deviceService.dart';
import '../../services/invitationService.dart';
import '../../services/member_invitation_service.dart';
import '../../services/ownerService.dart';
import '../../services/userService.dart';
import '../../services/player_positions_service.dart';
import '../../widget/add_grinta_player_sheet.dart';
import '../../widget/team_tracker_owners_sheet.dart';
import '../../widget/add_grinta_staff_sheet.dart';
import '../../widget/manage_unavailabilities_sheet.dart';
import '../../widget/member_search_sheet.dart';
import '../../widget/playerPhoto.dart';
import '../../widget/player_contact_lines.dart';
import '../../widget/coach_wearable_device_connect_section.dart';
import '../team_players/training_team_players_presence.dart';
import '../team_players/training_team_players_tracker.dart';

part 'team_detail_widgets.dart';

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({
    super.key,
    required this.team,
    required this.seasonId,
    this.categoryLabel,
    this.genderLabel,
    this.thresholdCards = const [],
    this.effectivesService,
    this.isManager=false,
  });

  final Team team;
  final String? seasonId;
  final String? categoryLabel;
  final String? genderLabel;
  final List<TeamThresholdCardData> thresholdCards;
  final EffectivesService? effectivesService;
  final bool isManager;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

enum _RosterSortColumn {
  player,
  age,
  position,
  height,
  weight,
  tracker,
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late final PlayerService _playerService;
  late final EffectivesService _effectivesService;
  late final DeviceOwnerService _deviceOwnerService;
  late final DeviceService _deviceService;
  late final OwnerService _ownerService;
  late final UserService _userService;

  late Future<List<_TeamMemberVm>> _future;

  _RosterSortColumn? _sortColumn;
  bool _sortAscending = true;

  List<dynamic> rawPlayers = [];
  bool _usesGrintaRoster = false;
  late Team _team;
  Team? _serverTeam;
  int _headerPlayersCount = 0;
  int _headerStaffCount = 0;
  bool _userOwnersLoaded = false;
  List<Owner> _userOwnersByEmail = const [];
  bool _isMemberOperationLoading = false;
  String? _resendingInvitationMemberId;
  MemberInvitationResult? _pendingMemberInvitationResult;

  @override
  void initState() {
    super.initState();

    _playerService = PlayerService();
    _effectivesService = widget.effectivesService ?? EffectivesService();

    _deviceOwnerService = DeviceOwnerService();
    _deviceService = DeviceService();
    _ownerService = OwnerService();
    _userService = UserService();

    _team = widget.team;
    _serverTeam = null;
    _headerPlayersCount = 0;
    _headerStaffCount = 0;
    _future = _fetchTeamFromFirestore().then((_) async {
      final List<_TeamMemberVm> members = await _loadMembers();
      await _refreshUserOwnersAvailability();
      return members;
    });
  }

  @override
  void didUpdateWidget(covariant TeamDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final String oldTeamId = oldWidget.team.keyTeam?.trim() ?? '';
    final String newTeamId = widget.team.keyTeam?.trim() ?? '';
    if (oldTeamId != newTeamId) {
      _team = widget.team;
      setState(() {
        _serverTeam = null;
        _headerPlayersCount = 0;
        _headerStaffCount = 0;
        _userOwnersLoaded = false;
        _userOwnersByEmail = const [];
        _future = _fetchTeamFromFirestore().then((_) async {
          final List<_TeamMemberVm> members = await _loadMembers();
          await _refreshUserOwnersAvailability();
          return members;
        });
      });
    }
  }

  Future<void> _refreshUserOwnersAvailability() async {
    final Team team = _serverTeam ?? _team;
    if (team.hasAnyTrackerOwners) {
      if (mounted) {
        setState(() {
          _userOwnersLoaded = true;
          _userOwnersByEmail = const [];
        });
      }
      return;
    }
    final List<Owner> owners = await _ownerService.getOwnersForTeamManagers(
      team: team,
      userService: _userService,
    );
    if (!mounted) return;
    setState(() {
      _userOwnersLoaded = true;
      _userOwnersByEmail = owners;
    });
  }

  bool _showTrackerOwnersButton(BuildContext context) {
    final Team team = _serverTeam ?? _team;
    if (team.hasAnyTrackerOwners) {
      return true;
    }
    if (!_canManageTeam(context)) {
      return false;
    }
    if (!_userOwnersLoaded || _userOwnersByEmail.isEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _onTrackerOwnersPressed(BuildContext context) async {
    final Team team = _serverTeam ?? _team;
    final bool isManager = _canManageTeam(context);
    if (isManager &&
        !team.hasAnyTrackerOwners &&
        !TeamTrackerAccess.hasCoachProTrackerAccess()) {
      final allowed =
          await TeamTrackerAccess.ensureCoachProForTeamTrackers(context);
      if (!allowed || !mounted) {
        return;
      }
    }

    if (!context.mounted) {
      return;
    }

    final bool? updated = await showTeamTrackerOwnersSheet(
      context,
      team: _serverTeam ?? _team,
      isManager: _canManageTeam(context),
      ownerService: _ownerService,
      teamService: TeamService(),
      userService: _userService,
    );
    if (updated == true && mounted) {
      await _reloadTeamAndMembers();
      await _refreshUserOwnersAvailability();
    }
  }

  Widget _buildTrackerOwnersHeaderButton(
    BuildContext context, {
    double size = 50,
    double iconSize = 24,
  }) {
    if (!_showTrackerOwnersButton(context)) {
      return const SizedBox.shrink();
    }
    return _HeaderSquareIconButton(
      size: size,
      iconSize: iconSize,
      icon: Icons.sensors_rounded,
      onTap: () => _onTrackerOwnersPressed(context),
    );
  }

  /// Managers ([widget.isManager] / session managed teams), Grinta owners
  /// ([Team.uid]), or entries in [Team.managers] for the signed-in Firebase user.
  bool _canManageTeam(BuildContext context) {
    final AppSession appSession = context.read<AppSession>();
    final String? currentUserUid =
        appSession.user?.uid ?? FirebaseAuth.instance.currentUser?.uid;
    final Team team = _serverTeam ?? _team;
    final String teamId = team.keyTeam?.trim() ?? '';
    final bool sessionManagedTeam = teamId.isNotEmpty &&
        appSession.managedTeamsIdsForSelectedSeason.contains(teamId);
    return canManageTeam(
      team,
      currentUserUid,
      isManager: widget.isManager || sessionManagedTeam,
    );
  }

  /// Display roster comes from legacy `team.players` when that array has IDs.
  bool _rosterDisplayUsesLegacy() => _teamHasLegacyPlayers();

  /// Add/edit/delete targets `grintaPlayers` for Grinta teams even when legacy
  /// `players` is still shown for display (stale migration data).
  bool _mutationsTargetGrintaRosterFor(Team team) {
    if (team.isGrinta == true) {
      return true;
    }
    return _teamUsesGrintaRosterFor(team);
  }

  /// Managers on Grinta teams may mutate `grintaPlayers` regardless of legacy
  /// `players` display state.
  bool _canMutateGrintaRoster(BuildContext context) {
    return _canManageTeam(context) && _team.isGrinta == true;
  }

  /// Roster mutations: allowed for Grinta managers; otherwise blocked when the
  /// roster is displayed from legacy `players` (externally managed).
  bool _canManageRoster(BuildContext context) {
    if (!_canManageTeam(context)) {
      return false;
    }
    if (_canMutateGrintaRoster(context)) {
      return true;
    }
    return !_rosterDisplayUsesLegacy();
  }

  void _applyFetchedTeamState({
    required Team? serverTeam,
    required int playersCount,
    required int staffCount,
    bool clearRosterFields = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _serverTeam = serverTeam;
      if (serverTeam != null) {
        _team = serverTeam;
      } else if (clearRosterFields) {
        _clearRosterFields(_team);
      }
      _headerPlayersCount = playersCount;
      _headerStaffCount = staffCount;
    });

    if (serverTeam != null) {
      unawaited(_refreshUserOwnersAvailability());
    }
  }

  Future<void> _fetchTeamFromFirestore({bool preferCache = false}) async {
    final String? teamId = widget.team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      debugPrint(
        'TeamDetailScreen: missing keyTeam — header counts forced to 0/0 '
        '(widget.players=${widget.team.players} widget.managers=${widget.team.managers})',
      );
      _applyFetchedTeamState(
        serverTeam: null,
        playersCount: 0,
        staffCount: 0,
        clearRosterFields: true,
      );
      return;
    }

    try {
      final snapshot = await TeamService().getTeamSnapshotFromServer(
        teamId,
        preferCache: preferCache,
      );
      if (!mounted) {
        return;
      }

      if (snapshot == null) {
        debugPrint(
          'TeamDetailScreen: team doc not found on server teamId=$teamId — '
          'header counts forced to 0/0 '
          '(widget.players=${widget.team.players} widget.managers=${widget.team.managers})',
        );
        _applyFetchedTeamState(
          serverTeam: null,
          playersCount: 0,
          staffCount: 0,
          clearRosterFields: true,
        );
        return;
      }

      final Map<String, dynamic> raw = snapshot.data()!;
      final Team freshTeam = Team.fromDocumentSnapshot(snapshot);

      final ({int players, int staff}) counts =
          _rosterHeaderCountsForTeam(freshTeam);
      debugPrint(
        'TeamDetailScreen roster header counts teamId=$teamId '
        'RAW players=${raw[keyTeamPlayers]} '
        'RAW grintaPlayers=${raw[keyTeamGrintaPlayers]} '
        'RAW managers=${raw[keyTeamManagers]} '
        'parsed players=${freshTeam.players} '
        'parsed grintaPlayers=${freshTeam.grintaPlayers} '
        'parsed managers=${freshTeam.managers} '
        'widget.players=${widget.team.players} '
        'widget.managers=${widget.team.managers} '
        '=> players=${counts.players} staff=${counts.staff}',
      );
      assert(
        counts.players >= 0 && counts.staff >= 0,
        'TeamDetailScreen invalid roster header counts for teamId=$teamId',
      );
      _applyFetchedTeamState(
        serverTeam: freshTeam,
        playersCount: counts.players,
        staffCount: counts.staff,
      );
    } catch (e, stackTrace) {
      debugPrint(
        'TeamDetailScreen team fetch failed teamId=$teamId: $e — '
        'header counts forced to 0/0 '
        '(widget.players=${widget.team.players} widget.managers=${widget.team.managers})',
      );
      debugPrint('$stackTrace');
      _applyFetchedTeamState(
        serverTeam: null,
        playersCount: 0,
        staffCount: 0,
        clearRosterFields: true,
      );
    }
  }

  void _clearRosterFields(Team team) {
    team.players = <dynamic>[];
    team.grintaPlayers = <GrintaPlayer>[];
    team.managers = <dynamic>[];
  }

  Future<void> _reloadTeamAndMembers() async {
    final List<GrintaPlayer> localGrintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);

    // Prefer cache after roster mutations so the just-written grintaPlayers
    // entry is visible immediately (server-only reads can lag the local write).
    await _fetchTeamFromFirestore(preferCache: true);
    _mergeLocalGrintaPlayers(localGrintaPlayers);

    final List<_TeamMemberVm> members = await _loadMembers();
    if (!mounted) {
      return;
    }
    await _refreshUserOwnersAvailability();
    if (!mounted) {
      return;
    }
    final ({int players, int staff}) counts = _rosterHeaderCountsForTeam(_team);
    setState(() {
      _headerPlayersCount = counts.players;
      _headerStaffCount = counts.staff;
      _future = Future<List<_TeamMemberVm>>.value(members);
    });
  }

  void _mergeLocalGrintaPlayers(List<GrintaPlayer> localEntries) {
    if (localEntries.isEmpty) {
      return;
    }

    final List<GrintaPlayer> merged =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final Set<String> mergedIds = <String>{
      for (final GrintaPlayer entry in merged)
        if (entry.playerId.trim().isNotEmpty) entry.playerId.trim(),
    };

    for (final GrintaPlayer entry in localEntries) {
      final String playerId = entry.playerId.trim();
      if (playerId.isEmpty || mergedIds.contains(playerId)) {
        continue;
      }
      merged.add(entry);
      mergedIds.add(playerId);
    }

    _team.grintaPlayers = merged;
  }

  String? _rosterMemberId(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is DocumentReference) {
      final String id = raw.id.trim();
      return id.isEmpty ? null : id;
    }

    if (raw is String) {
      final String id = raw.trim();
      return id.isEmpty ? null : id;
    }

    final String id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  int _nonEmptyRosterIdCount(List<dynamic>? ids) {
    if (ids == null || ids.isEmpty) {
      return 0;
    }

    var count = 0;
    for (final dynamic raw in ids) {
      if (_rosterMemberId(raw) != null) {
        count++;
      }
    }
    return count;
  }

  /// Header chips only: count roster ids from the team document arrays.
  ({int players, int staff}) _rosterHeaderCountsForTeam(Team team) {
    if (_teamUsesGrintaRosterFor(team)) {
      var players = 0;
      var staff = 0;

      for (final GrintaPlayer grintaPlayer
          in team.grintaPlayers ?? const <GrintaPlayer>[]) {
        final String playerId = grintaPlayer.playerId.trim();
        if (playerId.isEmpty) {
          continue;
        }

        if (isGrintaRosterStaff(
          positions: grintaPlayer.positions,
          fonction: grintaPlayer.fonction,
          listedInManagers: false,
        )) {
          staff++;
        } else {
          players++;
        }
      }

      return (players: players, staff: staff);
    }

    final Set<String> playerIds = _legacyPlayerRosterIdsFor(team);
    final Set<String> managerIds = _legacyManagerRosterIdsFor(team);
    var staffOnly = 0;
    for (final String id in managerIds) {
      if (!playerIds.contains(id)) {
        staffOnly++;
      }
    }

    return (
      players: _nonEmptyRosterIdCount(team.players),
      staff: staffOnly,
    );
  }

  bool _teamHasLegacyPlayersFor(Team team) {
    return _nonEmptyRosterIdCount(team.players) > 0;
  }

  bool _teamHasLegacyPlayers() => _teamHasLegacyPlayersFor(_team);

  bool _teamHasGrintaPlayersFor(Team team) {
    for (final GrintaPlayer grintaPlayer
        in team.grintaPlayers ?? const <GrintaPlayer>[]) {
      if (grintaPlayer.playerId.trim().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  bool _teamUsesGrintaRosterFor(Team team) {
    // Legacy `players` array takes priority over isGrinta / grintaPlayers.
    if (_teamHasLegacyPlayersFor(team)) {
      return false;
    }
    if (team.isGrinta == true) {
      return true;
    }
    return _teamHasGrintaPlayersFor(team);
  }

  bool _teamUsesGrintaRoster() => _teamUsesGrintaRosterFor(_team);

  bool _teamHasManagersFor(Team team) {
    return _nonEmptyRosterIdCount(team.managers) > 0;
  }

  bool _teamRosterIsEmptyFor(Team team) {
    return !_teamHasLegacyPlayersFor(team) &&
        !_teamHasGrintaPlayersFor(team) &&
        !_teamHasManagersFor(team);
  }

  bool _teamRosterIsEmpty() => _teamRosterIsEmptyFor(_team);

  Set<String> _legacyPlayerRosterIdsFor(Team team) {
    final Set<String> ids = <String>{};
    for (final dynamic raw in team.players ?? const <dynamic>[]) {
      final String? id = _rosterMemberId(raw);
      if (id != null) {
        ids.add(id);
      }
    }
    return ids;
  }

  Set<String> _legacyManagerRosterIdsFor(Team team) {
    final Set<String> ids = <String>{};
    for (final dynamic raw in team.managers ?? const <dynamic>[]) {
      final String? id = _rosterMemberId(raw);
      if (id != null) {
        ids.add(id);
      }
    }
    return ids;
  }

  Set<String> _legacyPlayerRosterIds() => _legacyPlayerRosterIdsFor(_team);

  Set<String> _legacyManagerRosterIds() => _legacyManagerRosterIdsFor(_team);

  bool _rowMatchesRosterIds(_TeamMemberVm row, Set<String> rosterIds) {
    if (rosterIds.isEmpty) {
      return false;
    }

    for (final String id in playerMemberLookupIds(row.player)) {
      if (rosterIds.contains(id)) {
        return true;
      }
    }

    for (final dynamic raw in row.player.users ?? const <dynamic>[]) {
      final String? id = _rosterMemberId(raw);
      if (id != null && rosterIds.contains(id)) {
        return true;
      }
    }

    return false;
  }

  /// Legacy effectives [Effectives.type]: 1=joueur, 2=entraineur, 3=dirigeant,
  /// 4=entraineur/joueur. Type 0 is a legacy player marker used elsewhere.
  bool _legacyEffectivesMeansPlayer(Effectives effectives) {
    final int type = effectives.type ?? 1;
    return type == 0 || type == 1 || type == 4;
  }

  bool _legacyEffectivesMeansStaff(Effectives effectives) {
    final int type = effectives.type ?? 1;
    return type == 2 || type == 3;
  }

  bool _isPlayerManager(_TeamMemberVm row) {
    return _playerHasManagerRights(row.player);
  }

  Set<String> _teamManagerUserIds([Team? team]) {
    final Set<String> ids = <String>{};
    for (final dynamic raw in (team ?? _team).managers ?? const <dynamic>[]) {
      final String trimmed = raw?.toString().trim() ?? '';
      if (trimmed.isNotEmpty) {
        ids.add(trimmed);
      }
    }
    return ids;
  }

  bool _playerHasManagerRights(Player player, [Team? team]) {
    final Set<String> managerUserIds = _teamManagerUserIds(team);
    if (managerUserIds.isEmpty) {
      return false;
    }
    return playerFirebaseUserIds(player).any(managerUserIds.contains);
  }

  void _syncLocalManagersForPlayer({
    required Player player,
    required bool grant,
    String? legacyMemberId,
  }) {
    final List<dynamic> managers =
        List<dynamic>.from(_team.managers ?? const <dynamic>[]);
    final Set<String> userIds = playerFirebaseUserIds(player);
    if (grant) {
      for (final String userId in userIds) {
        if (!managers.contains(userId)) {
          managers.add(userId);
        }
      }
    } else {
      for (final String userId in userIds) {
        managers.remove(userId);
      }
      final String? memberId = legacyMemberId?.trim();
      if (memberId != null && memberId.isNotEmpty) {
        managers.remove(memberId);
      }
    }
    _team.managers = managers;
  }

  Future<void> _persistManagerRightsForPlayer({
    required String teamId,
    required Player player,
    required bool grant,
    String? legacyMemberId,
  }) async {
    final Set<String> userIds = playerFirebaseUserIds(player);
    if (grant) {
      for (final String userId in userIds) {
        await TeamService().addManager(teamId: teamId, managerId: userId);
        await TeamService().addUser(teamId: teamId, userId: userId);
      }
      return;
    }

    for (final String userId in userIds) {
      await TeamService().removeManager(teamId: teamId, managerId: userId);
    }
    final String? memberId = legacyMemberId?.trim();
    if (memberId != null && memberId.isNotEmpty) {
      await TeamService().removeManager(teamId: teamId, managerId: memberId);
    }
  }

  /// Edit targets `grintaPlayers` for Grinta roster rows, or legacy-display rows
  /// on Grinta teams (managers may edit even without a prior grintaPlayers entry).
  bool _canEditPlayerRow(_TeamMemberVm row) {
    if (row.isGrintaRoster) {
      return true;
    }
    if (!_usesGrintaRosterPathFor(_team)) {
      return false;
    }
    if (_team.isGrinta == true && _isPlayerMember(row)) {
      return true;
    }
    return _resolveGrintaPlayerForRow(row) != null;
  }

  Set<String> _explicitRosterMemberIds() {
    final Set<String> ids = <String>{};

    if (_teamUsesGrintaRoster()) {
      for (final GrintaPlayer grintaPlayer
          in _team.grintaPlayers ?? const <GrintaPlayer>[]) {
        final String id = grintaPlayer.playerId.trim();
        if (id.isNotEmpty) {
          ids.add(id);
        }
      }
      return ids;
    }

    ids.addAll(_legacyPlayerRosterIds());
    ids.addAll(_legacyManagerRosterIds());
    return ids;
  }

  bool _isGrintaStaffGrintaPlayer(GrintaPlayer entry) {
    return isGrintaRosterStaff(
      positions: entry.positions,
      fonction: entry.fonction,
      listedInManagers: false,
    );
  }

  Set<String> _grintaPlayerRosterMemberIds() {
    final Set<String> ids = <String>{};
    for (final GrintaPlayer grintaPlayer
        in _team.grintaPlayers ?? const <GrintaPlayer>[]) {
      final String id = grintaPlayer.playerId.trim();
      if (id.isEmpty || _isGrintaStaffGrintaPlayer(grintaPlayer)) {
        continue;
      }
      ids.add(id);
    }
    return ids;
  }

  Set<String> _grintaStaffRosterMemberIds() {
    final Set<String> ids = <String>{};
    for (final GrintaPlayer grintaPlayer
        in _team.grintaPlayers ?? const <GrintaPlayer>[]) {
      final String id = grintaPlayer.playerId.trim();
      if (id.isEmpty || !_isGrintaStaffGrintaPlayer(grintaPlayer)) {
        continue;
      }
      ids.add(id);
    }
    return ids;
  }

  Set<String> _playerAddExcludeMemberIds() {
    if (_usesGrintaRosterPathFor(_team)) {
      return _grintaPlayerRosterMemberIds();
    }
    return _legacyPlayerRosterIds();
  }

  Set<String> _staffAddExcludeMemberIds() {
    if (_usesGrintaRosterPathFor(_team)) {
      return _grintaStaffRosterMemberIds();
    }
    return _legacyManagerRosterIds();
  }

  bool _grintaHasPlayerEntry(String memberId) {
    return _grintaPlayerRosterMemberIds().contains(memberId.trim());
  }

  bool _grintaHasStaffEntry(String memberId) {
    return _grintaStaffRosterMemberIds().contains(memberId.trim());
  }

  GrintaPlayer? _grintaEntryForMemberId(
    String memberId, {
    required bool staff,
  }) {
    final String trimmed = memberId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    for (final GrintaPlayer grintaPlayer
        in _team.grintaPlayers ?? const <GrintaPlayer>[]) {
      if (grintaPlayer.playerId.trim() != trimmed) {
        continue;
      }
      if (_isGrintaStaffGrintaPlayer(grintaPlayer) == staff) {
        return grintaPlayer;
      }
    }
    return null;
  }

  bool _isListedOnTeamRoster(_TeamMemberVm row) {
    return _rowMatchesRosterIds(row, _explicitRosterMemberIds());
  }

  Future<Effectives?> _resolveLegacyEffectivesForRow({
    required Player player,
    required String rosterMemberId,
    required String teamId,
  }) async {
    final Set<String> candidateIds = <String>{
      rosterMemberId.trim(),
      ...playerMemberLookupIds(player),
    }..removeWhere((String id) => id.isEmpty);

    for (final String memberId in candidateIds) {
      final Effectives? effectives =
          await _effectivesService.getEffectivesByMemberIdAndTeamId(
        memberId,
        teamId,
      );
      if (effectives != null) {
        return effectives;
      }
    }

    return null;
  }

  bool _hasStaffProfilePosition(_TeamMemberVm row) {
    if (row.isGrintaRoster) {
      return isGrintaRosterStaff(
        positions: row.grintaPositions,
        fonction: row.grintaFonction,
        listedInManagers: false,
      );
    }

    return hasStaffProfilePositionCodes(row.player.positionCodes);
  }

  bool _isPlayerMember(_TeamMemberVm row) {
    if (!_isListedOnTeamRoster(row)) {
      return false;
    }

    if (row.isGrintaRoster) {
      return !_hasStaffProfilePosition(row);
    }

    // Legacy roster: `team.players` defines the player section. Manager
    // permissions (`team.managers`) must not move a field player to staff.
    if (_rowMatchesRosterIds(row, _legacyPlayerRosterIds())) {
      return true;
    }

    if (_rowMatchesRosterIds(row, _legacyManagerRosterIds())) {
      return false;
    }

    final Effectives? effectives = row.effectives;
    return effectives != null && _legacyEffectivesMeansPlayer(effectives);
  }

  bool _isStaffMember(_TeamMemberVm row) {
    if (!_isListedOnTeamRoster(row)) {
      return false;
    }

    if (row.isGrintaRoster) {
      return _hasStaffProfilePosition(row);
    }

    // Legacy roster: staff = managers not listed in `team.players`.
    if (_rowMatchesRosterIds(row, _legacyPlayerRosterIds())) {
      return false;
    }

    if (_rowMatchesRosterIds(row, _legacyManagerRosterIds())) {
      return true;
    }

    final Effectives? effectives = row.effectives;
    return effectives != null && _legacyEffectivesMeansStaff(effectives);
  }

  Future<List<_TeamMemberVm>> _loadMembers() async {
    _usesGrintaRoster = _teamUsesGrintaRoster();

    if (_teamRosterIsEmpty()) {
      return <_TeamMemberVm>[];
    }

    if (_teamHasLegacyPlayers()) {
      return _loadLegacyMembers();
    }

    if (_usesGrintaRoster) {
      return _loadGrintaMembers();
    }

    return <_TeamMemberVm>[];
  }

  Future<List<_TeamMemberVm>> _loadLegacyMembers() async {
    // Effectives are legacy-only: never load when team.players is empty.
    if (!_teamHasLegacyPlayers()) {
      return <_TeamMemberVm>[];
    }

    final String? seasonId = widget.seasonId;
    final String? teamId = _team.keyTeam;
    rawPlayers = _team.players ?? const <dynamic>[];

    if (seasonId == null ||
        seasonId.isEmpty ||
        teamId == null ||
        teamId.isEmpty) {
      return <_TeamMemberVm>[];
    }

    final Set<String> memberIds = _explicitRosterMemberIds();

    final List<_TeamMemberVm?> rows = await Future.wait(
      memberIds.map((memberId) async {
        try {
          Player? player = await _playerService.getPlayerById(memberId);
          player ??= await _playerService.getPlayerByUserId(memberId);

          if (player == null) {
            return null;
          }

          final Effectives? effectives =
              await _resolveLegacyEffectivesForRow(
            player: player,
            rosterMemberId: memberId,
            teamId: teamId,
          );

          final List<_TrackerChipVm> trackers = await _loadTrackers(
            effectives?.trackers,
          );

          return _TeamMemberVm(
            player: player,
            effectives: effectives,
            trackers: trackers,
          );
        } catch (e, stackTrace) {
          debugPrint('Erreur _loadMembers memberId=$memberId : $e');
          debugPrint('$stackTrace');
          return null;
        }
      }),
    );

    return _dedupeAndSortMembers(rows);
  }

  Future<List<_TeamMemberVm>> _loadGrintaMembers() async {
    final String? seasonId = widget.seasonId;
    final String? teamId = _team.keyTeam;
    final List<GrintaPlayer> grintaPlayers =
        _team.grintaPlayers ?? const <GrintaPlayer>[];

    if (seasonId == null ||
        seasonId.isEmpty ||
        teamId == null ||
        teamId.isEmpty ||
        grintaPlayers.isEmpty) {
      return <_TeamMemberVm>[];
    }

    final Set<String> invitationIds = grintaPlayers
        .map((GrintaPlayer entry) => entry.invitationId?.trim() ?? '')
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Map<String, Invitation> invitationsById =
        invitationIds.isEmpty
            ? const <String, Invitation>{}
            : await InvitationService().getInvitationsByIds(invitationIds);

    final List<_TeamMemberVm?> rows = await Future.wait(
      grintaPlayers.map((GrintaPlayer grintaPlayer) async {
        final String memberId = grintaPlayer.playerId.trim();
        if (memberId.isEmpty) {
          return null;
        }

        try {
          Player? player = await _playerService.getPlayerById(memberId);
          player ??= await _playerService.getPlayerByUserId(memberId);

          player ??= Player(keyMember: memberId);
          normalizePlayerMemberId(player);

          final List<_TrackerChipVm> trackers = await _loadTrackers(
            grintaPlayer.trackers,
          );

          final GrintaPlayerHW? latestHw = grintaPlayer.latestHw;
          final String? invitationId = grintaPlayer.invitationId?.trim();
          bool? invitationAccepted;
          if (invitationId != null && invitationId.isNotEmpty) {
            invitationAccepted =
                invitationsById[invitationId]?.isValidated ?? false;
          }

          return _TeamMemberVm(
            player: player,
            effectives: null,
            trackers: trackers,
            grintaPositions: List<int>.from(grintaPlayer.positions),
            grintaFonction: grintaPlayer.fonction,
            isGrintaRoster: true,
            grintaEmail: grintaPlayer.email,
            grintaPhoneE164: grintaPlayer.phoneE164,
            grintaBirthday: grintaPlayer.birthday,
            grintaHeightCm: latestHw != null && latestHw.height > 0
                ? latestHw.height
                : null,
            grintaWeightKg: latestHw != null && latestHw.weight > 0
                ? latestHw.weight
                : null,
            grintaInvitationId: invitationId,
            invitationAccepted: invitationAccepted,
          );
        } catch (e, stackTrace) {
          debugPrint('Erreur _loadGrintaMembers memberId=$memberId : $e');
          debugPrint('$stackTrace');
          return null;
        }
      }),
    );

    return _sortGrintaMemberRows(rows, grintaPlayers);
  }

  List<_TeamMemberVm> _dedupeAndSortMembers(List<_TeamMemberVm?> rows) {
    final List<_TeamMemberVm> data = rows.whereType<_TeamMemberVm>().toList();

    final Set<String> seenMemberIds = <String>{};
    final List<_TeamMemberVm> uniqueData = <_TeamMemberVm>[];
    for (final _TeamMemberVm row in data) {
      final String memberKey = row.player.keyMember?.trim() ?? '';
      if (memberKey.isEmpty || seenMemberIds.contains(memberKey)) {
        continue;
      }
      seenMemberIds.add(memberKey);
      uniqueData.add(row);
    }

    uniqueData.sort((a, b) {
      final int orderA = a.effectives?.order ?? 999999;
      final int orderB = b.effectives?.order ?? 999999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return a.player.lastName!.toLowerCase().compareTo(b.player.lastName!.toLowerCase());

    });

    return uniqueData;
  }

  List<_TeamMemberVm> _sortGrintaMemberRows(
    List<_TeamMemberVm?> rows,
    List<GrintaPlayer> grintaPlayers,
  ) {
    final List<_TeamMemberVm> data = rows.whereType<_TeamMemberVm>().toList();

    final Map<String, int> rosterOrder = <String, int>{};
    for (int index = 0; index < grintaPlayers.length; index++) {
      final String playerId = grintaPlayers[index].playerId.trim();
      if (playerId.isNotEmpty) {
        rosterOrder['$playerId#$index'] = index;
      }
    }

    int orderForRow(_TeamMemberVm row, int fallbackIndex) {
      final String memberKey = effectiveMemberId(row.player)?.trim() ?? '';
      final bool rowIsStaff = _hasStaffProfilePosition(row);
      for (int index = 0; index < grintaPlayers.length; index++) {
        final GrintaPlayer entry = grintaPlayers[index];
        if (entry.playerId.trim() != memberKey) {
          continue;
        }
        if (_isGrintaStaffGrintaPlayer(entry) == rowIsStaff) {
          return rosterOrder['$memberKey#$index'] ?? index;
        }
      }
      return fallbackIndex;
    }

    data.sort((a, b) {
      final int orderA = orderForRow(a, 999999);
      final int orderB = orderForRow(b, 999999);

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return a.player.lastName!.toLowerCase().compareTo(b.player.lastName!.toLowerCase());
    });

    return data;
  }

  String _positionLabelForRow(_TeamMemberVm row, AppLocalizations l10n) {
    if (row.isGrintaRoster) {
      if (row.grintaPositions.isEmpty) {
        return _legacyProfileFieldPositionLabel(row.player, l10n);
      }

      final PlayerPositionsService positionsService =
          PlayerPositionsService.instance;
      return row.grintaPositions
          .map((code) => positionsService.labelForCode(code, l10n))
          .join(', ');
    }

    final int? effectivesPosition = row.effectives?.position;
    if (effectivesPosition != null &&
        isMemberProfileFieldPlayerRole(effectivesPosition)) {
      return getStrPosition(effectivesPosition, l10n);
    }

    if (effectivesPosition != null &&
        isDefiniteGrintaFieldPitchCode(effectivesPosition)) {
      return PlayerPositionsService.instance.labelForCode(
        effectivesPosition,
        l10n,
      );
    }

    return _legacyProfileFieldPositionLabel(row.player, l10n);
  }

  String _legacyProfileFieldPositionLabel(Player player, AppLocalizations l10n) {
    final PlayerPositionsService positionsService =
        PlayerPositionsService.instance;

    final List<int> grintaPitchCodes = player.positionCodes
        .where(isDefiniteGrintaFieldPitchCode)
        .toList(growable: false);
    if (grintaPitchCodes.isNotEmpty) {
      return grintaPitchCodes
          .map((int code) => positionsService.labelForCode(code, l10n))
          .join(', ');
    }

    final List<int> legacyFieldCodes = player.positionCodes
        .where(isMemberProfileFieldPlayerRole)
        .toList(growable: false);
    if (legacyFieldCodes.isNotEmpty) {
      return legacyFieldCodes
          .map((int code) => getStrPosition(code, l10n))
          .join(', ');
    }

    return l10n.entityPlayer;
  }

  Widget _playerContactLinesForRow(_TeamMemberVm row) {
    return PlayerContactLines(
      player: row.player,
      emailOverride: row.isGrintaRoster ? row.grintaEmail : null,
      phoneE164Override: row.isGrintaRoster ? row.grintaPhoneE164 : null,
    );
  }

  Future<List<_TrackerChipVm>> _loadTrackers(List<dynamic>? trackerIds) async {
    if (trackerIds == null || trackerIds.isEmpty) {
      return <_TrackerChipVm>[];
    }

    final List<String> ids = trackerIds
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final List<_TrackerChipVm> result = <_TrackerChipVm>[];

    for (final String trackerId in ids) {
      final _TrackerChipVm? tracker = await _loadTrackerById(trackerId);

      if (tracker != null) {
        result.add(tracker);
      }
    }

    return result;
  }

  bool _canAssignTeamTrackers(BuildContext context) {
    if (!_canManageRoster(context)) {
      return false;
    }
    if (!(_serverTeam ?? _team).hasAnyTrackerOwners) {
      return false;
    }
    return TeamTrackerAccess.hasCoachProTrackerAccess();
  }

  Iterable<String> _teamTrackerOwnerIds() {
    return (_serverTeam ?? _team)
        .ownerRefs
        .map((TeamOwnerRef ref) => ref.id.trim())
        .where((String id) => id.isNotEmpty);
  }

  Future<List<DeviceOwner>> _loadTeamTrackerDevices() async {
    final List<DeviceOwner> devices = <DeviceOwner>[];
    for (final String ownerId in _teamTrackerOwnerIds()) {
      final List<DeviceOwner> ownerDevices =
          await _deviceOwnerService.listByOwnerId(ownerId);
      devices.addAll(ownerDevices);
    }
    devices.sort(compareDeviceOwnersByCustomName);
    return devices;
  }

  Set<String> _collectAssignedTrackerDocIds(List<_TeamMemberVm> members) {
    final Set<String> assignedIds = <String>{};
    for (final _TeamMemberVm member in members) {
      for (final _TrackerChipVm tracker in member.trackers) {
        final String id = tracker.id.trim();
        if (id.isNotEmpty) {
          assignedIds.add(id);
        }
      }
    }
    for (final GrintaPlayer grintaPlayer
        in _team.grintaPlayers ?? const <GrintaPlayer>[]) {
      for (final String trackerId in grintaPlayer.trackers) {
        final String id = trackerId.trim();
        if (id.isNotEmpty) {
          assignedIds.add(id);
        }
      }
    }
    return assignedIds;
  }

  Future<DeviceOwner?> _resolveDeviceOwnerByTrackerId(String trackerId) async {
    final String trimmed = trackerId.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final DeviceOwner? byDocId = await _deviceOwnerService.getById(trimmed);
    if (byDocId != null) {
      return byDocId;
    }

    for (final String ownerId in _teamTrackerOwnerIds()) {
      final DeviceOwner? byCustomName =
          await _deviceOwnerService.getByOwnerIdAndCustomName(ownerId, trimmed);
      if (byCustomName != null) {
        return byCustomName;
      }
    }
    return null;
  }

  Future<void> _persistTrackerChange({
    required _TeamMemberVm row,
    required String deviceOwnerDocId,
    required bool add,
  }) async {
    final String? teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      throw StateError('Missing team id');
    }

    if (_mutationsTargetGrintaRosterFor(_team)) {
      final String? memberId = effectiveMemberId(row.player);
      if (memberId == null || memberId.isEmpty) {
        throw StateError('Missing player id');
      }

      GrintaPlayer? existing = _resolveGrintaPlayerForRow(row);
      if (existing != null) {
        final List<String> trackers = List<String>.from(existing.trackers);
        if (add) {
          if (!trackers.contains(deviceOwnerDocId)) {
            trackers.add(deviceOwnerDocId);
          }
        } else {
          trackers.remove(deviceOwnerDocId);
        }

        final GrintaPlayer updated = GrintaPlayer(
          playerId: existing.playerId,
          positions: List<int>.from(existing.positions),
          fonction: existing.fonction,
          trackers: trackers,
          email: existing.email,
          phoneE164: existing.phoneE164,
          birthday: existing.birthday,
          hwHistory: List<GrintaPlayerHW>.from(existing.hwHistory),
          invitationId: existing.invitationId,
        );

        final GrintaPlayer resolvedExisting = existing;
        await TeamService().updateGrintaPlayer(
          teamId: teamId,
          playerId: resolvedExisting.playerId,
          player: updated,
          staffEntry: _isGrintaStaffGrintaPlayer(resolvedExisting),
        );

        final List<GrintaPlayer> grintaPlayers =
            List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
        final int index = grintaPlayers.indexWhere(
          (GrintaPlayer entry) =>
              entry.playerId.trim() == resolvedExisting.playerId.trim() &&
              _isGrintaStaffGrintaPlayer(entry) ==
                  _isGrintaStaffGrintaPlayer(resolvedExisting),
        );
        if (index >= 0) {
          grintaPlayers[index] = updated;
          _team.grintaPlayers = grintaPlayers;
        }
        return;
      }

      if (!add) {
        return;
      }

      final List<int> positions = row.isGrintaRoster
          ? List<int>.from(row.grintaPositions)
          : <int>[];
      final GrintaPlayer created = GrintaPlayer(
        playerId: memberId,
        positions: positions,
        trackers: <String>[deviceOwnerDocId],
        email: row.grintaEmail,
        phoneE164: row.grintaPhoneE164,
        birthday: row.grintaBirthday,
      );
      await TeamService().addGrintaPlayer(
        teamId: teamId,
        player: created,
        firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
        staffEntry: false,
      );

      final List<GrintaPlayer> grintaPlayers =
          List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
      final bool alreadyOnRoster = grintaPlayers.any(
        (GrintaPlayer entry) =>
            entry.playerId.trim() == memberId.trim() &&
            !_isGrintaStaffGrintaPlayer(entry),
      );
      if (!alreadyOnRoster) {
        grintaPlayers.add(created);
      }
      _team.grintaPlayers = grintaPlayers;
      return;
    }

    final String? effectivesId = row.effectives?.ref?.id;
    if (effectivesId == null || effectivesId.isEmpty) {
      throw StateError('Missing effectives document');
    }

    if (add) {
      await _effectivesService.addTracker(
        effectivesId: effectivesId,
        trackerId: deviceOwnerDocId,
      );
    } else {
      await _effectivesService.removeTracker(
        effectivesId: effectivesId,
        trackerId: deviceOwnerDocId,
      );
    }
  }

  Future<_TrackerChipVm?> _loadTrackerById(String trackerId) async {
    try {
      final DeviceOwner? deviceOwner =
          await _resolveDeviceOwnerByTrackerId(trackerId);
      if (deviceOwner == null) {
        debugPrint('deviceOwner null pour trackerId=$trackerId');
        return null;
      }

      final String customName = deviceOwner.customName ?? '';

      final Owner? owner = await OwnerService().getOwnerById(deviceOwner.ownerId);

      if (owner == null || owner.name.isEmpty) {
        debugPrint('ownerId vide pour trackerId=$trackerId');
        return null;
      }
      final String label = <String>[
        if (customName.isNotEmpty) customName,
        if (owner.name.isNotEmpty) owner.name,
      ].join(' - ');

      debugPrint('label tracker=$label');

      if (label.isEmpty) {
        return null;
      }

      return _TrackerChipVm(
        id: trackerId,
        label: label,
      );
    } catch (e, stackTrace) {
      debugPrint('Erreur _loadTrackerById trackerId=$trackerId : $e');
      debugPrint('$stackTrace');
      return null;
    }
  }



  List<_TeamMemberVm> _playerRows(List<_TeamMemberVm> rows) {
    return rows.where(_isPlayerMember).toList();
  }

  List<_TeamMemberVm> _staffRows(
    List<_TeamMemberVm> rows,
    AppLocalizations l10n,
  ) {
    final List<_TeamMemberVm> data = rows.where(_isStaffMember).toList();

    data.sort((a, b) {
      final int orderA = a.effectives?.order ?? 999999;
      final int orderB = b.effectives?.order ?? 999999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return _displayName(a.player, l10n)
          .toLowerCase()
          .compareTo(_displayName(b.player, l10n).toLowerCase());
    });

    return data;
  }

  double _averagePlayersAge(List<_TeamMemberVm> rows) {
    final List<int> ages = rows.where(_isPlayerMember).map((r) {
      return _ageValueForRow(r) ?? -1;
    }).where((age) {
      return age >= 0;
    }).toList();

    if (ages.isEmpty) {
      return 0;
    }

    final int total = ages.reduce((a, b) => a + b);

    return total / ages.length;
  }

  String _displayName(Player player, AppLocalizations l10n) {
    return formatPlayerShortName(player, unknownLabel: l10n.entityPlayer);
  }

  void _onSort(_RosterSortColumn column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  List<_TeamMemberVm> _sortedRosterRows(
    List<_TeamMemberVm> rows,
    AppLocalizations l10n,
  ) {
    final List<_TeamMemberVm> data = rows.where((r) {
      return r.isGrintaRoster ||
          r.effectives != null ||
          (!_teamUsesGrintaRoster() && _isListedOnTeamRoster(r));
    }).toList();

    final _RosterSortColumn? column = _sortColumn;

    if (column == null) {
      return data;
    }

    data.sort((a, b) {
      int result = 0;

      switch (column) {
        case _RosterSortColumn.player:
          result = _compareText(
            _displayName(a.player, l10n),
            _displayName(b.player, l10n),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.age:
          result = _compareNullableInt(
            _ageValueForRow(a),
            _ageValueForRow(b),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.position:
          result = _compareText(
            _positionLabelForRow(a, l10n),
            _positionLabelForRow(b, l10n),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.height:
          result = _compareNullableInt(
            _heightCmForRow(a),
            _heightCmForRow(b),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.weight:
          result = _compareNullableInt(
            _weightKgSortValueForRow(a),
            _weightKgSortValueForRow(b),
            ascending: _sortAscending,
          );
          break;

        case _RosterSortColumn.tracker:
          result = _compareText(
            _trackerValue(a),
            _trackerValue(b),
            ascending: _sortAscending,
          );
          break;
      }

      if (result != 0) {
        return result;
      }

      return _displayName(a.player, l10n)
          .toLowerCase()
          .compareTo(_displayName(b.player, l10n).toLowerCase());
    });

    return data;
  }

  int _compareText(
      String a,
      String b, {
        required bool ascending,
      }) {
    final String valueA = a.trim().toLowerCase();
    final String valueB = b.trim().toLowerCase();

    if (valueA.isEmpty && valueB.isEmpty) {
      return 0;
    }

    if (valueA.isEmpty) {
      return 1;
    }

    if (valueB.isEmpty) {
      return -1;
    }

    final int result = valueA.compareTo(valueB);

    return ascending ? result : -result;
  }

  int _compareNullableInt(
      int? a,
      int? b, {
        required bool ascending,
      }) {
    if (a == null && b == null) {
      return 0;
    }

    if (a == null) {
      return 1;
    }

    if (b == null) {
      return -1;
    }

    final int result = a.compareTo(b);

    return ascending ? result : -result;
  }

  int? _positiveIntOrNull(int? value) {
    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  int? _ageValueForRow(_TeamMemberVm row) {
    final DateTime? birthDate = _birthDateForRow(row);

    if (birthDate == null) {
      return null;
    }

    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  DateTime? _birthDateForRow(_TeamMemberVm row) {
    if (row.isGrintaRoster && row.grintaBirthday != null) {
      return row.grintaBirthday;
    }

    return _getBirthDate(row.player);
  }

  int? _heightCmForRow(_TeamMemberVm row) {
    if (row.isGrintaRoster) {
      return _positiveIntOrNull(row.grintaHeightCm);
    }

    return _positiveIntOrNull(row.effectives?.taille);
  }

  int? _weightKgSortValueForRow(_TeamMemberVm row) {
    if (row.isGrintaRoster) {
      final double? weight = row.grintaWeightKg;
      if (weight == null || weight <= 0) {
        return null;
      }
      return weight.round();
    }

    return _positiveIntOrNull(row.effectives?.poids);
  }

  String _formatWeightLabel(double weight, AppLocalizations l10n) {
    if (weight == weight.roundToDouble()) {
      return l10n.teamDetailWeightKg(weight.round());
    }

    return '${weight.toStringAsFixed(1)} kg';
  }

  String _trackerValue(_TeamMemberVm row) {
    if (row.trackers.isEmpty) {
      return '';
    }

    return row.trackers.map((tracker) => tracker.label).join(' ');
  }

  String _staffRoleLabelFromProfile(Player player, AppLocalizations l10n) {
    for (final int code in player.positionCodes) {
      if (grintaStaffRoleCodes.contains(code)) {
        return grintaStaffRoleLabel(code, l10n);
      }
    }
    return '';
  }

  String _buildStaffRole(_TeamMemberVm row, AppLocalizations l10n) {
    final Effectives? effectives = row.effectives;
    if (effectives != null) {
      final String fromType = l10n.staffRoleLabel(effectives.type ?? -1);
      if (fromType != l10n.entityStaff && fromType != l10n.entityPlayer) {
        return fromType;
      }
    }

    final String fromProfile = _staffRoleLabelFromProfile(row.player, l10n);
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }

    return l10n.entityStaff;
  }

  List<Widget> _buildMemberStatusIcons(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final icons = <Widget>[];

    if (isMemberLinkedToAppAccount(row.player)) {
      icons.add(
        Tooltip(
          message: l10n.memberAppAccountLinked,
          child: Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: colors.success,
          ),
        ),
      );
    }

    if (row.isGrintaRoster) {
      final String? invitationId = row.grintaInvitationId?.trim();
      if (invitationId != null &&
          invitationId.isNotEmpty &&
          row.invitationAccepted != true) {
        icons.add(
          Tooltip(
            message: l10n.invitationPending,
            child: Icon(
              Icons.schedule_rounded,
              size: 18,
              color: colors.warning,
            ),
          ),
        );
      }
    }

    return icons;
  }

  String _buildStaffRoleForRow(_TeamMemberVm row, AppLocalizations l10n) {
    if (row.isGrintaRoster) {
      final int? fonction = resolveGrintaStaffFonction(
        fonction: row.grintaFonction,
        positions: row.grintaPositions,
      );
      if (fonction != null) {
        return grintaStaffRoleLabel(fonction, l10n);
      }
    }

    return _buildStaffRole(row, l10n);
  }

  bool _isMobileTeamDetailLayout(BuildContext context) {
    return !kIsWeb && MediaQuery.sizeOf(context).width < 900;
  }

  bool _canAddPlayers(BuildContext context) {
    final bool isEducatorOrCoach = context.select<AppSession, bool>(
      (session) => session.selectedPlayer?.isEducatorOrCoach ?? false,
    );
    return _canManageRoster(context) ||
        (!_rosterDisplayUsesLegacy() && isEducatorOrCoach);
  }

  Future<void> _showTeamInfoSheet(
    BuildContext context, {
    required int playersCount,
    required int staffsCount,
    required double averageAge,
  }) async {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.card,
      builder: (sheetContext) {
        final sheetL10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.groups_2_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    sheetL10n.teamMembersPlayers(playersCount),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.shield_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    sheetL10n.teamMembersStaff(staffsCount),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.cake_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    sheetL10n.teamDetailAverageAge(
                      averageAge.toStringAsFixed(0),
                    ),
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMemberMenu(
    BuildContext context, {
    required bool canAddPlayers,
    required bool canAddStaff,
  }) async {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.card,
      builder: (sheetContext) {
        final sheetL10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canAddPlayers)
                  ListTile(
                    leading: Icon(
                      Icons.person_add_outlined,
                      color: colors.primary,
                    ),
                    title: Text(
                      sheetL10n.actionAddPlayer,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _onAddPlayerPressed(context);
                    },
                  ),
                if (canAddPlayers && canAddStaff) const Divider(height: 1),
                if (canAddStaff)
                  ListTile(
                    leading: Icon(
                      Icons.shield_outlined,
                      color: colors.primary,
                    ),
                    title: Text(
                      sheetL10n.actionAddStaff,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _onAddStaffPressed(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _mobileRowBackgroundColor(AppColors colors, bool odd) {
    if (!odd) {
      return colors.card;
    }
    return Color.alphaBlend(
      colors.background.withValues(alpha: 0.45),
      colors.card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isMobileLayout = _isMobileTeamDetailLayout(context);
    final bool canAddPlayers = _canAddPlayers(context);
    final bool canAddStaff = _canManageRoster(context);
    final bool showMobileAddFab =
        isMobileLayout && (canAddPlayers || canAddStaff);

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: showMobileAddFab
          ? FloatingActionButton(
              heroTag: 'grinta-fab-team-detail',
              onPressed: _isMemberOperationLoading
                  ? null
                  : () => _showAddMemberMenu(
                        context,
                        canAddPlayers: canAddPlayers,
                        canAddStaff: canAddStaff,
                      ),
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: FutureBuilder<List<_TeamMemberVm>>(
              future: _future,
              builder: (context, snapshot) {
            final l10n = context.l10n;
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              );
            }

            final List<_TeamMemberVm> rows = snapshot.data ?? <_TeamMemberVm>[];
            final List<_TeamMemberVm> rosterRows = rows
                .where(_isListedOnTeamRoster)
                .toList();
            final List<_TeamMemberVm> playerRows = _playerRows(rosterRows);
            final List<_TeamMemberVm> staffRows = _staffRows(rosterRows, l10n);

            final int playersCount = _headerPlayersCount;
            final int staffsCount = _headerStaffCount;
            final double averageAge = _averagePlayersAge(playerRows);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobileLayout ? 16 : 24,
                isMobileLayout ? 16 : 24,
                isMobileLayout ? 16 : 24,
                showMobileAddFab ? 96 : (isMobileLayout ? 16 : 24),
              ),
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    rows: rows,
                    playersCount: playersCount,
                    staffsCount: staffsCount,
                    averageAge: averageAge,
                  ),
                  SizedBox(height: isMobileLayout ? 16 : 24),
                  _buildRosterCard(context, playerRows),
                  SizedBox(height: isMobileLayout ? 16 : 24),
                  _buildStaffCard(context, staffRows),
                ],
              ),
            );
          },
            ),
          ),
          if (_isMemberOperationLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: colors.background.withValues(alpha: 0.55),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, {
        required List<_TeamMemberVm> rows,
        required int playersCount,
        required int staffsCount,
        required double averageAge,
      }) {
    debugPrint(
      'UI header chips playersCount=$playersCount staffsCount=$staffsCount',
    );

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bool isMobileLayout = _isMobileTeamDetailLayout(context);

    final l10n = context.l10n;
    final String? currentUserUid =
        context.read<AppSession>().user?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    final bool isOwner = isTeamOwner(_team, currentUserUid);
    final String title = (_team.name ?? '').trim().isEmpty
        ? l10n.entityTeam
        : _team.name!.trim();

    debugPrint(
      'TeamDetailScreen header chips teamId=${_team.keyTeam} '
      'playersCount=$playersCount staffsCount=$staffsCount',
    );

    if (isMobileLayout) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: <Color>[
              colors.primary,
              colors.secondary.withValues(alpha: 0.9),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isOwner)
                  _HeaderSquareIconButton(
                    size: 40,
                    iconSize: 20,
                    icon: Icons.delete_outline_rounded,
                    onTap: () async {
                      await deleteOwnedTeam(
                        context,
                        team: _team,
                      );
                    },
                  ),
                if (isOwner) const SizedBox(width: 8),
                if (_canManageTeam(context))
                  _HeaderSquareIconButton(
                    size: 40,
                    iconSize: 20,
                    icon: Icons.edit_outlined,
                    onTap: () {},
                  ),
                if (_canManageTeam(context)) const SizedBox(width: 8),
                _HeaderSquareIconButton(
                  size: 40,
                  iconSize: 20,
                  icon: Icons.tune_rounded,
                  onTap: () async {
                    AnalyticsInteractions.logFeature(
                      AnalyticsFeatures.openTeamParam,
                      parameters: <String, Object>{
                        'is_manager': _canManageTeam(context),
                      },
                    );
                    final bool? updated =
                        await Navigator.of(context).push<bool>(
                      analyticsMaterialRoute<bool>(
                        screenName: AnalyticsScreenNames.teamParam,
                        builder: (_) => TeamParamScreen(
                          team: _team,
                          isManager: _canManageTeam(context),
                        ),
                      ),
                    );

                    if (updated == true && mounted) {
                      _reloadTeamAndMembers();
                    }
                  },
                ),
                if (_showTrackerOwnersButton(context)) ...[
                  const SizedBox(width: 8),
                  _buildTrackerOwnersHeaderButton(
                    context,
                    size: 40,
                    iconSize: 20,
                  ),
                ],
                const SizedBox(width: 8),
                _HeaderSquareIconButton(
                  size: 40,
                  iconSize: 20,
                  icon: Icons.info_outline_rounded,
                  onTap: () => _showTeamInfoSheet(
                    context,
                    playersCount: playersCount,
                    staffsCount: staffsCount,
                    averageAge: averageAge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.teamDetailBackToTeams,
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<Widget> chips = <Widget>[
      if ((widget.categoryLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.categoryLabel!.trim()),
      if ((widget.genderLabel ?? '').trim().isNotEmpty)
        _InfoChip(label: widget.genderLabel!.trim()),
      _InfoChip(label: l10n.teamMembersPlayers(playersCount)),
      _InfoChip(label: l10n.teamMembersStaff(staffsCount)),
      _InfoChip(
        label: l10n.teamDetailAverageAge(averageAge.toStringAsFixed(0)),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: <Color>[
            colors.primary,
            colors.secondary.withValues(alpha: 0.9),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool stacked = constraints.maxWidth < 1050;

          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: stacked ? 0 : 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Text(
                          title,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (isOwner) ...[
                          _HeaderSquareIconButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: () async {
                              await deleteOwnedTeam(
                                context,
                                team: _team,
                              );
                            },
                          ),
                        ],
                        if (_canManageTeam(context)) ...[
                          _HeaderSquareIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () {},
                          ),
                        ],
                        _HeaderSquareIconButton(
                          icon: Icons.tune_rounded,
                          onTap: () async {
                            AnalyticsInteractions.logFeature(
                              AnalyticsFeatures.openTeamParam,
                              parameters: <String, Object>{
                                'is_manager': _canManageTeam(context),
                              },
                            );
                            final bool? updated =
                            await Navigator.of(context).push<bool>(
                              analyticsMaterialRoute<bool>(
                                screenName: AnalyticsScreenNames.teamParam,
                                builder: (_) => TeamParamScreen(
                                  team: _team,
                                  isManager: _canManageTeam(context),
                                ),
                              ),
                            );

                            if (updated == true && mounted) {
                              _reloadTeamAndMembers();
                            }
                          },
                        ),
                        if (_showTrackerOwnersButton(context))
                          _buildTrackerOwnersHeaderButton(context),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: chips,
                    ),
                    const SizedBox(height: 18),
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.teamDetailBackToTeams,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRosterCard(BuildContext context, List<_TeamMemberVm> rows) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final List<_TeamMemberVm> visibleRows = _sortedRosterRows(rows, l10n);
    final bool isMobileLayout = _isMobileTeamDetailLayout(context);
    final bool canAddPlayers = _canAddPlayers(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobileLayout ? 16 : 24,
              isMobileLayout ? 12 : 20,
              isMobileLayout ? 16 : 24,
              isMobileLayout ? 12 : 20,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.groups_2_rounded,
                  color: colors.primary,
                  size: isMobileLayout ? 24 : 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.entityPlayers,
                    style: (isMobileLayout
                            ? textTheme.titleLarge
                            : textTheme.headlineSmall)
                        ?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canAddPlayers && !isMobileLayout) ...[
                  FilledButton(
                    onPressed: _isMemberOperationLoading
                        ? null
                        : () => _onAddPlayerPressed(context),
                    child: Text(l10n.actionAddPlayer),
                  ),
                ],
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool mobileRoster =
                  !kIsWeb && constraints.maxWidth < 900;
              final bool canManageTeam = _canManageTeam(context);
              final bool canManageRoster = _canManageRoster(context);
              final _MobileRosterLayout rosterLayout = mobileRoster
                  ? _MobileRosterLayout.fromWidth(
                      constraints.maxWidth,
                      canManageTeam: canManageTeam,
                      canManageRoster: canManageRoster,
                    )
                  : const _MobileRosterLayout(
                      showPositionColumn: true,
                      showInlineEditColumn: true,
                      playerFlex: 4,
                    );

              return Column(
                children: [
                  mobileRoster
                      ? _buildMobileTableHeader(
                          context,
                          layout: rosterLayout,
                        )
                      : _buildTableHeader(context, mobile: false),
                  if (visibleRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.emptyNoPlayerForTeam,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else if (mobileRoster)
                    ...List.generate(
                      visibleRows.length,
                      (index) => _buildMobileRow(
                        context,
                        layout: rosterLayout,
                        row: visibleRows[index],
                        odd: index.isOdd,
                      ),
                    )
                  else
                    ...List.generate(
                      visibleRows.length,
                      (index) => _buildRow(
                        context,
                        row: visibleRows[index],
                        odd: index.isOdd,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _setMemberOperationLoading(bool value) {
    if (_isMemberOperationLoading == value || !mounted) return;
    setState(() => _isMemberOperationLoading = value);
  }

  Future<void> _persistNewGrintaPlayer({
    required BuildContext context,
    required Player selected,
    required String memberId,
    required String teamId,
    required AddGrintaPlayerDetails details,
  }) async {
    final l10n = context.l10n;
    final MemberInvitationResult invitationResult =
        await MemberInvitationService.instance.notifyOrInviteMember(
      l10n: l10n,
      member: selected,
      memberId: memberId,
      email: details.email ?? '',
      teamId: teamId,
      seasonId: widget.seasonId,
      teamName: _team.name ?? '',
    );
    debugPrint(
      'TeamDetailScreen._persistNewGrintaPlayer notifyOrInviteMember result=$invitationResult',
    );
    if (!invitationResult.success && !invitationResult.invitationCreated) {
      throw StateError(invitationResult.error ?? '');
    }
    await _addPlayerToGrintaTeam(
      teamId: teamId,
      memberId: memberId,
      details: details,
      invitationId: invitationResult.invitationId,
    );
    debugPrint(
      'TeamDetailScreen._persistNewGrintaPlayer added player memberId=$memberId '
      'invitationId=${invitationResult.invitationId}',
    );
    await _reloadTeamAndMembers();
    _pendingMemberInvitationResult = invitationResult;
  }

  Future<void> _persistNewGrintaStaff({
    required BuildContext context,
    required Player selected,
    required String memberId,
    required String teamId,
    required AddGrintaStaffDetails details,
  }) async {
    final l10n = context.l10n;
    final MemberInvitationResult invitationResult =
        await MemberInvitationService.instance.notifyOrInviteMember(
      l10n: l10n,
      member: selected,
      memberId: memberId,
      email: details.email ?? '',
      teamId: teamId,
      seasonId: widget.seasonId,
      teamName: _team.name ?? '',
    );
    debugPrint(
      'TeamDetailScreen._persistNewGrintaStaff notifyOrInviteMember result=$invitationResult',
    );
    if (!invitationResult.success && !invitationResult.invitationCreated) {
      throw StateError(invitationResult.error ?? '');
    }
    await _addStaffToGrintaTeam(
      teamId: teamId,
      memberId: memberId,
      details: details,
      profile: selected,
      invitationId: invitationResult.invitationId,
    );
    debugPrint(
      'TeamDetailScreen._persistNewGrintaStaff added staff memberId=$memberId '
      'invitationId=${invitationResult.invitationId}',
    );
    await _reloadTeamAndMembers();
    _pendingMemberInvitationResult = invitationResult;
  }

  Future<void> _onAddPlayerPressed(BuildContext context) async {
    final teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return;

    final l10n = context.l10n;
    final Player? selected = await showMemberSearchSheet(
      context,
      title: l10n.actionAddPlayer,
      excludeMemberIds: _playerAddExcludeMemberIds(),
      showCreateButton: _usesGrintaRosterPathFor(_team),
    );
    if (selected == null || !context.mounted) return;

    final String? selectedMemberId = effectiveMemberId(selected);
    if (selectedMemberId == null || selectedMemberId.isEmpty) {
      AppSnackbar.show(
        context,
        l10n.errorGeneric(l10n.entityPlayerUnknown),
        isError: true,
      );
      return;
    }

    if (_usesGrintaRosterPathFor(_team)) {
      if (_grintaHasPlayerEntry(selectedMemberId)) {
        AppSnackbar.show(
          context,
          l10n.memberAlreadyPlayer,
          isError: true,
        );
        return;
      }
    } else if (_legacyPlayerRosterIds().contains(selectedMemberId)) {
      AppSnackbar.show(
        context,
        l10n.memberAlreadyOnTeamRoster,
        isError: true,
      );
      return;
    }

    _setMemberOperationLoading(true);
    bool canAdd = false;
    try {
      canAdd = await SubscriptionLimitsAccess.ensureCanAddPlayer(
        context,
        teamId: teamId,
        memberId: selectedMemberId,
        firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
      );
    } finally {
      _setMemberOperationLoading(false);
    }
    if (!canAdd || !context.mounted) return;

    _pendingMemberInvitationResult = null;

    try {
      if (_usesGrintaRosterPathFor(_team)) {
        final AddGrintaPlayerDetails? playerDetails =
            await showAddGrintaPlayerSheet(
          context,
          member: selected,
          onSubmit: (details) => _persistNewGrintaPlayer(
            context: context,
            selected: selected,
            memberId: selectedMemberId,
            teamId: teamId,
            details: details,
          ),
        );
        if (playerDetails == null || !context.mounted) return;

        AppSnackbar.show(
          context,
          '${l10n.actionAddPlayer}: ${playerDisplayName(selected, unknownLabel: l10n.entityPlayerUnknown)}',
          isError: false,
        );
        _showMemberInvitationResultIfNeeded(
          context,
          l10n,
          _pendingMemberInvitationResult,
        );
      } else {
        _setMemberOperationLoading(true);
        try {
          await _addPlayerToLegacyTeam(
            teamId: teamId,
            memberId: selectedMemberId,
          );

          if (!context.mounted) return;

          _dismissOpenSheets(context);
          await _reloadTeamAndMembers();

          if (!context.mounted) return;

          AppSnackbar.show(
            context,
            '${l10n.actionAddPlayer}: ${playerDisplayName(selected, unknownLabel: l10n.entityPlayerUnknown)}',
            isError: false,
          );
        } finally {
          _setMemberOperationLoading(false);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  void _dismissOpenSheets(BuildContext context) {
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  void _showMemberInvitationResultIfNeeded(
    BuildContext context,
    AppLocalizations l10n,
    MemberInvitationResult? result,
  ) {
    if (result == null ||
        result.success ||
        !result.invitationCreated ||
        result.emailSent) {
      return;
    }
    final error = result.error?.trim();
    if (error != null && error.isNotEmpty) {
      debugPrint('TeamDetailScreen member invitation email failed: $error');
    }
    AppSnackbar.show(
      context,
      kDebugMode && error != null && error.isNotEmpty
          ? l10n.errorGeneric(error)
          : l10n.memberInvitationEmailFailed,
      isError: true,
    );
  }

  bool _shouldShowResendInvitation(BuildContext context, _TeamMemberVm row) {
    if (!_canManageRoster(context)) {
      return false;
    }
    if (!row.isGrintaRoster) {
      return false;
    }
    return !isMemberLinkedToAppAccount(row.player);
  }

  bool _isResendInvitationEnabled(_TeamMemberVm row) {
    final String email = row.grintaEmail?.trim() ?? '';
    return email.isNotEmpty && isValidEmailFormat(email);
  }

  String _resendInvitationTooltip(AppLocalizations l10n, _TeamMemberVm row) {
    return _isResendInvitationEnabled(row)
        ? l10n.resendInvitationTooltip
        : l10n.resendInvitationNoEmailTooltip;
  }

  bool _isResendingInvitationForRow(_TeamMemberVm row) {
    final String? memberId = effectiveMemberId(row.player)?.trim();
    return memberId != null &&
        memberId.isNotEmpty &&
        memberId == _resendingInvitationMemberId;
  }

  Future<void> _persistGrintaInvitationId({
    required String teamId,
    required String memberId,
    required String invitationId,
    required bool staff,
  }) async {
    final GrintaPlayer? existing =
        _grintaEntryForMemberId(memberId, staff: staff);
    if (existing == null) {
      return;
    }

    final GrintaPlayer updated = GrintaPlayer(
      playerId: existing.playerId,
      positions: List<int>.from(existing.positions),
      fonction: existing.fonction,
      trackers: List<String>.from(existing.trackers),
      email: existing.email,
      phoneE164: existing.phoneE164,
      birthday: existing.birthday,
      hwHistory: List<GrintaPlayerHW>.from(existing.hwHistory),
      invitationId: invitationId,
    );

    await TeamService().updateGrintaPlayer(
      teamId: teamId,
      playerId: memberId,
      player: updated,
      staffEntry: staff,
    );

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final int index = grintaPlayers.indexWhere(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == memberId.trim() &&
          _isGrintaStaffGrintaPlayer(entry) == staff,
    );
    if (index >= 0) {
      grintaPlayers[index] = updated;
      _team.grintaPlayers = grintaPlayers;
    }
  }

  Future<void> _onResendInvitationPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    if (!_shouldShowResendInvitation(context, row) ||
        !_isResendInvitationEnabled(row) ||
        _isResendingInvitationForRow(row)) {
      return;
    }

    final String? memberId = effectiveMemberId(row.player)?.trim();
    if (memberId == null || memberId.isEmpty) {
      return;
    }

    final String? teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) {
      return;
    }

    final AppLocalizations l10n = context.l10n;
    final String email = row.grintaEmail?.trim() ?? '';
    final bool staff = _isStaffMember(row);

    setState(() => _resendingInvitationMemberId = memberId);
    try {
      final MemberInvitationResult result =
          await MemberInvitationService.instance.resendInvitation(
        l10n: l10n,
        memberId: memberId,
        email: email,
        teamId: teamId,
        seasonId: widget.seasonId,
      );

      if (!context.mounted) {
        return;
      }

      if (result.success && result.emailSent) {
        final String? invitationId = result.invitationId?.trim();
        if (invitationId != null && invitationId.isNotEmpty) {
          await _persistGrintaInvitationId(
            teamId: teamId,
            memberId: memberId,
            invitationId: invitationId,
            staff: staff,
          );
          await _reloadTeamAndMembers();
        }

        if (!context.mounted) {
          return;
        }

        AppSnackbar.show(
          context,
          l10n.resendInvitationSuccess,
          isError: false,
        );
        return;
      }

      if (result.skipped) {
        return;
      }

      AppSnackbar.show(
        context,
        kDebugMode &&
                result.error != null &&
                result.error!.trim().isNotEmpty
            ? l10n.errorGeneric(result.error!)
            : l10n.resendInvitationFailed,
        isError: true,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        l10n.errorGeneric(e.toString()),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _resendingInvitationMemberId = null);
      }
    }
  }

  Widget _buildResendInvitationButton(
    BuildContext context,
    _TeamMemberVm row, {
    required bool compact,
  }) {
    if (!_shouldShowResendInvitation(context, row)) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = context.l10n;
    final colors = context.appColors;
    final bool enabled = _isResendInvitationEnabled(row) &&
        !_isResendingInvitationForRow(row);
    final String tooltip = _resendInvitationTooltip(l10n, row);
    final bool loading = _isResendingInvitationForRow(row);

    if (compact) {
      return IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: 26,
          minHeight: 26,
        ),
        tooltip: tooltip,
        onPressed: enabled ? () => _onResendInvitationPressed(context, row) : null,
        icon: loading
            ? SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            : Icon(
                Icons.mail_outline_rounded,
                size: 17,
                color: enabled
                    ? colors.primary
                    : colors.textSecondary.withValues(alpha: 0.35),
              ),
      );
    }

    if (loading) {
      return SizedBox(
        width: _CircleGhostButton.webTableButtonSize,
        height: _CircleGhostButton.webTableButtonSize,
        child: Center(
          child: SizedBox(
            width: 15,
            height: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
      );
    }

    return _CircleGhostButton(
      icon: Icons.mail_outline_rounded,
      size: _CircleGhostButton.webTableButtonSize,
      iconSize: _CircleGhostButton.webTableIconSize,
      tooltip: tooltip,
      enabled: enabled,
      iconColor: enabled ? colors.primary : null,
      onTap: loading ? null : () => _onResendInvitationPressed(context, row),
    );
  }

  Future<void> _addPlayerToGrintaTeam({
    required String teamId,
    required String memberId,
    required AddGrintaPlayerDetails details,
    String? invitationId,
  }) async {
    final List<GrintaPlayerHW> hwHistory = details.initialMeasurement != null
        ? <GrintaPlayerHW>[details.initialMeasurement!]
        : const <GrintaPlayerHW>[];

    final GrintaPlayer newPlayer = GrintaPlayer(
      playerId: memberId,
      positions: List<int>.from(details.positions),
      email: details.email,
      phoneE164: details.phoneE164,
      birthday: details.birthday,
      hwHistory: hwHistory,
      invitationId: invitationId,
    );

    debugPrint(
      'TeamDetailScreen._addPlayerToGrintaTeam memberId=$memberId '
      'invitationId=$invitationId player=$newPlayer',
    );

    await TeamService().addGrintaPlayer(
      teamId: teamId,
      player: newPlayer,
      firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
      staffEntry: false,
    );

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final bool alreadyOnRoster = grintaPlayers.any(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == memberId.trim() &&
          !_isGrintaStaffGrintaPlayer(entry),
    );
    if (!alreadyOnRoster) {
      grintaPlayers.add(newPlayer);
    }
    _team.grintaPlayers = grintaPlayers;
  }

  Future<void> _addPlayerToLegacyTeam({
    required String teamId,
    required String memberId,
  }) async {
    final String? seasonId = widget.seasonId?.trim();
    if (seasonId == null || seasonId.isEmpty) {
      throw StateError('Missing seasonId for legacy player add');
    }

    await _effectivesService.addEffectives(
      Effectives(
        memberID: memberId,
        seasonID: seasonId,
        teamID: teamId,
        type: 0,
        clubId: _team.clubId?.trim() ?? '',
      ),
    );

    await TeamService().addPlayer(teamId: teamId, playerId: memberId);

    final List<dynamic> players =
        List<dynamic>.from(_team.players ?? const <dynamic>[]);
    if (!players.contains(memberId)) {
      players.add(memberId);
    }
    _team.players = players;
  }

  bool _usesGrintaRosterPathFor(Team team) =>
      _mutationsTargetGrintaRosterFor(team);

  GrintaPlayer? _grintaPlayerForMemberId(String memberId) {
    return _grintaEntryForMemberId(memberId, staff: false);
  }

  /// Resolves a Grinta roster entry using every stable member id on [row.player].
  GrintaPlayer? _resolveGrintaPlayerForRow(_TeamMemberVm row) {
    for (final String id in playerMemberLookupIds(row.player)) {
      final GrintaPlayer? entry = _grintaPlayerForMemberId(id);
      if (entry != null) {
        return entry;
      }
    }
    return null;
  }

  Future<void> _onTogglePlayerManagerPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    await _togglePlayerManager(context, row);
  }

  Future<bool> _togglePlayerManager(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    if (!_canManageTeam(context)) return _isPlayerManager(row);

    final String? teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return _isPlayerManager(row);

    final String? memberId = effectiveMemberId(row.player);
    if (memberId == null || memberId.isEmpty) return _isPlayerManager(row);

    final Player player = row.player;
    final bool isManager = _isPlayerManager(row);
    final Set<String> managerUserIds = playerFirebaseUserIds(player);

    if (!isManager && managerUserIds.isEmpty) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          context.l10n.errorGeneric(context.l10n.infoUserNotConnected),
          isError: true,
        );
      }
      return isManager;
    }

    try {
      await _persistManagerRightsForPlayer(
        teamId: teamId,
        player: player,
        grant: !isManager,
        legacyMemberId: memberId,
      );

      _syncLocalManagersForPlayer(
        player: player,
        grant: !isManager,
        legacyMemberId: memberId,
      );

      if (!context.mounted) return !isManager;
      await _reloadTeamAndMembers();
      return !isManager;
    } catch (e) {
      if (!context.mounted) return isManager;
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
        isError: true,
      );
      return isManager;
    }
  }

  Future<void> _onEditPlayerPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    if (!_canEditPlayerRow(row)) {
      return;
    }

    final teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return;

    final String? memberId = effectiveMemberId(row.player);
    if (memberId == null || memberId.isEmpty) return;

    final GrintaPlayer? existing = _resolveGrintaPlayerForRow(row);

    final l10n = context.l10n;
    final bool canToggleManager = _canManageTeam(context);
    final ValueNotifier<bool> managerNotifier =
        ValueNotifier<bool>(_isPlayerManager(row));
    final AddGrintaPlayerDetails? details = await showAddGrintaPlayerSheet(
      context,
      member: row.player,
      existingGrintaPlayer: existing,
      showManagerToggle: canToggleManager,
      isManagerListenable: canToggleManager ? managerNotifier : null,
      onToggleManager: canToggleManager
          ? () => _togglePlayerManager(context, row)
          : null,
    );
    managerNotifier.dispose();
    if (details == null || !context.mounted) return;

    try {
      MemberInvitationResult? invitationResult;
      if (existing == null) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: row.player,
          memberId: memberId,
          email: details.email ?? '',
          teamId: teamId,
          seasonId: widget.seasonId,
          teamName: _team.name ?? '',
        );
        if (!invitationResult.success && !invitationResult.invitationCreated) {
          if (!context.mounted) return;
          AppSnackbar.show(
            context,
            l10n.errorGeneric(invitationResult.error ?? ''),
            isError: true,
          );
          return;
        }
        await _addPlayerToGrintaTeam(
          teamId: teamId,
          memberId: memberId,
          details: details,
          invitationId: invitationResult.invitationId,
        );
      } else {
        String? invitationId = existing.invitationId;
        if (_invitationEmailChanged(existing.email, details.email)) {
          invitationResult =
              await MemberInvitationService.instance.notifyOrInviteMember(
            l10n: l10n,
            member: row.player,
            memberId: memberId,
            email: details.email ?? '',
            teamId: teamId,
            seasonId: widget.seasonId,
            teamName: _team.name ?? '',
            notifyIfLinked: false,
          );
          if (!invitationResult.success &&
              !invitationResult.invitationCreated) {
            if (!context.mounted) return;
            AppSnackbar.show(
              context,
              l10n.errorGeneric(invitationResult.error ?? ''),
              isError: true,
            );
            return;
          }
          if (invitationResult.invitationId != null &&
              invitationResult.invitationId!.trim().isNotEmpty) {
            invitationId = invitationResult.invitationId;
          }
        }

        await _updateGrintaTeamPlayer(
          teamId: teamId,
          memberId: memberId,
          existing: existing,
          details: details,
          invitationId: invitationId,
        );
      }

      if (!context.mounted) return;

      _dismissOpenSheets(context);
      await _reloadTeamAndMembers();

      if (!context.mounted) return;

      AppSnackbar.show(
        context,
        '${l10n.actionEditPlayer}: ${playerDisplayName(row.player, unknownLabel: l10n.entityPlayerUnknown)}',
        isError: false,
      );
      _showMemberInvitationResultIfNeeded(context, l10n, invitationResult);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  bool _invitationEmailChanged(String? previous, String? next) {
    return previous?.trim() != next?.trim();
  }

  Future<void> _updateGrintaTeamPlayer({
    required String teamId,
    required String memberId,
    required GrintaPlayer existing,
    required AddGrintaPlayerDetails details,
    String? invitationId,
  }) async {
    final List<GrintaPlayerHW> hwHistory =
        List<GrintaPlayerHW>.from(existing.hwHistory);

    final GrintaPlayerHW? newMeasurement = details.initialMeasurement;
    if (newMeasurement != null) {
      final GrintaPlayerHW? latest = existing.latestHw;
      final bool changed = latest == null ||
          latest.height != newMeasurement.height ||
          latest.weight != newMeasurement.weight;
      if (changed) {
        hwHistory.add(newMeasurement);
      }
    }

    final GrintaPlayer updated = GrintaPlayer(
      playerId: memberId,
      positions: List<int>.from(details.positions),
      trackers: List<String>.from(existing.trackers),
      email: details.email,
      phoneE164: details.phoneE164,
      birthday: details.birthday,
      hwHistory: hwHistory,
      invitationId: invitationId ?? existing.invitationId,
    );

    await TeamService().updateGrintaPlayer(
      teamId: teamId,
      playerId: memberId,
      player: updated,
      staffEntry: false,
    );

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final int index = grintaPlayers.indexWhere(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == memberId.trim() &&
          !_isGrintaStaffGrintaPlayer(entry),
    );
    if (index >= 0) {
      grintaPlayers[index] = updated;
    }
    _team.grintaPlayers = grintaPlayers;
  }

  Future<void> _onDeletePlayerPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    final l10n = context.l10n;
    final appColors = context.appColors;
    final Player player = row.player;
    final String playerName = _displayName(player, l10n);

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final dialogL10n = dialogContext.l10n;
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> onDeletePressed() async {
              if (isDeleting) return;
              setDialogState(() => isDeleting = true);

              try {
                if (row.isGrintaRoster) {
                  final String? memberId = effectiveMemberId(player);
                  final String? teamId = _team.keyTeam?.trim();
                  if (memberId == null ||
                      memberId.isEmpty ||
                      teamId == null ||
                      teamId.isEmpty) {
                    throw StateError('Missing member or team id');
                  }

                  await TeamService().removeGrintaPlayer(
                    teamId: teamId,
                    playerId: memberId,
                  );

                  final List<GrintaPlayer> grintaPlayers = List<GrintaPlayer>.from(
                      _team.grintaPlayers ?? const <GrintaPlayer>[]);
                  grintaPlayers.removeWhere(
                    (GrintaPlayer entry) =>
                        entry.playerId.trim() == memberId.trim() &&
                        !_isGrintaStaffGrintaPlayer(entry),
                  );
                  _team.grintaPlayers = grintaPlayers;
                } else if (row.effectives != null) {
                  await EffectivesService().deleteEffectives(row.effectives!);

                  rawPlayers.remove(player.keyMember);
                  _team.players = rawPlayers;
                  await TeamService().updateTeam(_team);
                }

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => isDeleting = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      dialogL10n.errorDeleteFailed(e.toString()),
                    ),
                    backgroundColor: appColors.danger,
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: appColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: appColors.border),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: appColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dialogL10n.teamDetailConfirmDeleteTitle,
                      style: TextStyle(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                dialogL10n.teamDetailConfirmRemovePlayerTeam(playerName),
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                OutlinedButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appColors.textSecondary,
                    side: BorderSide(color: appColors.border),
                  ),
                  child: Text(dialogL10n.actionCancel),
                ),
                FilledButton.icon(
                  onPressed: isDeleting ? null : onDeletePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: appColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  icon: isDeleting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(dialogL10n.actionDelete),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    _setMemberOperationLoading(true);
    try {
      await _reloadTeamAndMembers();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.teamDetailPlayerTeamRemoved(playerName),
            style: TextStyle(color: appColors.textPrimary),
          ),
          backgroundColor: appColors.success,
        ),
      );
    } finally {
      _setMemberOperationLoading(false);
    }
  }

  Future<void> _addStaffToGrintaTeam({
    required String teamId,
    required String memberId,
    required AddGrintaStaffDetails details,
    required Player profile,
    String? invitationId,
  }) async {
    final GrintaPlayer newStaff = GrintaPlayer(
      playerId: memberId,
      fonction: details.roleCode,
      email: details.email,
      phoneE164: details.phoneE164,
      invitationId: invitationId,
    );

    debugPrint(
      'TeamDetailScreen._addStaffToGrintaTeam memberId=$memberId '
      'invitationId=$invitationId staff=$newStaff',
    );

    await _persistManagerRightsForPlayer(
      teamId: teamId,
      player: profile,
      grant: true,
    );

    await TeamService().addGrintaPlayer(
      teamId: teamId,
      player: newStaff,
      firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
      staffEntry: true,
    );

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final bool alreadyOnRoster = grintaPlayers.any(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == memberId.trim() &&
          _isGrintaStaffGrintaPlayer(entry),
    );
    if (!alreadyOnRoster) {
      grintaPlayers.add(newStaff);
    }
    _team.grintaPlayers = grintaPlayers;

    _syncLocalManagersForPlayer(player: profile, grant: true);
  }

  Future<void> _addStaffToLegacyTeam({
    required String teamId,
    required String memberId,
    required AddGrintaStaffDetails details,
    required Player profile,
  }) async {
    final String? seasonId = widget.seasonId?.trim();
    if (seasonId == null || seasonId.isEmpty) {
      throw StateError('Missing seasonId for legacy staff add');
    }

    await _effectivesService.addEffectives(
      Effectives(
        memberID: memberId,
        seasonID: seasonId,
        teamID: teamId,
        type: details.roleCode,
        clubId: _team.clubId?.trim() ?? '',
      ),
    );

    _syncLocalManagersForPlayer(player: profile, grant: true);
    for (final String userId in playerFirebaseUserIds(profile)) {
      await TeamService().addUser(teamId: teamId, userId: userId);
    }
    await TeamService().updateTeam(_team);
  }

  Future<void> _onAddStaffPressed(BuildContext context) async {
    final teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return;
    if (!_canManageTeam(context)) return;

    final l10n = context.l10n;
    final Player? selected = await showMemberSearchSheet(
      context,
      title: l10n.actionAddStaff,
      excludeMemberIds: _staffAddExcludeMemberIds(),
      showCreateButton: true,
    );
    if (selected == null || !context.mounted) return;

    final String? memberId = effectiveMemberId(selected);
    if (memberId == null || memberId.isEmpty) {
      AppSnackbar.show(
        context,
        l10n.errorGeneric(l10n.entityPlayerUnknown),
        isError: true,
      );
      return;
    }

    if (_usesGrintaRosterPathFor(_team)) {
      if (_grintaHasStaffEntry(memberId)) {
        AppSnackbar.show(
          context,
          l10n.memberAlreadyStaff,
          isError: true,
        );
        return;
      }
    } else if (playerFirebaseUserIds(selected)
        .any(_legacyManagerRosterIds().contains)) {
      AppSnackbar.show(
        context,
        l10n.memberAlreadyOnTeamRoster,
        isError: true,
      );
      return;
    }

    _pendingMemberInvitationResult = null;

    try {
      if (_usesGrintaRosterPathFor(_team)) {
        final AddGrintaStaffDetails? details = await showAddGrintaStaffSheet(
          context,
          member: selected,
          onSubmit: (staffDetails) => _persistNewGrintaStaff(
            context: context,
            selected: selected,
            memberId: memberId,
            teamId: teamId,
            details: staffDetails,
          ),
        );
        if (details == null || !context.mounted) return;

        final String playerName = playerDisplayName(
          selected,
          unknownLabel: l10n.entityStaff,
        );
        AppSnackbar.show(
          context,
          '${l10n.actionAddStaff}: $playerName',
          isError: false,
        );
        _showMemberInvitationResultIfNeeded(
          context,
          l10n,
          _pendingMemberInvitationResult,
        );
      } else {
        final AddGrintaStaffDetails? details = await showAddGrintaStaffSheet(
          context,
          member: selected,
        );
        if (details == null || !context.mounted) return;

        _setMemberOperationLoading(true);
        try {
          await _addStaffToLegacyTeam(
            teamId: teamId,
            memberId: memberId,
            details: details,
            profile: selected,
          );

          if (!context.mounted) return;

          _dismissOpenSheets(context);
          await _reloadTeamAndMembers();

          if (!context.mounted) return;

          final String playerName = playerDisplayName(
            selected,
            unknownLabel: l10n.entityStaff,
          );
          AppSnackbar.show(
            context,
            '${l10n.actionAddStaff}: $playerName',
            isError: false,
          );
        } finally {
          _setMemberOperationLoading(false);
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _onEditStaffPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    if (!row.isGrintaRoster) {
      return;
    }

    final teamId = _team.keyTeam?.trim();
    if (teamId == null || teamId.isEmpty) return;

    final String? memberId = effectiveMemberId(row.player);
    if (memberId == null || memberId.isEmpty) return;

    final GrintaPlayer? existing =
        _grintaEntryForMemberId(memberId, staff: true);
    if (existing == null) return;

    final l10n = context.l10n;
    final AddGrintaStaffDetails? details = await showAddGrintaStaffSheet(
      context,
      member: row.player,
      existingGrintaStaff: existing,
    );
    if (details == null || !context.mounted) return;

    try {
      MemberInvitationResult? invitationResult;
      String? invitationId = existing.invitationId;
      if (_invitationEmailChanged(existing.email, details.email)) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: row.player,
          memberId: memberId,
          email: details.email ?? '',
          teamId: teamId,
          seasonId: widget.seasonId,
          teamName: _team.name ?? '',
          notifyIfLinked: false,
        );
        if (!invitationResult.success && !invitationResult.invitationCreated) {
          if (!context.mounted) return;
          AppSnackbar.show(
            context,
            l10n.errorGeneric(invitationResult.error ?? ''),
            isError: true,
          );
          return;
        }
        if (invitationResult.invitationId != null &&
            invitationResult.invitationId!.trim().isNotEmpty) {
          invitationId = invitationResult.invitationId;
        }
      }

      await _updateGrintaTeamStaff(
        teamId: teamId,
        memberId: memberId,
        existing: existing,
        details: details,
        invitationId: invitationId,
      );

      if (!context.mounted) return;

      _dismissOpenSheets(context);
      await _reloadTeamAndMembers();

      if (!context.mounted) return;

      AppSnackbar.show(
        context,
        '${l10n.actionEditStaff}: ${playerDisplayName(row.player, unknownLabel: l10n.entityStaff)}',
        isError: false,
      );
      _showMemberInvitationResultIfNeeded(context, l10n, invitationResult);
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _updateGrintaTeamStaff({
    required String teamId,
    required String memberId,
    required GrintaPlayer existing,
    required AddGrintaStaffDetails details,
    String? invitationId,
  }) async {
    final GrintaPlayer updated = GrintaPlayer(
      playerId: memberId,
      fonction: details.roleCode,
      trackers: List<String>.from(existing.trackers),
      email: details.email,
      phoneE164: details.phoneE164,
      birthday: existing.birthday,
      hwHistory: List<GrintaPlayerHW>.from(existing.hwHistory),
      invitationId: invitationId ?? existing.invitationId,
    );

    await TeamService().updateGrintaPlayer(
      teamId: teamId,
      playerId: memberId,
      player: updated,
      staffEntry: true,
    );

    final List<GrintaPlayer> grintaPlayers =
        List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
    final int index = grintaPlayers.indexWhere(
      (GrintaPlayer entry) =>
          entry.playerId.trim() == memberId.trim() &&
          _isGrintaStaffGrintaPlayer(entry),
    );
    if (index >= 0) {
      grintaPlayers[index] = updated;
    }
    _team.grintaPlayers = grintaPlayers;
  }

  Future<void> _onDeleteStaffPressed(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    final l10n = context.l10n;
    final appColors = context.appColors;
    final Player player = row.player;
    final String playerName = _displayName(player, l10n);

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final dialogL10n = dialogContext.l10n;
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> onDeletePressed() async {
              if (isDeleting) return;
              setDialogState(() => isDeleting = true);

              try {
                if (row.isGrintaRoster) {
                  final String? memberId = effectiveMemberId(player);
                  final String? teamId = _team.keyTeam?.trim();
                  if (memberId == null ||
                      memberId.isEmpty ||
                      teamId == null ||
                      teamId.isEmpty) {
                    throw StateError('Missing member or team id');
                  }

                  final Set<String> managerUserIds = playerFirebaseUserIds(player);

                  await TeamService().removeGrintaStaff(
                    teamId: teamId,
                    playerId: memberId,
                    extraManagerIds: managerUserIds,
                  );

                  final List<GrintaPlayer> grintaPlayers =
                      List<GrintaPlayer>.from(
                          _team.grintaPlayers ?? const <GrintaPlayer>[]);
                  grintaPlayers.removeWhere(
                    (GrintaPlayer entry) =>
                        entry.playerId.trim() == memberId.trim() &&
                        _isGrintaStaffGrintaPlayer(entry),
                  );
                  _team.grintaPlayers = grintaPlayers;
                  _team.grintaPlayerMemberIds =
                      grintaPlayerMemberIdsFromGrintaPlayers(grintaPlayers);

                  _syncLocalManagersForPlayer(
                    player: player,
                    grant: false,
                    legacyMemberId: memberId,
                  );
                } else {
                  final String? teamId = _team.keyTeam?.trim();
                  if (teamId == null || teamId.isEmpty) {
                    throw StateError('Missing team id');
                  }

                  if (row.effectives != null) {
                    await EffectivesService().deleteEffectives(row.effectives!);
                  }

                  final String? memberId = effectiveMemberId(player);
                  if (memberId == null || memberId.isEmpty) {
                    throw StateError('Missing member id');
                  }

                  await _persistManagerRightsForPlayer(
                    teamId: teamId,
                    player: player,
                    grant: false,
                    legacyMemberId: memberId,
                  );
                  _syncLocalManagersForPlayer(
                    player: player,
                    grant: false,
                    legacyMemberId: memberId,
                  );
                }

                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                if (!dialogContext.mounted) return;
                setDialogState(() => isDeleting = false);
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      dialogL10n.errorDeleteFailed(e.toString()),
                    ),
                    backgroundColor: appColors.danger,
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: appColors.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: appColors.border),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: appColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dialogL10n.teamDetailConfirmDeleteTitle,
                      style: TextStyle(
                        color: appColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                dialogL10n.teamDetailConfirmRemoveStaff(playerName),
                style: TextStyle(
                  color: appColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                OutlinedButton(
                  onPressed: isDeleting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appColors.textSecondary,
                    side: BorderSide(color: appColors.border),
                  ),
                  child: Text(dialogL10n.actionCancel),
                ),
                FilledButton.icon(
                  onPressed: isDeleting ? null : onDeletePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: appColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  icon: isDeleting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(dialogL10n.actionDelete),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true || !context.mounted) return;

    _setMemberOperationLoading(true);
    try {
      await _reloadTeamAndMembers();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.teamDetailPlayerRemoved(playerName),
            style: TextStyle(color: appColors.textPrimary),
          ),
          backgroundColor: appColors.success,
        ),
      );
    } finally {
      _setMemberOperationLoading(false);
    }
  }

  Widget _buildStaffCard(BuildContext context, List<_TeamMemberVm> staffRows) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final bool isMobileLayout = _isMobileTeamDetailLayout(context);
    final bool canAddStaff = _canManageRoster(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobileLayout ? 16 : 24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colors.primary,
                size: isMobileLayout ? 24 : 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.entityStaff,
                  style: (isMobileLayout
                          ? textTheme.titleLarge
                          : textTheme.headlineSmall)
                      ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (canAddStaff && !isMobileLayout) ...[
                FilledButton(
                  onPressed: _isMemberOperationLoading
                      ? null
                      : () => _onAddStaffPressed(context),
                  child: Text(l10n.actionAddStaff),
                ),
              ],
            ],
          ),
          SizedBox(height: isMobileLayout ? 16 : 24),
          if (staffRows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                l10n.emptyNoStaffForTeam,
                style: textTheme.titleMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth;

                if (constraints.maxWidth >= 1400) {
                  itemWidth = (constraints.maxWidth - 32) / 3;
                } else if (constraints.maxWidth >= 900) {
                  itemWidth = (constraints.maxWidth - 16) / 2;
                } else {
                  itemWidth = constraints.maxWidth;
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: staffRows.map((row) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildStaffMemberCard(context, row),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStaffMemberCard(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Player player = row.player;
    final l10n = context.l10n;
    final String name = _displayName(player, l10n);
    final String role = _buildStaffRoleForRow(row, l10n);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.75),
        ),
      ),
      child: Row(
        children: [
          PlayerPhoto(
            player: player,
          ),
          const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          ..._buildMemberStatusIcons(context, row)
                              .expand((icon) => [const SizedBox(width: 6), icon]),
                        ],
                      ),
                      PlayerContactLines(
                        player: player,
                        emailOverride:
                            row.isGrintaRoster ? row.grintaEmail : null,
                        phoneE164Override:
                            row.isGrintaRoster ? row.grintaPhoneE164 : null,
                      ),
                      const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_canManageRoster(context)) ...[
            if (_shouldShowResendInvitation(context, row)) ...[
              _buildResendInvitationButton(context, row, compact: false),
              const SizedBox(width: 6),
            ],
            if (row.isGrintaRoster) ...[
              _CircleGhostButton(
                icon: Icons.edit_outlined,
                onTap: () => _onEditStaffPressed(context, row),
              ),
              const SizedBox(width: 6),
            ],
            _CircleGhostButton(
              icon: Icons.delete_outline_rounded,
              onTap: () => _onDeleteStaffPressed(context, row),
            ),
          ]

        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, {required bool mobile}) {
    if (mobile) {
      final double width = MediaQuery.sizeOf(context).width;
      return _buildMobileTableHeader(
        context,
        layout: _MobileRosterLayout.fromWidth(
          width,
          canManageTeam: _canManageTeam(context),
          canManageRoster: _canManageRoster(context),
        ),
      );
    }

    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          _headerCell(
            l10n.entityPlayer,
            flex: 4,
            textTheme: textTheme,
            sortColumn: _RosterSortColumn.player,
          ),
          if (_canManageTeam(context) || _canManageRoster(context)) ...[
            _headerCell('', flex: 3, textTheme: textTheme),
          ],
          _headerCell(
            l10n.teamDetailColumnAge,
            flex: 1,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.age,
          ),
          _headerCell(
            l10n.teamDetailColumnPosition,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.position,
          ),
          _headerCell(
            l10n.teamDetailColumnHeight,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.height,
          ),
          _headerCell(
            l10n.teamDetailColumnWeight,
            flex: 2,
            textTheme: textTheme,
            center: true,
            sortColumn: _RosterSortColumn.weight,
          ),
          _headerCell(
            l10n.entityTracker,
            flex: 3,
            textTheme: textTheme,
            center: false,
            sortColumn: _RosterSortColumn.tracker,
          ),
        ],
      ),
    );
  }

  Widget _headerCell(
      String label, {
        required int flex,
        required TextTheme textTheme,
        bool center = false,
        _RosterSortColumn? sortColumn,
      }) {
    final colors = context.appColors;
    final bool sortable = sortColumn != null;
    final bool active = _sortColumn == sortColumn;

    final Widget content = center
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: active ? colors.primary : null,
                    ),
                  ),
                  if (sortable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      active
                          ? (_sortAscending
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded)
                          : Icons.unfold_more_rounded,
                      size: 15,
                      color: active ? colors.primary : colors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          )
        : Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: active ? colors.primary : null,
                    ),
                  ),
                ),
                if (sortable) ...[
                  const SizedBox(width: 4),
                  Icon(
                    active
                        ? (_sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                        : Icons.unfold_more_rounded,
                    size: 15,
                    color: active ? colors.primary : colors.textSecondary,
                  ),
                ],
              ],
            ),
          );

    return Expanded(
      flex: flex,
      child: sortable
          ? InkWell(
        onTap: () => _onSort(sortColumn),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      )
          : content,
    );
  }

  Widget _buildMobileTableHeader(
    BuildContext context, {
    required _MobileRosterLayout layout,
  }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;
    final bool canManageRoster = _canManageRoster(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          _headerCell(
            l10n.entityPlayer,
            flex: layout.playerFlex,
            textTheme: textTheme,
            sortColumn: _RosterSortColumn.player,
          ),
          _headerCell(
            l10n.teamDetailColumnApp,
            flex: 1,
            textTheme: textTheme,
            center: true,
          ),
          if (layout.showPositionColumn)
            _headerCell(
              l10n.teamDetailColumnPosition,
              flex: 1,
              textTheme: textTheme,
              center: true,
              sortColumn: _RosterSortColumn.position,
            ),
          _mobileIconHeaderCell(
            icon: Icons.sensors_rounded,
            tooltip: l10n.entityTracker,
            flex: 1,
            textTheme: textTheme,
            sortColumn: _RosterSortColumn.tracker,
          ),
          _mobileStaticIconHeaderCell(
            icon: Icons.verified_rounded,
            tooltip: l10n.teamDetailGrantManager,
            flex: 1,
          ),
          if (canManageRoster)
            _mobileStaticIconHeaderCell(
              icon: Icons.mail_outline_rounded,
              tooltip: l10n.resendInvitationTooltip,
              flex: 1,
            ),
          if (_canManageTeam(context))
            _mobileStaticIconHeaderCell(
              icon: Icons.event_busy_outlined,
              tooltip: l10n.teamDetailManageUnavailabilities,
              flex: 1,
            ),
          if (canManageRoster && layout.showInlineEditColumn)
            _mobileStaticIconHeaderCell(
              icon: Icons.edit_outlined,
              tooltip: l10n.actionEditPlayer,
              flex: 1,
            ),
          _mobileStaticIconHeaderCell(
            icon: Icons.info_outline_rounded,
            tooltip: l10n.teamDetailPlayerDetailsTitle,
            flex: 1,
          ),
        ],
      ),
    );
  }

  Widget _mobileStaticIconHeaderCell({
    required IconData icon,
    required String tooltip,
    required int flex,
  }) {
    final colors = context.appColors;

    return Expanded(
      flex: flex,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 16,
              color: colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileIconHeaderCell({
    required IconData icon,
    required String tooltip,
    required int flex,
    required TextTheme textTheme,
    required _RosterSortColumn sortColumn,
  }) {
    final colors = context.appColors;
    final bool active = _sortColumn == sortColumn;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => _onSort(sortColumn),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: tooltip,
                  child: Icon(
                    icon,
                    size: 16,
                    color: active ? colors.primary : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  active
                      ? (_sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                      : Icons.unfold_more_rounded,
                  size: 15,
                  color: active ? colors.primary : colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppAccountIndicator(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final l10n = context.l10n;

    if (isMemberLinkedToAppAccount(row.player)) {
      return Tooltip(
        message: l10n.memberAppAccountLinked,
        child: Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: colors.success,
        ),
      );
    }

    if (row.isGrintaRoster) {
      final String? invitationId = row.grintaInvitationId?.trim();
      if (invitationId != null &&
          invitationId.isNotEmpty &&
          row.invitationAccepted != true) {
        return Tooltip(
          message: l10n.invitationPending,
          child: Icon(
            Icons.schedule_rounded,
            size: 18,
            color: colors.warning,
          ),
        );
      }
    }

    return Icon(
      Icons.circle_outlined,
      size: 14,
      color: colors.textSecondary.withValues(alpha: 0.35),
    );
  }

  Widget _buildManagerIndicator(BuildContext context, _TeamMemberVm row) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final bool isManager = _isPlayerManager(row);
    final bool canToggle = _canManageTeam(context);

    final Widget icon = Icon(
      Icons.verified_rounded,
      size: 18,
      color: isManager
          ? colors.success
          : colors.textSecondary.withValues(alpha: 0.25),
    );

    if (!canToggle) {
      return icon;
    }

    return IconButton(
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(
        minWidth: 26,
        minHeight: 26,
      ),
      tooltip: isManager
          ? l10n.teamDetailRevokeManager
          : l10n.teamDetailGrantManager,
      onPressed: () => _onTogglePlayerManagerPressed(context, row),
      icon: icon,
    );
  }

  Future<void> _showPlayerDetailsSheet(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Effectives? effectives = row.effectives;

    final String age = _buildAgeForRow(row);
    final int? heightCm = _heightCmForRow(row);
    final String taille = heightCm != null
        ? l10n.teamDetailHeightCm(heightCm)
        : '-';
    final double? weightKg =
        row.isGrintaRoster ? row.grintaWeightKg : effectives?.poids?.toDouble();
    final String poids = weightKg != null && weightKg > 0
        ? (row.isGrintaRoster
            ? _formatWeightLabel(weightKg, l10n)
            : l10n.teamDetailWeightKg(weightKg.round()))
        : '-';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.card,
      builder: (sheetContext) {
        final sheetL10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sheetL10n.teamDetailPlayerDetailsTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _playerDetailLine(
                  context,
                  label: sheetL10n.teamDetailColumnAge,
                  value: age,
                ),
                const SizedBox(height: 10),
                _playerDetailLine(
                  context,
                  label: sheetL10n.teamDetailColumnHeight,
                  value: taille,
                ),
                const SizedBox(height: 10),
                _playerDetailLine(
                  context,
                  label: sheetL10n.teamDetailColumnWeight,
                  value: poids,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _playerDetailLine(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Future<void> _showManageUnavailabilitiesSheet(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    if (!_canManageTeam(context)) return;

    final String? memberId = effectiveMemberId(row.player);
    if (memberId == null || memberId.isEmpty) return;

    await showManageUnavailabilitiesSheet(
      context,
      player: row.player,
      seasonId: widget.seasonId,
      isManager: true,
      onChanged: _reloadTeamAndMembers,
    );
  }

  Future<void> _showPlayerTrackersSheet(
    BuildContext context,
    _TeamMemberVm row,
  ) async {
    final colors = context.appColors;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colors.card,
      builder: (sheetContext) {
        final NavigatorState sheetNavigator = Navigator.of(sheetContext);
        void closeSheetOnTrackerAssign() {
          if (sheetNavigator.mounted) {
            sheetNavigator.pop();
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sheetContext.l10n.entityTracker,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                if (_canManageTeam(context)) ...[
                  CoachWearableDeviceConnectSection(
                    playerId: (row.player.keyMember ?? '').trim(),
                    playerName: _displayName(row.player, sheetContext.l10n),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.border.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                ],
                _buildTrackerChipsCell(
                  sheetContext,
                  row,
                  closeSheetOnTrackerAssign: closeSheetOnTrackerAssign,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileRow(
    BuildContext context, {
    required _MobileRosterLayout layout,
    required _TeamMemberVm row,
    required bool odd,
  }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Player player = row.player;
    final Effectives? effectives = row.effectives;

    if (effectives == null &&
        !row.isGrintaRoster &&
        _teamUsesGrintaRoster()) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final String playerName = _displayName(player, l10n);
    final String position = _positionLabelForRow(row, l10n);
    final bool canManageRoster = _canManageRoster(context);
    final bool isUnavailable = isPlayerCurrentlyUnavailable(
      player,
      widget.seasonId,
      managerView: _canManageTeam(context),
    );
    final Color rowColor = isUnavailable
        ? colors.warning.withValues(alpha: 0.12)
        : _mobileRowBackgroundColor(colors, odd);
    final bool hasTrackers = row.trackers.isNotEmpty;

    final Widget rowContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: layout.playerFlex,
            child: Row(
              children: [
                PlayerPhoto(player: player, radius: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _CompactIconCell(
              width: 26,
              child: _buildAppAccountIndicator(context, row),
            ),
          ),
          if (layout.showPositionColumn)
            _valueCell(position, flex: 1, center: true),
          Expanded(
            flex: 1,
            child: _CompactIconCell(
              width: 26,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
                tooltip: l10n.entityTracker,
                onPressed: () => _showPlayerTrackersSheet(context, row),
                icon: Badge(
                  isLabelVisible: hasTrackers,
                  label: Text('${row.trackers.length}'),
                  child: Icon(
                    Icons.sensors_rounded,
                    size: 17,
                    color: hasTrackers
                        ? colors.primary
                        : colors.textSecondary.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: _CompactIconCell(
              width: 26,
              child: _buildManagerIndicator(context, row),
            ),
          ),
          if (_canManageRoster(context))
            Expanded(
              flex: 1,
              child: _CompactIconCell(
                width: 26,
                child: _buildResendInvitationButton(context, row, compact: true),
              ),
            ),
          if (_canManageTeam(context))
            Expanded(
              flex: 1,
              child: _CompactIconCell(
                width: 26,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  tooltip: l10n.teamDetailManageUnavailabilities,
                  onPressed: () =>
                      _showManageUnavailabilitiesSheet(context, row),
                  icon: Icon(
                    Icons.event_busy_outlined,
                    size: 17,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          if (canManageRoster && layout.showInlineEditColumn)
            Expanded(
              flex: 1,
              child: _CompactIconCell(
                width: 26,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                  tooltip: l10n.actionEditPlayer,
                  onPressed: () => _onEditPlayerPressed(context, row),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 17,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: _CompactIconCell(
              width: 26,
              child: IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
                tooltip: l10n.teamDetailPlayerDetailsTitle,
                onPressed: () => _showPlayerDetailsSheet(context, row),
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!canManageRoster) {
      return rowContent;
    }

    final VoidCallback? swipeEdit = layout.showInlineEditColumn
        ? null
        : () => _onEditPlayerPressed(context, row);

    return _TeamPlayerSwipeRow(
      key: ValueKey(
        'team-player-swipe-${effectiveMemberId(player) ?? player.keyMember ?? playerName}',
      ),
      backgroundColor: rowColor,
      editLabel: l10n.actionEditPlayer,
      removeLabel: l10n.teamDetailRemoveFromTeam,
      onEdit: swipeEdit,
      onRemove: () => _onDeletePlayerPressed(context, row),
      child: rowContent,
    );
  }

  Widget _buildRow(
      BuildContext context, {
        required _TeamMemberVm row,
        required bool odd,
      }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final Player player = row.player;
    final Effectives? effectives = row.effectives;

    if (effectives == null &&
        !row.isGrintaRoster &&
        _teamUsesGrintaRoster()) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final String playerName = _displayName(player, l10n);
    final String position = _positionLabelForRow(row, l10n);

    final int? heightCm = _heightCmForRow(row);
    final String taille = heightCm != null
        ? l10n.teamDetailHeightCm(heightCm)
        : '-';

    final double? weightKg =
        row.isGrintaRoster ? row.grintaWeightKg : effectives?.poids?.toDouble();
    final String poids = weightKg != null && weightKg > 0
        ? (row.isGrintaRoster
            ? _formatWeightLabel(weightKg, l10n)
            : l10n.teamDetailWeightKg(weightKg.round()))
        : '-';

    final String age = _buildAgeForRow(row);
    final bool isUnavailable = isPlayerCurrentlyUnavailable(
      player,
      widget.seasonId,
      managerView: _canManageTeam(context),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isUnavailable
            ? colors.warning.withValues(alpha: 0.12)
            : odd
                ? colors.background.withValues(alpha: 0.45)
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colors.border.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                PlayerPhoto(player: player),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              playerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall,
                            ),
                          ),
                          ..._buildMemberStatusIcons(context, row)
                              .expand((icon) => [const SizedBox(width: 6), icon]),
                        ],
                      ),
                      _playerContactLinesForRow(row),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_canManageTeam(context) || _canManageRoster(context)) ...[
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_canManageTeam(context)) ...[
                      _CircleGhostButton(
                        icon: Icons.verified_rounded,
                        size: _CircleGhostButton.webTableButtonSize,
                        iconSize: _CircleGhostButton.webTableIconSize,
                        iconColor: _isPlayerManager(row)
                            ? context.appColors.success
                            : null,
                        onTap: () =>
                            _onTogglePlayerManagerPressed(context, row),
                      ),
                      const SizedBox(width: 3),
                    ],
                    if (_canManageRoster(context)) ...[
                      _buildResendInvitationButton(context, row, compact: false),
                      if (_canManageTeam(context)) const SizedBox(width: 3),
                    ],
                    if (_canManageTeam(context)) ...[
                      _CircleGhostButton(
                        icon: Icons.event_busy_outlined,
                        size: _CircleGhostButton.webTableButtonSize,
                        iconSize: _CircleGhostButton.webTableIconSize,
                        onTap: () =>
                            _showManageUnavailabilitiesSheet(context, row),
                      ),
                      if (_canManageRoster(context)) const SizedBox(width: 3),
                    ],
                    if (_canManageRoster(context)) ...[
                      _CircleGhostButton(
                        icon: Icons.edit_outlined,
                        size: _CircleGhostButton.webTableButtonSize,
                        iconSize: _CircleGhostButton.webTableIconSize,
                        onTap: () => _onEditPlayerPressed(context, row),
                      ),
                      const SizedBox(width: 3),
                      _CircleGhostButton(
                        icon: Icons.delete_outline_rounded,
                        size: _CircleGhostButton.webTableButtonSize,
                        iconSize: _CircleGhostButton.webTableIconSize,
                        onTap: () => _onDeletePlayerPressed(context, row),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          _valueCell(age, flex: 1, center: true),
          _valueCell(position, flex: 2, center: true),
          _valueCell(taille, flex: 2, center: true),
          _valueCell(poids, flex: 2, center: true),
          Expanded(
            flex: 3,
            child: _buildTrackerChipsCell(context, row),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerChipsCell(
    BuildContext context,
    _TeamMemberVm row, {
    VoidCallback? closeSheetOnTrackerAssign,
  }) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (row.trackers.isEmpty)
            Text(
              '-',
              style: textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),

          ...row.trackers.map((tracker) {
            final bool canDelete = _canManageRoster(context);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      tracker.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canDelete) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () async {
                        await _deleteTrackerAffectation(
                          context: context,
                          row: row,
                          tracker: tracker,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (_canAssignTeamTrackers(context)) ...[
            _buildAddTrackerButton(
              context: context,
              row: row,
              closeSheetOnTrackerAssign: closeSheetOnTrackerAssign,
            ),
          ]

        ],
      ),
    );
  }
  Widget _buildAddTrackerButton({
    required BuildContext context,
    required _TeamMemberVm row,
    VoidCallback? closeSheetOnTrackerAssign,
  }) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await _addTrackerAffectation(
          context: context,
          row: row,
          closeSheetOnTrackerAssign: closeSheetOnTrackerAssign,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.45),
          ),
        ),
        child: Icon(
          Icons.add,
          size: 20,
          color: colors.primary,
        ),
      ),
    );
  }
  Future<void> _addTrackerAffectation({
    required BuildContext context,
    required _TeamMemberVm row,
    VoidCallback? closeSheetOnTrackerAssign,
  }) async {
    if (!_canAssignTeamTrackers(context)) {
      return;
    }

    final Team team = _serverTeam ?? _team;
    if (!team.hasAnyTrackerOwners) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        context.l10n.trainingPlayersNoTrackerAvailable,
      );
      return;
    }

    final List<DeviceOwner> allDevices = await _loadTeamTrackerDevices();
    final List<_TeamMemberVm> members = await _future;
    final Set<String> assignedIds = _collectAssignedTrackerDocIds(members);
    final List<DeviceOwner> available = allDevices
        .where((DeviceOwner device) => !assignedIds.contains(device.id))
        .toList()
      ..sort(compareDeviceOwnersByCustomName);

    if (!context.mounted) {
      return;
    }

    final DeviceOwner? selected = await showAssignTrackerDialog(
      context: context,
      availableDevices: available,
    );
    if (selected == null || !context.mounted) {
      return;
    }

    try {
      await _persistTrackerChange(
        row: row,
        deviceOwnerDocId: selected.id,
        add: true,
      );
      if (!context.mounted) {
        return;
      }
      closeSheetOnTrackerAssign?.call();
      await _reloadTeamAndMembers();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  Future<void> _deleteTrackerAffectation({
    required BuildContext context,
    required _TeamMemberVm row,
    required _TrackerChipVm tracker,
  }) async {
    final colors = context.appColors;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = dialogContext.l10n;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            dialogL10n.dialogDeleteAssignmentTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            dialogL10n.teamDetailConfirmRemoveTracker(tracker.label),
            style: TextStyle(
              color: colors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                dialogL10n.actionCancel,
                style: TextStyle(
                  color: colors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                dialogL10n.actionDelete,
                style: TextStyle(
                  color: colors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _persistTrackerChange(
        row: row,
        deviceOwnerDocId: tracker.id,
        add: false,
      );
      if (!context.mounted) {
        return;
      }
      await _reloadTeamAndMembers();
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      AppSnackbar.show(
        context,
        context.l10n.errorGeneric(e.toString()),
        isError: true,
      );
    }
  }

  String _buildAgeForRow(_TeamMemberVm row) {
    final int? age = _ageValueForRow(row);
    if (age == null) {
      return '-';
    }

    return age.toString();
  }

  DateTime? _getBirthDate(Player player) {
    final String? raw = player.birthDay;

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final List<String> parts = raw.trim().split('/');

    if (parts.length != 3) {
      return null;
    }

    final int? day = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Widget _valueCell(
      String value, {
        required int flex,
        bool center = false,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ),
    );
  }
}

