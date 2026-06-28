import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
import '../../util/player_photo_resolver.dart';

import '../../model/tracker/owner.dart';
import '../../services/effectivesService.dart';
import '../../services/deviceService.dart';
import '../../services/invitationService.dart';
import '../../services/member_invitation_service.dart';
import '../../services/ownerService.dart';
import '../../services/player_positions_service.dart';
import '../../widget/add_grinta_player_sheet.dart';
import '../../widget/add_grinta_staff_sheet.dart';
import '../../widget/member_search_sheet.dart';
import '../../widget/playerPhoto.dart';
import '../../widget/player_contact_lines.dart';

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

  late Future<List<_TeamMemberVm>> _future;

  _RosterSortColumn? _sortColumn;
  bool _sortAscending = true;

  List<dynamic> rawPlayers = [];
  bool _usesGrintaRoster = false;
  late Team _team;
  Team? _serverTeam;
  int _headerPlayersCount = 0;
  int _headerStaffCount = 0;

  @override
  void initState() {
    super.initState();

    _playerService = PlayerService();
    _effectivesService = widget.effectivesService ?? EffectivesService();

    _deviceOwnerService = DeviceOwnerService();
    _deviceService = DeviceService();
    _ownerService = OwnerService();

    _team = widget.team;
    _serverTeam = null;
    _headerPlayersCount = 0;
    _headerStaffCount = 0;
    _future = _fetchTeamFromFirestore().then((_) => _loadMembers());
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
        _future = _fetchTeamFromFirestore().then((_) => _loadMembers());
      });
    }
  }

  /// Legacy managers ([widget.isManager]) or Grinta team owners ([Team.uid]).
  bool _canManageTeam(BuildContext context) {
    if (widget.isManager) {
      return true;
    }
    final String? currentUserUid =
        context.read<AppSession>().user?.uid ??
        FirebaseAuth.instance.currentUser?.uid;
    return isTeamOwner(_team, currentUserUid);
  }

  /// Roster mutations are disabled when players are managed in another app.
  bool _canManageRoster(BuildContext context) {
    return !_teamUsesExternalLegacyRoster() && _canManageTeam(context);
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

    if (raw is! String) {
      return null;
    }

    final String id = raw.trim();
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
      final Set<String> managerIds = _legacyManagerRosterIdsFor(team);

      for (final GrintaPlayer grintaPlayer
          in team.grintaPlayers ?? const <GrintaPlayer>[]) {
        final String playerId = grintaPlayer.playerId.trim();
        if (playerId.isEmpty) {
          continue;
        }

        if (isGrintaRosterStaff(
          positions: grintaPlayer.positions,
          listedInManagers: managerIds.contains(playerId),
        )) {
          staff++;
        } else {
          players++;
        }
      }

      return (players: players, staff: staff);
    }

    return (
      players: _nonEmptyRosterIdCount(team.players),
      staff: _nonEmptyRosterIdCount(team.managers),
    );
  }

  bool _teamHasLegacyPlayersFor(Team team) {
    return _nonEmptyRosterIdCount(team.players) > 0;
  }

  bool _teamHasLegacyPlayers() => _teamHasLegacyPlayersFor(_team);

  /// Players/staff roster is managed in another app when `team.players` has IDs.
  bool _teamUsesExternalLegacyRoster() => _teamHasLegacyPlayers();

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

    final String keyMember = row.player.keyMember?.trim() ?? '';
    if (keyMember.isNotEmpty && rosterIds.contains(keyMember)) {
      return true;
    }

    final String userId = row.player.userID?.trim() ?? '';
    if (userId.isNotEmpty && rosterIds.contains(userId)) {
      return true;
    }

    return false;
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

  Set<String> _grintaManagerIds() => _legacyManagerRosterIds();

  bool _isGrintaStaffGrintaPlayer(GrintaPlayer entry) {
    return isGrintaRosterStaff(
      positions: entry.positions,
      listedInManagers:
          _grintaManagerIds().contains(entry.playerId.trim()),
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
    final Set<String> rosterIds = _explicitRosterMemberIds();
    if (rosterIds.isEmpty) {
      return false;
    }

    final String keyMember = row.player.keyMember?.trim() ?? '';
    if (keyMember.isNotEmpty && rosterIds.contains(keyMember)) {
      return true;
    }

    final String userId = row.player.userID?.trim() ?? '';
    if (userId.isNotEmpty && rosterIds.contains(userId)) {
      return true;
    }

    return false;
  }

  bool _hasStaffProfilePosition(_TeamMemberVm row) {
    if (row.isGrintaRoster) {
      return isGrintaRosterStaff(
        positions: row.grintaPositions,
        listedInManagers:
            _rowMatchesRosterIds(row, _legacyManagerRosterIds()),
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

    if (_rowMatchesRosterIds(row, _legacyPlayerRosterIds())) {
      final Effectives? effectives = row.effectives;
      return effectives == null || effectives.type == 0;
    }

    final Effectives? effectives = row.effectives;
    return effectives != null && effectives.type == 0;
  }

  bool _isStaffMember(_TeamMemberVm row) {
    if (!_isListedOnTeamRoster(row)) {
      return false;
    }

    if (row.isGrintaRoster) {
      return _hasStaffProfilePosition(row);
    }

    if (_rowMatchesRosterIds(row, _legacyManagerRosterIds())) {
      final Effectives? effectives = row.effectives;
      return effectives == null || effectives.type != 0;
    }

    final Effectives? effectives = row.effectives;
    return effectives != null && effectives.type != 0;
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

          final String effectiveMemberId =
              player.keyMember?.trim().isNotEmpty == true
                  ? player.keyMember!.trim()
                  : memberId;

          final Effectives? effectives =
          await _effectivesService.getEffectivesByMemberIdAndTeamId(
            effectiveMemberId,
            teamId,
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
      for (int index = 0; index < grintaPlayers.length; index++) {
        final GrintaPlayer entry = grintaPlayers[index];
        if (entry.playerId.trim() != memberKey) {
          continue;
        }
        if (listEquals(entry.positions, row.grintaPositions)) {
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
        return l10n.entityPlayer;
      }

      final PlayerPositionsService positionsService =
          PlayerPositionsService.instance;
      return row.grintaPositions
          .map((code) => positionsService.labelForCode(code, l10n))
          .join(', ');
    }

    return getStrPosition(row.effectives?.position ?? 0, l10n);
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

  Future<_TrackerChipVm?> _loadTrackerById(String trackerId) async {
    try {
      final DeviceOwner? deviceOwner = await _deviceOwnerService.getById(trackerId);
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
    final String first = player.firstName ?? '';
    final String last = player.lastName ?? '';
    final String value = '$first $last'.trim();

    return value.isEmpty ? l10n.entityPlayer : value;
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

  String _buildStaffRole(Effectives? effectives, AppLocalizations l10n) {
    if (effectives == null) {
      return l10n.entityStaff;
    }

    return l10n.staffRoleLabel(effectives.type ?? -1);
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
      for (final int code in row.grintaPositions) {
        if (grintaStaffRoleCodes.contains(code)) {
          return grintaStaffRoleLabel(code, l10n);
        }
      }
    }

    return _buildStaffRole(row.effectives, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FutureBuilder<List<_TeamMemberVm>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              );
            }

            final List<_TeamMemberVm> rows = snapshot.data ?? <_TeamMemberVm>[];
            final l10n = context.l10n;
            final List<_TeamMemberVm> rosterRows = rows
                .where(_isListedOnTeamRoster)
                .toList();
            final List<_TeamMemberVm> playerRows = _playerRows(rosterRows);
            final List<_TeamMemberVm> staffRows = _staffRows(rosterRows, l10n);

            final int playersCount = _headerPlayersCount;
            final int staffsCount = _headerStaffCount;
            final double averageAge = _averagePlayersAge(playerRows);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildHeader(
                    context,
                    rows: rows,
                    playersCount: playersCount,
                    staffsCount: staffsCount,
                    averageAge: averageAge,
                  ),
                  const SizedBox(height: 24),
                  _buildRosterCard(context, playerRows),
                  const SizedBox(height: 24),
                  _buildStaffCard(context, staffRows),
                ],
              ),
            );
          },
        ),
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
    final bool isEducatorOrCoach = context.select<AppSession, bool>(
      (session) => session.selectedPlayer?.isEducatorOrCoach ?? false,
    );
    final bool canAddPlayers = !_teamUsesExternalLegacyRoster() &&
        (_canManageTeam(context) || isEducatorOrCoach);

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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Row(
              children: [
                Icon(
                  Icons.groups_2_rounded,
                  color: colors.primary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.entityPlayers,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canAddPlayers) ... [
                  FilledButton(
                    onPressed: () => _onAddPlayerPressed(context),
                    child: Text(l10n.actionAddPlayer),
                  ),
                ]

              ],
            ),
          ),
          _buildTableHeader(context),
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
      ),
    );
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

    final canAdd = await SubscriptionLimitsAccess.ensureCanAddPlayer(
      context,
      teamId: teamId,
      memberId: selectedMemberId,
      firebaseUserId: FirebaseAuth.instance.currentUser?.uid,
    );
    if (!canAdd || !context.mounted) return;

    AddGrintaPlayerDetails? playerDetails;
    if (_usesGrintaRosterPathFor(_team)) {
      playerDetails = await showAddGrintaPlayerSheet(
        context,
        member: selected,
      );
      if (playerDetails == null || !context.mounted) return;
    }

    try {
      MemberInvitationResult? invitationResult;
      if (_usesGrintaRosterPathFor(_team)) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: selected,
          memberId: selectedMemberId,
          phoneE164: playerDetails!.phoneE164,
          teamId: teamId,
          seasonId: widget.seasonId,
          teamName: _team.name ?? '',
        );
        debugPrint(
          'TeamDetailScreen._onAddPlayerPressed notifyOrInviteMember result=$invitationResult',
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
          memberId: selectedMemberId,
          details: playerDetails,
          invitationId: invitationResult.invitationId,
        );
        debugPrint(
          'TeamDetailScreen._onAddPlayerPressed added player memberId=$selectedMemberId '
          'invitationId=${invitationResult.invitationId}',
        );
      } else {
        await _addPlayerToLegacyTeam(
          teamId: teamId,
          memberId: selectedMemberId,
        );
      }

      if (!context.mounted) return;

      _dismissOpenSheets(context);
      await _reloadTeamAndMembers();

      if (!context.mounted) return;

      AppSnackbar.show(
        context,
        '${l10n.actionAddPlayer}: ${playerDisplayName(selected, unknownLabel: l10n.entityPlayerUnknown)}',
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
        result.smsSent) {
      return;
    }
    final error = result.error?.trim();
    if (error != null && error.isNotEmpty) {
      debugPrint('TeamDetailScreen member invitation SMS failed: $error');
    }
    AppSnackbar.show(
      context,
      kDebugMode && error != null && error.isNotEmpty
          ? l10n.errorGeneric(error)
          : l10n.memberInvitationSmsFailed,
      isError: true,
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

  bool _usesGrintaRosterPathFor(Team team) => _teamUsesGrintaRosterFor(team);

  GrintaPlayer? _grintaPlayerForMemberId(String memberId) {
    return _grintaEntryForMemberId(memberId, staff: false);
  }

  Future<void> _onEditPlayerPressed(
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

    final GrintaPlayer? existing = _grintaPlayerForMemberId(memberId);
    if (existing == null) return;

    final l10n = context.l10n;
    final AddGrintaPlayerDetails? details = await showAddGrintaPlayerSheet(
      context,
      member: row.player,
      existingGrintaPlayer: existing,
    );
    if (details == null || !context.mounted) return;

    try {
      MemberInvitationResult? invitationResult;
      String? invitationId = existing.invitationId;
      if (_phoneE164Changed(existing.phoneE164, details.phoneE164)) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: row.player,
          memberId: memberId,
          phoneE164: details.phoneE164,
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

      await _updateGrintaTeamPlayer(
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

  bool _phoneE164Changed(String? previous, String? next) {
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
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.textSecondary,
                side: BorderSide(color: appColors.border),
              ),
              child: Text(dialogL10n.actionCancel),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: appColors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(dialogL10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

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

        final List<GrintaPlayer> grintaPlayers =
            List<GrintaPlayer>.from(_team.grintaPlayers ?? const <GrintaPlayer>[]);
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

      if (!context.mounted) return;
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
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorDeleteFailed(e.toString()),
          ),
          backgroundColor: appColors.danger,
        ),
      );
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
      positions: <int>[details.roleCode],
      email: details.email,
      phoneE164: details.phoneE164,
      invitationId: invitationId,
    );

    debugPrint(
      'TeamDetailScreen._addStaffToGrintaTeam memberId=$memberId '
      'invitationId=$invitationId staff=$newStaff',
    );

    await TeamService().addManager(teamId: teamId, managerId: memberId);

    final String? staffUserId = profile.userID?.trim();
    if (staffUserId != null &&
        staffUserId.isNotEmpty &&
        staffUserId != memberId) {
      await TeamService().addManager(teamId: teamId, managerId: staffUserId);
      await TeamService().addUser(teamId: teamId, userId: staffUserId);
    }

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

    final List<dynamic> managers =
        List<dynamic>.from(_team.managers ?? const <dynamic>[]);
    if (!managers.contains(memberId)) {
      managers.add(memberId);
    }
    if (staffUserId != null &&
        staffUserId.isNotEmpty &&
        !managers.contains(staffUserId)) {
      managers.add(staffUserId);
    }
    _team.managers = managers;
  }

  Future<void> _addStaffToLegacyTeam({
    required String teamId,
    required String memberId,
    required AddGrintaStaffDetails details,
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

    final List<dynamic> managers =
        List<dynamic>.from(_team.managers ?? const <dynamic>[]);
    if (!managers.contains(memberId)) {
      managers.add(memberId);
    }
    _team.managers = managers;
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
    } else if (_legacyManagerRosterIds().contains(memberId)) {
      AppSnackbar.show(
        context,
        l10n.memberAlreadyOnTeamRoster,
        isError: true,
      );
      return;
    }

    final AddGrintaStaffDetails? details = await showAddGrintaStaffSheet(
      context,
      member: selected,
    );
    if (details == null || !context.mounted) return;

    try {
      MemberInvitationResult? invitationResult;
      if (_usesGrintaRosterPathFor(_team)) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: selected,
          memberId: memberId,
          phoneE164: details.phoneE164,
          teamId: teamId,
          seasonId: widget.seasonId,
          teamName: _team.name ?? '',
        );
        debugPrint(
          'TeamDetailScreen._onAddStaffPressed notifyOrInviteMember result=$invitationResult',
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
        await _addStaffToGrintaTeam(
          teamId: teamId,
          memberId: memberId,
          details: details,
          profile: selected,
          invitationId: invitationResult.invitationId,
        );
        debugPrint(
          'TeamDetailScreen._onAddStaffPressed added staff memberId=$memberId '
          'invitationId=${invitationResult.invitationId}',
        );
      } else {
        await _addStaffToLegacyTeam(
          teamId: teamId,
          memberId: memberId,
          details: details,
        );
      }

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
      if (_phoneE164Changed(existing.phoneE164, details.phoneE164)) {
        invitationResult =
            await MemberInvitationService.instance.notifyOrInviteMember(
          l10n: l10n,
          member: row.player,
          memberId: memberId,
          phoneE164: details.phoneE164,
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
      positions: <int>[details.roleCode],
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
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: appColors.textSecondary,
                side: BorderSide(color: appColors.border),
              ),
              child: Text(dialogL10n.actionCancel),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: appColors.danger,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(dialogL10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;

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

        final String? staffUserId = player.userID?.trim();
        await TeamService().removeGrintaStaff(
          teamId: teamId,
          playerId: memberId,
          extraManagerIds: staffUserId != null &&
                  staffUserId.isNotEmpty &&
                  staffUserId != memberId
              ? <String>[staffUserId]
              : const <String>[],
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

        final List<dynamic> managers =
            List<dynamic>.from(_team.managers ?? const <dynamic>[]);
        managers.remove(memberId);
        if (staffUserId != null &&
            staffUserId.isNotEmpty &&
            staffUserId != memberId) {
          managers.remove(staffUserId);
        }
        _team.managers = managers;
      } else if (row.effectives != null) {
        await EffectivesService().deleteEffectives(row.effectives!);
        final List<dynamic>? rawManagers = _team.managers;
        rawManagers?.remove(player.keyMember);
        _team.managers = rawManagers;
        await TeamService().updateTeam(_team);
      }

      if (!context.mounted) return;
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
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorDeleteFailed(e.toString()),
          ),
          backgroundColor: appColors.danger,
        ),
      );
    }
  }

  Widget _buildStaffCard(BuildContext context, List<_TeamMemberVm> staffRows) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.entityStaff,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_canManageTeam(context) &&
                  !_teamUsesExternalLegacyRoster()) ...[
                FilledButton(
                  onPressed: () => _onAddStaffPressed(context),
                  child: Text(l10n.actionAddStaff),
                ),
              ]
            ],
          ),
          const SizedBox(height: 24),
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

  Widget _buildTableHeader(BuildContext context) {
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
          if (_canManageRoster(context)) ...[
            _headerCell('', flex: 1, textTheme: textTheme),
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

    final Widget content = Align(
      alignment: center ? Alignment.center : Alignment.centerLeft,
      child: Row(
        mainAxisSize: center ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment:
        center ? MainAxisAlignment.center : MainAxisAlignment.start,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: odd
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
          if (_canManageRoster(context)) ...[
            Expanded(
              flex: 1,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleGhostButton(
                        icon: Icons.edit_outlined,
                        onTap: () => _onEditPlayerPressed(context, row),
                      ),
                      const SizedBox(width: 6),
                      _CircleGhostButton(
                        icon: Icons.delete_outline_rounded,
                        onTap: () => _onDeletePlayerPressed(context, row),
                      ),
                    ],
                  ),
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

  Widget _buildTrackerChipsCell(BuildContext context, _TeamMemberVm row) {
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

            return InputChip(
              label: Text(tracker.label),
              labelStyle: textTheme.bodySmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: colors.surface,
              side: BorderSide(
                color: colors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              deleteIcon: _canManageRoster(context)
                  ? Icon(
                Icons.delete_outline,
                size: 18,
                color: colors.danger,
              )
                  : null,
              onDeleted: _canManageRoster(context)
                  ? () async {
                await _deleteTrackerAffectation(
                  context: context,
                  row: row,
                  tracker: tracker,
                );
              }
                  : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }),
          if (_canManageRoster(context)) ...[
            _buildAddTrackerButton(
              context: context,
              row: row,
            ),
          ]

        ],
      ),
    );
  }
  Widget _buildAddTrackerButton({
    required BuildContext context,
    required _TeamMemberVm row,
  }) {
    final colors = context.appColors;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await _addTrackerAffectation(
          context: context,
          row: row,
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
  }) async {
    // Ouvre ici un Dialog ou BottomSheet permettant de sélectionner
    // un tracker supplémentaire à affecter au joueur.

    // Exemple :
    //
    // final selectedTracker = await showModalBottomSheet<Tracker>(
    //   context: context,
    //   builder: (_) => TrackerSelectionBottomSheet(
    //     playerId: row.player.id,
    //     alreadyAssignedTrackers: row.trackers,
    //   ),
    // );
    //
    // if (selectedTracker == null) return;
    //
    // await trackerService.assignTrackerToPlayer(
    //   playerId: row.player.id,
    //   trackerId: selectedTracker.id,
    // );
    //
    // setState(() {});
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

    // À adapter avec ton service / ta collection Firestore.
    //
    // await trackerService.removeTrackerFromPlayer(
    //   playerId: row.player.id,
    //   trackerId: tracker.id,
    // );

    // setState(() {});
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

